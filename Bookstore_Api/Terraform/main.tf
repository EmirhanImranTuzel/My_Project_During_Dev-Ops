data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_instance" "docker-server" {
  ami             = data.aws_ami.amazon-linux-2.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  vpc_security_group_ids = [aws_security_group.sec-gr.id]
  tags = {
    Name = var.instance_tag
  }
  user_data = <<-EOF
              #! /bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              hostnamectl set-hostname "docker-compose-server"
              cd /home/ec2-user
              TOKEN="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"
              FOLDER="https://$TOKEN@raw.githubusercontent.com/EmirhanImranTuzel/My_Project_During_Dev-Ops/main/Bookstore_Api"
              curl -s --create-dirs -o bookstore-api.py -L "$FOLDER"/bookstore-api.py
              curl -s --create-dirs -o Dockerfile -L "$FOLDER"/Dockerfile
              curl -s --create-dirs -o docker-compose.yml -L "$FOLDER"/docker-compose.yml
              curl -s --create-dirs -o requirements.txt -L "$FOLDER"/requirements.txt
              # docker build -t bookstore-api:latest .
              docker-compose up
              EOF
# depends_on = [github_repository.myrepo, github_repository_file.myfiles]
}


resource "aws_security_group" "sec-gr" {
    name = "docker-compose-sec-group"
    tags = {
      Name = "docker-compose-sec-group"
    }
    ingress {
      from_port   = 80
      protocol    = "tcp"
      to_port     = 80
      cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
      from_port   = 22
      protocol    = "tcp"
      to_port     = 22
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      protocol    = -1
      to_port     = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
}
