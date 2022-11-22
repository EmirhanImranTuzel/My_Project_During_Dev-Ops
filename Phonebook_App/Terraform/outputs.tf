output "websiteurl" {
  value = "http://${aws_lb.Phonebook_ALB.dns_name}"
}
