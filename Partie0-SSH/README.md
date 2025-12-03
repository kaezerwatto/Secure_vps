# Partie 0 : Procédure de modification du serveur SSH

## Auteur
- **Nom** : AZAB A RANGA FRANCK MIGUEL
- **Matricule** : 23V2227
- **Filière** : Informatique L3
- **Cours** : INF 3611 - Administration Systèmes et Réseaux

---

## 1. Procédure correcte pour modifier la configuration du service SSH

La modification de la configuration SSH doit suivre une procédure rigoureuse pour éviter de perdre l'accès au serveur :

### Étape 1 : Sauvegarder la configuration actuelle
```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)
```

### Étape 2 : Éditer le fichier de configuration
```bash
sudo nano /etc/ssh/sshd_config
# ou
sudo vim /etc/ssh/sshd_config
```

### Étape 3 : Vérifier la syntaxe de la configuration
```bash
sudo sshd -t
```
Cette commande vérifie la validité syntaxique du fichier de configuration. Si aucune erreur n'est affichée, la configuration est correcte.

### Étape 4 : Ouvrir une nouvelle session SSH de test (AVANT de fermer la session actuelle)
```bash
# Dans un nouveau terminal, tester la connexion
ssh user@server_ip -p nouveau_port
```

### Étape 5 : Recharger le service SSH (pas redémarrer)
```bash
sudo systemctl reload sshd
# ou
sudo systemctl reload ssh
```
**Note importante** : Utiliser `reload` au lieu de `restart` permet de garder les sessions existantes actives.

### Étape 6 : Tester la nouvelle configuration
Ouvrir une nouvelle connexion SSH dans un terminal séparé pour vérifier que tout fonctionne.

### Étape 7 : Ne fermer la session actuelle qu'après confirmation
Une fois la connexion réussie avec la nouvelle configuration, vous pouvez fermer l'ancienne session.

---

## 2. Principal risque encouru si cette procédure n'est pas respectée

### **Risque : Perte totale d'accès au serveur (Lock-out)**

Si la procédure n'est pas respectée, le principal risque est de **se retrouver complètement verrouillé hors du serveur** sans possibilité de connexion SSH.

#### Causes possibles :
- **Erreur de syntaxe** dans le fichier `sshd_config` empêchant le service de démarrer
- **Changement de port SSH** sans avoir ouvert ce port dans le pare-feu
- **Désactivation de l'authentification par mot de passe** sans avoir configuré les clés SSH
- **Restriction d'accès** (`AllowUsers`, `AllowGroups`) excluant votre propre compte
- **Modification de `ListenAddress`** avec une adresse IP incorrecte

#### Conséquences :
- Impossibilité de se connecter au serveur
- Nécessité d'accéder physiquement au serveur ou via une console de récupération (KVM, IPMI, console cloud)
- Perte de temps et potentiellement de données
- Dans le cas d'un VPS Cloud, nécessité de démarrer en mode rescue ou de contacter le support

#### Prévention :
- Toujours tester avec `sshd -t` avant de recharger
- Toujours garder une session SSH ouverte pendant les modifications
- Toujours tester la nouvelle connexion avant de fermer l'ancienne

---

## 3. Cinq paramètres de sécurité SSH à modifier

### Paramètre 1 : `PermitRootLogin no`

**Configuration :**
```bash
PermitRootLogin no
```

**Justification :**
- Empêche la connexion directe en tant que root via SSH
- Le compte root est la cible principale des attaques par force brute
- Force l'utilisation d'un compte utilisateur normal puis `sudo` pour les tâches administratives
- Améliore la traçabilité des actions (on sait qui s'est connecté avant de devenir root)
- Principe du moindre privilège

---

### Paramètre 2 : `Port 2222` (ou autre port non standard)

**Configuration :**
```bash
Port 2222
```

**Justification :**
- Le port 22 est scanné en permanence par des bots automatisés
- Changer le port réduit considérablement le nombre de tentatives de connexion automatisées
- Technique de "security through obscurity" qui n'est pas suffisante seule mais réduit le bruit
- Réduit la charge sur les logs du serveur
- **Note** : N'oubliez pas d'ouvrir le nouveau port dans le pare-feu !

---

### Paramètre 3 : `PasswordAuthentication no`

**Configuration :**
```bash
PasswordAuthentication no
PubkeyAuthentication yes
```

**Justification :**
- Les mots de passe sont vulnérables aux attaques par force brute et dictionnaire
- Les clés SSH sont cryptographiquement plus sécurisées (2048 ou 4096 bits RSA, ou Ed25519)
- Impossible de deviner une clé privée par force brute
- Élimine les risques liés aux mots de passe faibles
- Améliore la sécurité sans compromettre la commodité

---

### Paramètre 4 : `MaxAuthTries 3`

**Configuration :**
```bash
MaxAuthTries 3
LoginGraceTime 60
MaxStartups 3:50:10
```

**Justification :**
- `MaxAuthTries 3` : Limite le nombre de tentatives d'authentification par connexion
- `LoginGraceTime 60` : Déconnecte après 60 secondes si l'authentification n'est pas complète
- `MaxStartups 3:50:10` : Limite les connexions simultanées non authentifiées
- Réduit l'efficacité des attaques par force brute
- Protège contre les tentatives d'épuisement de ressources (DoS)
- Bloque les scripts automatisés après quelques échecs

---

### Paramètre 5 : `AllowUsers` ou `AllowGroups`

**Configuration :**
```bash
AllowGroups ssh-allowed students-inf-361
# ou
AllowUsers user1 user2 user3
```

**Justification :**
- Restreint l'accès SSH à une liste explicite d'utilisateurs ou de groupes autorisés
- Même si un compte est compromis, il ne peut pas se connecter SSH s'il n'est pas dans la liste
- Applique le principe du moindre privilège
- Facilite la gestion centralisée des accès
- Protège contre les comptes système qui ne devraient jamais avoir accès SSH

---

## Paramètres supplémentaires recommandés

### Paramètre 6 : `Protocol 2`
```bash
Protocol 2
```
- Force l'utilisation de SSH version 2 uniquement (plus sécurisé)

### Paramètre 7 : `X11Forwarding no`
```bash
X11Forwarding no
```
- Désactive le transfert X11 si non nécessaire (réduit la surface d'attaque)

### Paramètre 8 : `ClientAliveInterval` et `ClientAliveCountMax`
```bash
ClientAliveInterval 300
ClientAliveCountMax 2
```
- Déconnecte les sessions inactives (timeout de 10 minutes)

### Paramètre 9 : `Banner /etc/ssh/banner`
```bash
Banner /etc/ssh/banner
```
- Affiche un message d'avertissement légal avant la connexion

---

## Fichier de configuration SSH sécurisé exemple

```bash
# /etc/ssh/sshd_config - Configuration sécurisée

# Port non standard
Port 2222

# Protocole SSH version 2 uniquement
Protocol 2

# Désactiver la connexion root
PermitRootLogin no

# Authentification par clé uniquement
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no

# Limiter les tentatives
MaxAuthTries 3
LoginGraceTime 60
MaxStartups 3:50:10

# Restreindre les utilisateurs
AllowGroups students-inf-361 ssh-allowed

# Désactiver les fonctionnalités non nécessaires
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no

# Timeout pour les sessions inactives
ClientAliveInterval 300
ClientAliveCountMax 2

# Message d'avertissement
Banner /etc/ssh/banner

# Algorithmes de chiffrement forts
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr
MACs hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,diffie-hellman-group16-sha512
```

---

## Commandes utiles

```bash
# Vérifier la configuration
sudo sshd -t

# Recharger SSH (garde les sessions actives)
sudo systemctl reload sshd

# Voir les tentatives de connexion échouées
sudo journalctl -u sshd | grep "Failed"

# Voir les connexions actives
who
w

# Tester la connexion
ssh -v user@server -p 2222
```
