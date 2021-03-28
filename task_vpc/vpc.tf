provider "aws" {
  region = "us-west-2"
}

######
# VPC
######
module "task_vpc" {
  source = "github.com/maxibra/terrafor_modules_base//vpc/aws?ref=0.0.2"

  name = var.vpc_name
  cidr = var.vpc_cidr

  vpc_tags = var.vpc_tags
}

################
# Public subnet
################
resource "aws_subnet" "public" {
  count = length(var.vpc_public_subnets) > 0 ? length(var.vpc_public_subnets) : 0

  vpc_id                  = module.task_vpc.vpc_id
  cidr_block              = element(concat(var.vpc_public_subnets, [""]), count.index)
  availability_zone       = element(var.vpc_azs, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      "Name" = format(
        "%s-public-%s",
        var.vpc_name,
        element(var.vpc_azs, count.index),
      )
    },
    var.vpc_tags,
  )
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0

  vpc_id            = module.task_vpc.vpc_id
  cidr_block        = var.vpc_private_subnets[count.index]
  availability_zone = element(var.vpc_azs, count.index)

  tags = merge(
    {
      "Name" = format(
        "%s-private-%s",
        var.vpc_name,
        element(var.vpc_azs, count.index),
      )
    },
    var.vpc_tags,
  )
}



