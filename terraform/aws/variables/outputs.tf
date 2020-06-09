output "instance_id" {
  description = "Instance ID of the instance"
  value       = "${aws_instance.demo.id}"
}

output "public_ip" {
  description = "Public IP of the instance"
  value       = "${aws_instance.demo.public_ip}"
}
