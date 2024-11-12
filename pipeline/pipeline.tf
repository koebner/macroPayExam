# Repositorio CodeCommit
resource "aws_codecommit_repository" "ami_repo" {
  repository_name = "macropay-ami-repo"
  description     = "Repositorio para código de generación de AMIs"
}

# Role para CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "macropay-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

# Proyecto CodeBuild
resource "aws_codebuild_project" "ami_builder" {
  name          = "macropay-ami-builder"
  description   = "Construye AMIs usando Packer"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:5.0"
    type                       = "LINUX_CONTAINER"
    privileged_mode            = true
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }
}

# Pipeline
resource "aws_codepipeline" "ami_pipeline" {
  name     = "macropay-ami-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.id
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner           = "AWS"
      provider        = "CodeCommit"
      version         = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.ami_repo.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name            = "BuildAMI"
      category        = "Build"
      owner          = "AWS"
      provider       = "CodeBuild"
      input_artifacts = ["source_output"]
      version        = "1"

      configuration = {
        ProjectName = aws_codebuild_project.ami_builder.name
      }
    }
  }

  stage {
    name = "Approve"
    action {
      name     = "ApproveAMI"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }
}

# Actualizar la configuración de lanzamiento cuando se aprueba una nueva AMI
resource "aws_lambda_function" "update_launch_config" {
  filename      = "update_launch_config.zip"
  function_name = "update_launch_config"
  role         = aws_iam_role.lambda_role.arn
  handler      = "index.handler"
  runtime      = "nodejs14.x"

  environment {
    variables = {
      LAUNCH_CONFIG_NAME = aws_launch_configuration.terraform_macroPay.name
    }
  }
}