# ===============================================================================
# Outputs Terraform
# TP 1 - INF 3611 : Administration Systèmes et Réseaux
#
# Auteur: AZAB A RANGA FRANCK MIGUEL - 23V2227
# ===============================================================================

output "connection_info" {
  description = "Informations de connexion au serveur"
  value = {
    server_ip   = var.server_ip
    ssh_port    = var.ssh_port
    ssh_user    = var.ssh_user
    ssh_command = "ssh -i ${var.ssh_private_key_path} -p ${var.ssh_port} ${var.ssh_user}@${var.server_ip}"
  }
}

output "configuration_summary" {
  description = "Résumé de la configuration appliquée"
  value = {
    group_name            = var.group_name
    disk_quota_gb         = var.disk_quota_gb
    ram_limit_percent     = var.ram_limit_percent
    force_password_change = var.force_password_change
    add_to_sudo           = var.add_to_sudo
  }
}

output "next_steps" {
  description = "Prochaines étapes pour les utilisateurs"
  value = <<-EOF
    
    ================================================================================
    CRÉATION DES UTILISATEURS TERMINÉE !
    ================================================================================
    
    Chaque utilisateur peut maintenant se connecter avec :
    
      ssh <username>@${var.server_ip} -p ${var.ssh_port}
    
    À la première connexion, un changement de mot de passe sera exigé.
    
    Pour transférer une clé SSH publique :
    
      ssh-copy-id -p ${var.ssh_port} <username>@${var.server_ip}
    
    ================================================================================
  EOF
}
