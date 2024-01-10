resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type  
  subnet_id = var.subnet_id
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

user_data = file("entry-script.sh")

 tags = {
  Name = "${var.env_prefix}-server"
 }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
  
}

resource "aws_default_security_group" "default-sg" {
    vpc_id = var.vpc_id
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

 