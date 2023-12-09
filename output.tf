output "public_inst_public_ip" {
  value = aws_instance.public_instance.public_ip
}

output "private_inst_private_ip" {
  value = aws_instance.private_instance.private_ip
}