//go:build !test_radius
// +build !test_radius

package radius_proxy

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/inverse-inc/go-utils/sharedutils"
	"github.com/inverse-inc/packetfence/go/chisel/share/cio"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/cache"
)

const defaultRadiusAuthK8Filter = "app=radiusd-auth"

func isPodReady(pod *v1.Pod) bool {
	if pod.DeletionTimestamp != nil {
		return false
	}

	for _, cond := range pod.Status.Conditions {
		if cond.Type == v1.PodReady {
			return cond.Status == v1.ConditionTrue
		}
	}

	return false
}

func getPodHostPort(pod *v1.Pod) string {
	port, err := getPodPort(pod)
	if err != nil {
		return pod.Status.PodIP + ":1812"
	}

	return fmt.Sprintf("%s:%d", pod.Status.PodIP, port)
}

func getPodPort(pod *v1.Pod) (int, error) {
	if len(pod.Spec.Containers) == 0 {
		return -1, errors.New("No Containers found")
	}

	ports := pod.Spec.Containers[0].Ports

	if len(ports) == 0 {
		return -1, errors.New("No port found")
	}

	return int(ports[0].ContainerPort), nil

}

func clientSetFromEnv() (*kubernetes.Clientset, error) {
	host := os.Getenv("K8S_MASTER_URI")
	if host == "" {
		return nil, errors.New("K8S_MASTER_URI is not defined")
	}

	token := os.Getenv("K8S_MASTER_TOKEN")
	if token == "" {
		return nil, errors.New("K8_MASTER_TOKEN is not defined")
	}

	return kubernetes.NewForConfig(
		&rest.Config{
			Host:            host,
			BearerToken:     token,
			TLSClientConfig: TLSClientConfigFromEnv(),
		},
	)
}

func getRadiusAuthFilter() string {
	if filter := os.Getenv("K8S_RADIUS_AUTH_FILTER"); filter != "" {
		return filter
	}

	return defaultRadiusAuthK8Filter
}

func NewRadiusProxyFromKubernetes(l *cio.Logger, radiusSecret string) (*Proxy, chan struct{}, error) {
	clientset, err := clientSetFromEnv()
	if err != nil {
		return nil, nil, err
	}

	data, err := os.ReadFile(os.Getenv("K8S_NAMESPACE_PATH"))
	if err != nil {
		return nil, nil, err
	}

	filter := getRadiusAuthFilter()

	namespace := string(data)
	pods, err := clientset.CoreV1().Pods(namespace).List(context.TODO(), metav1.ListOptions{LabelSelector: filter})
	if err != nil {
		return nil, nil, err
	}

	servers := []string{}
	for _, p := range pods.Items {
		addr := getPodHostPort(&p)
		l.Infof("Adding address %s", addr)
		servers = append(servers, addr)
	}

	radiusProxy := NewProxy(
		&ProxyConfig{
			Secret:         []byte(radiusSecret),
			Addrs:          servers,
			SessionTimeout: 20 * time.Second,
			Logger:         l,
		},
	)

	watchlist := cache.NewFilteredListWatchFromClient(
		clientset.CoreV1().RESTClient(),
		string(v1.ResourcePods),
		namespace,
		func(opts *metav1.ListOptions) {
			opts.LabelSelector = filter
		},
	)

	_, controller := cache.NewInformer( // also take a look at NewSharedIndexInformer
		watchlist,
		&v1.Pod{},
		0, //Duration is int64
		cache.ResourceEventHandlerFuncs{
			AddFunc: func(obj interface{}) {
				pod := obj.(*v1.Pod)
				if isPodReady(pod) {
					address := getPodHostPort(pod)
					l.Infof("Adding %s", address)
					radiusProxy.AddBackend(address)
					return
				}
			},
			DeleteFunc: func(obj interface{}) {
				pod := obj.(*v1.Pod)
				address := getPodHostPort(pod)
				l.Infof("Removing %s", address)
				radiusProxy.DeleteBackend(address)
			},
			UpdateFunc: func(oldObj, newObj interface{}) {
				pod := newObj.(*v1.Pod)
				if isPodReady(pod) {
					address := getPodHostPort(pod)
					l.Infof("Adding %s", address)
					radiusProxy.AddBackend(address)
					return
				}

				if pod.DeletionTimestamp != nil {
					address := getPodHostPort(pod)
					l.Infof("%s is terminating removing", address)
					radiusProxy.DeleteBackend(address)
				}
			},
		},
	)
	stop := make(chan struct{})
	go controller.Run(stop)

	return radiusProxy, stop, nil
}

func TLSClientConfigFromEnv() rest.TLSClientConfig {
	caFile := sharedutils.EnvOrDefault("K8S_MASTER_CA_FILE", "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
	return rest.TLSClientConfig{
		CAFile: caFile,
	}
}

func TLSConfigFromEnv() *tls.Config {
	caCerts := []byte(sharedutils.ReadFromFileOrStr(sharedutils.EnvOrDefault("K8S_MASTER_CA_FILE", "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")))
	rootCAs, _ := x509.SystemCertPool()
	if rootCAs == nil {
		rootCAs = x509.NewCertPool()
	}

	if ok := rootCAs.AppendCertsFromPEM(caCerts); !ok {
		fmt.Println("No K8S CA cert appended, using system certs only")
	}

	return &tls.Config{
		RootCAs: rootCAs,
	}
}
