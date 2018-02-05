###
### ECS Cluster IAM
###

resource "aws_iam_instance_profile" "ecs_profile" {
  # Can't disable due to reference
  #count       = "${module.enabled.value}"
  # TODO: use label
  name_prefix = "${replace(format("%.102s", replace("tf-ECSProfile-${var.name}-", "_", "-")), "/\\s/", "-")}"
  role        = "${aws_iam_role.ecs_role.name}"
  path        = "${var.iam_path}"
}

resource "aws_iam_role" "ecs_role" {
  # Can't disable due to reference
  #count       = "${module.enabled.value}"
  # TODO: use label
  name_prefix = "${replace(format("%.32s", replace("tf-ECSInRole-${var.name}-", "_", "-")), "/\\s/", "-")}"
  path        = "${var.iam_path}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
      "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com"]

    },
    "Effect": "Allow",
    "Sid": ""
    }
  ]
}
EOF
}

# It may be useful to add the following for troubleshooting the InstanceStatus
# Health check if using the fitnesskeeper/consul docker image
# "ec2:Describe*",
# "autoscaling:Describe*",

resource "aws_iam_policy" "ecs_policy" {
  count       = "${module.enabled.value ? length(var.custom_iam_policy) > 0 ? 0 : 1 : 0}"
  name_prefix = "${replace(format("%.102s", replace("tf-ECSInPol-${var.name}-", "_", "-")), "/\\s/", "-")}"
  description = "A terraform created policy for ECS"
  path        = "${var.iam_path}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "custom_ecs_policy" {
  count       = "${module.enabled.value ? length(var.custom_iam_policy) > 0 ? 1 : 0 : 0}"
  name_prefix = "${replace(format("%.102s", replace("tf-ECSInPol-${var.name}-", "_", "-")), "/\\s/", "-")}"
  description = "A terraform created policy for ECS"
  path        = "${var.iam_path}"
  policy = "${var.custom_iam_policy}"
}

resource "aws_iam_policy_attachment" "attach_ecs" {
  count       = "${module.enabled.value}"
  name        = "ecs-attachment"
  roles       = ["${aws_iam_role.ecs_role.name}"]
  policy_arn  = "${element(concat(aws_iam_policy.ecs_policy.*.arn, aws_iam_policy.custom_ecs_policy.*.arn), 0)}"
}

/*
# IAM Resources for Consul and Registrator Agents

data "aws_iam_policy_document" "consul_task_policy" {
  statement {
    actions = [
      "autoscaling:Describe*",
      "ec2:Describe*",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role_consul_task" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "consul_task" {
  count               = "${module.enabled.value && var.enable_agents ? 1 : 0}"
  name_prefix         = "${replace(format("%.32s", replace("tf-agentTaskRole-${var.name}-", "_", "-")), "/\\s/", "-")}"
  path                = "${var.iam_path}"
  assume_role_policy  = "${data.aws_iam_policy_document.assume_role_consul_task.json}"
}

resource "aws_iam_role_policy" "consul_ecs_task" {
  count       = "${module.enabled.value && var.enable_agents ? 1 : 0}"
  name_prefix = "${replace(format("%.102s", replace("tf-agentTaskPol-${var.name}-", "_", "-")), "/\\s/", "-")}"
  role        = "${aws_iam_role.consul_task.id}"
  policy      = "${data.aws_iam_policy_document.consul_task_policy.json}"
}
*/
