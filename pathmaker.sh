#!/bin/bash

#############################################
# PathMaker - Tool Path Installer
# Installs scripts/tools to PATH for easy access
# Usage: ./pathmaker.sh <script-path> <command-name>
#############################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}    PathMaker v1.0${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}[!] Error: Missing arguments${NC}"
    echo -e "${YELLOW}Usage: $0 <script-path> <command-name>${NC}"
    echo -e "${YELLOW}Example: $0 /path/to/shortecho.py shortecho${NC}"
    exit 1
fi

SCRIPT_PATH="$1"
COMMAND_NAME="$2"

# Check if script exists
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${RED}[!] Error: Script not found: $SCRIPT_PATH${NC}"
    exit 1
fi

# Get absolute path
SCRIPT_PATH=$(realpath "$SCRIPT_PATH")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
SCRIPT_NAME=$(basename "$SCRIPT_PATH")

echo -e "${BLUE}[*] Script: ${SCRIPT_PATH}${NC}"
echo -e "${BLUE}[*] Command name: ${COMMAND_NAME}${NC}\n"

# Determine installation directory
# Try ~/.local/bin first (no sudo needed), fallback to /usr/local/bin
if [ -d "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
    NEEDS_SUDO=false
elif [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
    NEEDS_SUDO=false
else
    INSTALL_DIR="/usr/local/bin"
    NEEDS_SUDO=true
fi

echo -e "${BLUE}[*] Installation directory: ${INSTALL_DIR}${NC}"

# Create ~/.local/bin if it doesn't exist
if [ "$INSTALL_DIR" = "$HOME/.local/bin" ] && [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}[*] Creating $INSTALL_DIR${NC}"
    mkdir -p "$INSTALL_DIR"
fi

# Check if command already exists
WRAPPER_PATH="$INSTALL_DIR/$COMMAND_NAME"
if [ -f "$WRAPPER_PATH" ]; then
    echo -e "${YELLOW}[!] Warning: Command '$COMMAND_NAME' already exists${NC}"
    read -p "Overwrite? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}[!] Installation cancelled${NC}"
        exit 1
    fi
fi

# Detect script type
SCRIPT_TYPE="unknown"
if [[ "$SCRIPT_NAME" == *.py ]]; then
    SCRIPT_TYPE="python"
    # Check if script has shebang
    FIRST_LINE=$(head -n 1 "$SCRIPT_PATH")
    if [[ "$FIRST_LINE" =~ ^#! ]]; then
        HAS_SHEBANG=true
    else
        HAS_SHEBANG=false
    fi
elif [[ "$SCRIPT_NAME" == *.sh ]]; then
    SCRIPT_TYPE="bash"
    HAS_SHEBANG=true
elif [ -x "$SCRIPT_PATH" ]; then
    SCRIPT_TYPE="executable"
    HAS_SHEBANG=true
else
    # Check if it has a shebang to determine type
    FIRST_LINE=$(head -n 1 "$SCRIPT_PATH")
    if [[ "$FIRST_LINE" =~ ^#!/usr/bin/env\ python || "$FIRST_LINE" =~ ^#!/usr/bin/python ]]; then
        SCRIPT_TYPE="python"
        HAS_SHEBANG=true
    elif [[ "$FIRST_LINE" =~ ^#!/bin/bash || "$FIRST_LINE" =~ ^#!/bin/sh ]]; then
        SCRIPT_TYPE="bash"
        HAS_SHEBANG=true
    fi
fi

echo -e "${BLUE}[*] Detected script type: ${SCRIPT_TYPE}${NC}"

# Create wrapper script
echo -e "${YELLOW}[*] Creating wrapper script...${NC}"

WRAPPER_CONTENT=""

if [ "$SCRIPT_TYPE" = "python" ] && [ "$HAS_SHEBANG" = false ]; then
    # Python script without shebang - create wrapper
    WRAPPER_CONTENT="#!/bin/bash
# Wrapper created by PathMaker for $SCRIPT_NAME
cd \"$SCRIPT_DIR\"
python3 \"$SCRIPT_PATH\" \"\$@\"
"
elif [ "$SCRIPT_TYPE" = "python" ] || [ "$SCRIPT_TYPE" = "bash" ] || [ "$SCRIPT_TYPE" = "executable" ]; then
    # Script with shebang or executable - create simple wrapper
    WRAPPER_CONTENT="#!/bin/bash
# Wrapper created by PathMaker for $SCRIPT_NAME
cd \"$SCRIPT_DIR\"
\"$SCRIPT_PATH\" \"\$@\"
"
else
    echo -e "${RED}[!] Error: Unable to determine how to execute script${NC}"
    echo -e "${YELLOW}[*] Make sure the script has a proper shebang or is a known file type${NC}"
    exit 1
fi

# Write wrapper script
if [ "$NEEDS_SUDO" = true ]; then
    echo -e "${YELLOW}[!] Requires sudo to write to $INSTALL_DIR${NC}"
    echo "$WRAPPER_CONTENT" | sudo tee "$WRAPPER_PATH" > /dev/null
    sudo chmod +x "$WRAPPER_PATH"
else
    echo "$WRAPPER_CONTENT" > "$WRAPPER_PATH"
    chmod +x "$WRAPPER_PATH"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[+] Wrapper script created: $WRAPPER_PATH${NC}"
else
    echo -e "${RED}[!] Error: Failed to create wrapper script${NC}"
    exit 1
fi

# Check if directory is in PATH
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    echo -e "${GREEN}[+] $INSTALL_DIR is already in PATH${NC}"
else
    echo -e "${YELLOW}[!] Warning: $INSTALL_DIR is not in PATH${NC}"
    
    # Detect shell
    SHELL_NAME=$(basename "$SHELL")
    if [ "$SHELL_NAME" = "zsh" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ "$SHELL_NAME" = "bash" ]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    echo -e "${BLUE}[*] Detected shell: $SHELL_NAME${NC}"
    echo -e "${BLUE}[*] Config file: $SHELL_RC${NC}"
    
    read -p "Add $INSTALL_DIR to PATH in $SHELL_RC? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check if already added
        if grep -q "export PATH=.*$INSTALL_DIR" "$SHELL_RC" 2>/dev/null; then
            echo -e "${YELLOW}[*] PATH entry already exists in $SHELL_RC${NC}"
        else
            echo "" >> "$SHELL_RC"
            echo "# Added by PathMaker" >> "$SHELL_RC"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
            echo -e "${GREEN}[+] Added to $SHELL_RC${NC}"
            echo -e "${YELLOW}[*] Run 'source $SHELL_RC' or restart your terminal${NC}"
        fi
    else
        echo -e "${YELLOW}[*] Skipped adding to PATH${NC}"
        echo -e "${YELLOW}[*] Add manually: export PATH=\"$INSTALL_DIR:\$PATH\"${NC}"
    fi
fi

# Make original script executable if it isn't
if [ ! -x "$SCRIPT_PATH" ]; then
    echo -e "${YELLOW}[*] Making original script executable${NC}"
    chmod +x "$SCRIPT_PATH"
fi

# Success message
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}[✓] Installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}You can now run: ${YELLOW}$COMMAND_NAME${NC}"
echo -e "${CYAN}Example: ${YELLOW}$COMMAND_NAME --help${NC}\n"

# Test if command is accessible
if command -v "$COMMAND_NAME" &> /dev/null; then
    echo -e "${GREEN}[+] Command '$COMMAND_NAME' is ready to use!${NC}"
else
    echo -e "${YELLOW}[!] Command not immediately available${NC}"
    echo -e "${YELLOW}[*] Try: source $SHELL_RC${NC}"
    echo -e "${YELLOW}[*] Or restart your terminal${NC}"
fi

echo ""
