output "resource_ids" {
  value = [
    aws_api_gateway_resource.hash_resource.id,
    aws_api_gateway_method.hash_method.id,
    aws_api_gateway_integration.hash_integration.id,
  ]
}