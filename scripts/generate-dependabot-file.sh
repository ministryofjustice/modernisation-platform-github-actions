#!/usr/bin/env bash

set -euo pipefail

dependabot_file=".github/dependabot.yml"
mkdir -p "$(dirname "$dependabot_file")"

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
docker_dirs=$(find . -name Dockerfile | sed 's|^\./||' | xargs -n1 dirname | awk -F/ '{print $1}' | sort -u)
if [[ -n "$docker_dirs" ]]; then
  echo "  - package-ecosystem: \"docker\"" >> "$dependabot_file"
  echo "    directories:" >> "$dependabot_file"
  echo "$docker_dirs" | while read -r dir; do
    echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
  done
  echo "    schedule:" >> "$dependabot_file"
  echo "      interval: \"daily\"" >> "$dependabot_file"
fi

# Terraform
tf_dirs=$(find . -name '*.tf' ! -path '*/.terraform/*' | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
if [[ -n "$tf_dirs" ]]; then
  echo "  - package-ecosystem: \"terraform\"" >> "$dependabot_file"
  echo "    directories:" >> "$dependabot_file"
  echo "$tf_dirs" | while read -r dir; do
    echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
  done
  echo "    schedule:" >> "$dependabot_file"
  echo "      interval: \"daily\"" >> "$dependabot_file"
fi

# Go modules
gomod_dirs=$(find . -name 'go.mod' ! -path '*/.terraform/*' | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
if [[ -n "$gomod_dirs" ]]; then
  echo "  - package-ecosystem: \"gomod\"" >> "$dependabot_file"
  echo "    directories:" >> "$dependabot_file"
  echo "$gomod_dirs" | while read -r dir; do
    echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
  done
  echo "    schedule:" >> "$dependabot_file"
  echo "      interval: \"daily\"" >> "$dependabot_file"
fi

# Python (pip)
pip_dirs=$(find . \( -name 'requirements.txt' -o -name 'pyproject.toml' \) | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
if [[ -n "$pip_dirs" ]]; then
  echo "  - package-ecosystem: \"pip\"" >> "$dependabot_file"
  echo "    directories:" >> "$dependabot_file"
  echo "$pip_dirs" | while read -r dir; do
    echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
  done
  echo "    schedule:" >> "$dependabot_file"
  echo "      interval: \"daily\"" >> "$dependabot_file"
fi

# Node (npm)
npm_dirs=$(find . -name 'package.json' ! -path '*/node_modules/*' | sed 's|^\./||' | xargs -n1 dirname | sort -u | awk -F/ '{print $1}' | sort -u)
if [[ -n "$npm_dirs" ]]; then
  echo "  - package-ecosystem: \"npm\"" >> "$dependabot_file"
  echo "    directories:" >> "$dependabot_file"
  echo "$npm_dirs" | while read -r dir; do
    echo "      - \"/$dir/**/*\"" >> "$dependabot_file"
  done
  echo "    schedule:" >> "$dependabot_file"
  echo "      interval: \"daily\"" >> "$dependabot_file"
fi

echo "✅ dependabot.yml has been generated at $dependabot_file"
