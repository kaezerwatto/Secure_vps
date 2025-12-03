# Partie 1 : Script Bash - Automatisation de création d'utilisateurs

## Auteur
- **Nom** : AZAB A RANGA FRANCK MIGUEL
- **Matricule** : 23V2227
- **Filière** : Informatique L3
- **Cours** : INF 3611 - Administration Systèmes et Réseaux

---

## Description

Ce script Bash automatise la création d'utilisateurs sous Linux à partir d'un fichier `users.txt`. Il implémente toutes les fonctionnalités demandées dans le TP.

## Fonctionnalités implémentées

| # | Fonctionnalité | Statut |
|---|----------------|--------|
| 1 | Création du groupe (paramètre du script) | OK |
| 2a | Création utilisateur avec nom d'utilisateur | OK |
| 2b | Nom complet, Whatsapp, email dans GECOS | OK |
| 2c | Vérification/installation du shell préféré | OK |
| 2d | Création du répertoire personnel | OK |
| 3 | Ajout au groupe students-inf-361 | OK |
| 4 | Mot de passe haché en SHA-512 | OK |
| 5 | Forcer changement mot de passe | OK |
| 6 | Ajout au groupe sudo + restriction 'su' | OK |
| 7 | Message de bienvenue (WELCOME.txt + .bashrc) | OK |
| 8 | Quota disque 15 Go | OK |
| 9 | Limite mémoire 20% RAM | OK |
| 10 | Fichier de logs avec date/heure | OK |

## Prérequis

- Système Linux (Ubuntu/Debian/CentOS/RHEL)
- Privilèges root (sudo)
- Fichier `users.txt` avec les informations des utilisateurs

## Installation

```bash
# Cloner le projet
git clone https://github.com/votre-username/TP-INF3611.git
cd TP-INF3611/Partie1-Bash

# Rendre le script exécutable
chmod +x create_users.sh

# Créer le fichier users.txt
nano users.txt
```

## Format du fichier users.txt

```
username;default_password;full_name;phone;email;preferred_shell
```

### Exemple :

```
jean;Password123!;Jean Dupont;+237699001122;jean.dupont@email.com;/bin/bash
marie;SecurePass456;Marie Kamga;+237677889900;marie.kamga@email.com;/bin/zsh
paul;MyPass789;Paul Nguema;+237655443322;paul.nguema@email.com;/usr/bin/fish
```

## Utilisation

```bash
# Syntaxe
sudo ./create_users.sh <nom_du_groupe> [chemin_fichier_users]

# Exemple avec le groupe par défaut
sudo ./create_users.sh students-inf-361

# Exemple avec un fichier personnalisé
sudo ./create_users.sh students-inf-361 /path/to/my_users.txt

# Afficher l'aide
./create_users.sh --help
```

## Structure des logs

Le script génère automatiquement un fichier de log avec le format :
```
user_creation_YYYYMMDD_HHMMSS.log
```

### Exemple de contenu du log :

```
================================================================================
SCRIPT DE CRÉATION D'UTILISATEURS - INF 3611
Date et heure d'exécution: 2025-12-01 10:30:45
Auteur: AZAB A RANGA FRANCK MIGUEL - 23V2227
================================================================================
[2025-12-01 10:30:45] [INFO] Création du groupe 'students-inf-361'...
[2025-12-01 10:30:45] [SUCCESS] Groupe 'students-inf-361' créé avec succès.
[2025-12-01 10:30:46] [INFO] Création de l'utilisateur: jean
[2025-12-01 10:30:46] [SUCCESS] Utilisateur 'jean' créé avec le shell '/bin/bash'.
...
```

## Sécurité implémentée

### Hachage SHA-512
Le mot de passe est haché avec l'algorithme SHA-512 avant d'être stocké :
```bash
openssl passwd -6 -salt "$salt" "$password"
```

### Changement de mot de passe obligatoire
```bash
chage -d 0 "$username"
```

### Restriction de 'su'
Les membres du groupe ne peuvent pas utiliser la commande `su` grâce à PAM :
```
auth required pam_wheel.so
```

### Quotas disque
Configuration de quota de 15 Go par utilisateur :
```bash
setquota -u "$username" $soft_limit $hard_limit 0 0 "$mount_point"
```

### Limites mémoire
Configuration dans `/etc/security/limits.conf` :
```
username  soft  as  $limit_kb
username  hard  as  $limit_kb
```

## Dépannage

### Le quota ne fonctionne pas
Assurez-vous que les quotas sont activés sur le système de fichiers :
```bash
# Éditer /etc/fstab et ajouter usrquota,grpquota
UUID=xxx /home ext4 defaults,usrquota,grpquota 0 2

# Remonter et initialiser les quotas
sudo mount -o remount /home
sudo quotacheck -cum /home
sudo quotaon /home
```

### L'installation du shell échoue
Si le shell demandé n'est pas disponible, le script attribue automatiquement `/bin/bash`.

## Fichiers générés

| Fichier | Description |
|---------|-------------|
| `user_creation_*.log` | Journal d'exécution du script |
| `~/WELCOME.txt` | Message de bienvenue pour chaque utilisateur |
| `~/.bashrc` | Modifié pour afficher WELCOME.txt |

## Licence

Ce projet est réalisé dans le cadre du cours INF 3611 à l'Université de Yaoundé I.
