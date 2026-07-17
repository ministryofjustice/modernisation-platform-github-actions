plugin "aws" {
    enabled = true
    version = "0.33.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
    signature = "pgp"
}

plugin "terraform" {
    enabled = true
    version = "0.9.1"
    preset  = "recommended"
    source  = "github.com/terraform-linters/tflint-ruleset-terraform"
    signature = "pgp"
}

rule "terraform_deprecated_index" {
    enabled = false
}
