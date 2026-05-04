output "private_subnet_ids" {
  value = module.vpc.private_subnets
}
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}