provider "aws" {
  region = "${var.region}"

  # Make it faster by skipping something
  skip_get_ec2_platforms      = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
}

data "aws_vpc" "vpc" {
  tags {
    Env = "${var.environment}"
  }
}
data "aws_subnet_ids" "private_subnet_ids" {
  vpc_id = "${data.aws_vpc.vpc.id}"
  tags {
    Network = "Private"
  }
}
data "aws_subnet" "private_subnets" {
  count = "${length(data.aws_subnet_ids.private_subnet_ids.ids)}"
  id = "${data.aws_subnet_ids.private_subnet_ids.ids[count.index]}"
}

/*
module "disabled" {
  source  = "../"
  enabled = false
  name    = "disabled"
  environment   = "one"
  key_name      = ""
  subnet_id     = []
  vpc_id        = "${data.aws_vpc.vpc.id}"
}
*/

module "ecs-basic" {
  source  = "../"
  name    = "ecs-basic"
  environment   = "one"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = ["${data.aws_subnet_ids.private_subnet_ids.ids}"]
  vpc_id        = "${data.aws_vpc.vpc.id}"
}
