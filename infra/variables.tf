variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "docker_image" {
  type    = string
  default = "elibarraza/adopcion-mascotas:1.1"
}

variable "domain_name" {
  type    = string
  default = "EliAdopta.com"
}
