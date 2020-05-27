package api

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/inverse-inc/go-radius/dictionary"
	"github.com/julienschmidt/httprouter"
	"net/http"
)

var radiusAttributesJson string
var radiusAttributes []RadiusAttribute

type RadiusAttributeValue struct {
	Name  string `json:"name"`
	Value uint   `json:"value"`
}

func radisAttributesFilter(items []RadiusAttribute, filter func(ra *RadiusAttribute) bool) []RadiusAttribute {
	output := []RadiusAttribute{}
	for _, i := range items {
		if filter(&i) {
			output = append(output, i)
		}
	}

	return output
}

type RadiusAttribute struct {
	Name          string                 `json:"name"`
	AllowedValues []RadiusAttributeValue `json:"allowed_values"`
	PlaceHolder   string                 `json:"placeholder,omitempty"`
	Vendor        string                 `json:"vendor,omitempty"`
}

type RadiusAttributesResults struct {
    ApiError
	Items   []RadiusAttribute `json:"items,omitempty"`
}

func (h APIHandler) radiusAttributes(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, radiusAttributesJson)
}

type searchRequest struct {
	Query *Query `json:"query,omitempty"`
}

func (h APIHandler) searchRadiusAttributes(w http.ResponseWriter, r *http.Request, p httprouter.Params) {

	w.WriteHeader(http.StatusOK)
	b := bytes.NewBuffer(nil)
	b.ReadFrom(r.Body)
	search := &searchRequest{}
	json.Unmarshal(b.Bytes(), &search)
	var out []byte
	f, err := makeRadiusAttributeFilter(search.Query)
    searchResults := RadiusAttributesResults{ApiError:ApiError{Status: 200}}
	if err != nil {
		out, _ = json.Marshal(err)
        searchResults.ApiError = *err.(*ApiError)
	} else {
		searchResults.Items = radisAttributesFilter(radiusAttributes, f)
	}

    out, _ = json.Marshal(&searchResults)
	fmt.Fprintf(w, string(out))
}

func setupRadiusDictionary() {
	parser := &dictionary.Parser{
		Opener: &dictionary.FileSystemOpener{
			Root: "/usr/share/freeradius",
		},
		IgnoreIdenticalAttributes:  true,
		IgnoreUnknownAttributeType: true,
	}

	results := RadiusAttributesResults{}

	d, err := parser.ParseFile("/usr/local/pf/lib/pf/util/combined_dictionary")
	if err != nil {
		fmt.Println(err)
	} else {

		appendRadiusAttributes(&results.Items, d.Attributes, d.Values, "")

		for _, v := range d.Vendors {
			appendRadiusAttributes(&results.Items, v.Attributes, v.Values, v.Name)
		}
	}

	res, _ := json.Marshal(&results)
	radiusAttributesJson = string(res)
	radiusAttributes = results.Items
}

func appendRadiusAttributes(items *[]RadiusAttribute, attributes []*dictionary.Attribute, values []*dictionary.Value, vendor string) {
	for _, a := range attributes {
		var allowedValues []RadiusAttributeValue
		for _, v := range dictionary.ValuesByAttribute(values, a.Name) {
			allowedValues = append(allowedValues, RadiusAttributeValue{Name: v.Name, Value: v.Number})
		}

		*items = append(*items, RadiusAttribute{Name: a.Name, AllowedValues: allowedValues, PlaceHolder: placeHolders[a.Name], Vendor: vendor})
	}
}
