resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Web server - allows SSH and HTTP"

  tags = {
    Name    = "web-sg"
    Project = "Exam"
  }
}

# Port 22 — SSH — your IP only
resource "aws_vpc_security_group_ingress_rule" "web-ssh" {
  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "102.88.108.230/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# Port 80 — HTTP — public
resource "aws_vpc_security_group_ingress_rule" "web-http" {
  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

# Outbound — all traffic allowed
resource "aws_vpc_security_group_egress_rule" "web-outbound" {
  security_group_id = aws_security_group.web-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ── Database Security Group ────────────────────────────────
resource "aws_security_group" "db-sg" {
  name        = "db-sg"
  description = "Database - port 3306 from web server only"

  tags = {
    Name    = "db-sg"
    Project = "Exam"
  }
}

# Port 3306 — MySQL — web server ONLY
resource "aws_vpc_security_group_ingress_rule" "db-mysql" {
  security_group_id            = aws_security_group.db-sg.id
  referenced_security_group_id = aws_security_group.web-sg.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

# Outbound — all traffic allowed
resource "aws_vpc_security_group_egress_rule" "db-outbound" {
  security_group_id = aws_security_group.db-sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}