# 📦 Guide d'Installation - Ansible & Terraform

Ce guide détaille l'installation de tous les outils nécessaires pour le TP.

---

## 📋 Sommaire

1. [Installation d'Ansible](#-installation-dansible)
2. [Installation de Terraform](#-installation-de-terraform)
3. [Configuration du Vault Ansible](#-configuration-du-vault-ansible)
4. [Vérification des installations](#-vérification-des-installations)

---

## 🤖 Installation d'Ansible

### Ubuntu / Debian / Kali Linux

```bash
# Méthode 1 : Via apt (recommandé)
sudo apt update
sudo apt install ansible -y

# Vérifier l'installation
ansible --version
```

### Alternative : Via pip (dernière version)

```bash
# Installer pip si nécessaire
sudo apt install python3-pip -y

# Installer Ansible via pip
pip3 install ansible

# Ajouter au PATH si nécessaire
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Vérifier
ansible --version
```

### Modules Ansible requis

```bash
# Installer la collection community.general (pour mail)
ansible-galaxy collection install community.general

# Vérifier les collections installées
ansible-galaxy collection list
```

---

## 🏗️ Installation de Terraform

### Ubuntu / Debian / Kali Linux

```bash
# 1. Ajouter la clé GPG HashiCorp
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# 2. Ajouter le dépôt HashiCorp
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# 3. Mettre à jour et installer
sudo apt update
sudo apt install terraform -y

# 4. Vérifier l'installation
terraform --version
```

### Alternative : Installation manuelle (si le dépôt ne fonctionne pas)

```bash
# 1. Télécharger la dernière version
TERRAFORM_VERSION="1.6.6"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# 2. Décompresser
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# 3. Déplacer vers /usr/local/bin
sudo mv terraform /usr/local/bin/

# 4. Rendre exécutable
sudo chmod +x /usr/local/bin/terraform

# 5. Vérifier
terraform --version

# 6. Nettoyer
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
```

### Activer l'autocomplétion Terraform

```bash
# Pour Bash
terraform -install-autocomplete

# Recharger le shell
source ~/.bashrc
```

---

## 🔐 Configuration du Vault Ansible

Le fichier `vault.yml` contient les secrets (mot de passe SMTP). Il doit être chiffré avant d'être commité.

### Chiffrer le vault

```bash
cd ~/Bureau/Securite_vps/Partie2-Ansible

# Chiffrer le fichier (vous devrez créer un mot de passe)
ansible-vault encrypt vault.yml

# Vous serez invité à entrer un mot de passe de vault
# ⚠️ NOTEZ CE MOT DE PASSE, vous en aurez besoin pour exécuter le playbook
```

### Créer un fichier de mot de passe vault (optionnel)

```bash
# Créer un fichier contenant le mot de passe du vault
echo "votre_mot_de_passe_vault" > ~/.vault_password
chmod 600 ~/.vault_password

# Configurer ansible.cfg pour utiliser ce fichier
echo "vault_password_file = ~/.vault_password" >> ansible.cfg
```

### Éditer le vault chiffré

```bash
# Voir le contenu
ansible-vault view vault.yml

# Modifier le contenu
ansible-vault edit vault.yml

# Déchiffrer (attention !)
ansible-vault decrypt vault.yml
```

### Exécuter le playbook avec le vault

```bash
# Méthode 1 : Demander le mot de passe
ansible-playbook -i inventory.ini create_users.yml --ask-vault-pass

# Méthode 2 : Utiliser un fichier de mot de passe
ansible-playbook -i inventory.ini create_users.yml --vault-password-file ~/.vault_password
```

---

## ✅ Vérification des installations

Exécutez ce script pour vérifier que tout est installé :

```bash
#!/bin/bash
echo "=== 🔍 Vérification des installations ==="
echo ""

# Ansible
echo -n "Ansible : "
if command -v ansible &> /dev/null; then
    echo "✅ $(ansible --version | head -1)"
else
    echo "❌ Non installé"
fi

# Terraform
echo -n "Terraform : "
if command -v terraform &> /dev/null; then
    echo "✅ $(terraform --version | head -1)"
else
    echo "❌ Non installé"
fi

# Git
echo -n "Git : "
if command -v git &> /dev/null; then
    echo "✅ $(git --version)"
else
    echo "❌ Non installé"
fi

# Python
echo -n "Python : "
if command -v python3 &> /dev/null; then
    echo "✅ $(python3 --version)"
else
    echo "❌ Non installé"
fi

echo ""
echo "=== Vérification terminée ==="
```

### Commande rapide de vérification

```bash
echo "Ansible: $(ansible --version 2>/dev/null | head -1 || echo 'Non installé')"
echo "Terraform: $(terraform --version 2>/dev/null | head -1 || echo 'Non installé')"
```

---

## 🔧 Configuration SMTP Gmail

Pour que l'envoi d'emails fonctionne avec Gmail :

### 1. Activer l'authentification à 2 facteurs

1. Aller sur https://myaccount.google.com/security
2. Activer la "Validation en deux étapes"

### 2. Créer un mot de passe d'application

1. Aller sur https://myaccount.google.com/apppasswords
2. Sélectionner "Autre (nom personnalisé)"
3. Nommer : "Ansible TP INF3611"
4. Copier le mot de passe généré (format : `xxxx xxxx xxxx xxxx`)
5. Mettre ce mot de passe dans `vault.yml`

### 3. Configuration actuelle

Votre configuration SMTP :
- **Host** : smtp.gmail.com
- **Port** : 587
- **User** : francnkkaezer30@gmail.com
- **Password** : (stocké de manière sécurisée dans vault.yml)

---

## 📝 Récapitulatif des commandes

```bash
# Installation complète (copier-coller)
sudo apt update
sudo apt install ansible git python3-pip unzip -y
ansible-galaxy collection install community.general

# Terraform (si dépôt ne fonctionne pas)
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_1.6.6_linux_amd64.zip

# Vérification
ansible --version
terraform --version
```

---

## ⚠️ Problèmes courants

| Problème | Solution |
|----------|----------|
| `ansible: command not found` | `export PATH="$HOME/.local/bin:$PATH"` |
| `No module named 'ansible'` | `pip3 install ansible` |
| `terraform: command not found` | Vérifier `/usr/local/bin/terraform` |
| Erreur GPG Terraform | Utiliser l'installation manuelle |
| Vault password incorrect | Recréer avec `ansible-vault rekey` |
