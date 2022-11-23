# variable "files" {
#     default = ["bookstore-api.py", "Dockerfile", "docker-compose.yml", "requirements.txt"] 
# }
variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "key_name" {
  type = string
  default = "Emirhan"
}

variable "instance_tag" {
  type    = string
  default = "Web Server of Bookstore"
}
