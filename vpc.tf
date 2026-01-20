resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.env}-nat"
  }
}

data "aws_availability_zones" "azs" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.4.0"

  name = "${local.env}-vpc"
  cidr = local.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 3) 
  private_subnets = local.private_subnet_cidr_blocks
  public_subnets  = local.public_subnet_cidr_blocks

  enable_dns_hostnames    = true
  enable_dns_support      = true
  single_nat_gateway      = true
  enable_nat_gateway      = true
  reuse_nat_ips           = true
  one_nat_gateway_per_az  = false
  external_nat_ip_ids     = [aws_eip.nat.id]

  map_public_ip_on_launch = true

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                              = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb"                                       = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_cluster_name}" = "shared"
  }

  tags = {
    Name = "${local.env}-vpc"
  }
}