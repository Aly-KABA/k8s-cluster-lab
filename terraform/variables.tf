variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "k8s-cluster-lab"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "instance_type" {
  description = "Type d'instance pour les nœuds (t3.small minimum pour kubeadm)"
  type        = string
  default     = "t3.small"
}

variable "key_pair_name" {
  description = "Nom de la Key Pair EC2 existante, utilisée pour SSH (à créer dans la console AWS avant terraform apply)"
  type        = string
}

variable "my_ip_cidr" {
  description = "Ton IP publique en CIDR (ex: 1.2.3.4/32), pour restreindre SSH/API à toi uniquement"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "Bloc CIDR du subnet public (pas de NAT Gateway = pas de frais supplémentaires)"
  type        = string
  default     = "10.10.1.0/24"
}
