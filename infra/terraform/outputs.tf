output "instance_public_ip" {
  description = "Public IP address of the CloudCart EC2 instance"
  value       = aws_instance.cloudcart_app.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.cloudcart_app.id
}

output "ssh_connection_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ~/.ssh/aws-keys/cloudcart-keypair.pem ubuntu@${aws_instance.cloudcart_app.public_ip}"
}
