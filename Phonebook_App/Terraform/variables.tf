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
  default = "Web Server of Phonebook App"
}

variable "desired_capacity_of_instance" {
  type    = number
  default = 2
}

variable "minimum_size_of_instance" {
  type    = number
  default = 1
}

variable "maximum_size_of_instance" {
  type    = number
  default = 3
}