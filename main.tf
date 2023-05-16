terraform {
  backend "s3" {
    bucket         = "juniorhamish-terraform-backend"
    key            = "football-organizer/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "football-organizer-state"
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_iam_role" "cognito_pre_signup_lambda_role" {
  name = "Cognito_Pre_Signup_Email_Check_Lambda_Role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "sts:AssumeRole",
          "Principal" : {
            "Service" : "lambda.amazonaws.com"
          },
          "Effect" : "Allow",
          "Sid" : ""
        }
      ]
    }
  )
}

resource "aws_iam_policy" "cognito_pre_signup_policy" {
  name        = "Cognito_Pre_Signup_Policy"
  path        = "/"
  description = "AWS IAM Policy for accessing cognito users"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : "cognito-idp:ListUsers",
          "Resource" : "arn:aws:cognito-idp:eu-west-2:522341695260:userpool/eu-west-2_AQejk3Z18",
          "Effect" : "Allow"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.cognito_pre_signup_lambda_role.name
  policy_arn = aws_iam_policy.cognito_pre_signup_policy.arn
}

data "archive_file" "create_pre_signup_email_check_archive_file" {
  type        = "zip"
  source_dir  = "preSignupLambda/"
  output_path = "${path.module}/.archive_files/pre_signup_lambda.zip"

  depends_on = [null_resource.main]
}

resource "null_resource" "main" {
  triggers = {
    updated_at = timestamp()
  }

  provisioner "local-exec" {
    command = "npm ci"

    working_dir = "${path.module}/preSignupLambda"
  }
}

resource "aws_lambda_function" "terraform_lambda_func" {
  filename         = "${path.module}/.archive_files/pre_signup_lambda.zip"
  function_name    = "Cognito_Unique_Email_Lambda"
  role             = aws_iam_role.cognito_pre_signup_lambda_role.arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.create_pre_signup_email_check_archive_file.output_base64sha256
  runtime          = "nodejs18.x"
  timeout          = 30
  depends_on       = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}
