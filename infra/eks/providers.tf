provider "aws" {
  region = var.aws_region
}

/*
 We’ll configure the kubernetes provider AFTER the cluster exists
 (using the cluster endpoint & auth). Not needed for the initial apply.
*/

# kubernetes provider will be configured AFTER the EKS cluster exists
# (we'll fill it in once we have cluster endpoint & auth)
