# 🧪 Guide de Test en Local (Sans VPS)

Ce guide explique comment tester toutes les parties du TP sans avoir accès à un VPS.

---

## 📋 Options de test disponibles

| Option | Complexité | Recommandation |
|--------|:----------:|----------------|
| **Option 1** : Test direct sur votre machine | ⭐ Facile | ✅ Recommandé pour débuter |
| **Option 2** : Machine virtuelle (VM) | ⭐⭐ Moyen | ✅ Simulation réaliste |
| **Option 3** : Conteneur Docker | ⭐⭐⭐ Avancé | Pour tests rapides |

---

## 🚀 Option 1 : Test direct sur votre machine (Recommandé)

### Prérequis
- Linux (Ubuntu/Debian/Kali)
- Accès sudo

### 1.1 Tester le Script Bash (Partie 1)

```bash
# 1. Aller dans le répertoire
cd ~/Bureau/Securite_vps/Partie1-Bash

# 2. Rendre le script exécutable
chmod +x create_users.sh

# 3. Tester en mode simulation (dry-run) - Ajouter cette option au script
# Ou exécuter directement (créera de vrais utilisateurs sur votre machine)
sudo ./create_users.sh students-inf-361

# 4. Vérifier les résultats
getent group students-inf-361
cat /etc/passwd | grep -E "jean|marie|paul|alice|bob"
cat user_creation_*.log
```

### 1.2 Tester Ansible en localhost (Partie 2)

```bash
# 1. Aller dans le répertoire Ansible
cd ~/Bureau/Securite_vps/Partie2-Ansible

# 2. Créer un inventaire local
cat > inventory_local.ini << 'EOF'
[local]
localhost ansible_connection=local

[local:vars]
ansible_python_interpreter=/usr/bin/python3
group_name=students-inf-361
disk_quota_gb=15
ram_limit_percent=20
ssh_port=22
EOF

# 3. Tester la connexion
ansible -i inventory_local.ini local -m ping

# 4. Exécuter le playbook en local (dry-run d'abord)
ansible-playbook -i inventory_local.ini create_users.yml --check

# 5. Exécuter pour de vrai
sudo ansible-playbook -i inventory_local.ini create_users.yml
```

### 1.3 Tester Terraform (Partie 3)

Terraform nécessite une connexion SSH, donc on le teste avec localhost :

```bash
# 1. Aller dans le répertoire
cd ~/Bureau/Securite_vps/Partie3-Terraform

# 2. Vérifier la syntaxe Terraform
terraform init
terraform validate
terraform plan -var="server_ip=127.0.0.1" -var="ssh_user=$USER"

# Note: L'exécution réelle nécessite une vraie connexion SSH
```

---

## 🖥️ Option 2 : Machine Virtuelle (Simulation VPS)

### 2.1 Créer une VM avec Vagrant (Méthode simple)

```bash
# 1. Installer Vagrant et VirtualBox
sudo apt install vagrant virtualbox -y

# 2. Créer un répertoire pour la VM
mkdir ~/test-vps && cd ~/test-vps

# 3. Initialiser une VM Ubuntu
vagrant init ubuntu/jammy64

# 4. Démarrer la VM
vagrant up

# 5. Se connecter à la VM
vagrant ssh

# 6. Obtenir l'IP de la VM
vagrant ssh -c "hostname -I"
```

### 2.2 Configurer SSH pour la VM

```bash
# Sur votre machine hôte, copier votre clé SSH
vagrant ssh-copy-id

# Ou utiliser la clé Vagrant
# La clé est dans : .vagrant/machines/default/virtualbox/private_key
```

### 2.3 Tester avec la VM

```bash
# Mettre à jour l'inventaire Ansible avec l'IP de la VM
cd ~/Bureau/Securite_vps/Partie2-Ansible

# Modifier inventory.ini avec l'IP de votre VM (exemple: 192.168.56.10)
# ansible_host=192.168.56.10 ansible_user=vagrant ansible_port=22
```

---

## 🐳 Option 3 : Conteneur Docker

### 3.1 Créer un conteneur de test

```bash
# 1. Créer un Dockerfile
mkdir ~/docker-test-vps && cd ~/docker-test-vps

cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

# Installation des paquets nécessaires
RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo \
    python3 \
    quota \
    && rm -rf /var/lib/apt/lists/*

# Configuration SSH
RUN mkdir /var/run/sshd
RUN echo 'root:testpassword' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Créer un utilisateur admin
RUN useradd -m -s /bin/bash admin && \
    echo 'admin:admin' | chpasswd && \
    usermod -aG sudo admin

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF

# 2. Construire l'image
docker build -t test-vps .

# 3. Lancer le conteneur
docker run -d -p 2222:22 --name mon-vps test-vps

# 4. Tester la connexion SSH
ssh -p 2222 admin@localhost
# Mot de passe: admin
```

### 3.2 Tester avec le conteneur

```bash
# Mettre à jour l'inventaire Ansible
cd ~/Bureau/Securite_vps/Partie2-Ansible

cat > inventory_docker.ini << 'EOF'
[vps_servers]
docker_vps ansible_host=127.0.0.1 ansible_user=admin ansible_port=2222 ansible_password=admin

[vps_servers:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
group_name=students-inf-361
ssh_port=2222
EOF

# Tester
ansible -i inventory_docker.ini vps_servers -m ping --ask-pass
```

---

## 📝 Tests rapides sans installation

### Test 1 : Vérifier la syntaxe du script Bash

```bash
cd ~/Bureau/Securite_vps/Partie1-Bash

# Vérifier la syntaxe (sans exécuter)
bash -n create_users.sh && echo "✅ Syntaxe OK" || echo "❌ Erreur de syntaxe"

# Afficher les fonctions
grep -E "^[a-z_]+\(\)" create_users.sh
```

### Test 2 : Vérifier la syntaxe Ansible

```bash
cd ~/Bureau/Securite_vps/Partie2-Ansible

# Vérifier la syntaxe du playbook
ansible-playbook create_users.yml --syntax-check

# Lister les tâches
ansible-playbook create_users.yml --list-tasks
```

### Test 3 : Vérifier Terraform

```bash
cd ~/Bureau/Securite_vps/Partie3-Terraform

# Initialiser
terraform init

# Valider la syntaxe
terraform validate

# Formater le code
terraform fmt
```

---

## 🎯 Commandes de test rapide (copier-coller)

```bash
# === TEST COMPLET EN LOCAL ===

# 1. Vérifier les syntaxes
echo "=== Vérification des syntaxes ==="
cd ~/Bureau/Securite_vps

echo "Bash..."
bash -n Partie1-Bash/create_users.sh && echo "✅ Bash OK"

echo "Ansible..."
cd Partie2-Ansible && ansible-playbook create_users.yml --syntax-check && echo "✅ Ansible OK"
cd ..

echo "Terraform..."
cd Partie3-Terraform && terraform init -backend=false > /dev/null 2>&1 && terraform validate && echo "✅ Terraform OK"
cd ..

echo ""
echo "=== Tous les tests de syntaxe passés ! ==="
```

---

## ⚠️ Notes importantes

1. **Tests sur votre machine locale** : Les utilisateurs créés seront de vrais utilisateurs sur votre système !

2. **Nettoyage après tests** :
   ```bash
   # Supprimer les utilisateurs de test
   sudo userdel -r jean.dupont
   sudo userdel -r marie.kamga
   sudo userdel -r paul.nguema
   sudo userdel -r alice.mbarga
   sudo userdel -r bob.fouda
   
   # Supprimer le groupe
   sudo groupdel students-inf-361
   ```

3. **Email** : Les emails ne seront pas envoyés sans configuration SMTP valide (c'est normal).

---

## 📊 Checklist de test

- [ ] Script Bash : syntaxe valide
- [ ] Script Bash : exécution réussie (local ou VM)
- [ ] Ansible : syntaxe valide
- [ ] Ansible : ping localhost réussi
- [ ] Ansible : playbook exécuté (mode check)
- [ ] Terraform : init réussi
- [ ] Terraform : validate réussi
- [ ] Utilisateurs créés visibles dans `/etc/passwd`
- [ ] Groupe `students-inf-361` créé
- [ ] Fichier de log généré
