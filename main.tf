
resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.env_prefix}-vpc"
  }

}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name = "${var.env_prefix}-subnet-1"
  }

}

/*
resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-rtb"
    }
  
}
*/

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
      Name = "${var.env_prefix}-igw"
    }
  
}

/*
resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
  
}

*/

resource "aws_default_route_table" "main-rtb" {
default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id  

route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    
    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
    
}

/*
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        #cidr_blocks = ["0.0.0.0/0", "192.168.1.1/32"]
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = [] # for endpoint access > Not relevant for this demo
    
    }

    tags = {
      
      Name = "${var.env_prefix}-sg"
    }
  
}

*/

# Using a default security group


resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        #cidr_blocks = ["0.0.0.0/0", "192.168.1.1/32"]
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = [] # for endpoint access > Not relevant for this demo
    
    }

    tags = {
      
      Name = "${var.env_prefix}-default-sg"
    }
  
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type  
  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_default_security_group.default-sg.id]
 # availability_zone = var.avail_zone # is already determined by the subnet_id
 associate_public_ip_address = true
 # key_name = "fyoumbis-va-kp"
 key_name = aws_key_pair.ssh-key.key_name

 /*
 user_data = <<EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install docker -y
              sudo systemctl start docker
              sudo usermod -aG docker ec2-user
              docker run -p 8080:80 nginx
             EOF
  */

# user_data = file("entry-script.sh")

connection {
  type = "ssh"
  host = self.public_ip
  user = "ec2_user"
  private_key = file(var.private_key_location)
}

provisioner "file" {
  source = "entry-script.sh"
  destination = "~/entry-script.sh"
  
}

provisioner "remote-exec" {
  
   script = file("entry-script.sh") # The file must exist on the remote machine
 /*
  inline = [
    "export ENV=dev",
    "mkdir newdir"
  ]
  */
}

provisioner "local-exec" {
  command = "echo ${self.public_ip} > output.txt"
  
}
 tags = {
  Name = "${var.env_prefix}-server"
 }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
  
}
 
