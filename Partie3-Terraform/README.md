# Partie 3 : Terraform - Exécution du script de création d'utilisateurs

## Auteur
- **Nom** : AZAB A RANGA FRANCK MIGUEL
- **Matricule** : 23V2227
- **Filière** : Informatique L3
- **Cours** : INF 3611 - Administration Systèmes et Réseaux

---

## Description

Cette configuration Terraform permet d'exécuter le script Bash de création d'utilisateurs sur un serveur VPS distant. Terraform gère :

- Le transfert du script et du fichier utilisateurs vers le serveur
- L'exécution du script avec les paramètres appropriés
- La vérification post-création
- La génération d'un rapport d'exécution

## Structure des fichiers

```
Partie3-Terraform/
├── README.md               # Ce fichier
├── main.tf                 # Configuration principale Terraform
├── variables.tf            # Définition des variables
├── outputs.tf              # Sorties Terraform
└── terraform.tfvars.example # Exemple de fichier de variables
```

## Prérequis

### Installation de Terraform

```bash
# Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Vérification
terraform --version
```

### Configuration SSH

1. Générer une paire de clés SSH (si nécessaire) :
```bash
ssh-keygen -t ed25519 -C "votre-email@example.com"
```

2. Copier la clé publique sur le serveur :
```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@VOTRE_IP_VPS
```

3. Tester la connexion :
```bash
ssh admin@VOTRE_IP_VPS
```

## Configuration

### 1. Créer le fichier de variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Modifier terraform.tfvars

```hcl
# Adresse IP de votre serveur VPS
server_ip = "VOTRE_IP_VPS"

# Utilisateur SSH (doit avoir les privilèges sudo)
ssh_user = "admin"

# Port SSH du serveur
ssh_port = 22

# Chemin vers votre clé privée SSH
ssh_private_key_path = "~/.ssh/id_rsa"

# Nom du groupe à créer
group_name = "students-inf-361"
```

## Utilisation

### Initialisation

```bash
cd Partie3-Terraform
terraform init
```

### Planification (prévisualisation)

```bash
terraform plan
```

### Application

```bash
terraform apply
```

Terraform vous demandera confirmation. Tapez `yes` pour continuer.

### Avec les variables en ligne de commande

```bash
terraform apply \
  -var="server_ip=192.168.1.100" \
  -var="ssh_user=admin" \
  -var="group_name=students-inf-361"
```

### Destruction (optionnel)

Pour supprimer les ressources créées localement :

```bash
terraform destroy
```

## Variables disponibles

| Variable | Description | Défaut | Obligatoire |
|----------|-------------|--------|-------------|
| `server_ip` | Adresse IP du VPS | - | ✅ |
| `ssh_user` | Utilisateur SSH | `admin` | ❌ |
| `ssh_port` | Port SSH | `22` | ❌ |
| `ssh_private_key_path` | Clé privée SSH | `~/.ssh/id_rsa` | ❌ |
| `group_name` | Nom du groupe | `students-inf-361` | ❌ |
| `disk_quota_gb` | Quota disque (Go) | `15` | ❌ |
| `ram_limit_percent` | Limite RAM (%) | `20` | ❌ |
| `cleanup_temp_files` | Nettoyer les fichiers temp | `false` | ❌ |

## Outputs

Après l'exécution, Terraform affiche :

```
Outputs:

server_ip = "192.168.1.100"
ssh_connection_command = "ssh -i ~/.ssh/id_rsa -p 22 admin@192.168.1.100"
group_name = "students-inf-361"
execution_timestamp = "2025-12-01_10-30-45"
report_file = "./execution_report_2025-12-01_10-30-45.txt"
```

## Workflow complet

```bash
# 1. Se placer dans le répertoire Terraform
cd Partie3-Terraform

# 2. Créer et configurer les variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# 3. Initialiser Terraform
terraform init

# 4. Vérifier le plan d'exécution
terraform plan

# 5. Appliquer la configuration
terraform apply

# 6. Vérifier les outputs
terraform output

# 7. Se connecter au serveur pour vérifier
ssh admin@VOTRE_IP_VPS
getent group students-inf-361
```

## Fichiers générés

| Fichier | Description |
|---------|-------------|
| `terraform.tfstate` | État de l'infrastructure Terraform |
| `execution_report_*.txt` | Rapport d'exécution local |
| `.terraform/` | Cache des providers Terraform |

## Dépannage

### Erreur de connexion SSH

```bash
# Vérifier la connectivité
ping VOTRE_IP_VPS

# Tester SSH manuellement
ssh -v -i ~/.ssh/id_rsa admin@VOTRE_IP_VPS

# Vérifier les permissions de la clé
chmod 600 ~/.ssh/id_rsa
```

### Timeout lors de l'exécution

Augmentez le timeout dans `main.tf` :
```hcl
connection {
  timeout = "15m"
}
```

### Script non trouvé

Vérifiez que le script existe :
```bash
ls -la ../Partie1-Bash/create_users.sh
ls -la ../Partie1-Bash/users.txt
```

## Sécurité

⚠️ **Bonnes pratiques :**

1. **Ne commitez jamais `terraform.tfvars`** avec des secrets
2. Ajoutez au `.gitignore` :
   ```
   *.tfvars
   *.tfstate
   *.tfstate.backup
   .terraform/
   ```
3. Utilisez des variables d'environnement pour les secrets :
   ```bash
   export TF_VAR_server_ip="192.168.1.100"
   ```

## Intégration Terraform / Bash

Ce projet démontre l'intégration entre Terraform et Bash :

1. **Terraform** gère l'infrastructure et l'orchestration
2. **Bash** exécute la logique métier (création d'utilisateurs)
3. **Provisioners** transfèrent et exécutent les scripts

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Terraform  │────▶│   SSH/SCP   │────▶│  VPS Linux  │
│   (Local)   │     │  Transfer   │     │   Script    │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Licence

Ce projet est réalisé dans le cadre du cours INF 3611 à l'Université de Yaoundé I.
