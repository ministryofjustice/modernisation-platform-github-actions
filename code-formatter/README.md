# PR Code Formatter

A Github Action to apply code formatting to file in **PRs only**. CI GH Action will run and automatically commit to the same branch when there is a difference in files in the PR.

Formats Ruby, Terraform, YAML/YML, Python, Markdown, JSON and html.md.erb files within a PR.

## History

This was previously deployed in ministryofjustice/github-actions. This is the version of the action as at release [v18.6.0](https://github.com/ministryofjustice/github-actions/tree/v18.6.0/code-formatter)

## Usage

Create a file in your repo called `.github/workflows/format-code.yml` with the
following contents:

```
name: code-formatter

on:
  pull_request:
    types: [opened, edited, reopened, synchronize]

jobs:
  format-code:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ministryofjustice/github-actions/code-formatter@v6
        with:
          ignore-files: "fileA.json,fileB.rb,fileC.yaml"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

The `with: ignore-files:` is optional.

`GITHUB_TOKEN` is provided automatically by github actions. You do
not need to do anything extra to make it available. Just use the
content above, exactly as shown.
