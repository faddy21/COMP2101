#!/bin/bash


# Git commands to add, commit, and push changes
git add .
git commit -m "$commit_message"
git push origin main  # Replace "main" with your branch name if it's different

# Check if the push was successful
if [ $? -eq 0 ]; then
    echo "Scripts updated successfully on GitHub."
else
    echo "Error: Failed to update scripts on GitHub."
fi
