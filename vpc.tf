


module "myapp-vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "2.64.0"
  name                 = var.vpc_name
  cidr                 = var.vpc_cidr_block
  azs                  = data.aws_availability_zones.azs.names
  private_subnets      = var.private_subnet_cidr_blocks
  public_subnets       = var.public_subnet_cidr_blocks
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = 1
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks.cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = 1
  }

}