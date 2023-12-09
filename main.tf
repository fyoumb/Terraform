
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your VPC CIDR block

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "two-tier-vpc"
    environment = "dev"
    application = "my_own_project-main"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24" # Replace with your desired public subnet CIDR block
  availability_zone       = "us-east-1a"  # Change to your desired AZ
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24" # Replace with your desired private subnet CIDR block
  availability_zone = "us-east-1b"  # Change to your desired AZ
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_security_group" "allow_allip" {
  vpc_id      = aws_vpc.my_vpc.id
  name_prefix = "allow_all_ip"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "my_keypair" {
  key_name   = "terraform-va-kp"         # Replace with your desired key pair name
  public_key = file("~/.ssh/id_rsa.pub") # Replace with the path to your public key file
}

resource "aws_instance" "public_instance" {
  ami = data.aws_ami.amazon_linux.id
  # Replace with your desired AMI ID
  instance_type   = "t2.micro" # Change to your desired instance type
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.allow_allip.id]
  key_name        = aws_key_pair.my_keypair.key_name

  tags = {
    Name = "Webserver"
  }
}


resource "aws_instance" "private_instance" {
  ami             = data.aws_ami.amazon_linux.id # Replace with your desired AMI ID
  instance_type   = "t2.micro"                   # Change to your desired instance type
  subnet_id       = aws_subnet.private_subnet.id
  security_groups = [aws_security_group.allow_allip.id]
  key_name        = aws_key_pair.my_keypair.key_name

  tags = {
    Name = "Database"
  }
}

resource "aws_eip" "nat_eip" {
  # instance = aws_instance.public_instance.id
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "private_rt"
  }
}

resource "aws_route" "private_subnet_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0" # Default route for NAT Gateway
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_route_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}