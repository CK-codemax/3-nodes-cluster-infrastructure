output "ssh_commands" {
  description = "SSH commands to connect to each instance"
  value = {
    master_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.masters[0].public_ip}"
    worker1_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.workers[0].public_ip}"
    worker2_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.workers[1].public_ip}"
  }
}

output "master_public_ips" {
  description = "Public IP addresses of the master instances"
  value       = aws_instance.masters[*].public_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the worker instances"
  value       = aws_instance.workers[*].public_ip
}


