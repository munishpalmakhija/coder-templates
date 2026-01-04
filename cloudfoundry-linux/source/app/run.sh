#Author - Munishpal Makhija

#    ===========================================================================
#    Created by:    Munishpal Makhija
#    Version:       1.0
#    Blog:          https://munishpalmakhija.com
#    Twitter:       @munishpal_singh
#  
set +e

export HOME=/home/vcap
export PATH=$HOME/code-server/bin:$HOME/bin:$PATH

echo "=== Starting Coder workspace with Development Tools ==="

# Detect OS and architecture
TARGETOS="linux"
TARGETARCH="amd64"

# Install code-server
echo "Installing code-server..."
curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=$HOME/code-server || {
  echo "Error: Failed to install code-server"
  exit 1
}

# Function to install a tool (non-fatal)
install_tool() {
  local tool_name=$1
  local install_func=$2
  
  echo "Installing $tool_name..."
  if $install_func; then
    echo "$tool_name installed successfully"
    return 0
  else
    echo "Warning: $tool_name installation failed, but continuing..."
    return 1
  fi
}

# Function to install Tanzu CLI
install_tanzu_cli() {
  mkdir -p $HOME/bin
  
  # Check if Tanzu CLI is already installed
  if command -v tanzu &> /dev/null; then
    echo "Tanzu CLI already installed"
    tanzu version
    return 0
  fi
  
  # Try binary download method first (most reliable in Cloud Foundry)
  echo "Downloading Tanzu CLI binary..."
  TANZU_URL="https://github.com/vmware-tanzu/tanzu-cli/releases/latest/download/tanzu-cli-linux-amd64.tar.gz"
  
  cd $HOME/bin || return 1
  
  # Download the binary
  if curl -fsSL -L "$TANZU_URL" -o tanzu-cli.tar.gz 2>&1; then
    echo "Extracting Tanzu CLI..."
    if tar -xzf tanzu-cli.tar.gz 2>&1; then
      # Find the tanzu binary - it might be in a subdirectory or directly in current dir
      TANZU_BINARY=$(find . -type f \( -name "tanzu" -o -name "tanzu-cli-linux_amd64" \) -executable | head -n 1)
      
      if [ -z "$TANZU_BINARY" ]; then
        # If not found, look for any executable file
        TANZU_BINARY=$(find . -type f -executable | head -n 1)
      fi
      
      if [ -n "$TANZU_BINARY" ] && [ -f "$TANZU_BINARY" ]; then
        echo "Found Tanzu CLI binary at: $TANZU_BINARY"
        # Move it to $HOME/bin/tanzu
        mv "$TANZU_BINARY" $HOME/bin/tanzu
        chmod +x $HOME/bin/tanzu
        
        # Clean up extracted files and archive
        rm -rf $HOME/bin/v* 2>/dev/null  # Remove version directories like v1.5.3
        rm -f tanzu-cli.tar.gz
        cd $HOME
        
        # Verify installation
        if $HOME/bin/tanzu version > /dev/null 2>&1; then
          echo "Tanzu CLI installed successfully:"
          $HOME/bin/tanzu version
          return 0
        else
          echo "Warning: Tanzu CLI binary found but version check failed"
          return 1
        fi
      else
        echo "Warning: Could not find tanzu binary in archive"
        rm -f tanzu-cli.tar.gz
        cd $HOME
        return 1
      fi
    else
      echo "Warning: Failed to extract Tanzu CLI archive"
      rm -f tanzu-cli.tar.gz
      cd $HOME
      return 1
    fi
  else
    echo "Warning: Failed to download Tanzu CLI"
    cd $HOME
    return 1
  fi
}

# Function to install GitHub CLI
install_gh_cli() {
  local GH_CLI_VERSION="2.83.2"
  mkdir -p $HOME/bin
  
  if command -v gh &> /dev/null; then
    echo "GitHub CLI already installed"
    gh --version
    return 0
  fi
  
  cd $HOME/bin || return 1
  
  local GH_URL="https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_${TARGETOS}_${TARGETARCH}.tar.gz"
  
  if curl -fsSL -L "$GH_URL" -o gh-cli.tar.gz 2>&1; then
    if tar -xzf gh-cli.tar.gz 2>&1; then
      # Move gh binary from subdirectory
      if [ -f "gh_${GH_CLI_VERSION}_${TARGETOS}_${TARGETARCH}/bin/gh" ]; then
        mv "gh_${GH_CLI_VERSION}_${TARGETOS}_${TARGETARCH}/bin/gh" $HOME/bin/gh
        chmod +x $HOME/bin/gh
        rm -rf "gh_${GH_CLI_VERSION}_${TARGETOS}_${TARGETARCH}" gh-cli.tar.gz
        cd $HOME
        
        if $HOME/bin/gh --version > /dev/null 2>&1; then
          return 0
        fi
      fi
    fi
    rm -f gh-cli.tar.gz
  fi
  
  cd $HOME
  return 1
}

# Function to install Helm
install_helm() {
  local HELM_VERSION="4.0.4"
  mkdir -p $HOME/bin
  
  if command -v helm &> /dev/null; then
    echo "Helm already installed"
    helm version
    return 0
  fi
  
  cd $HOME/bin || return 1
  
  local HELM_URL="https://get.helm.sh/helm-v${HELM_VERSION}-${TARGETOS}-${TARGETARCH}.tar.gz"
  
  if curl -fsSL -L "$HELM_URL" -o helm.tar.gz 2>&1; then
    if tar -xzf helm.tar.gz 2>&1; then
      # Find helm binary (usually in ${TARGETOS}-${TARGETARCH}/helm)
      local HELM_BINARY=$(find . -name "helm" -type f -executable | head -n 1)
      if [ -n "$HELM_BINARY" ] && [ -f "$HELM_BINARY" ]; then
        mv "$HELM_BINARY" $HOME/bin/helm
        chmod +x $HOME/bin/helm
        rm -rf ${TARGETOS}-${TARGETARCH} helm.tar.gz 2>/dev/null
        cd $HOME
        
        if $HOME/bin/helm version > /dev/null 2>&1; then
          return 0
        fi
      fi
    fi
    rm -f helm.tar.gz
  fi
  
  cd $HOME
  return 1
}

# Function to install OM CLI
install_om_cli() {
  local OM_VERSION="7.18.4"
  mkdir -p $HOME/bin
  
  if command -v om &> /dev/null; then
    echo "OM CLI already installed"
    om version
    return 0
  fi
  
  cd $HOME/bin || return 1
  
  local OM_URL="https://github.com/pivotal-cf/om/releases/download/${OM_VERSION}/om-${TARGETOS}-${TARGETARCH}-${OM_VERSION}.tar.gz"
  
  if curl -fsSL -L "$OM_URL" -o om-cli.tar.gz 2>&1; then
    if tar -xzf om-cli.tar.gz 2>&1; then
      # OM binary is usually directly in the archive
      if [ -f "om" ]; then
        chmod +x om
        mv om $HOME/bin/om
        rm -f om-cli.tar.gz
        cd $HOME
        
        if $HOME/bin/om version > /dev/null 2>&1; then
          return 0
        fi
      fi
    fi
    rm -f om-cli.tar.gz
  fi
  
  cd $HOME
  return 1
}

# Function to install BOSH CLI
install_bosh_cli() {
  local BOSH_CLI_VERSION="7.9.15"
  mkdir -p $HOME/bin
  
  if command -v bosh &> /dev/null; then
    echo "BOSH CLI already installed"
    bosh --version
    return 0
  fi
  
  cd $HOME/bin || return 1
  
  local BOSH_URL="https://github.com/cloudfoundry/bosh-cli/releases/download/v${BOSH_CLI_VERSION}/bosh-cli-${BOSH_CLI_VERSION}-${TARGETOS}-${TARGETARCH}"
  
  if curl -fsSL -L "$BOSH_URL" -o bosh 2>&1; then
    chmod +x bosh
    mv bosh $HOME/bin/bosh
    cd $HOME
    
    if $HOME/bin/bosh --version > /dev/null 2>&1; then
      return 0
    fi
  fi
  
  cd $HOME
  return 1
}

# Function to install CF CLI
install_cf_cli() {
  local CF_CLI_VERSION="8.17.0"
  mkdir -p $HOME/bin
  
  if command -v cf &> /dev/null; then
    echo "CF CLI already installed"
    cf version
    return 0
  fi
  
  cd $HOME/bin || return 1
  
  local CF_URL="https://github.com/cloudfoundry/cli/releases/download/v${CF_CLI_VERSION}/cf8-cli_${CF_CLI_VERSION}_${TARGETOS}_x86-64.tgz"
  
  if curl -fsSL -L "$CF_URL" -o cf-cli.tgz 2>&1; then
    if tar -xzf cf-cli.tgz 2>&1; then
      # CF CLI binary is usually in the root of the archive
      local CF_BINARY=$(find . -name "cf" -type f -executable | head -n 1)
      if [ -n "$CF_BINARY" ] && [ -f "$CF_BINARY" ]; then
        mv "$CF_BINARY" $HOME/bin/cf
        chmod +x $HOME/bin/cf
        # Clean up any extracted directories
        rm -rf cf* 2>/dev/null || true
        cd $HOME
        
        if $HOME/bin/cf version > /dev/null 2>&1; then
          return 0
        fi
      fi
    fi
    rm -f cf-cli.tgz
  fi
  
  cd $HOME
  return 1
}

# Function to install JFrog CLI
install_jfrog_cli() {
  local JFROG_CLI_VERSION="2.87.0"
  mkdir -p $HOME/bin
  
  if command -v jf &> /dev/null; then
    echo "JFrog CLI already installed"
    jf --version
    return 0
  fi
  
  cd $HOME/bin || return 1
  
  echo "Installing JFrog CLI version $JFROG_CLI_VERSION..."
  
  # Try using the installer but with version override
  INSTALLER_SCRIPT=$(curl -s "https://install-cli.jfrog.io")
  
  # Modify installer to use specific version and install location
  MODIFIED_SCRIPT=$(echo "$INSTALLER_SCRIPT" | \
    sed "s|/usr/local/bin|$HOME/bin|g" | \
    sed "s|sudo ||g" | \
    sed "s|Please approve this installation by entering your password||g" | \
    sed "s|We'd like to install.*Please approve||g")
  
  # Try to override version detection in the script
  # The installer typically gets version from GitHub API or uses "latest"
  # We'll inject our version before the download happens
  MODIFIED_SCRIPT=$(echo "$MODIFIED_SCRIPT" | \
    awk -v version="$JFROG_CLI_VERSION" '
      /VERSION=/ { print "VERSION=\"" version "\""; next }
      /get_latest_version|latest/ { gsub(/latest|get_latest_version/, version); }
      { print }
    ')
  
  # Execute
  echo "$MODIFIED_SCRIPT" | bash 2>&1
  
  # Verify
  if [ -f "$HOME/bin/jf" ] && [ -x "$HOME/bin/jf" ]; then
    if $HOME/bin/jf --version > /dev/null 2>&1; then
      echo "JFrog CLI installed successfully"
      cd $HOME
      return 0
    else
      echo "JFrog CLI binary installed"
      cd $HOME
      return 0
    fi
  fi
  
  cd $HOME
  return 1
}

# Install all tools (non-fatal - workspace should still start)
echo "=== Installing Development Tools ==="

install_tool "Tanzu CLI" install_tanzu_cli
install_tool "GitHub CLI" install_gh_cli
install_tool "Helm" install_helm
install_tool "OM CLI" install_om_cli
install_tool "BOSH CLI" install_bosh_cli
install_tool "CF CLI" install_cf_cli
install_tool "JFrog CLI" install_jfrog_cli

# Verify installed tools
echo ""
echo "=== Installed Tools Summary ==="
for tool in tanzu gh helm om bosh cf jf; do
  if command -v $tool &> /dev/null; then
    echo "✅ $tool: $(command -v $tool)"
    $tool --version 2>/dev/null | head -n 1 || $tool version 2>/dev/null | head -n 1 || echo "   (installed but version check unavailable)"
  else
    echo "❌ $tool: Not found"
  fi
done

# Start code-server
echo ""
echo "Starting code-server on port 13337..."
$HOME/code-server/bin/code-server --auth none --port 13337 >$HOME/code-server.log 2>&1 &

# Wait a moment for code-server to start
sleep 2

# Download and run Coder agent
if [ -n "$CODER_AGENT_TOKEN" ] && [ -n "$CODER_AGENT_URL" ]; then
  echo "Setting up Coder agent..."
  echo "Coder server URL: $CODER_AGENT_URL"
  
  mkdir -p $HOME/bin
  cd $HOME/bin
  
  # Download agent binary from Coder server
  echo "Downloading Coder agent binary..."
  if curl -fsSL "${CODER_AGENT_URL}/bin/coder-linux-amd64" -o coder 2>&1; then
    chmod +x coder
    
    # Verify the binary
    if ./coder --version > /dev/null 2>&1; then
      # Run the agent
      echo "Starting Coder agent..."
      export CODER_AGENT_AUTH="token"
      ./coder agent &
      echo "Coder agent started"
    else
      echo "Error: Downloaded Coder binary is not valid, trying GitHub fallback..."
      # Fallback: try GitHub release
      if curl -fsSL "https://github.com/coder/coder/releases/latest/download/coder_linux_amd64" -o coder 2>&1; then
        chmod +x coder
        if ./coder --version > /dev/null 2>&1; then
          export CODER_AGENT_AUTH="token"
          ./coder agent &
          echo "Coder agent started (from GitHub)"
        else
          echo "Error: GitHub Coder binary is also not valid"
        fi
      else
        echo "Error: Could not download Coder agent binary from GitHub"
      fi
    fi
  else
    echo "Failed to download from Coder server, trying GitHub fallback..."
    # Fallback: try GitHub release
    if curl -fsSL "https://github.com/coder/coder/releases/latest/download/coder_linux_amd64" -o coder 2>&1; then
      chmod +x coder
      if ./coder --version > /dev/null 2>&1; then
        export CODER_AGENT_AUTH="token"
        ./coder agent &
        echo "Coder agent started (from GitHub)"
      else
        echo "Error: GitHub Coder binary is not valid"
      fi
    else
      echo "Error: Could not download Coder agent binary"
    fi
  fi
  
  cd $HOME
else
  echo "Warning: CODER_AGENT_TOKEN or CODER_AGENT_URL not set"
fi

# Keep container alive - tail code-server logs
echo ""
echo "Workspace ready. Keeping container alive..."
tail -f $HOME/code-server.log
