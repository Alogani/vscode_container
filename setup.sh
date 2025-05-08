#!/bin/bash

# Exit immediately if any command exits with a non-zero status
set -e

# Variables
REPO_URL="https://github.com/Alogani/vscode_container.git"
INSTALL_DIR="/opt/vscode_container"
CONTAINERS_DIR="$INSTALL_DIR/containers"
DEDICATED_USER="codeserver"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run with sudo or as root."
    exit 1
fi

DEFAULT_MAIN_USER="$(id -u --name)"
read -p "Enter the main user (default: $DEFAULT_MAIN_USER): " MAIN_USER
MAIN_USER="${MAIN_USER:-$DEFAULT_MAIN_USER}"

# Function to echo messages
echo_message() {
    echo -e "\n*** $1 ***\n"
}

# Function to check if a command exists
check_command() {
    if ! command -v "$1" > /dev/null 2>&1; then
        echo "ERROR: $1 is not installed. Please install it before proceeding."
        exit 1
    fi
}

# Function to warn about a missing command
warn_command() {
    if ! command -v "$1" > /dev/null 2>&1; then
        echo "WARNING: $1 is not installed. Some features may not work as expected."
    fi
}

check_command "podman"
warn_command "bindfs"

echo "All necessary tools are installed or warned. Proceeding with the setup..."

# Clone the repository
echo_message "Cloning the repository to $INSTALL_DIR"
if [ ! -d "$INSTALL_DIR" ]; then
    git clone "$REPO_URL" "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/src/*"
else
    echo "Directory $INSTALL_DIR already exists. Skipping cloning."
fi

# Create config and local directories
echo_message "Creating config and local directories"
mkdir -p "$INSTALL_DIR/config"
mkdir -p "$INSTALL_DIR/local"

# Create the dedicated user
echo_message "Creating dedicated user: $DEDICATED_USER"
if id "$DEDICATED_USER" >/dev/null 2>&1; then
    echo "User $DEDICATED_USER already exists."
else
    useradd -m -s /bin/bash "$DEDICATED_USER"
fi

# Modify the sudoers file
echo_message "Modifying the sudoers file"
SUDOERS_FILE="/etc/sudoers.d/$DEDICATED_USER"
if [ ! -f "$SUDOERS_FILE" ]; then
    echo "$MAIN_USER ALL=($DEDICATED_USER) NOPASSWD: ALL" >"$SUDOERS_FILE"
    chmod 440 "$SUDOERS_FILE"
else
    echo "Sudoers file for $DEDICATED_USER already exists."
fi

# Create containers directory and set ownership
echo_message "Setting ownership for $CONTAINERS_DIR"
mkdir -p "$CONTAINERS_DIR"
chown -R "$DEDICATED_USER:$DEDICATED_USER" "$INSTALL_DIR"

# Create a symbolic link for vscode_container.sh in /usr/local/bin
ln -sf "$INSTALL_DIR/src/vscode_container.sh" /usr/local/bin/vscode_container
echo "vscode_container.sh installed in /usr/local/bin/vscode_container (symlink)."

# Create a symbolic link for .desktop file in the user's .local/share/applications directory
DESKTOP_FILE="$INSTALL_DIR/org.alogani.vscode_container.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    sudo - $MAIN_USER -c sh -c """
      mkdir -p "$HOME/.local/share/applications"
      ln -s "$DESKTOP_FILE" "$HOME/.local/share/applications/"
      echo "Desktop file installed in $HOME/.local/share/applications (symlink)."
    """
else
    echo "Desktop file not found at $DESKTOP_FILE. Skipping installation."
fi


echo_message "Setup completed successfully!"
