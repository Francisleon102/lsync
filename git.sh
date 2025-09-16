#!/bin/bash

# Check if repo has a remote
if git remote get-url origin > /dev/null 2>&1; then
    # Normal commit and push flow
    read -p "Enter your commit message: " text
    git add .
    git commit -m "$text"
    git push origin main
else
    # No remote yet
    read -n1 -p "Press x to link: " key
    echo
    if [[ $key == "x" ]]; then
        read -p "Enter your remote URL (e.g. git@github.com:user/repo.git): " url
        git remote add origin "$url"
        echo "✅ Remote added: $url"
    fi
fi
