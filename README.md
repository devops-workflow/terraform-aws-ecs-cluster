
# terraform-aws-ecs-cluster

[![CircleCI](https://circleci.com/gh/devops-workflow/terraform-aws-ecs-cluster/tree/master.svg?style=svg)](https://circleci.com/gh/devops-workflow/terraform-aws-ecs-cluster/tree/master)
[![Github release](https://img.shields.io/github/release/devops-workflow/terraform-aws-ecs-cluster.svg)](https://github.com/devops-workflow/terraform-aws-ecs-cluster/releases)

A terraform module to provide ECS clusters in AWS.

This Module currently supports Terraform 0.10.x, but does not require it. If
you use tfenv, this module contains a `.terraform-version` file which matches
the version of Terraform we currently use to test with.

## Module Input Variables

### Required

- `name` - ECS cluster name
- `key_name` - An EC2 key pair name
- `subnet_id` - A list of subnet IDs
- `vpc_id` - The VPC ID to place the cluster in

### Optional

**NOTE About User Data:** The `user_data` parameter overwrites the `user_data` template used by this module, this will break some of the module features (e.g. `docker_storage_size`, `dockerhub_token`, and `dockerhub_email`). However, `additional_user_data_script` will concatenate additional data to the end of the current `user_data` script. It is recomended that you use `additional_user_data_script`. These two parameters are mutually exclusive - you can not pass both into this module and expect it to work.

- `additional_user_data_script` - Additional `user_data` scripts content
- `region` - AWS Region - defaults to us-east-1
- `servers`  - Number of ECS Servers to start in the cluster - defaults to 1
- `min_servers`  - Minimum number of ECS Servers to start in the cluster - defaults to 1
- `max_servers`  - Maximum number of ECS Servers to start in the cluster - defaults to 10
- `instance_type` - AWS instance type - defaults to t2.micro
- `iam_path` - IAM path, this is useful when creating resources with the same name across multiple regions. Defaults to /
- `associate_public_ip_address` - assign a publicly-routable IP address to every instance in the cluster - default: `false`.
- `docker_storage_size` - EBS Volume size in Gib that the ECS Instance uses for Docker images and metadata - defaults to 22
- `dockerhub_email` - Email Address used to authenticate to dockerhub. http://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html
- `dockerhub_token` - Auth Token used for dockerhub. http://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html
- `extra_tags` - Additional tags to be added to the ECS autoscaling group. Must be in the form of an array of hashes. See https://www.terraform.io/docs/providers/aws/r/autoscaling_group.html for examples.

```
extra_tags = [
    {
      key                 = "consul_server"
      value               = "true"
      propagate_at_launch = true
    },
  ]
```

- `allowed_cidr_blocks` - List of subnets to allow into the ECS Security Group. Defaults to `["0.0.0.0/0"]`.
- `ami` - A specific AMI image to use, eg `ami-95f8d2f3`. Defaults to the latest ECS optimized Amazon Linux AMI.
- `ami_version` - Specific version of the Amazon ECS AMI to use (e.g. `2016.09`). Defaults to `*`. Ignored if `ami` is specified.
- `heartbeat_timeout` - Heartbeat Timeout setting for how long it takes for the graceful shutodwn hook takes to timeout. This is useful when deploying clustered applications like consul that benifit from having a deploy between autoscaling create/destroy actions. Defaults to 180"
- `security_group_ids` - a list of security group IDs to apply to the launch configuration
- `user_data` - The instance user data (e.g. a `cloud-init` config) to use in the `aws_launch_configuration`
- `custom_iam_policy` -  JSON containing the custom IAM policy for ECS nodes. Will overwrite the default one if set.

- `consul_image` - Image to use when deploying consul, defaults to the hashicorp consul image
- `registrator_image` - Image to use when deploying registrator agent, defaults to the gliderlabs registrator:latest
- `enable_agents` - Enable Consul Agent and Registrator tasks on each ECS Instance. Defaults to false

## Usage

```hcl
module "ecs-cluster" {
  source    = "github.com/terraform-community-modules/tf_aws_ecs"
  name      = "infra-services"
  servers   = 1
  subnet_id = ["subnet-6e101446"]
  vpc_id    = "vpc-99e73dfc"
}
```

## Example cluster with consul and Registrator

In order to start the Consul/Registrator task in ECS, you'll need to pass in a consul config into the `additional_user_data_script` script parameter.  For example, you might pass something like this:

Please note, this module will try to mount `/etc/consul/` into `/consul/config` in the container and assumes that the consul config lives under `/etc/consul` on the docker host.

```Shell
/bin/mkdir -p /etc/consul
cat <<"CONSUL" > /etc/consul/config.json
{
  "raft_protocol": 3,
  "log_level": "INFO",
  "enable_script_checks": true,
  "datacenter": "${datacenter}",
  "retry_join_ec2": {
    "tag_key": "consul_server",
    "tag_value": "true"
  }
}
CONSUL
```

```hcl
data "template_file" "ecs_consul_agent_json" {
  template = "${file("ecs_consul_agent.json.sh")}"

  vars {
    datacenter = "infra-services"
  }
}

module "ecs-cluster" {
  source                      = "github.com/terraform-community-modules/tf_aws_ecs"
  name                        = "infra-services"
  servers                     = 1
  subnet_id                   = ["subnet-6e101446"]
  vpc_id                      = "vpc-99e73dfc"
  additional_user_data_script = "${data.template_file.ecs_consul_agent_json.rendered}"
  enable_agents               = true
}
```

## Outputs (remove once verified with descriptions)

- `cluster_id` - _(String)_ ECS Cluster id for use in ECS task and service definitions.
- `cluster_name` - (String) ECS Cluster name that can be used for CloudWatch app autoscaling policy resource_id.
- `autoscaling_group` _(Map)_ A map with keys `id`, `name`, and `arn` of the `aws_autoscaling_group` created.

## Authors

- [Tim Hartmann](https://github.com/tfhartmann)
- [Joe Stump](https://github.com/joestump)
- [Michal](https://github.com/mbolek)

## License

[MIT](LICENSE)

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| additional\_user\_data\_script | - | string | `` | no |
| allowed\_cidr\_blocks | List of subnets to allow into the ECS Security Group. Defaults to ['0.0.0.0/0'] | list | `<list>` | no |
| ami | - | string | `` | no |
| ami\_version | - | string | `*` | no |
| associate\_public\_ip\_address | - | string | `false` | no |
| attributes | Suffix name with additional attributes (policy, role, etc.) | list | `<list>` | no |
| consul\_image | Image to use when deploying consul, defaults to the hashicorp consul image | string | `consul:latest` | no |
| custom\_iam\_policy | Custom IAM policy (JSON). If set will overwrite the default one | string | `` | no |
| delimiter | Delimiter to be used between `name`, `namespaces`, `attributes`, etc. | string | `-` | no |
| docker\_storage\_size | EBS Volume size in Gib that the ECS Instance uses for Docker images and metadata | string | `22` | no |
| dockerhub\_email | Email Address used to authenticate to dockerhub. http://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html | string | `` | no |
| dockerhub\_token | Auth Token used for dockerhub. http://docs.aws.amazon.com/AmazonECS/latest/developerguide/private-auth.html | string | `` | no |
| ebs\_optimized | EBS Optimized | string | `true` | no |
| enable\_agents | Enable Consul Agent and Registrator tasks on each ECS Instance | string | `false` | no |
| enabled | Set to false to prevent the module from creating anything | string | `true` | no |
| environment | Environment (ex: `dev`, `qa`, `stage`, `prod`). (Second or top level namespace. Depending on namespacing options) | string | - | yes |
| extra\_tags | - | list | `<list>` | no |
| heartbeat\_timeout | Heartbeat Timeout setting for how long it takes for the graceful shutodwn hook takes to timeout. This is useful when deploying clustered applications like consul that benifit from having a deploy between autoscaling create/destroy actions. Defaults to 180 | string | `180` | no |
| iam\_path | IAM path, this is useful when creating resources with the same name across multiple regions. Defaults to / | string | `/` | no |
| instance\_type | AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types | string | `m5.large` | no |
| key\_name | SSH key name in your AWS account for AWS instances. | string | - | yes |
| max\_servers | Maximum number of ECS servers to run. | string | `10` | no |
| min\_servers | Minimum number of ECS servers to run. | string | `1` | no |
| name | Base name for resources | string | - | yes |
| name\_prefix | - | string | `` | no |
| namespace-env | Prefix name with the environment. If true, format is: <env>-<name> | string | `true` | no |
| namespace-org | Prefix name with the organization. If true, format is: <org>-<env namespaced name>. If both env and org namespaces are used, format will be <org>-<env>-<name> | string | `false` | no |
| organization | Organization name (Top level namespace). | string | `` | no |
| placement\_group | The name of the placement group into which you'll launch your instances, if any | string | `` | no |
| region | The region of AWS, for AMI lookups. | string | `us-east-1` | no |
| registrator\_image | Image to use when deploying registrator agent, defaults to the gliderlabs registrator:latest image | string | `gliderlabs/registrator:latest` | no |
| security\_group\_ids | A list of Security group IDs to apply to the launch configuration | list | `<list>` | no |
| servers | The number of servers to launch. | string | `1` | no |
| subnet\_id | The AWS Subnet ID in which you want to delpoy your instances | list | - | yes |
| tagName | Name tag for the servers | string | `ECS Node` | no |
| tags | A map of additional tags | map | `<map>` | no |
| tags\_ag | Additional tags for Autoscaling group. A list of tag blocks. Each element is a map with key, value, and propagate_at_launch. | list | `<list>` | no |
| termination\_policies | A list of policies to decide how the instances in the auto scale group should be terminated. The allowed values are OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, Default | list | `<list>` | no |
| user\_data | - | string | `` | no |
| vpc\_id | The AWS VPC ID which you want to deploy your instances | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| autoscaling\_group | Map of ASG info |
| cluster\_id | ECS Cluster ID |
| cluster\_name | ECS Cluster Name |
| cluster\_security\_group\_id | ECS Cluster Security Group ID |
| cluster\_size | Cluster size. Number of EC2 instances desired |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM GRAPH HOOK -->

### Resource Graph of plan

![Terraform Graph](resource-plan-graph.png)
<!-- END OF PRE-COMMIT-TERRAFORM GRAPH HOOK -->
