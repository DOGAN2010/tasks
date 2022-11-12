terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
# profile = "task"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "key-name" {
  default = "karaca"   # change here
}

locals {
  name = "task"   # change here, optional
}

resource "aws_instance" "master" {
  ami                  = "ami-04505e74c0741db8d"
  instance_type        = "t3a.medium"
  key_name             = var.key-name
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  security_groups      = ["${local.name}-k8s-master-sec-gr"]
  user_data            = data.template_file.master.rendered
  tags = {
    Name = "${local.name}-kube-master"
  }
}

resource "aws_instance" "worker" {
  ami                  = "ami-04505e74c0741db8d"
  instance_type        = "t3a.medium"
  key_name             = var.key-name
  iam_instance_profile = aws_iam_instance_profile.ec2connectprofile.name
  security_groups      = ["${local.name}-k8s-master-sec-gr"]
  user_data            = data.template_file.worker.rendered
  tags = {
    Name = "${local.name}-kube-worker"
  }
  depends_on = [aws_instance.master]
}

resource "aws_iam_instance_profile" "ec2connectprofile" {
  name = "ec2connectprofile"
  role = aws_iam_role.ec2connectcli.name
}

resource "aws_iam_role" "ec2connectcli" {
  name = "ec2connectcli"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "ec2-instance-connect:SendSSHPublicKey",
          "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:osuser" : "ubuntu"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        }
      ]
    })
  }
}

data "template_file" "worker" {
  template = file("worker.sh")
  vars = {
    region = data.aws_region.current.name
    master-id = aws_instance.master.id
    master-private = aws_instance.master.private_ip
  }

}

data "template_file" "master" {
  template = file("master.sh")
}

resource "aws_security_group" "tf-k8s-master-sec-gr" {
  name = "${local.name}-k8s-master-sec-gr"
  tags = {
    Name = "${local.name}-k8s-master-sec-gr"
  }

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "master_public_dns" {
  value = aws_instance.master.public_dns
}

output "master_private_dns" {
  value = aws_instance.master.private_dns
}

output "worker_public_dns" {
  value = aws_instance.worker.public_dns
}

output "worker_private_dns" {
  value = aws_instance.worker.private_dns
}


resource "kubernetes_namespace" "qa" {
  metadata {
    annotations = {
      name = "qa"
    }

    # labels = {
    #   mylabel = "label-value"
    # }

    name = "qa-namespace"
  }
}

resource "kubernetes_namespace" "staging" {
  metadata {
    annotations = {
      name = "staging"
    }

    # labels = {
    #   mylabel = "label-value"
    # }

    name = "staging-namespace"
  }
}


resource "aws_s3_bucket" "bucket-qa" {
  bucket = "qa-FIRSTNAME-LASTNAME-stormreply-platform-challenge"
}

resource "aws_s3_bucket" "bucket-staging" {
  bucket = "staging-FIRSTNAMELASTNAME-stormreply-platform-challenge"
}

# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"
# }
resource "aws_s3_bucket_lifecycle_configuration" "bucket-config-qa" {
  bucket = aws_s3_bucket.bucket-qa.bucket

  rule {
    id = "task"

    expiration {
      days = 1
    }

    filter {
      and {
        prefix = "2022*/"

        tags = {
          rule      = "task"
          autoclean = "true"
        }
      }
    }

    status = "Enabled"

  }

}

resource "aws_s3_bucket_lifecycle_configuration" "bucket-config-staging" {
  bucket = aws_s3_bucket.bucket-staging.bucket

  rule {
    id = "task"

    expiration {
      days = 1
    }

    filter {
      and {
        prefix = "2022*/"

        tags = {
          rule      = "task"
          autoclean = "true"
        }
      }
    }

    status = "Enabled"

  }

}


resource "kubernetes_cron_job" "task" {
  metadata {
    name = "task"
  }
  spec {
    concurrency_policy            = "Replace"
    failed_jobs_history_limit     = 5
    schedule                      = "*/5 * * * *"
    starting_deadline_seconds     = 10
    # successful_jobs_history_limit = 10
    job_template {
      metadata {}
      spec {
        backoff_limit              = 6
        ttl_seconds_after_finished = 10
        template {
          metadata {}
          spec {
            container {
              name    = "hello"
              
              ##  DOCKERHUB İMAGE CREATE ETTİKTEN SONRA DÜZENLE ????
              ## depends_on: ekleme ??
              image   = "busybox" 
              # command = ["/bin/sh", "-c", "date; echo Hello from the Kubernetes cluster"]
            }
          }
        }
      }
    }
  }
}



# resource "aws_s3_bucket" "versioning_bucket" {
#   bucket = "my-versioning-bucket"
# }

# resource "aws_s3_bucket_acl" "versioning_bucket_acl" {
#   bucket = aws_s3_bucket.versioning_bucket.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_versioning" "versioning" {
#   bucket = aws_s3_bucket.versioning_bucket.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "versioning-bucket-config" {
#   # Must have bucket versioning enabled first
#   depends_on = [aws_s3_bucket_versioning.versioning]

#   bucket = aws_s3_bucket.versioning_bucket.id

#   rule {
#     id = "config"

#     filter {
#       prefix = "config/"
#     }

#     noncurrent_version_expiration {
#       noncurrent_days = 90
#     }

#     noncurrent_version_transition {
#       noncurrent_days = 30
#       storage_class   = "STANDARD_IA"
#     }

#     noncurrent_version_transition {
#       noncurrent_days = 60
#       storage_class   = "GLACIER"
#     }

#     status = "Enabled"
#   }
#}