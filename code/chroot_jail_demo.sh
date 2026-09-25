#!/bin/bash
# chroot_jail_demo.sh
# credit: Google Gemini

# Ensure the script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script as root or with sudo."
  exit 1
fi

# 1. Configuration
JAIL_DIR="/var/chroot_jail"
COMMANDS=(bash ls pwd mkdir rm cp touch cat grep)

echo "=== Initializing Chroot Jail at $JAIL_DIR ==="

# 2. Create base directory structure
mkdir -p "$JAIL_DIR"/{bin,etc,lib,lib64,usr/bin,usr/lib}

# Helper function to find and copy dependencies; mostly shlibs
copy_deps() {
    local target_bin="$1"
    
    # Use ldd to find dependencies, extract absolute paths, and loop through them
    ldd "$target_bin" | grep -o '/[^-][^ ]*' | while read -r lib; do
        if [ -f "$lib" ]; then
            # Mirror the directory structure inside the jail
            local lib_dir=$(dirname "$lib")
            mkdir -p "${JAIL_DIR}${lib_dir}"
            
            # Copy the library if it doesn't already exist
            if [ ! -f "${JAIL_DIR}${lib}" ]; then
                cp "$lib" "${JAIL_DIR}${lib}"
            fi
        fi
    done
}

# 3. Process each configured command
for cmd in "${COMMANDS[@]}"; do
    # Locate the full path of the command on the host system
    cmd_path=$(which "$cmd" 2>/dev/null)
    
    if [ -n "$cmd_path" ] && [ -f "$cmd_path" ]; then
        echo "Processing: $cmd ($cmd_path)"
        
        # Mirror the command's parent directory inside the jail
        cmd_dir=$(dirname "$cmd_path")
        mkdir -p "${JAIL_DIR}${cmd_dir}"
        
        # Copy the command binary and its dependencies
        cp "$cmd_path" "${JAIL_DIR}${cmd_path}"
        copy_deps "$cmd_path"
    else
        echo "Warning: Command '$cmd' not found on host. Skipping."
    fi
done

# 4. Copy basic identity configuration files for terminal readability
cp /etc/passwd /etc/group "$JAIL_DIR/etc/" 2>/dev/null

echo "=== Chroot Jail Built Successfully! ==="
echo "You can now enter the jail by running:"
echo "sudo chroot $JAIL_DIR /usr/bin/bash"

