module "code_signing_bucket" {
  source      = "../modules/aws-s3-bucket"
  bucket_name = "${var.prefix}-code-signing"
}

resource "aws_signer_signing_profile" "this" {
  platform_id = "AWSLambda-SHA384-ECDSA"
  # invalid value for name (must be alphanumeric with max length of 64 characters)
  name = "${substr(var.prefix, 0, 51)}_lambda_code_signer"

  signature_validity_period {
    value = 3
    type  = "MONTHS"
  }
}

resource "aws_lambda_code_signing_config" "this" {
  allowed_publishers {
    signing_profile_version_arns = [aws_signer_signing_profile.this.version_arn]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

