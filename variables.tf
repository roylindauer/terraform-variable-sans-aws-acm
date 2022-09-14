variable "domain_name" {
  type = map(string)
}

variable "subject_alternative_names" {
  type = list(map(string))
}

variable "tags" {
  type = map(string)
}
