output "ecs_instance_public_ip" {
  description = "Public IP address of ECS EC2 instance"
  value       = aws_instance.ecs_host.public_ip
}

output "ecs_instance_ipv6_addresses" {
  description = "IPv6 addresses of ECS EC2 instance"
  value       = aws_instance.ecs_host.ipv6_addresses
}
