terraform {
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = var.esxi_hostssl
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

resource "esxi_guest" "appserver" {
  guest_name = "week5-appserver"
  disk_store = "datastore1"

  memsize  = "2048"
  numvcpus = "1"

  ovf_source = var.ovf_file
  network_interfaces {
    virtual_network = "VM Network"
  }

  guestinfo = {
    "metadata"          = filebase64("../cloudinit/appserver/metadata.yaml")
    "metadata.encoding" = "base64"
    "userdata"          = filebase64("../cloudinit/userdata.yaml")
    "userdata.encoding" = "base64"
  }
}

resource "null_resource" "save_ips" {
  provisioner "local-exec" {
    command = <<EOT
cat > ../inventory.ini<< EOF
[all]
${esxi_guest.appserver.ip_address}

[webservers]
${esxi_guest.appserver.ip_address}

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_user=thomas
ansible_ssh_private_key_file=~/.ssh/skylab
EOF
    EOT
  }
}

output "ips" {
  value = {
    appserver = esxi_guest.appserver.ip_address
  }
}
