# 🔧 Code Formatter (Reusable Workflow)

This is a reusable GitHub Actions workflow that runs [MegaLinter](https://megalinter.io/) to automatically lint and format your codebase. It helps enforce consistent standards and can auto-correct issues.

This version uses the **Terraform flavor** of MegaLinter and does not currently support switching flavors.

To create pull requests with signed commits containing any fixes, you can chain this workflow with a separate [signed-commit reusable workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions/tree/main/signed-commit).

---

## ✅ Features

- Powered by [MegaLinter](https://megalinter.io/), the all-in-one code linter and formatter
- Supports Terraform, YAML, JSON, and Markdown by default
- Pre-configured with optimized linters for Terraform repositories
- Uploads SARIF reports to GitHub Security tab for actionable insights
- Fully configurable via workflow inputs

---

## 🚀 Quick Start

Create a workflow file in your repository, for example `.github/workflows/format-code.yml`:

```yaml
name: Format Code

on:
  pull_request:
    types: [opened, edited, reopened, synchronize]

permissions:
  contents: write
  security-events: write # needed for SARIF upload

jobs:
  format-code:
    uses: ministryofjustice/modernisation-platform-github-actions/format-code@<ref>
    with:
      ignore_files: "README.md"

  commit-fixes:
    uses: ministryofjustice/modernisation-platform-github-actions/signed-commit@<ref>
    with:
      github_token: ${{ secrets.GITHUB_TOKEN }}
      pr_title: "GitHub Actions Code Formatter workflow"
      pr_body: "This pull request includes updates from the GitHub Actions Code Formatter workflow. Please review the changes and merge if everything looks good."
```

> 🔁 Replace `<ref>` with a specific commit SHA or tag (e.g. `v1.0.0`) to ensure stability.

---

## 🧾 Inputs

These inputs let you fine-tune MegaLinter behaviour. All are optional with sensible defaults:

| Name                                         | Default Value                                                               | Description                                                           |
| -------------------------------------------- | --------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `apply_fixes`                                | `all`                                                                       | What to fix (e.g., `none`, `all`)                                     |
| `apply_fixes_event`                          | `all`                                                                       | When to apply fixes (`push`, `pull_request`, `all`)                   |
| `apply_fixes_mode`                           | `pull_request`                                                              | How to apply fixes (`commit` or `pull_request`)                       |
| `disable_errors`                             | `true`                                                                      | If `true`, warnings do not fail the job                               |
| `email_reporter`                             | `false`                                                                     | If `true`, sends email reports                                        |
| `enable_linters`                             | `JSON_PRETTIER,YAML_PRETTIER,TERRAFORM_TERRAFORM_FMT,MARKDOWN_MARKDOWNLINT` | Comma-separated list of linters to enable                             |
| `ignore_files`                               | `""`                                                                        | Glob patterns of files to exclude                                     |
| `markdown_markdownlint_filter_regex_exclude` | `""`                                                                        | Regex pattern to exclude specific Markdown files                      |
| `report_output_folder`                       | `megalinter-reports`                                                        | Folder to output MegaLinter reports to                                |
| `validate_all_codebase`                      | `false`                                                                     | If `true`, lints the entire codebase regardless of changes            |
| `yaml_prettier_filter_regex_exclude`         | `(.github/*)`                                                               | Regex pattern to exclude YAML files (default excludes GitHub configs) |

---

## 🔐 Security Notes

- All actions are **pinned to full commit SHAs** for security and reproducibility
- SARIF output is uploaded to GitHub Security tab
- Uses GitHub’s `GITHUB_TOKEN` with the **principle of least privilege** encouraged

---

## 🛠 Customization

Although the workflow is optimized for Terraform-based repositories by default, you can override linters and inputs to tailor behavior to your codebase. Example:

```yaml
with:
  enable_linters: "TERRAFORM_TERRAFORM_FMT,YAML_PRETTIER"
  ignore_files: ".terraform/*,README.md"
```

---

## 🤝 Contributing

We welcome PRs for improvements, additional linters, updated docs, and bug fixes.

---

## 📚 Resources

- [MegaLinter Docs](https://megalinter.io/)
- [SARIF Format](https://docs.github.com/en/code-security/code-scanning/working-with-code-scanning/sarif-support-for-code-scanning)
- [Signed Commit Workflow](https://github.com/ministryofjustice/modernisation-platform-github-actions)
