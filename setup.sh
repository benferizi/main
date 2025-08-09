#!/bin/bash

# Enhanced setup script for benferizi/main
# Clones or updates core repositories into sibling directories
# Supports --pull, --clean, --python, and --node flags

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

# Repository configuration
REPOSITORIES=(
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

# Default GitHub organization/user
DEFAULT_ORG="benferizi"

# Special repositories that might be from different organizations
declare -A REPO_ORGS=(
    ["buildx"]="docker"
    ["runner-images"]="actions"
    ["codespaces-jupyter"]="github"
    ["codespaces-react"]="github"
)

# Command line flags
PULL_FLAG=false
CLEAN_FLAG=false
PYTHON_FLAG=false
NODE_FLAG=false

# Function to print colored output
print_status() {
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

# Function to show usage
show_usage() {
    cat << EOF
Enhanced Setup Script for benferizi/main

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    --pull      Force update all repositories (git pull)
    --clean     Reset repositories to clean state (git reset --hard)
    --python    Run Python automation (setup.py, requirements.txt) in each repo
    --node      Run Node.js automation (setup.js, package.json) in each repo
    --help, -h  Show this help message

DESCRIPTION:
    This script clones or updates the following repositories into sibling directories:
    $(printf "    - %s\n" "${REPOSITORIES[@]}")

    The script is idempotent and safe for repeated use. It will:
    1. Clone missing repositories
    2. Update existing repositories (if --pull is specified)
    3. Run language-specific setup if requested (--python, --node)

EXAMPLES:
    ./setup.sh                    # Basic setup - clone missing repos
    ./setup.sh --pull             # Update all repositories
    ./setup.sh --clean --pull     # Reset and update all repositories
    ./setup.sh --python --node    # Setup repos and run automation
EOF
}

# Function to parse command line arguments
parse_arguments() {
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
            --python)
                PYTHON_FLAG=true
                shift
                ;;
            --node)
                NODE_FLAG=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to get repository URL
get_repo_url() {
    local repo_name=$1
    local org=${REPO_ORGS[$repo_name]:-$DEFAULT_ORG}
    echo "https://github.com/${org}/${repo_name}.git"
}

# Function to clone or update a repository
clone_or_update_repo() {
    local repo_name=$1
    local repo_path="${PARENT_DIR}/${repo_name}"
    local repo_url=$(get_repo_url "$repo_name")
    
    print_status "Processing repository: $repo_name"
    
    if [[ -d "$repo_path" ]]; then
        print_status "Repository exists: $repo_path"
        
        cd "$repo_path"
        
        # Check if it's a git repository
        if [[ ! -d ".git" ]]; then
            print_warning "Directory exists but is not a git repository: $repo_path"
            return 1
        fi
        
        # Clean repository if requested
        if [[ "$CLEAN_FLAG" == true ]]; then
            print_status "Cleaning repository..."
            git reset --hard HEAD
            git clean -fd
            print_success "Repository cleaned"
        fi
        
        # Pull updates if requested
        if [[ "$PULL_FLAG" == true ]]; then
            print_status "Pulling latest changes..."
            if git pull origin HEAD; then
                print_success "Repository updated"
            else
                print_warning "Failed to pull updates for $repo_name"
                return 1
            fi
        else
            print_status "Skipping pull (use --pull to update)"
        fi
    else
        print_status "Cloning repository: $repo_url"
        
        if git clone "$repo_url" "$repo_path"; then
            print_success "Repository cloned: $repo_path"
        else
            print_error "Failed to clone repository: $repo_name"
            return 1
        fi
    fi
    
    return 0
}

# Function to run Python automation
run_python_automation() {
    local repo_path=$1
    local repo_name=$(basename "$repo_path")
    
    print_status "Checking for Python automation in $repo_name..."
    
    cd "$repo_path"
    
    # Check for requirements.txt
    if [[ -f "requirements.txt" ]]; then
        print_status "Found requirements.txt, installing dependencies..."
        if command -v pip3 &> /dev/null; then
            if pip3 install -r requirements.txt; then
                print_success "Python dependencies installed"
            else
                print_warning "Failed to install Python dependencies"
            fi
        else
            print_warning "pip3 not found, skipping requirements.txt"
        fi
    fi
    
    # Check for setup.py
    if [[ -f "setup.py" ]]; then
        print_status "Found setup.py, running setup..."
        if command -v python3 &> /dev/null; then
            if python3 setup.py develop; then
                print_success "Python setup completed"
            else
                print_warning "Failed to run Python setup"
            fi
        else
            print_warning "python3 not found, skipping setup.py"
        fi
    fi
    
    if [[ ! -f "requirements.txt" && ! -f "setup.py" ]]; then
        print_status "No Python automation files found"
    fi
}

# Function to run Node.js automation
run_node_automation() {
    local repo_path=$1
    local repo_name=$(basename "$repo_path")
    
    print_status "Checking for Node.js automation in $repo_name..."
    
    cd "$repo_path"
    
    # Check for package.json
    if [[ -f "package.json" ]]; then
        print_status "Found package.json, installing dependencies..."
        if command -v npm &> /dev/null; then
            if npm install; then
                print_success "Node.js dependencies installed"
            else
                print_warning "Failed to install Node.js dependencies"
            fi
        else
            print_warning "npm not found, skipping package.json"
        fi
    fi
    
    # Check for setup.js
    if [[ -f "setup.js" ]]; then
        print_status "Found setup.js, running setup..."
        if command -v node &> /dev/null; then
            if node setup.js; then
                print_success "Node.js setup completed"
            else
                print_warning "Failed to run Node.js setup"
            fi
        else
            print_warning "node not found, skipping setup.js"
        fi
    fi
    
    if [[ ! -f "package.json" && ! -f "setup.js" ]]; then
        print_status "No Node.js automation files found"
    fi
}

# Function to process all repositories
process_repositories() {
    local success_count=0
    local total_count=${#REPOSITORIES[@]}
    
    print_status "Processing $total_count repositories..."
    print_status "Target parent directory: $PARENT_DIR"
    
    for repo in "${REPOSITORIES[@]}"; do
        echo
        print_status "=== Processing $repo ==="
        
        if clone_or_update_repo "$repo"; then
            local repo_path="${PARENT_DIR}/${repo}"
            
            # Run Python automation if requested
            if [[ "$PYTHON_FLAG" == true ]]; then
                run_python_automation "$repo_path"
            fi
            
            # Run Node.js automation if requested
            if [[ "$NODE_FLAG" == true ]]; then
                run_node_automation "$repo_path"
            fi
            
            ((success_count++))
        else
            print_error "Failed to process repository: $repo"
        fi
    done
    
    echo
    print_success "=== Summary ==="
    print_success "Successfully processed: $success_count/$total_count repositories"
    
    if [[ $success_count -lt $total_count ]]; then
        print_warning "Some repositories failed to process. Check the output above for details."
        return 1
    fi
    
    return 0
}

# Main function
main() {
    print_status "Enhanced Setup Script for benferizi/main"
    print_status "Script location: $SCRIPT_DIR"
    print_status "Parent directory: $PARENT_DIR"
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show configuration
    echo
    print_status "Configuration:"
    print_status "  Pull updates: $PULL_FLAG"
    print_status "  Clean repos: $CLEAN_FLAG"
    print_status "  Python automation: $PYTHON_FLAG"
    print_status "  Node.js automation: $NODE_FLAG"
    
    # Check required tools
    echo
    print_status "Checking required tools..."
    
    if ! command -v git &> /dev/null; then
        print_error "git is not installed or not in PATH"
        exit 1
    else
        print_success "git is available"
    fi
    
    if [[ "$PYTHON_FLAG" == true ]]; then
        if command -v python3 &> /dev/null; then
            print_success "python3 is available"
        else
            print_warning "python3 not found, Python automation may fail"
        fi
        
        if command -v pip3 &> /dev/null; then
            print_success "pip3 is available"
        else
            print_warning "pip3 not found, Python automation may fail"
        fi
    fi
    
    if [[ "$NODE_FLAG" == true ]]; then
        if command -v node &> /dev/null; then
            print_success "node is available"
        else
            print_warning "node not found, Node.js automation may fail"
        fi
        
        if command -v npm &> /dev/null; then
            print_success "npm is available"
        else
            print_warning "npm not found, Node.js automation may fail"
        fi
    fi
    
    # Process repositories
    echo
    if process_repositories; then
        echo
        print_success "Setup completed successfully!"
    else
        echo
        print_error "Setup completed with errors. Please check the output above."
        exit 1
    fi
}

# Run main function with all arguments
main "$@"