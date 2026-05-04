resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  availability_zone      = "eu-west-3a"
  #   user_data              = file("web1.sh")

  tags = {
    Name    = "Geeben-app"
    Project = "Exam"
  }
}

resource "aws_instance" "db" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.db-sg.id]
  availability_zone      = "eu-west-3a"
  #   user_data              = file("web2.sh")

  tags = {
    Name    = "Geeben-db"
    Project = "Exam"
  }
}

resource "aws_instance" "ansible" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web-sg.id]
  availability_zone      = "eu-west-3a"
  #   user_data              = file("web2.sh")

  tags = {
    Name    = "Geeben-ansible"
    Project = "Exam"
  }
}