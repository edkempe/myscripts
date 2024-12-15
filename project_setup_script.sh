#!/bin/bash

# Project Setup Script

# Exit on any error
set -e

# Function to display usage
usage() {
    echo "Usage: $0 <project_name>"
    echo "Creates a new Python project with Git and GitHub integration"
    exit 1
}

# Check if project name is provided
if [ $# -eq 0 ]; then
    usage
fi

# Project configuration
PROJECT_NAME="$1"
PROJECTS_DIR="/Users/ekempe/VS Code"
GITHUB_USERNAME="edkempe"

# Validate project name
if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Invalid project name. Use only alphanumeric characters, underscores, and hyphens."
    exit 1
fi

# Full project path
PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

# Function to check GitHub CLI authentication
check_gh_auth() {
    if ! gh auth status &>/dev/null; then
        echo "Error: GitHub CLI is not authenticated."
        echo "Please run 'gh auth login' first."
        exit 1
    fi
}

# Handle existing local project directory conflict
handle_local_conflict() {
    echo "A directory with the name '$PROJECT_NAME' already exists locally."
    echo "Choose an option:"
    echo "1. Delete existing local project directory"
    echo "2. Choose a different project name"
    echo "3. Exit project setup"
    while true; do
        read -p "Enter your choice (1-3): " choice
        case "$choice" in
            1)
                read -p "Are you sure you want to delete the existing directory? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -rf "$PROJECT_PATH"
                    return 0
                else
                    echo "Deletion cancelled."
                    continue
                fi
                ;;
            2)
                read -p "Enter a new project name: " NEW_PROJECT_NAME
                PROJECT_NAME="$NEW_PROJECT_NAME"
                PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"
                if [ -d "$PROJECT_PATH" ]; then
                    echo "The new project name directory is also taken. Try again."
                    continue
                fi
                return 0
                ;;
            3)
                echo "Project setup cancelled."
                exit 0
                ;;
            *)
                echo "Invalid option. Please choose 1, 2, or 3."
                ;;
        esac
    done
}

# Handle existing repository conflict
handle_repo_conflict() {
    echo "Repository $PROJECT_NAME already exists on GitHub."
    echo "Choose an option:"
    echo "1. Overwrite existing repository"
    echo "2. Rename the project"
    echo "3. Cancel project setup"
    while true; do
        read -p "Enter your choice (1-3): " choice
        case "$choice" in
            1)
                gh repo delete "$PROJECT_NAME" --yes
                break
                ;;
            2)
                read -p "Enter a new project name: " NEW_PROJECT_NAME
                PROJECT_NAME="$NEW_PROJECT_NAME"
                PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"
                if gh repo view "$PROJECT_NAME" &>/dev/null; then
                    echo "The new project name is also taken. Try again."
                    continue
                fi
                break
                ;;
            3)
                echo "Project setup cancelled."
                exit 0
                ;;
            *)
                echo "Invalid option. Please choose 1, 2, or 3."
                ;;
        esac
    done
}

# Check for existing local project directory
check_local_project() {
    if [ -d "$PROJECT_PATH" ]; then
        handle_local_conflict
    fi
}

# Check for existing repository
check_repo_exists() {
    if gh repo view "$PROJECT_NAME" &>/dev/null; then
        handle_repo_conflict
    fi
}

# Main script execution
check_local_project
check_gh_auth
check_repo_exists

# Create project directory
mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"

# Initialize Git repository
if ! git init; then
    echo "Error: Failed to initialize Git repository."
    exit 1
fi

# Verify local Git repository
if [ ! -d .git ]; then
    echo "Error: Git repository was not created successfully."
    exit 1
fi

# Create README
cat << EOF > README.md
# $PROJECT_NAME Project

## Overview
A Python project developed with best practices.

## Setup Instructions
- Python 3.9+
- Virtual environment
- Development dependencies managed via pip

## Getting Started
1. Clone the repository
2. Create virtual environment: \`python3 -m venv venv\`
3. Activate: \`source venv/bin/activate\`
4. Install dependencies: \`pip install -r requirements.txt\`
EOF

# Create comprehensive .gitignore
cat << EOF > .gitignore
# Python
__pycache__/
*.py[cod]
*\$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual Environments
.env
.venv
venv/
ENV/

# IDE and Editor files
.idea/
.vscode/
*.sublime-project
*.sublime-workspace
*.swp
*.swo

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Logs and databases
*.log
*.sqlite3

# Project-specific ignores
EOF

# Create initial project structure
mkdir -p src tests lambda_functions config

# Create initial Python files
touch src/__init__.py
touch src/main.py
touch tests/__init__.py
touch tests/test_main.py
touch config/__init__.py
touch config/settings.py

# Create a basic main.py
cat << EOF > src/main.py
"""
Main entry point for the $PROJECT_NAME project.
"""

def main():
    """
    Main function to demonstrate project structure.
    """
    print("Welcome to $PROJECT_NAME!")

if __name__ == "__main__":
    main()
EOF

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install initial dependencies
pip install \
    boto3 \
    awscli \
    pytest \
    mypy \
    black \
    pylint \
    python-dotenv

# Freeze dependencies
pip freeze > requirements.txt

# Add initial commit
git add .
git commit -m "Initial project setup for $PROJECT_NAME"

# Create GitHub repository
if ! gh repo create "$PROJECT_NAME" --public --source="$PROJECT_PATH"; then
    echo "Error: Failed to create GitHub repository."
    echo "Please check your GitHub authentication and network connection."
    exit 1
fi

# Push to GitHub
if ! git push -u origin main; then
    echo "Error: Failed to push to GitHub repository."
    exit 1
fi

# Output completion message
echo "Project '$PROJECT_NAME' setup complete!"
echo "Repository: https://github.com/$GITHUB_USERNAME/$PROJECT_NAME"
echo ""
echo "Next steps:"
echo "1. Activate virtual environment: source venv/bin/activate"
echo "2. Install dependencies: pip install -r requirements.txt"
echo "3. Start developing!"

# Exit virtual environment
deactivate
