# --- Provider & Backend Configuration ---
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1" # Must be us-east-1 for CLOUDFRONT scope WAF
}

# --- 1. Package the Lambda Function ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

# --- 2. Create the IAM Role for Lambda ---
resource "aws_iam_role" "waf_update_role" {
  name = "WAF-Update-Role-Terraform"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Attach WAF access policy
resource "aws_iam_role_policy_attachment" "waf_policy_attach" {
  role       = aws_iam_role.waf_update_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSWAFFullAccess"
}

# Attach basic Lambda execution policy for logging
resource "aws_iam_role_policy_attachment" "lambda_logging_attach" {
  role       = aws_iam_role.waf_update_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- 3. Create the Lambda Function ---
resource "aws_lambda_function" "block_malicious_ip" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "BlockMaliciousIP-Terraform"
  role          = aws_iam_role.waf_update_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# --- 4. Create the WAF Resources ---
resource "aws_wafv2_ip_set" "malicious_ips" {
  name        = "malicious-ips-terraform"
  scope       = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses   = [] # Starts empty
}

# --- 5. Enable GuardDuty ---
data "aws_guardduty_detector" "default" {
}

# --- 6. Create the EventBridge Rule & Target ---
resource "aws_cloudwatch_event_rule" "guardduty_finding_rule" {
  name        = "GuardDuty-Finding-Rule"
  description = "Trigger on GuardDuty Recon:EC2/Portscan findings"

  event_pattern = jsonencode({
    "source" : ["aws.guardduty"],
    "detail-type" : ["GuardDuty Finding"],
    "detail" : {
      "type" : ["Recon:EC2/Portscan"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_finding_rule.name
  target_id = "BlockMaliciousIPLambda"
  arn       = aws_lambda_function.block_malicious_ip.arn
}

# --- 7. Grant EventBridge Permission to Invoke Lambda ---
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.block_malicious_ip.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding_rule.arn
}