terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.20"
    }
    vsphere = {
      source  = "hashicorp/vsphere"
      version = ">= 2.0"
    }
  }
}

provider "coder" {
}

# Terraform variables for vSphere

variable "vsphere_server" {
  type        = string
  description = "vSphere server URL (e.g., vcenter.example.com)"
}

variable "vsphere_user" {
  type        = string
  description = "vSphere username for authentication"
  sensitive   = true
}

variable "vsphere_password" {
  type        = string
  description = "vSphere password for authentication"
  sensitive   = true
}

variable "vsphere_datacenter" {
  type        = string
  description = "vSphere datacenter name"
}

variable "vsphere_datastore" {
  type        = string
  description = "vSphere datastore name"
}

variable "vsphere_cluster" {
  type        = string
  description = "vSphere cluster name"
}

variable "vsphere_network" {
  type        = string
  description = "vSphere network name"
}

variable "vsphere_template" {
  type        = string
  description = "vSphere VM template name to clone from"
}

variable "vsphere_folder" {
  type        = string
  description = "vSphere folder path for VMs (e.g., 'DC/vm/MyFolder' or 'MyFolder')"
}

provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "2"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
  option {
    name  = "6 Cores"
    value = "6"
  }
  option {
    name  = "8 Cores"
    value = "8"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in GB"
  default      = "4"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "2 GB"
    value = "2"
  }
  option {
    name  = "4 GB"
    value = "4"
  }
  option {
    name  = "8 GB"
    value = "8"
  }
  option {
    name  = "16 GB"
    value = "16"
  }
}

data "coder_parameter" "disk_size" {
  name         = "disk_size"
  display_name = "Disk Size"
  description  = "The disk size in GB"
  default      = "50"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 20
    max = 500
  }
}

data "coder_parameter" "coder_server_url" {
  name         = "coder_server_url"
  display_name = "Coder Server URL"
  description  = "Public URL/IP of your Coder server (e.g., http://10.x.x.x or https://coder.example.com)"
  type         = "string"
  default      = ""
  icon         = "/emojis/1f310.png"
  mutable      = false
}


locals {
  
  vm_name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
  coder_server_url = data.coder_parameter.coder_server_url.value
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# vSphere data sources

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "ds" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vsphere_template
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_folder" "folder" {
  count = var.vsphere_folder != "" ? 1 : 0
  path  = var.vsphere_folder
}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = ""

  env = {
    CODER_AGENT_URL     = local.coder_server_url
  }

  metadata {
    display_name = "CPU Usage"
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "RAM Usage"
    key          = "1_ram_usage"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Home Disk"
    key          = "3_home_disk"
    script       = "coder stat disk --path $${HOME}"
    interval     = 60
    timeout      = 1
  }
}


resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337?folder=/home/$${USER}"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

# vSphere VM resource

resource "vsphere_virtual_machine" "workspace" {
  count = data.coder_workspace.me.start_count
  
  name             = local.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id
  folder           = var.vsphere_folder != "" ? data.vsphere_folder.folder[0].path : null

  num_cpus               = tonumber(data.coder_parameter.cpu.value)
  memory                 = tonumber(data.coder_parameter.memory.value) * 1024
  guest_id               = data.vsphere_virtual_machine.template.guest_id
  scsi_type              = data.vsphere_virtual_machine.template.scsi_type
  firmware               = data.vsphere_virtual_machine.template.firmware
  scsi_bus_sharing       = data.vsphere_virtual_machine.template.scsi_bus_sharing

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    
    customize {
      linux_options {
        host_name = lower(replace(replace(local.vm_name, "_", "-"), ".", "-"))
        domain    = "local"
      }
      
      network_interface {
        ipv4_address = null
        ipv4_netmask = null
      }
    }
  }

  disk {
    label            = "disk0"
    size             = tonumber(data.coder_parameter.disk_size.value)
    eagerly_scrub    = false
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  # Use both guestinfo and vApp properties for maximum compatibility
  extra_config = {
    "guestinfo.userdata"          = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      coder_agent_token = coder_agent.main.token
      coder_agent_url   = local.coder_server_url
    }))
    "guestinfo.userdata.encoding" = "base64"
  }

  # Also set vApp properties (some vSphere setups prefer this)
  vapp {
    properties = {
      "user-data" = base64encode(templatefile("${path.module}/cloud-init.yaml", {
        coder_agent_token = coder_agent.main.token
        coder_agent_url   = local.coder_server_url
      }))
    }
  }

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
      disk[0].size,
    ]
  }
}


resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = vsphere_virtual_machine.workspace[0].id
  
  item {
    key   = "memory"
    value = "${data.coder_parameter.memory.value} GB"
  }
  
  item {
    key   = "disk"
    value = "${data.coder_parameter.disk_size.value} GB"
  }
  
  item {
    key   = "cpus"
    value = data.coder_parameter.cpu.value
  }
  
  item {
    key   = "vm_name"
    value = local.vm_name
  }
}