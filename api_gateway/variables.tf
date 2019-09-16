variable "name" {
  description = "The name given to the API"
}

variable "path_part" {
  description = "The last part segment of this API resource"
}

variable "stage_name" {
  description = "The name of the point of deployment such as test, dev, or prod"
}

variable "api_gateway_method_settings" {
  type = list(object({
    http_method = string
    authorization = string
    type = string
    uri = string
  }))
  description = "A may of all the settings for the api gateway"
}
