terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.20"
    }
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = ">= 0.50"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "coder" {
}

# Terraform variables for Cloud Foundry

variable "cf_api_url" {
  type        = string
  description = "Cloud Foundry API URL (e.g., https://api.cf.example.com)"
  default     = ""
}

variable "cf_org" {
  type        = string
  description = "Cloud Foundry organization name"
  default     = ""
}

variable "cf_space" {
  type        = string
  description = "Cloud Foundry space name"
  default     = ""
}

variable "cf_user" {
  type        = string
  description = "Cloud Foundry username for authentication"
  sensitive   = true
  default     = ""
}

variable "cf_password" {
  type        = string
  description = "Cloud Foundry password for authentication"
  sensitive   = true
}

provider "cloudfoundry" {
  api_url              = var.cf_api_url
  user                 = var.cf_user
  password             = var.cf_password
  skip_ssl_validation  = true
}


data "coder_parameter" "cpu" {
  name         = "cpu"
  display_name = "CPU"
  description  = "The number of CPU cores"
  default      = "1"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "1 Core"
    value = "1"
  }
  option {
    name  = "2 Cores"
    value = "2"
  }
  option {
    name  = "4 Cores"
    value = "4"
  }
}

data "coder_parameter" "memory" {
  name         = "memory"
  display_name = "Memory"
  description  = "The amount of memory in MB"
  default      = "1024"
  icon         = "/icon/memory.svg"
  mutable      = true
  option {
    name  = "512 MB"
    value = "512"
  }
  option {
    name  = "1 GB"
    value = "1024"
  }
  option {
    name  = "2 GB"
    value = "2048"
  }
  option {
    name  = "4 GB"
    value = "4096"
  }
}

data "coder_parameter" "disk_quota" {
  name         = "disk_quota"
  display_name = "Disk Quota"
  description  = "The disk quota in MB"
  default      = "2048"
  type         = "number"
  icon         = "/emojis/1f4be.png"
  mutable      = false
  validation {
    min = 512
    max = 10240
  }
}

# Git Repository Parameters

data "coder_parameter" "git_repo_url" {
  name         = "git_repo_url"
  display_name = "Git Repository URL"
  description  = "Base URL of the self-hosted Git repository (e.g., https://git.example.com or https://git.example.com/org)"
  type         = "string"
  default      = "https://github.com"
  icon         = "/emojis/1f5c3.png"
  mutable      = false
}

data "coder_parameter" "git_repo_name" {
  name         = "git_repo_name"
  display_name = "Repository Name"
  description  = "Name of the repository to clone (e.g., my-project or org/my-project)"
  type         = "string"
  default      = "munishpalmakhija/coder-templates"
  icon         = "/emojis/1f4c1.png"
  mutable      = false
}

data "coder_parameter" "git_branch_name" {
  name         = "git_branch_name"
  display_name = "Branch Name"
  description  = "Branch name to clone (leave empty for default branch)"
  type         = "string"
  default      = "main"
  icon         = "/emojis/1f4cb.png"
  mutable      = false
}

data "coder_parameter" "git_api_token" {
  name         = "git_api_token"
  display_name = "Git API Token"
  description  = "API token for authenticating with the Git repository"
  type         = "string"
  default      = ""
  icon         = "/emojis/1f511.png"
  mutable      = false
}

data "coder_parameter" "coder_server_url" {
  name         = "coder_server_url"
  display_name = "Coder Server URL"
  description  = "Public URL/IP of your Coder server (e.g., http://10.0.0.100:80 or https://coder.example.com)"
  type         = "string"
  default      = ""
  icon         = "/emojis/1f310.png"
  mutable      = false
}


locals {
  git_full_url = data.coder_parameter.git_repo_url.value != "" && data.coder_parameter.git_repo_name.value != "" ? (
    "${trim(data.coder_parameter.git_repo_url.value, "/")}/${trim(data.coder_parameter.git_repo_name.value, "/")}"
  ) : ""
  
  git_repo_dir = data.coder_parameter.git_repo_name.value != "" ? (
    basename(data.coder_parameter.git_repo_name.value)
  ) : ""
  
  git_domain = data.coder_parameter.git_repo_url.value != "" ? (
    replace(replace(data.coder_parameter.git_repo_url.value, "https://", ""), "http://", "")
  ) : ""
  
  app_name = "coder-${data.coder_workspace_owner.me.name}-${lower(data.coder_workspace.me.name)}"
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}

# Create the app zip file from the app directory

data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/app.zip"
  excludes    = [".DS_Store"]
}

resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<-EOT
    set -e
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=$${HOME}/code-server
    $${HOME}/code-server/bin/code-server --auth none --port 13337 >$${HOME}/code-server.log 2>&1 &
  EOT

  env = {
    GIT_AUTHOR_NAME     = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL    = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME  = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
    GIT_API_TOKEN       = data.coder_parameter.git_api_token.value
    GIT_REPO_URL        = local.git_full_url
    GIT_DOMAIN          = local.git_domain
    CODER_AGENT_URL     = data.coder_parameter.coder_server_url.value != "" ? data.coder_parameter.coder_server_url.value : null
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

# Coder module for Cursor IDE support - placed after agent is defined

module "cursor" {
  source  = "registry.coder.com/coder/cursor/coder"
  
  agent_id = coder_agent.main.id
}

# Coder module for JetBrains Gateway support

module "jetbrains_gateway" {
  source  = "registry.coder.com/coder/jetbrains-gateway/coder"
  
  agent_id = coder_agent.main.id
  folder = local.git_repo_dir != "" ? "/home/vcap/${local.git_repo_dir}" : "/home/vcap"
}


resource "coder_script" "git_clone" {
  count = local.git_full_url != "" ? 1 : 0
  
  agent_id     = coder_agent.main.id
  display_name = "Clone Git Repository"
  icon         = "/emojis/1f4c1.png"
  
  script = <<-EOT
    #!/bin/bash
    set -e
    if ! command -v git &> /dev/null; then
      apt-get update
      apt-get install -y git
    fi
    REPO_DIR="$${HOME}/${local.git_repo_dir}"
    GIT_URL="$${GIT_REPO_URL}"
    GIT_TOKEN="$${GIT_API_TOKEN}"
    GIT_DOMAIN="$${GIT_DOMAIN}"
    BRANCH="${data.coder_parameter.git_branch_name.value}"
    if [ -n "$${GIT_TOKEN}" ] && [ -n "$${GIT_DOMAIN}" ]; then
      git config --global credential.helper store
      CREDENTIAL_FILE="$${HOME}/.git-credentials"
      echo "https://$${GIT_TOKEN}@$${GIT_DOMAIN}" > "$${CREDENTIAL_FILE}"
      chmod 600 "$${CREDENTIAL_FILE}"
      git config --global credential.https://$${GIT_DOMAIN}.helper store
    fi
    if [ ! -d "$${REPO_DIR}" ]; then
      echo "Cloning repository: $${GIT_URL}"
      if [ -n "$${GIT_TOKEN}" ]; then
        AUTH_URL="$${GIT_URL/https:\/\//https:\/\/$${GIT_TOKEN}@}"
        git clone "$${AUTH_URL}" "$${REPO_DIR}"
      else
        git clone "$${GIT_URL}" "$${REPO_DIR}"
      fi
      if [ -n "$${BRANCH}" ] && [ -d "$${REPO_DIR}" ]; then
        cd "$${REPO_DIR}"
        git fetch origin "$${BRANCH}" || git fetch origin
        git checkout "$${BRANCH}" 2>/dev/null || git checkout -b "$${BRANCH}" "origin/$${BRANCH}"
        echo "Checked out branch: $${BRANCH}"
      fi
    else
      echo "Repository already exists: $${REPO_DIR}"
      if [ -d "$${REPO_DIR}" ]; then
        cd "$${REPO_DIR}"
        git fetch origin
        if [ -n "$${BRANCH}" ]; then
          git checkout "$${BRANCH}" 2>/dev/null || git checkout -b "$${BRANCH}" "origin/$${BRANCH}"
          echo "Checked out branch: $${BRANCH}"
        fi
      fi
    fi
  EOT
  
  run_on_start = true
}

resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = local.git_repo_dir != "" ? "http://localhost:13337?folder=/home/vcap/${local.git_repo_dir}" : "http://localhost:13337?folder=/home/vcap"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

resource "cloudfoundry_app" "workspace" {
  count = data.coder_workspace.me.start_count
  
  name             = local.app_name
  org_name         = var.cf_org
  space_name       = var.cf_space
  instances        = 1
  memory           = "${data.coder_parameter.memory.value}M"
  disk_quota       = "${data.coder_parameter.disk_quota.value}M"
  buildpacks       = ["https://github.com/cloudfoundry/binary-buildpack.git"]
  enable_ssh       = true
  health_check_type = "process"
  
  path = data.archive_file.app_zip.output_path
  
  command = "./run.sh"
  
  environment = {
    CODER_AGENT_TOKEN = coder_agent.main.token
    CODER_AGENT_URL   = data.coder_parameter.coder_server_url.value
    GIT_AUTHOR_NAME   = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_AUTHOR_EMAIL  = data.coder_workspace_owner.me.email
    GIT_COMMITTER_NAME = coalesce(data.coder_workspace_owner.me.full_name, data.coder_workspace_owner.me.name)
    GIT_COMMITTER_EMAIL = data.coder_workspace_owner.me.email
    GIT_API_TOKEN     = data.coder_parameter.git_api_token.value
    GIT_REPO_URL      = local.git_full_url
    GIT_DOMAIN        = local.git_domain
  }
  
  depends_on = [data.archive_file.app_zip]
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = cloudfoundry_app.workspace[0].id
  
  item {
    key   = "memory"
    value = "${data.coder_parameter.memory.value} MB"
  }
  
  item {
    key   = "disk"
    value = "${data.coder_parameter.disk_quota.value} MB"
  }
  
  item {
    key   = "instances"
    value = "1"
  }
}