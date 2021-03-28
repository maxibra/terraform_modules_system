###################
# Internet Gateway
###################
resource "aws_internet_gateway" "task-igw" {

  vpc_id = module.task_vpc.vpc_id

  tags = merge(
    {
      "Name" = format("%s", var.vpc_name)
    },
    var.vpc_tags,
  )
}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  count = length(var.vpc_public_subnets) > 0 ? 1 : 0

  vpc_id = module.task_vpc.vpc_id

  tags = merge(
    {
      "Name" = format("%s-public-rt", var.vpc_name)
    },
    var.vpc_tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.vpc_public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.task-igw.id

  timeouts {
    create = "5m"
  }
}

#################
# Private routes
#################
resource "aws_route_table" "private" {
  count  = length(var.vpc_private_subnets) > 0 ? 1 : 0
  vpc_id = module.task_vpc.vpc_id

  tags = merge(
    {
      "Name" = format("%s-private-rt", var.vpc_name)
    },
    var.vpc_tags,
  )

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
  }
}


##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count = length(var.vpc_private_subnets) > 0 ? length(var.vpc_private_subnets) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "public" {
  count = length(var.vpc_public_subnets) > 0 ? length(var.vpc_public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}


##########################
# Security Group
##########################
resource "aws_security_group" "task-sg" {

  vpc_id = module.task_vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    // This means, all ip address are allowed to ssh !
    // Do not do it in the production. Put your office or home address in it!
    cidr_blocks = ["0.0.0.0/0"]
  }

  //If you do not add this rule, you can not reach the NGIX
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
