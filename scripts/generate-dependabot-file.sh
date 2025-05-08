#!/usr/bin/env bash

set -euo pipefail

dependabot_file=".github/dependabot.yml"
# Clear the dependabot file
> "$dependabot_file"

echo "Generating dependabot.yml..."

cat > "$dependabot_file" << 'EOF'
# This file is auto-generated, do not manually amend.
# scripts/generate-dependabot-file.sh

version: 2

updates:
EOF

# GitHub Actions (single root)
cat >> "$dependabot_file" << EOF
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "daily"
EOF

# Bundler (only if Gemfile.lock is found at root)
[[ -f Gemfile.lock ]] && cat >> "$dependabot_file" << EOF
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "daily"
EOF

# Docker
docker_files=$(find . -name Dockerfile)
if [[ -n "$docker_files" ]]; then
  docker_dirs=$(echo "$docker_files" | sed 's|^\./||' | xargs -n1 dirname | awk -F/ '{print $1}' | sort -u)
  if [[ -n "$docker_dirs" ]]; then
    echo "  - package-ecosystem: \"docker\"" >> "$dependabot_file"
    echo "    directories:" >> "$dependabot_file"
    echo "$docker_dirs" | while read -r dir; do
      echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
    done
    echo "    schedule:" >> "$dependabot_file"
    echo "      interval: \"daily\"" >> "$dependabot_file"
  fi
fi

# Terraform
tf_files=$(find . -name '*.tf' ! -path '*/.terraform/*')
if [[ -n "$tf_files" ]]; then
  tf_dirs=$(echo "$tf_files" | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
  if [[ -n "$tf_dirs" ]]; then
    echo "  - package-ecosystem: \"terraform\"" >> "$dependabot_file"
    echo "    directories:" >> "$dependabot_file"
    echo "$tf_dirs" | while read -r dir; do
      echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
    done
    echo "    schedule:" >> "$dependabot_file"
    echo "      interval: \"daily\"" >> "$dependabot_file"
  fi
fi

# Go Modules
gomod_files=$(find . -name 'go.mod' ! -path '*/.terraform/*')
if [[ -n "$gomod_files" ]]; then
  gomod_dirs=$(echo "$gomod_files" | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
  if [[ -n "$gomod_dirs" ]]; then
    echo "  - package-ecosystem: \"gomod\"" >> "$dependabot_file"
    echo "    directories:" >> "$dependabot_file"
    echo "$gomod_dirs" | while read -r dir; do
      echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
    done
    echo "    schedule:" >> "$dependabot_file"
    echo "      interval: \"daily\"" >> "$dependabot_file"
  fi
fi

# Python (pip)
py_files=$(find . \( -name 'requirements.txt' -o -name 'pyproject.toml' \))
if [[ -n "$py_files" ]]; then
  pip_dirs=$(echo "$py_files" | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
  if [[ -n "$pip_dirs" ]]; then
    echo "  - package-ecosystem: \"pip\"" >> "$dependabot_file"
    echo "    directories:" >> "$dependabot_file"
    echo "$pip_dirs" | while read -r dir; do
      echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
    done
    echo "    schedule:" >> "$dependabot_file"
    echo "      interval: \"daily\"" >> "$dependabot_file"
  fi
fi

# Node (npm)
npm_files=$(find . -name 'package.json' ! -path '*/node_modules/*')
if [[ -n "$npm_files" ]]; then
  npm_dirs=$(echo "$npm_files" | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
  if [[ -n "$npm_dirs" ]]; then
    echo "  - package-ecosystem: \"npm\"" >> "$dependabot_file"
    echo "    directories:" >> "$dependabot_file"
    echo "$npm_dirs" | while read -r dir; do
      echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
    done
    echo "    schedule:" >> "$dependabot_file"
    echo "      interval: \"daily\"" >> "$dependabot_file"
  fi
fi

echo "✅ dependabot.yml has been generated at $dependabot_file"
