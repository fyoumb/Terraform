resource "aws_vpc" "DemoVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "DemoVPC"
  }
}

/*
variable "vpc_id" {
  description = "ID of the existing VPC"
  default = 
}
*/

variable "azs" {
  type        = list(string)
  description = "List of Availability Zones (AZs)"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidr_blocks" {
  type        = map(string)
  description = "CIDR blocks for public subnets"
  default = {
    us-east-1a = "10.0.1.0/24",
    us-east-1b = "10.0.2.0/24"
  }
}

variable "private_subnet_cidr_blocks" {
  type        = map(string)
  description = "CIDR blocks for private subnets"
  default = {
    us-east-1a = "10.0.3.0/24",
    us-east-1b = "10.0.4.0/24"
  }
}

resource "aws_subnet" "public" {
  for_each = { for az in var.azs : az => var.public_subnet_cidr_blocks[az] }

  vpc_id                  = aws_vpc.DemoVPC.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true # Enable public IP auto-assignment for public subnets

  tags = {
    Name = "PublicSubnet-${each.key}"
  }
}

resource "aws_subnet" "private" {
  for_each = { for az in var.azs : az => var.private_subnet_cidr_blocks[az] }

  vpc_id            = aws_vpc.DemoVPC.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name = "PrivateSubnet-${each.key}"
  }
}

# Create the EC2

data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}

resource "aws_instance" "example_ec2" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  key_name        = "fyoumbis-va-kp"
  subnet_id       = aws_subnet.public["us-east-1a"].id # Replace with the actual AZ
 security_groups = [aws_security_group.public_sg.id]

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_instance" "example_ec2_priv" {
  ami             = data.aws_ami.amazon_linux.id
  instance_type   = "t2.micro"
  key_name        = "fyoumbis-va-kp"
  subnet_id       = aws_subnet.private["us-east-1a"].id # Replace with the actual AZ
 security_groups = [aws_security_group.private_sg.id]

  tags = {
    Name = "Private_ec2"
  }
}
# Create an IGW

resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.DemoVPC.id
  tags = {
    Name = "DemoIGW"
  }

}


# Create a route table named PublicRouteTable and a second one named PrivateRouteTable and associate the public and private subnets with them respectively

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.DemoVPC.id
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.DemoVPC.id
  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"                      # Default route for public route table
  gateway_id             = aws_internet_gateway.demo_igw.id # Replace with the IGW ID
}


resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public["us-east-1a"].id # Replace with actual subnet IDs
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_2" {
  subnet_id      = aws_subnet.public["us-east-1b"].id # Replace with actual subnet IDs
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_1" {
  subnet_id      = aws_subnet.private["us-east-1a"].id # Replace with actual subnet IDs
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_2" {
  subnet_id      = aws_subnet.private["us-east-1b"].id # Replace with actual subnet IDs
  route_table_id = aws_route_table.private_route_table.id
}

# Security Groups

resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Example security group for SSH and HTTP"
  vpc_id      = aws_vpc.DemoVPC.id

  # Inbound SSH (Port 22) rule
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your allowed IP range
  }

  # Inbound HTTP (Port 80) rule
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your allowed IP range
  }

  # Allow all outbound traffic

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your allowed IP range
  }

  # Optionally, you can add more rules as needed
}

# private SGs

resource "aws_security_group" "private_sg" {
  vpc_id      = aws_vpc.DemoVPC.id
  name        = "private-sg"
  description = "Security Group for the destination"
  # Define the ingress rules for sg-destination (if needed)
# Allow all outbound traffic

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your allowed IP range
  }

}

# Allow incoming traffic from sg-source to sg-destination
resource "aws_security_group_rule" "allow_sg_source_to_destination" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_sg.id
  security_group_id        = aws_security_group.private_sg.id
}

# Create a NAT GW and add it to the private RT
# A NAT GW is highly available in an AZ only
# For HA across AZs, each AZ should have its own NAT GW


# Create a NAT Gateway
resource "aws_nat_gateway" "example_nat_gateway" {
  allocation_id = aws_eip.example_eip.id
  subnet_id     = aws_subnet.public["us-east-1a"].id
}


# Create a default route in the private routing table that directs traffic to the NAT Gateway
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0" # Redirect all traffic
  nat_gateway_id         = aws_nat_gateway.example_nat_gateway.id
}

# Allocate an Elastic IP (EIP) for the NAT Gateway
resource "aws_eip" "example_eip" {
}


# Output the public IP

data "aws_instance" "example_ec2" {
  instance_id = aws_instance.example_ec2.id
}

data "aws_instance" "example_ec2_priv" {
  instance_id = aws_instance.example_ec2_priv.id
}

output "BastionHost_public_ip" {
  value = data.aws_instance.example_ec2.public_ip

}


output "private_ec2_priv_ip" {
  value = data.aws_instance.example_ec2_priv.private_ip

}

