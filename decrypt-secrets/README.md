# Decrypt Secrets GitHub Action

This action is designed to decrypt secrets that are encrypted with GPG and base64 encoded. It requires a passphrase to perform the decryption.

## Usage

```yaml
- name: Decrypt Secrets
  uses: ministryofjustice/modernisation-platform-github-actions/decrypt-secrets@main
  with:
    environment_management: ${{ needs.retrieve-secrets.outputs.environment_management }}
    passphrase: ${{ secrets.PASSPHRASE }}
```
## Inputs

- **`passphrase`** (Required): The passphrase used to decrypt the GPG-encrypted secrets. Store this passphrase securely in GitHub Secrets.
- **Inputs** (Optional): You can pass any encrypted secrets as inputs. For example:
  - `environment_management`
  - `pagerduty_token`
  - `pagerduty_userapi_token`
  - `slack_webhook_url`
  - `terraform_github_token`
  
  These inputs should be the base64-encoded, GPG-encrypted secrets that you want to decrypt. 

### Outputs

The action will decrypt the provided inputs (if any) and make them available as environment variables in subsequent steps. The environment variables will be named dynamically based on the secret names you provide in the inputs. For example, the decrypted values will be available as:

- `ENVIRONMENT_MANAGEMENT`: Decrypted `environment_management` secret.
- `PAGERDUTY_TOKEN`: Decrypted `pagerduty_token` secret.
- `PAGERDUTY_USERAPI_TOKEN`: Decrypted `pagerduty_userapi_token` secret.
- `SLACK_WEBHOOK_URL`: Decrypted `slack_webhook_url` secret.
- `TERRAFORM_GITHUB_TOKEN`: Decrypted `terraform_github_token` secret.


### Notes

- The input names (e.g., `environment_management`, `pagerduty_token`, etc.) depend on the secrets you are retrieving and encrypting. They may change if additional secrets are retrieved or removed from your `AWS Secrets Manager` configuration. You should update the workflow to reflect any changes in the retrieved secrets.
- The `decrypt-secrets` action should be used after the secrets are retrieved and encrypted by the `retrieve-secrets` job.
- The action applies multiline-safe masking by default. For plain-text secrets it masks the full value, an escaped full value, and each non-empty line. For JSON secrets it masks the raw JSON and all string leaf values.
- When a decrypted value contains newlines, the action writes it to `$GITHUB_ENV` using heredoc multiline syntax to avoid truncation or accidental log exposure.
