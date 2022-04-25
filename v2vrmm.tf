terraform {
  required_providers {
    ibm = {
      source  = "ibm-cloud/ibm"
      #version = "1.38.0"
    }
  }
  required_version = ">= 0.12"
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region = var.ibm_region
}

data "ibm_is_vpc" "vpc" {
  name = var.vpc_name
}

data "ibm_resource_group" "rg" {
  name = var.resource_group
}

data "ibm_is_subnet" "subnet" {
  name = var.subnet_name
}

data "ibm_is_ssh_key" "ssh_key_id" {
  name = var.ssh_key
}

resource "ibm_is_security_group" "sg" {
  name           = "${var.vpc_name}-sg"
  vpc            = data.ibm_is_vpc.vpc.id
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

resource "ibm_is_image" "custom_image" {
  name             = "${var.vpc_name}-cent-os-7"
  href             = var.image_url
  operating_system = "centos-7-amd64"
  resource_group   = data.ibm_resource_group.rg.id
  timeouts {
    create = "90m"
    delete = "90m"
  }
}

resource "ibm_is_instance" "vsi" {
  name           = "${var.vpc_name}-vsi"
  vpc            = data.ibm_is_vpc.vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.ssh_key_id.id]
  resource_group = data.ibm_resource_group.rg.id
  image          = ibm_is_image.custom_image.id
  profile        = var.profile

  user_data = file("download_discovery.sh")
  primary_network_interface {
    subnet          = data.ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.sg.id]
  }
}

resource "ibm_is_floating_ip" "fip" {
  count          = var.is_create_fip ? 1 : 0
  name           = "${var.vpc_name}-fip"
  target         = ibm_is_instance.vsi.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.rg.id
}

output "PUBLIC_IP" {
  description = "Public ip address of RMM server."
  value = var.is_create_fip ? ibm_is_floating_ip.fip[0].address : "Public IP address is not created."
}

variable "TF_VERSION" {
  default     = "0.12"
  description = "Terraform engine version to be used in schematics"
}

variable "image_url" {
  default = "cos://us-east/rackware-rmm-bucket/RackWareRMMv7.4.0.561.qcow2"
  description = "URL for source VSI image used to spin up instance."
}

variable "ibmcloud_api_key" {
  description = "Enter your IBM Cloud API Key, you can get your IBM Cloud API key using: https://cloud.ibm.com/iam#/apikeys"
  type        = string
}

variable "ssh_key" {
  description = "The IBM Cloud platform SSH keys."
  type        = string
}

variable "ibm_region" {
  description = "IBM Cloud region where all resources will be deployed."
  type        = string
}

variable "zone" {
  description = "The zone of VPC."
  type        = string
}

variable "resource_group" {
  description = "Resource group name."
}

variable "profile" {
  default = "bx2-2x8"
  description = "Profile for compute server."
}

variable "vpc_name" {
  description = "The name of VPC."
  type        = string
}

variable "subnet_name" {
  description = "The name of subnet."
  type        = string
}

variable "is_create_fip" {
  description = "Do you want to create and associate floating IP address?"
  type        = bool
  default     = false
}
