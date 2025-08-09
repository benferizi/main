#!/bin/bash

# Setup script for benferizi/main advanced build system
# Automates cloning and updating of core repositories

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Repository configurations
GITHUB_ORG="benferizi"
REPOS=(
    "happiness-engine-20250807"
    "stellar-forge-20250807"
    "benferizi-masterpiece"
    "benferizi-20250807-ultimate"
    "quantum-builder"
    "buildx"
    "runner-images"
    "system-prompts-and-models-of-ai-tools"
    "codespaces-jupyter"
    "codespaces-react"
)

# Script directory (where setup.sh is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Parent directory (where sibling repos should be cloned)
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Flags
PULL_FLAG=false
CLEAN_FLAG=false
HELP_FLAG=false

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_separator() {
    echo "----------------------------------------"
}

# Help function
show_help() {
    cat << EOF
Setup Script for benferizi/main Advanced Build System

USAGE:
    ./setup.sh [OPTIONS]

DESCRIPTION:
    Automates the cloning and updating of core repositories into sibling 
    directories. The script is idempotent and safe to run multiple times.

OPTIONS:
    --pull      Force git pull on all existing repositories
    --clean     Remove and freshly clone all repositories
    --help      Show this help message

REPOSITORIES MANAGED:
EOF
    for repo in "${REPOS[@]}"; do
        echo "    - $repo"
    done
    cat << EOF

EXAMPLES:
    ./setup.sh                  # Clone missing repos, skip existing ones
    ./setup.sh --pull          # Clone missing repos and update existing ones
    ./setup.sh --clean         # Remove all repos and clone fresh copies

NOTES:
    - Repositories are cloned as siblings to the main repository
    - Script requires git to be installed and accessible
    - Works on macOS and Linux systems
    - No Python or Node.js dependencies required
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --pull)
                PULL_FLAG=true
                shift
                ;;
            --clean)
                CLEAN_FLAG=true
                shift
                ;;
            --help|-h)
                HELP_FLAG=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# Check if git is available
check_dependencies() {
    if ! command -v git >/dev/null 2>&1; then
        print_error "git is required but not installed."
        exit 1
    fi
}

# Clone or update a single repository
process_repository() {
    local repo_name="$1"
    local repo_path="$PARENT_DIR/$repo_name"
    local repo_url="https://github.com/$GITHUB_ORG/$repo_name.git"
    
    print_separator
    print_info "Processing repository: $repo_name"
    
    # Handle clean flag - remove existing directory
    if [[ "$CLEAN_FLAG" == true ]] && [[ -d "$repo_path" ]]; then
        print_info "Removing existing directory for fresh clone..."
        rm -rf "$repo_path"
    fi
    
    # Clone if directory doesn't exist
    if [[ ! -d "$repo_path" ]]; then
        print_info "Cloning $repo_name..."
        if git clone "$repo_url" "$repo_path"; then
            print_success "Successfully cloned $repo_name"
        else
            print_error "Failed to clone $repo_name"
            return 1
        fi
    else
        print_info "Repository $repo_name already exists"
        
        # Handle pull flag or update existing repo
        if [[ "$PULL_FLAG" == true ]]; then
            print_info "Updating $repo_name..."
            if (cd "$repo_path" && git pull origin main 2>/dev/null) || \
               (cd "$repo_path" && git pull origin master 2>/dev/null) || \
               (cd "$repo_path" && git pull 2>/dev/null); then
                print_success "Successfully updated $repo_name"
            else
                print_warning "Could not update $repo_name (may not have remote tracking branch)"
            fi
        else
            print_info "Skipping update (use --pull to force update)"
        fi
    fi
}

# Main execution function
main() {
    # Parse arguments
    parse_args "$@"
    
    # Show help if requested
    if [[ "$HELP_FLAG" == true ]]; then
        show_help
        exit 0
    fi
    
    # Check dependencies
    check_dependencies
    
    # Print header
    echo
    print_info "benferizi/main Advanced Build System Setup"
    print_info "Script location: $SCRIPT_DIR"
    print_info "Target directory: $PARENT_DIR"
    print_info "Pull flag: $PULL_FLAG"
    print_info "Clean flag: $CLEAN_FLAG"
    echo
    
    # Ensure parent directory exists
    if [[ ! -d "$PARENT_DIR" ]]; then
        print_error "Parent directory does not exist: $PARENT_DIR"
        exit 1
    fi
    
    # Process each repository
    local success_count=0
    local total_count=${#REPOS[@]}
    
    for repo in "${REPOS[@]}"; do
        if process_repository "$repo"; then
            ((success_count++))
        fi
    done
    
    # Print summary
    print_separator
    print_info "Setup completed!"
    print_success "Successfully processed $success_count out of $total_count repositories"
    
    if [[ $success_count -eq $total_count ]]; then
        print_success "All repositories are ready!"
    else
        print_warning "Some repositories may need manual attention"
    fi
    echo
}

# Run main function with all arguments
main "$@"