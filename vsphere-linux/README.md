---
display_name: vSphere Linux VMs
description: Deploy Coder workspaces on vSphere VMs with browser-based VS Code access
icon: https://www.vmware.com/content/dam/digitalmarketing/vmware/en/images/icons/vmw-vsphere-icon.png
maintainer_github: munishpalmakhija
verified: false
tags: [vsphere, vmware, linux, cloud-init]
---

# Coder Workspaces on vSphere VMs

Deploy [Coder workspaces](https://coder.com/docs/workspaces) as vSphere virtual machines. This template provisions development workspaces on vSphere infrastructure with browser-based VS Code access and cloud-init-based initialization.

## Features

- **vSphere VM Deployment**: Workspaces deployed as vSphere virtual machines cloned from a template
- **Cloud-init Integration**: Automatic initialization using cloud-init with VMware guestinfo support
- **Coder Agent**: Automatically installed and configured to connect to your Coder server
- **IDE Support**: Browser-based VS Code access:
  - **code-server**: Browser-based VS Code running on port 13337
- **Environment Variables**: Coder configuration automatically set as environment variables
- **Persistent Storage**: VM disk storage persists across workspace restarts
- **SSH Access**: Standard SSH access to VMs for troubleshooting

## Prerequisites

### Infrastructure

- **vSphere Environment**: Access to a vSphere/vCenter server with:
  - A datacenter, cluster, datastore, and network configured
  - A VM template with Linux OS pre-installed (Ubuntu recommended)
  - Network connectivity to your Coder server
  - Sufficient resources (CPU, memory, storage) for workspace instances
  - Permissions to create and manage VMs

### VM Template Requirements

Your vSphere VM template must be configured with the following:

#### Required Template Configuration

- **Install Required packages**: The template must have common packages such as Cloud-init and VMware tools. It is essential for automatic VM configuration. It reads configuration data from vSphere guestinfo properties and applies it on first boot.
- **VMware Datasource Configuration**: Create a configuration file to tell cloud-init to read from VMware guestinfo. 
- **Cloud-init Services Enabled**: Ensure required services are enabled
- **Passwordless Sudo**: The default user (typically `ubuntu`) must have passwordless sudo access
- **Home Directory**: Ensure the user's home directory exists and has correct permissionsash
- **Base Packages**: Install essential packages that will be needed by the Coder agent and code-server
- **Clean Cloud-init State**: Before converting the VM to a template, you must clean all cloud-init state. This ensures that cloud-init will run fresh on each cloned VM
