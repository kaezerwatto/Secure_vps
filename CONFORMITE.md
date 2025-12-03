# 📋 RAPPORT DE CONFORMITÉ - TP1 INF 3611

## Vérification complète du projet par rapport aux exigences du TP

**Étudiant** : AZAB A RANGA FRANCK MIGUEL  
**Matricule** : 23V2227  
**Date de vérification** : 03 décembre 2025

---

## ✅ PARTIE 0 : Procédure de modification du serveur SSH

| # | Exigence | Statut | Emplacement | Détails |
|:-:|----------|:------:|-------------|---------|
| 0.1 | Décrire la procédure correcte pour modifier SSH | ✅ | `Partie0-SSH/README.md` | 7 étapes détaillées (sauvegarde, édition, vérification syntaxe, test, reload, validation) |
| 0.2 | Expliquer le principal risque (lock-out) | ✅ | `Partie0-SSH/README.md` | Section complète sur le risque de verrouillage, causes, conséquences et prévention |
| 0.3 | Citer et justifier 5 paramètres de sécurité | ✅ | `Partie0-SSH/README.md` | **5 paramètres avec justifications** : PermitRootLogin, Port, PasswordAuthentication, MaxAuthTries, AllowGroups |

**Score Partie 0 : 3/3 ✅**

---

## ✅ PARTIE 1 : Script Bash `create_users.sh`

| # | Exigence | Statut | Fonction/Ligne | Détails |
|:-:|----------|:------:|----------------|---------|
| 1.1 | Groupe passé en paramètre | ✅ | `main()`, ligne 27 | `GROUP_NAME="${1:-}"` |
| 1.2a | Créer utilisateur avec nom d'utilisateur | ✅ | `create_user()`, ligne 434 | `useradd ... "$username"` |
| 1.2b | Nom complet, WhatsApp, email (GECOS) | ✅ | `create_user()`, ligne 433 | `-c "${full_name},${phone},${email}"` |
| 1.2c | Shell préféré (vérif/install) | ✅ | `check_and_install_shell()`, lignes 147-203 | Vérifie existence, installe si nécessaire, fallback /bin/bash |
| 1.2d | Répertoire personnel | ✅ | `create_user()`, ligne 431 | `useradd -m` (crée le home) |
| 1.3 | Ajouter au groupe students-inf-361 | ✅ | `create_user()`, ligne 438-440 | `usermod -aG "$group" "$username"` |
| 1.4 | MDP haché SHA-512 | ✅ | `hash_password()`, lignes 208-213 | `openssl passwd -6 -salt "$salt" "$password"` |
| 1.5 | Forcer changement MDP 1ère connexion | ✅ | `create_user()`, ligne 447 | `chage -d 0 "$username"` |
| 1.6 | Ajouter au groupe sudo | ✅ | `create_user()`, ligne 443-445 | `usermod -aG sudo "$username"` |
| 1.6 | Empêcher 'su' pour le groupe | ✅ | `restrict_su_command()`, lignes 371-403 | Configure `pam_wheel.so` dans `/etc/pam.d/su` |
| 1.7 | Message bienvenue ~/WELCOME.txt | ✅ | `create_welcome_message()`, lignes 219-276 | Fichier créé avec message personnalisé |
| 1.7 | Afficher dans ~/.bashrc | ✅ | `configure_bashrc()`, lignes 282-300 | Ajoute `cat ~/WELCOME.txt` dans .bashrc |
| 1.8 | Quota 15 Go | ✅ | `setup_disk_quota()`, lignes 306-339 | `setquota -u "$username"` |
| 1.9 | Limite mémoire 20% RAM | ✅ | `setup_memory_limits()`, lignes 345-368 | `/etc/security/limits.conf` avec calcul RAM |
| 1.10 | Fichier de log avec date/heure | ✅ | `LOG_FILE`, ligne 26 | `user_creation_$(date +%Y%m%d_%H%M%S).log` + logging complet |

**Score Partie 1 : 10/10 ✅**

---

## ✅ PARTIE 2 : Playbook Ansible `create_users.yml`

| # | Exigence | Statut | Task Ansible | Détails |
|:-:|----------|:------:|--------------|---------|
| 2.1 | Reproduire opérations du script Bash | ✅ | Toutes les tâches | Création groupe, utilisateurs, quotas, limites, etc. |
| 2.2 | Chargement depuis users.txt | ✅ | Lignes 55-73 | `slurp` + parsing regex du fichier TXT |
| 2.3 | Création groupe | ✅ | Ligne 103 | Module `group` |
| 2.4 | Création utilisateurs | ✅ | Lignes 165-179 | Module `user` avec password_hash SHA-512 |
| 2.5 | Shell vérifié/installé | ✅ | Lignes 144-163 | Installation zsh/fish si nécessaire |
| 2.6 | Forcer changement MDP | ✅ | Lignes 181-183 | `chage -d 0` |
| 2.7 | Restriction su (pam_wheel) | ✅ | Lignes 115-135 | Configuration PAM |
| 2.8 | Message bienvenue | ✅ | Lignes 189-208 | Template `welcome.txt.j2` + modification .bashrc |
| 2.9 | Limites mémoire | ✅ | Lignes 218-231 | `blockinfile` dans limits.conf |
| **EMAIL** | | | |
| 2.E1 | Adresse IP du serveur | ✅ | Ligne 248 | `{{ server_ip }}` |
| 2.E2 | Port SSH | ✅ | Ligne 263 | `{{ ssh_port }}` (2222) |
| 2.E3 | Nom d'utilisateur | ✅ | Ligne 264 | `{{ item.username }}` |
| 2.E4 | Mot de passe initial | ✅ | Ligne 265 | `{{ item.password }}` |
| 2.E5 | Commande SSH | ✅ | Lignes 271-272 | `ssh {{ item.username }}@{{ server_ip }} -p {{ ssh_port }}` |
| 2.E6 | ssh-copy-id (Linux/macOS/Windows) | ✅ | Lignes 276-282 | 3 variantes : Linux/macOS, Windows PowerShell, universelle |

**Score Partie 2 : 15/15 ✅**

---

## ✅ PARTIE 3 : Terraform

| # | Exigence | Statut | Fichier | Détails |
|:-:|----------|:------:|---------|---------|
| 3.1 | Utiliser Terraform pour exécuter le script | ✅ | `main.tf` | `null_resource` avec `remote-exec` |
| 3.2 | Fichier main.tf | ✅ | `main.tf` | 289 lignes, transfert + exécution |
| 3.3 | Fichier variables.tf | ✅ | `variables.tf` | 145 lignes, toutes variables définies |
| 3.4 | Connexion SSH | ✅ | `main.tf` lignes 74-80 | Configuration complète (host, user, key, port) |
| 3.5 | Transfert du script | ✅ | `main.tf` lignes 83-85 | `provisioner "file"` |
| 3.6 | Transfert de users.txt | ✅ | `main.tf` lignes 88-90 | `provisioner "file"` |
| 3.7 | Exécution du script | ✅ | `main.tf` lignes 119-139 | `sudo /tmp/create_users.sh ${var.group_name}` |

**Score Partie 3 : 7/7 ✅**

---

## ✅ LIVRABLES ATTENDUS

| # | Livrable | Statut | Emplacement |
|:-:|----------|:------:|-------------|
| L1 | Script `create_users.sh` | ✅ | `Partie1-Bash/create_users.sh` (565 lignes) |
| L2 | Playbook `create_users.yml` | ✅ | `Partie2-Ansible/create_users.yml` (370 lignes) |
| L3 | Inventaire Ansible | ✅ | `Partie2-Ansible/inventory.ini` |
| L4 | Fichier `users.txt` | ✅ | `Partie1-Bash/users.txt` + `Partie2-Ansible/users.txt` |
| L5 | Dossier Terraform (main.tf + variables.tf) | ✅ | `Partie3-Terraform/` (+ outputs.tf en bonus) |
| L6 | README.md par partie | ✅ | 4 README.md (Partie0, Partie1, Partie2, Partie3) |
| L7 | README.md global | ✅ | `README.md` à la racine (avec Mermaid) |
| L8 | Projet sur GitHub | ✅ | `https://github.com/kaezerwatto/Secure_vps` |

**Score Livrables : 8/8 ✅**

---

## ✅ COMPÉTENCES VISÉES

| # | Compétence | Statut | Preuves |
|:-:|------------|:------:|---------|
| C1 | Scripts Bash robustes | ✅ | Script 565 lignes, gestion erreurs, logs |
| C2 | Création/gestion utilisateurs et groupes | ✅ | useradd, groupadd, usermod |
| C3 | Gestion permissions et restrictions | ✅ | pam_wheel.so, sudo, chage |
| C4 | Durcissement SSH | ✅ | 5 paramètres + script configure_ssh.sh |
| C5 | Gestion ressources système | ✅ | Quotas, limits.conf |
| C6 | Personnalisation environnement | ✅ | WELCOME.txt, .bashrc |
| C7 | Ansible + emails automatiques | ✅ | Playbook complet + module mail |
| C8 | Terraform + intégration Bash | ✅ | null_resource + provisioners |
| C9 | Documentation technique | ✅ | README complets + diagrammes Mermaid |

**Score Compétences : 9/9 ✅**

---

## 📊 SCORE GLOBAL

| Partie | Points obtenus | Points max |
|--------|:--------------:|:----------:|
| Partie 0 - SSH | 3 | 3 |
| Partie 1 - Bash | 10 | 10 |
| Partie 2 - Ansible | 15 | 15 |
| Partie 3 - Terraform | 7 | 7 |
| Livrables | 8 | 8 |
| Compétences | 9 | 9 |
| **TOTAL** | **52** | **52** |

---

## 🎯 CONCLUSION

### ✅ TOUTES LES EXIGENCES SONT RESPECTÉES

Le projet répond à **100%** des exigences du TP1 INF 3611.

### 📁 Structure finale du projet

```
Secure_vps/
├── README.md                          ✅ Documentation globale avec Mermaid
├── INSTALLATION.md                    ✅ Guide d'installation
├── TESTS_LOCAL.md                     ✅ Guide de test
├── .gitignore                         ✅ Sécurité (vault.yml, tfvars)
│
├── Partie0-SSH/
│   ├── README.md                      ✅ Procédure + risques + 5 paramètres
│   └── configure_ssh.sh               ✅ Script de durcissement
│
├── Partie1-Bash/
│   ├── README.md                      ✅ Documentation
│   ├── create_users.sh                ✅ 10 fonctionnalités
│   └── users.txt                      ✅ Format requis
│
├── Partie2-Ansible/
│   ├── README.md                      ✅ Documentation
│   ├── create_users.yml               ✅ Playbook complet + emails
│   ├── inventory.ini                  ✅ Inventaire
│   ├── vault.yml                      ✅ Secrets chiffrés
│   ├── users.txt                      ✅ Format requis
│   └── templates/welcome.txt.j2       ✅ Template message
│
└── Partie3-Terraform/
    ├── README.md                      ✅ Documentation
    ├── main.tf                        ✅ Configuration principale
    ├── variables.tf                   ✅ Variables définies
    └── outputs.tf                     ✅ Bonus
```

### 🔐 Points de sécurité

- ✅ Mots de passe SMTP stockés dans `vault.yml` (chiffré Ansible Vault)
- ✅ Fichiers sensibles dans `.gitignore`
- ✅ Mots de passe hachés SHA-512
- ✅ Restriction su via PAM

---

**Vérifié le 03/12/2025**  
**Projet 100% conforme aux exigences du TP**
