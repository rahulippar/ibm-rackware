
variable "TF_VERSION" {
  default     = "0.12"
  description = "terraform engine version to be used in schematics"
}

variable "image_url" {
  /* default = "cos://us-south/cos-davidng-south/RackWareRMMP2PBYOL.qcow2" */
  /* default = "cos://us-east/rackware-rmm-bucket/RackWareBYOLNov2021.qcow2" */
  /* default = "cos://us-east/rri-cos-wes-us-east/RRI_V2V_RMM_RackWareBYOLNov2021_RackWareBYOLNov2021.qcow2" */
  /* default = "cos://us-east/kal-rmm/rri_RackWareBYOLNov2021.qcow2" */
  default = "cos://us-east/kal-rmm/RMM_2022_02_28_RackWareRMMv7.4.0.561.qcow2"
}

/**
            End of the Provider code
*/

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.ibm_region
}

##################################################################################################

resource "ibm_is_vpc" "vpc" {
  name           = "${var.name}vpc"
  resource_group = data.ibm_resource_group.rg.id
}


data "ibm_resource_group" "rg" {
  name = var.resource_group
}

resource "ibm_is_security_group" "sg" {
  name           = "${var.name}sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.rg.id
}


resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "ssh_443" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "ssh_outbound" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

}

resource "ibm_is_subnet" "subnet" {
  name                     = "${var.name}subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = 8
  resource_group           = data.ibm_resource_group.rg.id
}


data "ibm_is_ssh_key" "ssh_key_id" {
  name = var.ssh_key
}


resource "ibm_is_image" "custom_image" {
  name             = "${var.name}-cent-os-7"
  href             = var.image_url
  operating_system = "centos-7-amd64"
  resource_group   = data.ibm_resource_group.rg.id
  timeouts {
    create = "90m"
    delete = "90m"
  }
}


resource "ibm_is_instance" "vsi" {
  name           = "${var.name}vsi"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.ssh_key_id.id]
  resource_group = data.ibm_resource_group.rg.id
  image          = ibm_is_image.custom_image.id
  profile        = var.profile

  user_data = file("download_discovery.sh")
  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.sg.id]
  }
}

resource "ibm_is_floating_ip" "fip" {
  name           = "${var.name}fip"
  target         = ibm_is_instance.vsi.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.rg.id
}

output "PUBLIC_IP" {
  value = ibm_is_floating_ip.fip.address
}

/**
Variable Section
*/

variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key needed to deploy IAM enabled resources"
  type        = string
}

variable "ssh_key" {
  description = "The IBM Cloud platform SSH keys"
  type        = string
}

variable "ibm_region" {
  description = "IBM Cloud region where all resources will be deployed"
  type        = string
}

variable "resource_group" {
  description = "Please enter yourcd  resource group name."
}

variable "profile" {
  default = "bx2-2x8"
}

variable "name" {
  description = "The name of VPC."
  type        = string
}

variable "zone" {
  description = "The value of the zone of VPC."
  type        = string
}
