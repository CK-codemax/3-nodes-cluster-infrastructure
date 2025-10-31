# Security Groups
resource "aws_security_group" "masters" {
  name_prefix = "${var.cluster_name}-masters-"

  # HTTP/HTTPS - Only allow from VPC (Load Balancers will route through VPC)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "HTTP access from VPC (Load Balancers)"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "HTTPS access from VPC (Load Balancers)"
  }

  # SSH access (for management)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access for management"
  }

  # Kubernetes API server (kubeadm) - for management
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API server access"
  }

  # etcd client API (kubeadm HA)
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  # Kubelet API
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  # kube-scheduler
  ingress {
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    self        = true
  }

  # kube-controller-manager
  ingress {
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    self        = true
  }

  # Pod-to-pod communication: Allow all traffic from nodes in same security group
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Pod-to-pod communication: Allow all traffic from Calico Pod CIDR (192.168.0.0/16)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/16"]
  }

  # Pod-to-pod communication: Allow all traffic from default VPC (172.31.0.0/16)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.31.0.0/16"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-masters-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "workers" {
  name_prefix = "${var.cluster_name}-workers-"

  # HTTP/HTTPS - Only allow from VPC (Load Balancers will route through VPC)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "HTTP access from VPC (Load Balancers)"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "HTTPS access from VPC (Load Balancers)"
  }

  # SSH access (for management)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access for management"
  }

  # Kubelet API - Only from masters
  ingress {
    from_port       = 10250
    to_port         = 10250
    protocol        = "tcp"
    security_groups = [aws_security_group.masters.id]
    description     = "Kubelet API access from masters"
  }

  # NodePort services - Only allow from VPC (Load Balancers), not from internet
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "NodePort access from VPC (Load Balancers)"
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "udp"
    cidr_blocks = ["172.31.0.0/16"]
    description = "NodePort UDP access from VPC (Load Balancers)"
  }

  # All traffic from masters
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.masters.id]
  }

  # Pod-to-pod communication: Allow all traffic from nodes in same security group
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Pod-to-pod communication: Allow all traffic from Calico Pod CIDR (192.168.0.0/16)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/16"]
  }

  # Pod-to-pod communication: Allow all traffic from default VPC (172.31.0.0/16)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["172.31.0.0/16"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-workers-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}



