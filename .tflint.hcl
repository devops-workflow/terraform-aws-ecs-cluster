config {
terraform_version = "0.11.11"
deep_check = true
ignore_module = {
"devops-workflow/autoscaling/aws" = true
"devops-workflow/boolean/local" = true
"devops-workflow/label/local" = true
"devops-workflow/security-group/aws" = true
}
}

