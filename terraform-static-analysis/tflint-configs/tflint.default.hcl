plugin "terraform" {
    enabled = true
    version = "0.15.0"
    preset  = "recommended"
    source  = "github.com/terraform-linters/tflint-ruleset-terraform"
    signature = "pgp"
}

rule "terraform_deprecated_index" {
    enabled = false
}
