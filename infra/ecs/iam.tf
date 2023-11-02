# IAM
data "aws_iam_policy_document" "this" {
  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "this" { 
  assume_role_policy = data.aws_iam_policy_document.this.json 
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role = resource.aws_iam_role.this.name
}
