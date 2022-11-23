output "bookstore-api-public-ip" {
  value = "http://${aws_instance.docker-server.public_ip}"
}