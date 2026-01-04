---
display_name: Cloud Foundry Applications
description: Deploy Coder workspaces on Cloud Foundry Apps with pre-installed development tools and automatic Git repository cloning
icon: https://blogs.vmware.com/tanzu/wp-content/uploads/sites/154/2025/03/vmw-blogtile-tanzu-platform-v1-2.png?w=576&h=324&crop=1
maintainer_github: munishpalmakhija
verified: false
tags: [cloudfoundry, buildpack, git, tanzu, helm, bosh, cf-cli, jfrog, jfrog-cli, development-tools]
---

# Coder Workspaces on Cloud Foundry

Deploy [Coder workspaces](https://coder.com/docs/workspaces) as Cloud Foundry applications with pre-installed development tools. This template provisions development workspaces on Cloud Foundry infrastructure with automatic Git repository cloning, browser-based VS Code access.

## Features

- **Cloud Foundry Deployment**: Workspaces deployed as Cloud Foundry applications using buildpacks
- **Pre-installed Development Tools**: Multiple CLI tools automatically installed and configured:
  - **Tanzu CLI**: VMware Tanzu command-line interface
  - **Helm**: Kubernetes package manager
  - **CF CLI**: Cloud Foundry command-line interface
  - **BOSH CLI**: BOSH deployment and lifecycle management
  - **OM CLI**: Operations Manager command-line interface
  - **GitHub CLI**: GitHub command-line interface
  - **JFrog CLI**: JFrog command-line interface for Artifactory and Xray
- **IDE Support**: Multiple IDE options available:
  - **code-server**: Browser-based VS Code running on port 13337
  - **Cursor IDE**: AI-enhanced IDE via Cursor Desktop
  - **JetBrains Gateway**: Connect JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, etc.) to the workspace
- **Automatic Git Cloning**: Automatically clones self-hosted Git repositories with API token authentication
- **Branch Support**: Supports cloning specific branches from Git repositories
- **code-server**: Browser-based VS Code running on port 13337
- **Coder Agent**: Automatic connection to your Coder server for workspace management
- **Persistent Storage**: Files in `/home/vcap` persist across workspace restarts
- **SSH Access**: Enable SSH access to workspaces for troubleshooting

## Prerequisites

### Infrastructure

- **Cloud Foundry Foundation**: Access to a Cloud Foundry foundation with:
  - An organization and space where you can deploy applications
  - Sufficient quota for workspace instances
  - Network connectivity to your Coder server
  - Buildpack support enabled
  - SSH access enabled for applications

### Authentication

During template import, you'll need to provide:

- **Cloud Foundry API URL**: The API endpoint for your Cloud Foundry foundation (e.g., `https://api.cf.example.com`)
- **Cloud Foundry Organization**: The organization name
- **Cloud Foundry Space**: The space within the organization
- **Cloud Foundry Username**: Your Cloud Foundry username
- **Cloud Foundry Password**: Your Cloud Foundry password

### Coder Server Configuration

- **Coder Server URL**: The public URL/IP of your Coder server (e.g., `http://10.0.0.100:80` or `https://coder.example.com`)

### Resource Configuration

- **CPU**: Number of CPU cores (1, 2, or 4)
- **Memory**: Amount of memory in MB (512, 1024, 2048, or 4096)
- **Disk Quota**: Disk quota in MB (512-10240)

### Git Repository Configuration (Optional)

- **Git Repository URL**: Base URL of your self-hosted Git repository (e.g., `https://git.example.com` or `https://git.example.com/org`)
- **Repository Name**: Name of the repository to clone (e.g., `my-project` or `org/my-project`)
- **Branch Name**: Specific branch to checkout (optional, leave empty for default branch)
- **Git API Token**: API token for authenticating with the Git repository

## Architecture

This template provisions Coder workspaces as Cloud Foundry applications:

- **Cloud Foundry Application**: Each workspace is deployed as a Cloud Foundry app
- **Buildpack-based Deployment**: Uses the binary-buildpack to run the workspace runtime
- **Persistent Home Directory**: Files in `/home/vcap` persist across workspace restarts
- **code-server**: Browser-based VS Code running on port 13337
- **Coder Agent**: Connects the workspace back to your Coder server for management
- **Development Tools**: All CLI tools pre-installed in `/home/vcap/bin` and available in PATH
- **Git Repository**: Automatically cloned to `/home/vcap/<repository-name>` on workspace startup

## Installed Tools

All tools are automatically installed during workspace startup and are available in the workspace PATH:

### Tanzu CLI (vLatest)
- **Purpose**: VMware Tanzu command-line interface for managing Tanzu Kubernetes clusters and packages
- **Installation**: Downloaded from GitHub releases
- **Usage**: `tanzu version`, `tanzu cluster list`, `tanzu package install`
- **Documentation**: [Tanzu CLI Documentation](https://docs.vmware.com/en/VMware-Tanzu-CLI/index.html)

### Helm (v4.0.4)
- **Purpose**: Kubernetes package manager for managing applications and charts
- **Installation**: Downloaded from Helm releases
- **Usage**: `helm version`, `helm install`, `helm upgrade`, `helm list`
- **Documentation**: [Helm Documentation](https://helm.sh/docs/)

### Cloud Foundry CLI (v8.17.0)
- **Purpose**: Command-line interface for interacting with Cloud Foundry
- **Installation**: Downloaded from Cloud Foundry CLI releases
- **Usage**: `cf version`, `cf login`, `cf apps`, `cf push`
- **Documentation**: [CF CLI Documentation](https://docs.cloudfoundry.org/cf-cli/)

### BOSH CLI (v7.9.15)
- **Purpose**: BOSH deployment and lifecycle management tool
- **Installation**: Downloaded from BOSH CLI releases
- **Usage**: `bosh --version`, `bosh deployments`, `bosh vms`
- **Documentation**: [BOSH Documentation](https://bosh.io/docs/)

### OM CLI (v7.18.4)
- **Purpose**: Operations Manager command-line interface for managing Pivotal Operations Manager
- **Installation**: Downloaded from OM CLI releases
- **Usage**: `om version`, `om deployed-products`, `om staged-products`
- **Documentation**: [OM CLI Documentation](https://github.com/pivotal-cf/om)

### GitHub CLI (v2.83.2)
- **Purpose**: GitHub command-line interface for working with GitHub repositories and workflows
- **Installation**: Downloaded from GitHub CLI releases
- **Usage**: `gh --version`, `gh repo clone`, `gh pr create`, `gh issue list`
- **Documentation**: [GitHub CLI Documentation](https://cli.github.com/manual/)

### JFrog CLI (v2.87.0)
- **Purpose**: JFrog command-line interface for interacting with JFrog Artifactory, Xray, and Distribution
- **Installation**: Installed using official JFrog installer script (version 2.87.0)
- **Version**: To change the version, edit `app/run.sh` and modify `JFROG_CLI_VERSION` variable in the `install_jfrog_cli()` function
- **Usage**: 
  - Configure: `jf c add <server-id> --url="https://your-artifactory-url" --access-token="your-token"`
  - Search artifacts: `jf rt search "repo-name/*"`
  - Upload files: `jf rt upload`
  - Download files: `jf rt download`
  - Build info: `jf rt build-info`
- **Configuration**: Users can configure JFrog CLI with their own Artifactory credentials after workspace creation
- **Documentation**: [JFrog CLI Documentation](https://www.jfrog.com/confluence/display/CLI/JFrog+CLI)