#!/bin/bash

# Save original directory to return to it on exit
ORIGINAL_DIR="$(pwd)"

# Determine script's absolute path
SCRIPT_PATH="$(realpath "$BASH_SOURCE")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# --- Helper Functions ---

# Function to display the main menu
function show_menu() {
    # Define colors for better readability
    CYAN='\033[0;36m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color

    clear
    echo -e "${YELLOW}                                   UTOOL MENU                                ${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}                           🔧 DEVELOPMENT TOOLS                              ${NC}"
    echo "  � 1. Development Environment Setup     🖼️  2. Install image libs"
    echo "  🔴 3. Install Redis & Sidekiq           💎 4. Install Rails"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}                           🗄️ DATABASE SETUP                                 ${NC}"
    echo "  🗄️ 5. Setup MariaDB                      🐘 6. Setup PostgreSQL"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}                           🌐 SERVER & DEPLOY                                ${NC}"
    echo "  👤 7. Tạo deploy user                    🌐 8. Add Domain (Nginx/Host)"
    echo "  🚀 9. Setup Capistrano deploy            📋 10. Add Logrotate"
    echo "  🔑 11. SSH keygen                        🐳 12. Install Docker"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}                           🎨 WSL2 TOOLS                                     ${NC}"
    echo "  🎨 13. WSL SmartGit UI                   🔧 14. WSL2 add aliases"
    echo "  🔨 15. WSL2 bash init setup"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}                           ⚙️ SYSTEM                                         ${NC}"
    echo -e "  ${GREEN}🔄 16. Update UTool${NC}"
    echo "  🗑️ 99. Remove UTool                      🚪 Exit (q|quit|exit|0)"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────────────────────${NC}"
}

# Function to update the tool from git
function update_tool() {
  echo "Updating UTool from the latest version..."
  cd "$SCRIPT_DIR" || exit
  # Using reset --hard to discard local changes and pull the latest version
  git reset --hard HEAD
  git pull
  echo "✅ UTool updated successfully!"
  cd "$ORIGINAL_DIR"
  echo "Press Enter to continue..."
  read -r
}


# --- Main Loop ---

# Handle direct 'update' argument for backward compatibility or quick access
if [ "$1" == 'update' ]; then
  update_tool
  exit 0
fi

while true; do
  show_menu
  read -p "=> Select an option: " INPUT
  echo "====================================================================="
  case "$INPUT" in
    1)
      bash $SCRIPT_DIR/ubuntu22/install_common_dev_libs.sh;;
    2)
      bash $SCRIPT_DIR/ubuntu22/image_lib.sh;;
    3)
      bash $SCRIPT_DIR/ubuntu22/sidekiq.sh;;
    4)
      bash $SCRIPT_DIR/ubuntu22/rails_setup.sh;;
    5)
      bash $SCRIPT_DIR/ubuntu22/mysql.sh;;
    6)
      bash $SCRIPT_DIR/ubuntu22/postgresql.sh;;
    7)
      bash $SCRIPT_DIR/ubuntu22/user.sh;;
    8)
      bash $SCRIPT_DIR/ubuntu22/nginx_ssl.sh;;
    9)
      bash $SCRIPT_DIR/ubuntu22/capostrano_rails_puma.sh;;
    10)
      bash $SCRIPT_DIR/ubuntu22/logrotate.sh;;
    11)
      bash $SCRIPT_DIR/commons/sshs.sh;;
    12)
      bash $SCRIPT_DIR/ubuntu22/docker.sh;;
    13)
      bash $SCRIPT_DIR/wsl2/wsl2_smartgit.sh;;
    14)
      bash $SCRIPT_DIR/wsl2/wsl2_add_alias.sh;;
    15)
      bash $SCRIPT_DIR/wsl2/wsl2_bash_init.sh;;
    16)
      update_tool;;
    99)
      bash $SCRIPT_DIR/uninstall_utool;;
    q|quit|exit|0)
      echo "Exiting UTool. Goodbye!"
      cd "$ORIGINAL_DIR"
      break;;
    *)
      echo "Invalid option. Please try again.";;
  esac
  echo "=================================== END ===================================="
  echo "Press Enter to return to the menu..."
  read -r
done
