#!/bin/bash

# Script configuration
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/dotfiles_install.log"
BACKUP_DIR="$HOME/.dotfiles_backup"
DRY_RUN=false
INTERACTIVE=true
VERBOSE=false
UPDATE_EXISTING=true

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOTFILES_DIR="/Users/bobbylee/Documents/repos/dotfiles"
# Define the path for the custom PHPCS directory
CUSTOM_PHPCS_DIR="$DOTFILES_DIR/.composer/phpcs"

# Error handling
set -euo pipefail
trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR

# Usage information
usage() {
  cat <<EOF
Usage: $(basename $0) [OPTIONS]

Options:
    -h, --help          Show this help message
    -v, --version       Show version information
    -d, --dry-run      Show what would be done without making changes
    -n, --non-interactive    Run without user prompts (use defaults)
    -V, --verbose      Enable verbose output
    --skip-backup      Skip creating backups of existing files
    --cleanup-backups  Remove backups older than 30 days
    --uninstall        Remove installed configurations

Examples:
    $(basename $0) --dry-run        # Show what would be done
    $(basename $0) --non-interactive # Install without prompts
    $(basename $0) --uninstall      # Remove installed configurations
EOF
}

# Error handler
error_handler() {
  local exit_code=$1
  local line_no=$2
  local bash_lineno=$3
  local last_command=$4
  local func_stack=$5

  echo -e "${RED}Error occurred in:${NC}"
  echo "  - Command: $last_command"
  echo "  - Line: $line_no"
  echo "  - Exit code: $exit_code"
  echo "  - Function stack: $func_stack"

  if [ "$DRY_RUN" = false ]; then
    echo -e "${YELLOW}Attempting rollback...${NC}"
    rollback
  fi

  exit $exit_code
}

# Logger function
log() {
  local level=$1
  shift
  local message="$@"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case $level in
  "INFO")
    local color=$GREEN
    ;;
  "WARNING")
    local color=$YELLOW
    ;;
  "ERROR")
    local color=$RED
    ;;
  *)
    local color=$NC
    ;;
  esac

  if [ "$VERBOSE" = true ] || [ "$level" != "DEBUG" ]; then
    echo -e "${color}[$timestamp] [$level] $message${NC}"
  fi
  echo "[$timestamp] [$level] $message" >>"$LOG_FILE"
}

# Check for dependencies
check_dependencies() {
  log "INFO" "Checking dependencies..."
  local missing_deps=()

  for dep in git php curl sudo; do
    if ! command -v $dep &>/dev/null; then
      missing_deps+=($dep)
    fi
  done

  if [ ${#missing_deps[@]} -ne 0 ]; then
    log "ERROR" "Missing dependencies: ${missing_deps[*]}"
    exit 1
  fi

  log "INFO" "All dependencies found"
}

# Backup management
backup_file() {
  local file=$1
  if [ -e "$file" ]; then
    local backup_path="$BACKUP_DIR/$(basename "$file").$(date +%Y%m%d_%H%M%S)"
    if [ "$DRY_RUN" = false ]; then
      mkdir -p "$BACKUP_DIR"
      cp -R "$file" "$backup_path"
      log "INFO" "Backed up $file to $backup_path"
    else
      log "INFO" "(DRY-RUN) Would backup $file to $backup_path"
    fi
  fi
}

cleanup_old_backups() {
  if [ -d "$BACKUP_DIR" ]; then
    log "INFO" "Cleaning up old backups..."
    if [ "$DRY_RUN" = false ]; then
      find "$BACKUP_DIR" -type f -mtime +30 -delete
    else
      log "INFO" "(DRY-RUN) Would delete backups older than 30 days"
    fi
  fi
}

# Rollback function
rollback() {
  log "WARNING" "Rolling back changes..."
  if [ -d "$BACKUP_DIR" ]; then
    local today_backups=("$BACKUP_DIR"/*."$(date +%Y%m%d)"*)
    for backup in "${today_backups[@]}"; do
      if [ -f "$backup" ]; then
        local original_file="${backup%.*.*}"
        log "INFO" "Restoring $original_file from $backup"
        if [ "$DRY_RUN" = false ]; then
          cp -f "$backup" "$original_file"
        fi
      fi
    done
  fi
}

# Parse command line arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    -v | --version)
      echo "Version: $VERSION"
      exit 0
      ;;
    -d | --dry-run)
      DRY_RUN=true
      shift
      ;;
    -n | --non-interactive)
      INTERACTIVE=false
      shift
      ;;
    -V | --verbose)
      VERBOSE=true
      shift
      ;;
    --skip-backup)
      SKIP_BACKUP=true
      shift
      ;;
    --cleanup-backups)
      cleanup_old_backups
      exit 0
      ;;
    --uninstall)
      uninstall
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
    esac
  done
}

# Function to create symlink
create_symlink() {
  local source="$1"
  local target="$2"

  # Check if the source exists
  if [ ! -e "$source" ]; then
    echo "Warning: Source does not exist: $source. Skipping."
    return
  fi

  # Remove existing symlink if it exists
  if [ -L "$target" ]; then
    echo "Removing existing symlink: $target"
    rm "$target"
  elif [ -f "$target" ] || [ -d "$target" ]; then
    # Prompt the user for backup
    echo "Existing file or directory found at: $target"
    read -p "Do you want to back it up? (y/n): " choice
    case "$choice" in
    y | Y)
      echo "Backing up existing file or directory: $target"
      mv "$target" "${target}.bak"
      ;;
    n | N)
      echo "Skipping backup and overwriting: $target"
      rm -rf "$target"
      ;;
    *)
      echo "Invalid choice. Skipping operation for: $target"
      return
      ;;
    esac
  fi

  # Create symlink
  ln -s "$source" "$target"
  echo "Created symlink: $source -> $target"
}

# =====================================================
# 1. Core Installation Functions
# =====================================================
install_oh_my_zsh() {
  log "INFO" "Installing Oh My Zsh..."
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    if [ "$DRY_RUN" = false ]; then
      if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
        log "ERROR" "Failed to install Oh My Zsh"
        return 1
      fi
    else
      log "INFO" "(DRY-RUN) Would install Oh My Zsh"
    fi
  else
    log "INFO" "Oh My Zsh already installed"
  fi
}

install_zsh_plugins() {
  local plugins=(
    "zsh-users/zsh-autosuggestions:$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting:$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    "jeffreytse/zsh-vi-mode:$HOME/.oh-my-zsh/custom/plugins/zsh-vi-mode"
  )

  for plugin in "${plugins[@]}"; do
    IFS=: read -r repo_path install_path <<<"$plugin"
    if [ ! -d "$install_path" ]; then
      log "INFO" "Installing $repo_path..."
      if [ "$DRY_RUN" = false ]; then
        if ! git clone "https://github.com/$repo_path" "$install_path"; then
          log "ERROR" "Failed to install plugin: $repo_path"
          return 1
        fi
      else
        log "INFO" "(DRY-RUN) Would install plugin: $repo_path"
      fi
    else
      log "INFO" "Plugin $repo_path already installed"
      if [ "$DRY_RUN" = false ] && [ "$UPDATE_EXISTING" = true ]; then
        (cd "$install_path" && git pull)
      fi
    fi
  done
}

install_powerlevel10k() {
  local install_path="$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  if [ ! -d "$install_path" ]; then
    log "INFO" "Installing Powerlevel10k..."
    if [ "$DRY_RUN" = false ]; then
      if ! git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "$install_path"; then
        log "ERROR" "Failed to install Powerlevel10k"
        return 1
      fi
    else
      log "INFO" "(DRY-RUN) Would install Powerlevel10k"
    fi
  else
    log "INFO" "Powerlevel10k already installed"
    if [ "$DRY_RUN" = false ] && [ "$UPDATE_EXISTING" = true ]; then
      (cd "$install_path" && git pull)
    fi
  fi
}

# =====================================================
# 2. Composer Functions
# =====================================================
install_composer() {
  if ! command -v composer &>/dev/null; then
    log "INFO" "Installing Composer..."
    if [ "$DRY_RUN" = false ]; then
      local EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
      php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
      local ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

      if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        log "ERROR" "Composer installer verification failed"
        rm composer-setup.php
        return 1
      fi

      if ! php composer-setup.php --quiet; then
        log "ERROR" "Composer installation failed"
        rm composer-setup.php
        return 1
      fi

      rm composer-setup.php
      sudo mv composer.phar /usr/local/bin/composer
    else
      log "INFO" "(DRY-RUN) Would install Composer"
    fi
  else
    log "INFO" "Composer already installed"
    if [ "$DRY_RUN" = false ] && [ "$UPDATE_EXISTING" = true ]; then
      composer self-update
    fi
  fi

  # Now that Composer is installed, let's add the custom phpcs directory to the home directory
  if [ -d "$HOME/.composer" ]; then
    log "INFO" "Existing .composer directory found"

    # Ensure phpcs directory exists in .composer and create symlink for custom ruleset
    mkdir -p "$HOME/.composer/phpcs"

    # Set up custom phpcs ruleset symlink
    CUSTOM_PHPCS_DIR="$DOTFILES_DIR/.composer/BobbysWP"
    create_symlink "$CUSTOM_PHPCS_DIR" "$HOME/.composer/phpcs/BobbysWP"
  else
    log "ERROR" ".composer directory not found after Composer installation"
    return 1
  fi

}

install_composer_dependencies() {
  if [ "$DRY_RUN" = false ]; then
    # Define the dependencies, config, and scripts directly
    local require_dev_dependencies=(
      "friendsofphp/php-cs-fixer:^3.65"
      "squizlabs/php_codesniffer:^3.7"
      "wp-coding-standards/wpcs:^3.1"
      "phpcompatibility/php-compatibility:^9.3"
      "phpcsstandards/phpcsutils:^1.0"
      "phpcsstandards/phpcsextra:^1.2"
    )

    # Define the scripts to add
    local scripts_section=(
      "phpcs --config-set installed_paths /Users/bobbylee/.composer/phpcs/BobbysWP,/Users/bobbylee/.composer/vendor/phpcompatibility/php-compatibility,/Users/bobbylee/.composer/vendor/phpcsstandards/phpcsextra,/Users/bobbylee/.composer/vendor/phpcsstandards/phpcsutils,/Users/bobbylee/.composer/vendor/wp-coding-standards/wpcs"
      "phpcs --config-set default_standard BobbysWP"
    )

    # Path to the global composer.json file
    COMPOSER_JSON="$HOME/.composer/composer.json"

    # Check if composer.json exists
    if [ ! -f "$COMPOSER_JSON" ]; then
      log "ERROR" "$COMPOSER_JSON not found"
      return 1
    fi

    # Define the config section (this time, adding directly to composer.json)
    echo "INFO: Installing config..."

    cd "$HOME/.composer" # Make sure we're in the right directory

    # Check if the config.allow-plugins section exists in composer.json
    if ! grep -q '"config":' "$HOME/.composer/composer.json"; then
      # If the "config" section doesn't exist, add it
      echo '{"config": {"allow-plugins": {"dealerdirect/phpcodesniffer-composer-installer": true}}}' >>"$HOME/.composer/composer.json"
    else
      # If the "config" section already exists, append the allow-plugins configuration
      jq '.config += {"allow-plugins": {"dealerdirect/phpcodesniffer-composer-installer": true}}' "$HOME/.composer/composer.json" >"$HOME/.composer/composer.json.tmp" && mv "$HOME/.composer/composer.json.tmp" "$HOME/.composer/composer.json"
    fi

    # Install the dependencies
    composer install || {
      log "ERROR" "Failed to install dependencies"
      return 1
    }

    # Install the require-dev dependencies and update composer.json
    if [ ${#require_dev_dependencies[@]} -gt 0 ]; then
      echo "INFO: Installing require-dev dependencies..."
      cd "$HOME/.composer" # Make sure we're in the right directory
      for dep in "${require_dev_dependencies[@]}"; do
        composer require --dev "$dep" || {
          log "ERROR" "Failed to install dependency $dep"
          return 1
        }
      done
    fi

    # Run composer install to ensure everything is installed and composer.json is updated
    log "INFO" "Running composer install to apply the ruleset"
    cd "$HOME/.composer" && composer install || {
      log "ERROR" "composer install failed"
      return 1
    }

    # Run each command in the scripts_section
    for script in "${scripts_section[@]}"; do
      echo "Running: $script"
      eval "$script" || {
        echo "ERROR: Failed to run $script"
        return 1
      }
    done

  else
    log "INFO" "(DRY-RUN) Would install dependencies and apply config/scripts"
  fi
}

# =====================================================
# 4. Uninstall Function
# =====================================================
uninstall() {
  log "INFO" "Starting uninstallation process..."

  if [ "$INTERACTIVE" = true ]; then
    read -p "Are you sure you want to uninstall? This will remove all dotfile configurations. (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log "INFO" "Uninstallation cancelled"
      exit 0
    fi
  fi

  if [ "$DRY_RUN" = false ]; then
    # Remove symlinks
    local symlinks=(
      "$HOME/.config/nvim"
      "$HOME/.aerospace.toml"
      "$HOME/.wezterm.lua"
      "$HOME/.zshrc"
      "$HOME/.zprofile"
    )

    for link in "${symlinks[@]}"; do
      if [ -L "$link" ]; then
        log "INFO" "Removing symlink: $link"
        rm "$link"
        # Restore backup if it exists
        if [ -f "${link}.bak" ]; then
          mv "${link}.bak" "$link"
        fi
      fi
    done

    # Remove installed components
    if [ -d "$HOME/.oh-my-zsh" ]; then
      log "INFO" "Removing Oh My Zsh..."
      rm -rf "$HOME/.oh-my-zsh"
    fi

    # Clean up composer configuration
    if [ -d "$HOME/.composer" ]; then
      if [ "$INTERACTIVE" = true ]; then
        read -p "Do you want to remove Composer configuration? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          log "INFO" "Removing Composer configuration..."
          rm -rf "$HOME/.composer"
        fi
      fi
    fi

    log "INFO" "Uninstallation complete"
  else
    log "INFO" "(DRY-RUN) Would perform uninstallation"
  fi
}

# =====================================================
# Main Installation Logic
# =====================================================
main() {
  parse_args "$@"
  check_dependencies

  log "INFO" "Starting installation with options: DRY_RUN=$DRY_RUN, INTERACTIVE=$INTERACTIVE"

  # Create necessary directories
  mkdir -p "$HOME/.config"

  # Core installations
  install_oh_my_zsh
  install_zsh_plugins
  install_powerlevel10k

  # Composer setup
  install_composer
  install_composer_dependencies

  # Create symlinks
  create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
  create_symlink "$DOTFILES_DIR/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"
  create_symlink "$DOTFILES_DIR/.wezterm.lua" "$HOME/.wezterm.lua"
  create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  create_symlink "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"

  # Final steps
  if [ "$DRY_RUN" = false ]; then
    (cd "$HOME/.composer" && composer install)
    cleanup_old_backups
  fi

  log "INFO" "Installation completed successfully!"
}

# Execute main function with all arguments
main "$@"
