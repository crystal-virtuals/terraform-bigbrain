##################################################################
# Amplify
##################################################################

resource "aws_amplify_app" "frontend" {
  name       = "${var.project_name}-frontend"
  repository = var.amplify_repository

  # GitHub personal access token
  access_token = var.github_access_token

  platform = "WEB"

  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  environment_variables = var.amplify_app_environment_variables

  tags = local.tags
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = "main"

  framework = "React"
  # stage     = "PRODUCTION"

  environment_variables = var.amplify_branch_environment_variables
}

resource "aws_amplify_webhook" "main" {
  app_id      = aws_amplify_app.frontend.id
  branch_name = aws_amplify_branch.main.branch_name
  description = "Trigger Amplify build from Terraform"
}

resource "null_resource" "trigger_amplify_deploy" {
  triggers = {
    # Re-trigger if the webhook URL changes, or if you bump this value manually
    webhook_url = aws_amplify_webhook.main.url
    trigger_ver = "1"
  }

  provisioner "local-exec" {
    command = "curl -X POST '${aws_amplify_webhook.main.url}'"
  }

  depends_on = [aws_amplify_branch.main]
}
