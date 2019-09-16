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
  description = "A may of all the settings for the api gateway. When creating an OPTIONS put it last in the list as the integrations/method response resources rely on it going last"
}

variable "lambda_function_names" {
  type = "list"
  description = "A list of all the lambda function names, used for lambda permissions"
}

