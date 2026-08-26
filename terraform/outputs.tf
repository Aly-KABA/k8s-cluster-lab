output "control_plane_public_ip" {
  description = "IP publique du nœud control-plane (pour SSH et kubectl)"
  value       = aws_instance.nodes["control-plane"].public_ip
}

output "worker_public_ips" {
  description = "IPs publiques des 2 workers"
  value = {
    worker-1 = aws_instance.nodes["worker-1"].public_ip
    worker-2 = aws_instance.nodes["worker-2"].public_ip
  }
}

output "all_private_ips" {
  description = "IPs privées des 3 nœuds (utilisées pour kubeadm init/join)"
  value = {
    for k, v in aws_instance.nodes : k => v.private_ip
  }
}

output "ssh_commands" {
  description = "Commandes SSH prêtes à l'emploi pour chaque nœud"
  value = {
    for k, v in aws_instance.nodes :
    k => "ssh -i <ta-clé.pem> ubuntu@${v.public_ip}"
  }
}
