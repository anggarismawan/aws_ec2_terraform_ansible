# below we define with the variable instance_count how many servers we want to create
variable "instance_count" {
  default = "2"
}

# below we define the default server names
variable "instance_tags" {
  type = list(string)
  default = ["poc-tf-ansible-1", "poc-tf-ansible-2", "poc-tf-ansible-3", "poc-tf-ansible-4", "poc-tf-ansible-5"]
}

# we use Ubuntu as the OS
variable "ami" {
  type = string
  default = "ami-02c28895d7962c033" #ap-southeast-3 image for x86_64 Ubuntu_20.04 2021-05-28T21:06:05.000Z
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

