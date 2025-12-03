# ===============================================================================
#
#          FILE:  main.tf
#
#   DESCRIPTION:  Configuration Terraform pour exécuter le script de création
#                 d'utilisateurs sur un VPS Linux
#                 TP 1 - INF 3611 : Administration Systèmes et Réseaux
#
#        AUTHOR:  AZAB A RANGA FRANCK MIGUEL
#     MATRICULE:  23V2227
#       FILIÈRE:  Informatique L3
#   INSTITUTION:  Université de Yaoundé I - Faculté des Sciences
#
#       VERSION:  1.0
#       CREATED:  01/12/2025
#
# ===============================================================================

# ===============================================================================
# CONFIGURATION TERRAFORM
# ===============================================================================

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# ===============================================================================
# VARIABLES LOCALES
# ===============================================================================

locals {
  # Timestamp pour les logs
  timestamp = formatdate("YYYY-MM-DD_hh-mm-ss", timestamp())
  
  # Chemin du script
  script_path = "${path.module}/../Partie1-Bash/create_users.sh"
  users_file  = "${path.module}/../Partie1-Bash/users.txt"
  
  # Fichiers à transférer
  files_to_transfer = [
    {
      source      = local.script_path
      destination = "/tmp/create_users.sh"
    },
    {
      source      = local.users_file
      destination = "/tmp/users.txt"
    }
  ]
}

# ===============================================================================
# RESSOURCE: Transfert des fichiers vers le serveur
# ===============================================================================

resource "null_resource" "transfer_files" {
  # Déclencheur pour forcer le re-transfert si les fichiers changent
  triggers = {
    script_hash = filemd5(local.script_path)
    users_hash  = filemd5(local.users_file)
    always_run  = timestamp()
  }

  # Configuration de la connexion SSH
  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    port        = var.ssh_port
    timeout     = "5m"
  }

  # Transfert du script
  provisioner "file" {
    source      = local.script_path
    destination = "/tmp/create_users.sh"
  }

  # Transfert du fichier utilisateurs
  provisioner "file" {
    source      = local.users_file
    destination = "/tmp/users.txt"
  }

  # Rendre le script exécutable
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_users.sh",
      "echo 'Fichiers transférés avec succès à ${local.timestamp}'"
    ]
  }
}

# ===============================================================================
# RESSOURCE: Exécution du script de création d'utilisateurs
# ===============================================================================

resource "null_resource" "execute_script" {
  depends_on = [null_resource.transfer_files]

  triggers = {
    script_hash = filemd5(local.script_path)
    users_hash  = filemd5(local.users_file)
    group_name  = var.group_name
  }

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    port        = var.ssh_port
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo '================================================================================'",
      "echo 'TERRAFORM - EXÉCUTION DU SCRIPT DE CRÉATION D'UTILISATEURS'",
      "echo 'Date: ${local.timestamp}'",
      "echo 'Serveur: ${var.server_ip}'",
      "echo 'Groupe: ${var.group_name}'",
      "echo '================================================================================'",
      "",
      "# Exécution du script avec sudo",
      "sudo /tmp/create_users.sh ${var.group_name} /tmp/users.txt",
      "",
      "echo '================================================================================'",
      "echo 'SCRIPT EXÉCUTÉ AVEC SUCCÈS'",
      "echo '================================================================================'",
    ]
  }
}

# ===============================================================================
# RESSOURCE: Vérification post-création
# ===============================================================================

resource "null_resource" "verify_users" {
  depends_on = [null_resource.execute_script]

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    port        = var.ssh_port
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ''",
      "echo '================================================================================'",
      "echo 'VÉRIFICATION DES UTILISATEURS CRÉÉS'",
      "echo '================================================================================'",
      "",
      "echo 'Membres du groupe ${var.group_name}:'",
      "getent group ${var.group_name} || echo 'Groupe non trouvé'",
      "",
      "echo ''",
      "echo 'Derniers utilisateurs créés (depuis /etc/passwd):'",
      "tail -10 /etc/passwd",
      "",
      "echo ''",
      "echo 'Fichiers de log générés:'",
      "ls -la /tmp/user_creation_*.log 2>/dev/null || echo 'Aucun fichier de log trouvé dans /tmp'",
      "",
      "echo ''",
      "echo '================================================================================'",
      "echo 'VÉRIFICATION TERMINÉE'",
      "echo '================================================================================'",
    ]
  }
}

# ===============================================================================
# RESSOURCE: Nettoyage des fichiers temporaires (optionnel)
# ===============================================================================

resource "null_resource" "cleanup" {
  depends_on = [null_resource.verify_users]
  
  # Ne s'exécute que si le nettoyage est activé
  count = var.cleanup_temp_files ? 1 : 0

  connection {
    type        = "ssh"
    host        = var.server_ip
    user        = var.ssh_user
    private_key = file(var.ssh_private_key_path)
    port        = var.ssh_port
    timeout     = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Nettoyage des fichiers temporaires...'",
      "rm -f /tmp/create_users.sh /tmp/users.txt",
      "echo 'Nettoyage terminé.'"
    ]
  }
}

# ===============================================================================
# RESSOURCE: Génération du rapport local
# ===============================================================================

resource "local_file" "execution_report" {
  depends_on = [null_resource.execute_script]
  
  filename = "${path.module}/execution_report_${local.timestamp}.txt"
  
  content = <<-EOF
    ================================================================================
    RAPPORT D'EXÉCUTION TERRAFORM - CRÉATION D'UTILISATEURS
    ================================================================================
    
    Date d'exécution    : ${local.timestamp}
    Serveur cible       : ${var.server_ip}
    Port SSH            : ${var.ssh_port}
    Utilisateur SSH     : ${var.ssh_user}
    Groupe créé         : ${var.group_name}
    
    ================================================================================
    FICHIERS TRANSFÉRÉS
    ================================================================================
    
    - Script     : ${local.script_path} -> /tmp/create_users.sh
    - Utilisateurs : ${local.users_file} -> /tmp/users.txt
    
    ================================================================================
    CONFIGURATION APPLIQUÉE
    ================================================================================
    
    - Quota disque      : 15 Go
    - Limite mémoire    : 20% RAM
    - Changement MDP    : Obligatoire à la première connexion
    - Groupe sudo       : Oui
    - Restriction su    : Activée
    
    ================================================================================
    Auteur: AZAB A RANGA FRANCK MIGUEL - 23V2227
    INF 3611 - Université de Yaoundé I
    ================================================================================
  EOF
}

# ===============================================================================
# OUTPUTS
# ===============================================================================

output "server_ip" {
  description = "Adresse IP du serveur cible"
  value       = var.server_ip
}

output "ssh_connection_command" {
  description = "Commande SSH pour se connecter au serveur"
  value       = "ssh -i ${var.ssh_private_key_path} -p ${var.ssh_port} ${var.ssh_user}@${var.server_ip}"
}

output "group_name" {
  description = "Nom du groupe créé"
  value       = var.group_name
}

output "execution_timestamp" {
  description = "Horodatage de l'exécution"
  value       = local.timestamp
}

output "report_file" {
  description = "Chemin du rapport d'exécution"
  value       = local_file.execution_report.filename
}
