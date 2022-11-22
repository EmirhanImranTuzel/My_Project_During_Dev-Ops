data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}
resource "aws_security_group" "Sec_grp_ALB" {
  name        = "Sec_grp_for_ALB"
  description = "Allow http traffic from anywhere"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sec_grp_for_ALB"
  }
}

resource "aws_security_group" "Sec_grp_LT" {
  name        = "Sec_grp_for_LT"
  description = "Allow http traffic from Sec_grp_for_ALB"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    description     = "HTTP from Sec_grp_for_ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.Sec_grp_ALB.id]
  }

  ingress {
    description = "SSH from everywhere"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Sec_grp_for_LT"
  }
}

resource "aws_security_group" "Sec_grp_DB" {
  name        = "Sec_grp_for_DB"
  description = "Allow 3306 traffic from instances"
  vpc_id      = data.aws_vpc.default_vpc.id

  ingress {
    description     = "3306 from instances"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.Sec_grp_LT.id]
  }
  tags = {
    Name = "Sec_grp_for_DB"
  }
}

# data "template_file" "user_data" {
#   template = file("${abspath(path.module)}/userdata.sh")
#   vars = {
#     "rds_endpoint" = aws_db_instance.phonebook.address
#   }
# }
resource "aws_launch_template" "Phonebook_LT" {
  name                   = "Phonebook_App_LT"
  image_id               = data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.Sec_grp_LT.id]
  user_data              = base64encode("${templatefile("${path.module}/userdata.sh", { rds_endpoint = aws_db_instance.phonebook.address })}")
  # user_data = "${base64encode(data.template_file.userdata.rendered)

  # user_data = filebase64("user-data.sh")  These two can be used after git action done
  # depends_on = [github_repository_file.dbendpoint]
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.instance_tag
    }
  }
}

# resource "github_repository_file" "dbendpoint" {
#   file = "dbserver.endpoint"
#   content = aws_db_instance.db-server.address
#   repository = "phonebook_app"
#   overwrite_on_create = true
#   branch = "main"
# }

resource "aws_lb_target_group" "Phonebook_TG" {
  name        = "Phonebook-App-TG"
  target_type = "instance"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default_vpc.id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb" "Phonebook_ALB" {
  name                       = "Phonebook-App-ALB"
  ip_address_type            = "ipv4"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.Sec_grp_ALB.id]
  subnets                    = data.aws_subnets.default_subnet.ids
  enable_deletion_protection = false
}

resource "aws_lb_listener" "Phonebook_Listener_for_ALB" {
  load_balancer_arn = aws_lb.Phonebook_ALB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Phonebook_TG.arn
  }
}

resource "aws_autoscaling_group" "Phonebook_ASG" {
  vpc_zone_identifier       = aws_lb.Phonebook_ALB.subnets
  desired_capacity          = var.desired_capacity_of_instance
  max_size                  = var.maximum_size_of_instance
  min_size                  = var.minimum_size_of_instance
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.Phonebook_TG.arn]
  launch_template {
    id      = aws_launch_template.Phonebook_LT.id
    version = "$Latest"
  }
}

resource "aws_db_instance" "phonebook" {
  allocated_storage      = 20
  identifier             = "phonebook-app-db"
  db_name                = "phonebook"
  engine                 = "mysql"
  engine_version         = "8.0.28"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "EmirhanTuzel"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = false
  port                   = 3306
  vpc_security_group_ids = [aws_security_group.Sec_grp_DB.id]
}
