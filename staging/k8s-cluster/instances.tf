# Key Pair
resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = file("${path.module}/../../k8s-cluster-key.pub")

  tags = {
    Name = "${var.cluster_name}-keypair"
  }
}

# Master Nodes
resource "aws_instance" "masters" {
  count = 1

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.master_instance_type
  key_name              = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.masters.id]
  subnet_id             = data.terraform_remote_state.vpc.outputs.public_subnet_ids[0]
  iam_instance_profile  = aws_iam_instance_profile.etcd_backup.name

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/../../scripts/master-userdata.sh", {
    cluster_name = var.cluster_name
    node_index   = count.index + 1
  }))

  tags = {
    Name = "${var.cluster_name}-master-${count.index + 1}"
    Role = "master"
  }

}

# Worker Nodes
resource "aws_instance" "workers" {
  count = 2

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  key_name              = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.workers.id]
  subnet_id             = data.terraform_remote_state.vpc.outputs.public_subnet_ids[count.index % length(data.terraform_remote_state.vpc.outputs.public_subnet_ids)]
  # AWS workloads use master node IAM permissions via etcd_backup role
  iam_instance_profile  = null

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/../../scripts/worker-userdata.sh", {
    cluster_name = var.cluster_name
    node_index   = count.index + 1
  }))

  tags = {
    Name = "${var.cluster_name}-worker-${count.index + 1}"
    Role = "worker"
  }

}
