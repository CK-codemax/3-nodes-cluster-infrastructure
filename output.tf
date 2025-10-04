output "ssh_commands" {
  description = "SSH commands to connect to each instance"
  value = {
    master_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.masters[0].public_ip}"
    worker1_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.workers[0].public_ip}"
    worker2_ssh = "ssh -i k8s-cluster-key ubuntu@${aws_instance.workers[1].public_ip}"
  }
}

output "master_instance_ids" {
  description = "IDs of the master instances"
  value       = aws_instance.masters[*].id
}

output "master_private_ips" {
  description = "Private IP addresses of the master instances"
  value       = aws_instance.masters[*].private_ip
}

output "master_public_ips" {
  description = "Public IP addresses of the master instances"
  value       = aws_instance.masters[*].public_ip
}

output "worker_instance_ids" {
  description = "IDs of the worker instances"
  value       = aws_instance.workers[*].id
}

output "worker_private_ips" {
  description = "Private IP addresses of the worker instances"
  value       = aws_instance.workers[*].private_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the worker instances"
  value       = aws_instance.workers[*].public_ip
}


output "key_pair_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.main.key_name
}

output "ami_id" {
  description = "ID of the AMI used"
  value       = data.aws_ami.ubuntu.id
}

output "cluster_info" {
  description = "Cluster information"
  value = {
    cluster_name      = var.cluster_name
    kubernetes_version = var.kubernetes_version
    region           = var.aws_region
  }
}


