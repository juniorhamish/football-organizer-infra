terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket         = "juniorhamish-terraform-backend"
    key            = "football-organizer/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "football-organizer-state"
  }
}

provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Project = "Football Organizer"
    }
  }
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

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "Cognito_Unique_Email_Lambda_With_Layer"
  description   = "Check email address is unique"
  attach_policy = true
  policy        = aws_iam_policy.cognito_pre_signup_policy.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  timeout       = 20
  publish       = true

  source_path = "./preSignupLambda/function"

  layers = [
    module.lambda_layer_s3.lambda_layer_arn,
  ]

  environment_variables = {
    Serverless = "Terraform"
  }
}

module "lambda_layer_s3" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "node_modules_cognito"
  description         = "Node modules layer for cognito functions"
  compatible_runtimes = ["nodejs18.x"]

  source_path = "./preSignupLambda/layer"
}