###
### Terraform AWS ECS Cluster
###

# Documentation references:

module "enabled" {
  source  = "devops-workflow/boolean/local"
  version = "0.1.1"
  value   = "${var.enabled}"
}

# Define composite variables for resources
module "label" {
  source        = "devops-workflow/label/local"
  version       = "0.1.3"
  organization  = "${var.organization}"
  name          = "${var.name}"
  namespace-env = "${var.namespace-env}"
  namespace-org = "${var.namespace-org}"
  environment   = "${var.environment}"
  delimiter     = "${var.delimiter}"
  attributes    = "${var.attributes}"
  tags          = "${var.tags}"
}

# Lookup ECS optimised Amazon AMI in the selected region
data "aws_ami" "aws_optimized_ecs" {
  #count     = "${module.enabled.value}"
  #count       = "${var.lookup_latest_ami ? 1 : 0}"
  most_recent = true
  owners = ["amazon"]
  /*filter {
    name   = "owner-alias"
    values = ["amazon"]
  }*/
  filter {
    name   = "name"
    values = ["amzn-ami-${var.ami_version}-amazon-ecs-optimized"]
  }
  /*filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }*/
}

data "template_file" "user_data" {
  # TODO: option to pass in
  # Cannot disable due to reference
  #count     = "${module.enabled.value}"
  template  = "${file("${path.module}/templates/user_data.tpl")}"
  vars {
    additional_user_data_script = "${var.additional_user_data_script}"
    cluster_name                = "${aws_ecs_cluster.this.name}"
    docker_storage_size         = "${var.docker_storage_size}"
    dockerhub_token             = "${var.dockerhub_token}"
    dockerhub_email             = "${var.dockerhub_email}"
  }
}

data "aws_vpc" "vpc" {
  #count = "${module.enabled.value}"
  id    = "${var.vpc_id}"
}

###
### AWS ECS Cluster
###
resource "aws_ecs_cluster" "this" {
  #count = "${module.enabled.value}"
  name  = "${module.label.id}"
}

module "asg" {
  #source    = "git::https://github.com/devops-workflow/terraform-aws-autoscaling.git?ref=tags/v0.1.3"
  source      = "git::https://github.com/devops-workflow/terraform-aws-autoscaling.git"
  enabled     = "${module.enabled.value}"
  name        = "${module.label.name}"
  environment = "${module.label.environment}"
  // Launch configuration
  associate_public_ip_address = "${var.associate_public_ip_address}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs_profile.name}"
  image_id                    = "${var.ami == "" ? data.aws_ami.aws_optimized_ecs.id : var.ami}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${var.key_name}"
  security_groups             = ["${concat(list(module.sg.id), var.security_group_ids)}"]
  user_data                   = "${coalesce(var.user_data, data.template_file.user_data.rendered)}"
  ebs_block_device  = [{
    device_name           = "/dev/xvdcz"
    volume_size           = "${var.docker_storage_size}"
    volume_type           = "gp2"
    delete_on_termination = true
  }]
  // Autoscaling group
  vpc_zone_identifier   = ["${var.subnet_id}"]
  # TODO: make setable: EC2 or ELB
  health_check_type     = "EC2"
  min_size              = "${var.min_servers}"
  max_size              = "${var.max_servers}"
  desired_capacity      = "${var.servers}"
  termination_policies  = ["OldestLaunchConfiguration", "ClosestToNextInstanceHour", "Default"]
  tags_ag               = ["${var.extra_tags}"]
}

module "sg" {
  source      = "git::https://github.com/devops-workflow/terraform-aws-security-group.git"
  enabled     = "${module.enabled.value}"
  name        = "${module.label.name}"
  description         = "Container Instance Allowed Ports"
  egress_cidr_blocks  = ["0.0.0.0/0"]
  egress_rules        = ["all-all"]
  environment         = "${module.label.environment}"
  ingress_cidr_blocks = "${var.allowed_cidr_blocks}"
  ingress_rules       = ["all-tcp", "all-udp"]
  vpc_id              = "${data.aws_vpc.vpc.id}"
}
