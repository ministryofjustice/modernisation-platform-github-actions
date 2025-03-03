# Signed-Commit Action

This GitHub Action enables creating signed commits using GitHub GraphQL and optionally opens a pull request (PR) if changes are detected. It ensures that commits made within workflows are signed and verifiable.

## 📌 Features

- Uses GitHub GraphQL to create signed commits
- Automatically creates a new branch for commits
- Optionally opens a PR when changes are detected
- Can be used within any workflow as a step

## 🚀 Usage

To use this action in a workflow, add the following step:

```yaml
- name: Create a signed commit
  uses: ministryofjustice/modernisation-platform-github-actions/signed-commit@41ce9117af6179f195ea00c3b7c06b3442d3e33c # v1.1.0
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    pr_title: "Automated Signed Commit"
    pr_body: "This PR was created automatically to update generated files."
```

## 🔧 Inputs

| Name           | Required | Description                                            |
| -------------- | -------- | ------------------------------------------------------ |
| `github_token` | ✅       | GitHub token with permissions to commit and create PRs |
| `pr_title`     | ❌       | Title for the PR (only required if creating a new PR)  |
| `pr_body`      | ❌       | Body for the PR (only required if creating a new PR)   |

## ✅ Example Workflow

```yaml
name: Signed Commit Example

on:
  push:
    branches:
      - main

jobs:
  signed-commit-job:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Make changes
        run: echo "Example change" >> file.txt

      - name: Create a signed commit
        uses: ministryofjustice/modernisation-platform-github-actions/signed-commit@41ce9117af6179f195ea00c3b7c06b3442d3e33c # v1.1.0
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          pr_title: "Automated Signed Commit"
          pr_body: "This PR was created automatically to update generated files."
```

## 📝 Notes

- The workflow requires a **GitHub token** with write permissions.
- If no changes are detected, no commit or PR will be created.
- If running within a PR, no new PR will be opened.
