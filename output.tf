output "webapp_public_ip" {
  value = aws_instance.webapp.public_ip
}

output "db_public_ip" {
  value = aws_instance.db.public_ip
}