#!/bin/bash

# Get the directory of the script
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    
    # Remove existing file/link if it exists
    if [ -L "$target" ]; then
        echo "Removing existing symlink: $target"
        rm "$target"
    elif [ -f "$target" ] || [ -d "$target" ]; then
        echo "Backing up existing file: $target"
        mv "$target" "${target}.bak"
    fi
    
    # Create symlink
    ln -s "$source" "$target"
    echo "Created symlink: $source -> $target"
}

# Nvim configuration
create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Aerospace configuration
create_symlink "$DOTFILES_DIR/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"

# Zsh configuration (moved to .config/zsh)
create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/zsh/.zshrc"
create_symlink "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.config/zsh/.p10k.zsh"

# Add more configurations as needed
# create_symlink "$DOTFILES_DIR/some_other_config" "$HOME/.some_other_config"

echo "Dotfiles symlinked successfully!"
