# ===============================================================================
#
#          FILE:  variables.tf
#
#   DESCRIPTION:  Variables Terraform pour le script de création d'utilisateurs
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
# VARIABLES DE CONNEXION SSH
# ===============================================================================

variable "server_ip" {
  description = "Adresse IP du serveur VPS cible"
  type        = string
  
  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.server_ip))
    error_message = "L'adresse IP doit être au format IPv4 valide (ex: 192.168.1.100)."
  }
}

variable "ssh_user" {
  description = "Nom d'utilisateur SSH pour la connexion au serveur"
  type        = string
  default     = "admin"
  
  validation {
    condition     = length(var.ssh_user) > 0
    error_message = "Le nom d'utilisateur SSH ne peut pas être vide."
  }
}

variable "ssh_port" {
  description = "Port SSH du serveur"
  type        = number
  default     = 22
  
  validation {
    condition     = var.ssh_port > 0 && var.ssh_port <= 65535
    error_message = "Le port SSH doit être compris entre 1 et 65535."
  }
}

variable "ssh_private_key_path" {
  description = "Chemin vers la clé privée SSH pour l'authentification"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# ===============================================================================
# VARIABLES DE CONFIGURATION DES UTILISATEURS
# ===============================================================================

variable "group_name" {
  description = "Nom du groupe à créer pour les utilisateurs"
  type        = string
  default     = "students-inf-361"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9_-]*$", var.group_name))
    error_message = "Le nom du groupe doit commencer par une lettre minuscule et ne contenir que des lettres minuscules, chiffres, tirets et underscores."
  }
}

variable "users_file_path" {
  description = "Chemin vers le fichier contenant la liste des utilisateurs"
  type        = string
  default     = "../Partie1-Bash/users.txt"
}

variable "script_path" {
  description = "Chemin vers le script de création d'utilisateurs"
  type        = string
  default     = "../Partie1-Bash/create_users.sh"
}

# ===============================================================================
# VARIABLES DE QUOTA ET LIMITES
# ===============================================================================

variable "disk_quota_gb" {
  description = "Quota d'espace disque en Go par utilisateur"
  type        = number
  default     = 15
  
  validation {
    condition     = var.disk_quota_gb > 0 && var.disk_quota_gb <= 100
    error_message = "Le quota disque doit être compris entre 1 et 100 Go."
  }
}

variable "ram_limit_percent" {
  description = "Limite de mémoire RAM en pourcentage par processus utilisateur"
  type        = number
  default     = 20
  
  validation {
    condition     = var.ram_limit_percent > 0 && var.ram_limit_percent <= 50
    error_message = "La limite RAM doit être comprise entre 1 et 50 %."
  }
}

# ===============================================================================
# VARIABLES DE COMPORTEMENT
# ===============================================================================

variable "cleanup_temp_files" {
  description = "Supprimer les fichiers temporaires après l'exécution"
  type        = bool
  default     = false
}

variable "force_password_change" {
  description = "Forcer le changement de mot de passe à la première connexion"
  type        = bool
  default     = true
}

variable "add_to_sudo" {
  description = "Ajouter les utilisateurs au groupe sudo"
  type        = bool
  default     = true
}

# ===============================================================================
# VARIABLES D'ENVIRONNEMENT (optionnelles, pour les secrets)
# ===============================================================================

variable "ssh_password" {
  description = "Mot de passe SSH (si l'authentification par clé n'est pas utilisée)"
  type        = string
  default     = ""
  sensitive   = true
}
