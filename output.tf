output "ecs_instance_public_ip" {
  description = "Public IP address of ECS EC2 instance"
  value       = aws_instance.ecs_host.public_ip
}
