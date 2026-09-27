# Bootstrap remote Terraform state

Run this directory only once per AWS account/region before working in an environment directory. It deliberately uses local Terraform state during bootstrap because the remote backend does not exist yet.

The configuration creates a versioned, encrypted, non-public S3 bucket and a DynamoDB state-lock table. Both resources have Terraform `prevent_destroy` enabled to reduce accidental deletion. Removing them is a deliberate final teardown action that requires changing the configuration after all environment resources are gone.

Copy `terraform.tfvars.example` to `terraform.tfvars`, set the named AWS profile you use for the lab, make only account-appropriate changes, and keep that copied file private.
