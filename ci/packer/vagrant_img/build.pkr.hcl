build {
  name = "dev"
  sources = [
    "source.vagrant.centos-7",
    "source.vagrant.debian-9"
  ]

  provisioner "ansible" {
    playbook_file = "${var.provisioner_dir}/site.yml"
    host_alias = "${var.pfserver_name}"
    groups = [
      "${var.ansible_pfservers_group}",
      "${var.ansible_group}",
    ]
    inventory_directory = "${var.provisioner_dir}/inventory"
    galaxy_file = "${var.provisioner_dir}/requirements.yml"
    galaxy_force_install = true
    use_proxy = false
  }

  provisioner "file" {
    only = ["vagrant.centos-7"]
    source = "${var.pfroot_dir}/rpm/packetfence.spec"
    destination = "${var.spec_file_path}"
  }
  
  provisioner "shell" {
    only = ["vagrant.centos-7"]
    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script = "${var.pfroot_dir}/addons/dev-helpers/centos-chroot/install-packages-from-spec.sh"
    environment_vars = [
      "SPEC=${var.spec_file_path}"
    ]
  }

  provisioner "shell" {
    only = ["vagrant.debian-9"]
    execute_command = "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'"
    script = "${var.pfroot_dir}/addons/dev-helpers/debian/install-pf-dependencies.sh"
  }

  post-processors {
    post-processor "vagrant-cloud" {
      box_tag = "inverse-inc/${var.pfserver_name}"
      version = "${var.box_version}"
      access_token = "${var.access_token}"
      version_description = "${var.box_description}"
      # temp workaround to a bug on Vagrant Cloud with Packer 1.6.6
      no_direct_upload = true
    }
  }
}

build {
  name = "stable"
  sources = [
    "source.vagrant.centos-7",
    "source.vagrant.debian-9"
  ]

  provisioner "ansible" {
    playbook_file = "${var.provisioner_dir}/site.yml"
    host_alias = "${var.pfserver_name}"
    groups = [
      "${var.ansible_pfservers_group}",
      "${var.ansible_group}",
    ]
    inventory_directory = "${var.provisioner_dir}/inventory"
    galaxy_file = "${var.provisioner_dir}/requirements.yml"
    galaxy_force_install = true
    use_proxy = false
  }

  post-processors {
    post-processor "vagrant-cloud" {
      box_tag = "inverse-inc/${var.pfserver_name}"
      version = "${var.box_version}"
      access_token = "${var.access_token}"
      version_description = "${var.box_description}"
      # temp workaround to a bug on Vagrant Cloud with Packer 1.6.6
      no_direct_upload = true
    }
  }
}
