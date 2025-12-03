# Partie 2 : Playbook Ansible - Automatisation de création d'utilisateurs

## Auteur
- **Nom** : AZAB A RANGA FRANCK MIGUEL
- **Matricule** : 23V2227
- **Filière** : Informatique L3
- **Cours** : INF 3611 - Administration Systèmes et Réseaux

---

## Description

Ce playbook Ansible automatise la création d'utilisateurs sous Linux, reproduisant exactement les fonctionnalités du script Bash avec en plus l'envoi d'emails personnalisés.

## Fonctionnalités implémentées

| # | Fonctionnalité | Statut |
|---|----------------|--------|
| 1 | Création du groupe students-inf-361 | ✅ |
| 2 | Création des utilisateurs avec toutes les informations | ✅ |
| 3 | Vérification/installation des shells | ✅ |
| 4 | Mot de passe haché SHA-512 | ✅ |
| 5 | Forcer changement mot de passe | ✅ |
| 6 | Ajout aux groupes sudo + restriction 'su' | ✅ |
| 7 | Message de bienvenue (WELCOME.txt + .bashrc) | ✅ |
| 8 | Configuration des limites mémoire | ✅ |
| 9 | Génération de logs | ✅ |
| 10 | **Envoi d'email personnalisé** | ✅ |

## Structure des fichiers

```
Partie2-Ansible/
├── README.md                 # Ce fichier
├── create_users.yml          # Playbook principal
├── inventory.ini             # Fichier d'inventaire
├── ansible.cfg               # Configuration Ansible
├── users.yml                 # Variables des utilisateurs (YAML)
└── templates/
    └── welcome.txt.j2        # Template du message de bienvenue
```

## Prérequis

### Sur la machine de contrôle (votre PC)

```bash
# Installation d'Ansible
sudo apt update
sudo apt install ansible python3-pip -y

# Vérification
ansible --version
```

### Sur le serveur cible (VPS)

- Système Linux (Ubuntu/Debian recommandé)
- Python 3 installé
- Accès SSH configuré
- Utilisateur avec privilèges sudo

## Configuration

### 1. Modifier l'inventaire

Éditez le fichier `inventory.ini` avec les informations de votre VPS :

```ini
[vps_servers]
vps1 ansible_host=VOTRE_IP_VPS ansible_user=VOTRE_USER ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### 2. Configurer les utilisateurs

Éditez le fichier `users.yml` ou directement dans le playbook :

```yaml
users:
  - username: nouvel.utilisateur
    password: "MotDePasse123!"
    full_name: "Nouvel Utilisateur"
    phone: "+237600000000"
    email: "utilisateur@email.com"
    shell: "/bin/bash"
```

### 3. Configurer l'envoi d'emails (optionnel)

Pour Gmail, créez un mot de passe d'application :
1. Allez sur https://myaccount.google.com/apppasswords
2. Créez un mot de passe pour "Mail"
3. Utilisez ce mot de passe dans le playbook

**Sécurisation avec Ansible Vault :**

```bash
# Créer un fichier de variables chiffrées
ansible-vault create secrets.yml

# Contenu du fichier secrets.yml :
smtp_user: "votre-email@gmail.com"
smtp_password: "votre-mot-de-passe-application"
```

## Utilisation

### Vérifier la connectivité

```bash
ansible -i inventory.ini all -m ping
```

### Exécuter le playbook

```bash
# Exécution standard
ansible-playbook -i inventory.ini create_users.yml

# Avec vérification préalable (dry-run)
ansible-playbook -i inventory.ini create_users.yml --check

# Avec les variables chiffrées
ansible-playbook -i inventory.ini create_users.yml --ask-vault-pass

# Avec verbose
ansible-playbook -i inventory.ini create_users.yml -v
```

### Exécuter sur un hôte spécifique

```bash
ansible-playbook -i inventory.ini create_users.yml --limit vps1
```

## Contenu de l'email envoyé

Chaque utilisateur reçoit un email contenant :

- ✅ Adresse IP du serveur
- ✅ Port d'écoute SSH
- ✅ Nom d'utilisateur
- ✅ Mot de passe initial
- ✅ Commande SSH de connexion
- ✅ Commande pour transmettre la clé publique (Linux/macOS/Windows)

### Exemple d'email :

```
Bonjour Jean Dupont,

Bienvenue sur le serveur VPS du cours INF 3611 !

═══════════════════════════════════════════════════════════════
                  INFORMATIONS DE CONNEXION
═══════════════════════════════════════════════════════════════

📍 Adresse IP du serveur : 192.168.1.100
🔌 Port SSH              : 22
👤 Nom d'utilisateur     : jean.dupont
🔑 Mot de passe initial  : TempPass123!

💻 Commande SSH pour se connecter :
   ssh jean.dupont@192.168.1.100 -p 22

🔐 Commande pour transmettre votre clé publique SSH :
   • Linux/macOS :
     ssh-copy-id -p 22 jean.dupont@192.168.1.100
   • Windows (PowerShell) :
     type $env:USERPROFILE\.ssh\id_rsa.pub | ssh -p 22 jean.dupont@192.168.1.100 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

## Logs générés

Le playbook génère un fichier de log sur le serveur :
```
/var/log/ansible_user_creation_YYYY-MM-DD.log
```

## Dépannage

### Erreur de connexion SSH

```bash
# Tester la connexion manuelle
ssh -i ~/.ssh/id_rsa admin@VOTRE_IP_VPS

# Vérifier les permissions de la clé
chmod 600 ~/.ssh/id_rsa
```

### Erreur d'envoi d'email

1. Vérifiez les paramètres SMTP
2. Activez "Accès aux applications moins sécurisées" ou utilisez un mot de passe d'application
3. Vérifiez que le port 587 n'est pas bloqué

### Module manquant

```bash
pip3 install passlib  # Pour le hachage de mot de passe
```

## Sécurité

⚠️ **Important :**
- Ne committez jamais de mots de passe en clair
- Utilisez `ansible-vault` pour les données sensibles
- Changez les mots de passe par défaut immédiatement
- Sécurisez le fichier d'inventaire

## Licence

Ce projet est réalisé dans le cadre du cours INF 3611 à l'Université de Yaoundé I.
