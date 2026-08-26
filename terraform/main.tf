terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Réseau minimal : 1 VPC, 1 subnet public, pas de NAT Gateway
# (les 3 nœuds ont une IP publique directe -> zéro frais de NAT)
# ---------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-igw" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = merge(local.common_tags, { Name = "${var.project_name}-subnet" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-rt" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------------------------
# Security Group - ports nécessaires à un cluster kubeadm
# Référence officielle : https://kubernetes.io/docs/reference/networking/ports-and-protocols/
# ---------------------------------------------------------------------------
resource "aws_security_group" "k8s" {
  name        = "${var.project_name}-sg"
  description = "Ports requis pour un cluster kubeadm (control-plane + workers)"
  vpc_id      = aws_vpc.main.id

  # --- Accès admin depuis ton IP uniquement ---
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "API server Kubernetes (kubectl depuis ta machine)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # --- Communication interne entre les 3 nœuds (etcd, kubelet, scheduler, CNI...) ---
  ingress {
    description = "Tout le trafic interne au VPC (etcd, kubelet, CNI Calico/Flannel...)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # --- NodePort, pour exposer l'app de démo (30000-32767) ---
  ingress {
    description = "NodePort services (demo app)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-sg" })
}

# ---------------------------------------------------------------------------
# AMI Ubuntu 22.04 la plus récente (officielle Canonical)
# ---------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------
# Les 3 nœuds du cluster : 1 control-plane + 2 workers
# ---------------------------------------------------------------------------
resource "aws_instance" "nodes" {
  for_each = {
    control-plane = "control-plane"
    worker-1      = "worker"
    worker-2      = "worker"
  }

  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.k8s.id]
  key_name               = var.key_pair_name

  root_block_device {
    volume_size = 20 # Go - suffisant pour kubeadm + quelques images de conteneurs
    volume_type = "gp3"
  }

  user_data = file("${path.module}/../scripts/node-setup.sh")

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${each.key}"
    Role = each.value
  })
}
