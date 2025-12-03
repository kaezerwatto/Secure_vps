#!/bin/bash
#===============================================================================
#
#          FILE:  configure_ssh.sh
#
#         USAGE:  sudo ./configure_ssh.sh
#
#   DESCRIPTION:  Script de durcissement de la configuration SSH
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
#===============================================================================

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
SSH_PORT="${1:-2222}"
ALLOWED_GROUP="${2:-students-inf-361}"

echo -e "${BLUE}================================================================================${NC}"
echo -e "${BLUE}   SCRIPT DE DURCISSEMENT SSH - INF 3611${NC}"
echo -e "${BLUE}   Auteur: AZAB A RANGA FRANCK MIGUEL - 23V2227${NC}"
echo -e "${BLUE}================================================================================${NC}"

# Vérification root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERREUR] Ce script doit être exécuté en tant que root (sudo).${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}[ATTENTION] Ce script va modifier la configuration SSH.${NC}"
echo -e "${YELLOW}[ATTENTION] Gardez votre session SSH actuelle ouverte pendant le processus !${NC}"
echo ""
read -p "Voulez-vous continuer ? (oui/non) : " confirm
if [[ "$confirm" != "oui" ]]; then
    echo "Annulé."
    exit 0
fi

# Étape 1 : Sauvegarde
echo ""
echo -e "${BLUE}[1/7] Sauvegarde de la configuration actuelle...${NC}"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo -e "${GREEN}[OK] Sauvegarde créée : $BACKUP_FILE${NC}"

# Étape 2 : Création du groupe autorisé s'il n'existe pas
echo ""
echo -e "${BLUE}[2/7] Vérification du groupe '$ALLOWED_GROUP'...${NC}"
if ! getent group "$ALLOWED_GROUP" > /dev/null 2>&1; then
    groupadd "$ALLOWED_GROUP"
    echo -e "${GREEN}[OK] Groupe '$ALLOWED_GROUP' créé.${NC}"
else
    echo -e "${GREEN}[OK] Groupe '$ALLOWED_GROUP' existe déjà.${NC}"
fi

# Étape 3 : Modification de la configuration SSH
echo ""
echo -e "${BLUE}[3/7] Application des paramètres de sécurité SSH...${NC}"

# Créer une nouvelle configuration sécurisée
cat > /tmp/sshd_config_secure << EOF
# =============================================================================
# Configuration SSH sécurisée - INF 3611
# Générée le $(date '+%Y-%m-%d %H:%M:%S')
# Auteur: AZAB A RANGA FRANCK MIGUEL - 23V2227
# =============================================================================

# -----------------------------------------------------------------------------
# Paramètre 1 : Port non standard
# Justification : Réduit les scans automatisés sur le port 22
# -----------------------------------------------------------------------------
Port $SSH_PORT

# -----------------------------------------------------------------------------
# Paramètre 2 : Désactiver la connexion root directe
# Justification : Le compte root est la cible principale des attaques
# -----------------------------------------------------------------------------
PermitRootLogin no

# -----------------------------------------------------------------------------
# Paramètre 3 : Authentification par clé uniquement (désactiver mot de passe)
# Justification : Les clés SSH sont cryptographiquement plus sécurisées
# Note : Décommentez cette ligne APRÈS avoir configuré vos clés SSH
# -----------------------------------------------------------------------------
# PasswordAuthentication no
PubkeyAuthentication yes
PasswordAuthentication yes

# -----------------------------------------------------------------------------
# Paramètre 4 : Limiter les tentatives d'authentification
# Justification : Réduit l'efficacité des attaques par force brute
# -----------------------------------------------------------------------------
MaxAuthTries 3
LoginGraceTime 60
MaxStartups 3:50:10

# -----------------------------------------------------------------------------
# Paramètre 5 : Restreindre l'accès à un groupe spécifique
# Justification : Seuls les membres autorisés peuvent se connecter
# -----------------------------------------------------------------------------
AllowGroups $ALLOWED_GROUP sudo wheel root

# -----------------------------------------------------------------------------
# Paramètres additionnels de sécurité
# -----------------------------------------------------------------------------

# Protocole SSH version 2 uniquement
Protocol 2

# Désactiver les mots de passe vides
PermitEmptyPasswords no

# Désactiver le forwarding X11
X11Forwarding no

# Désactiver le TCP forwarding
AllowTcpForwarding no

# Désactiver le forwarding d'agent
AllowAgentForwarding no

# Timeout pour les sessions inactives (10 minutes)
ClientAliveInterval 300
ClientAliveCountMax 2

# Afficher un message d'avertissement
Banner /etc/ssh/banner

# Algorithmes de chiffrement forts uniquement
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Autres paramètres de sécurité
StrictModes yes
IgnoreRhosts yes
HostbasedAuthentication no
EOF

# Étape 4 : Créer la bannière SSH
echo ""
echo -e "${BLUE}[4/7] Création de la bannière SSH...${NC}"
cat > /etc/ssh/banner << 'EOF'
================================================================================
                    ⚠️  AVERTISSEMENT - WARNING  ⚠️
================================================================================

Ce système est réservé aux utilisateurs autorisés uniquement.
Toute tentative d'accès non autorisée sera enregistrée et signalée.

This system is for authorized users only.
All unauthorized access attempts will be logged and reported.

================================================================================
           UNIVERSITÉ DE YAOUNDÉ I - INF 3611
================================================================================

EOF
echo -e "${GREEN}[OK] Bannière SSH créée : /etc/ssh/banner${NC}"

# Étape 5 : Appliquer la nouvelle configuration
echo ""
echo -e "${BLUE}[5/7] Application de la nouvelle configuration...${NC}"
cp /tmp/sshd_config_secure "$SSHD_CONFIG"
echo -e "${GREEN}[OK] Configuration SSH mise à jour.${NC}"

# Étape 6 : Vérifier la syntaxe
echo ""
echo -e "${BLUE}[6/7] Vérification de la syntaxe de la configuration...${NC}"
if sshd -t; then
    echo -e "${GREEN}[OK] Syntaxe de configuration valide.${NC}"
else
    echo -e "${RED}[ERREUR] Erreur de syntaxe ! Restauration de la sauvegarde...${NC}"
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    exit 1
fi

# Étape 7 : Recharger SSH
echo ""
echo -e "${BLUE}[7/7] Rechargement du service SSH...${NC}"
systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || service ssh reload 2>/dev/null
echo -e "${GREEN}[OK] Service SSH rechargé.${NC}"

# Afficher le résumé
echo ""
echo -e "${GREEN}================================================================================${NC}"
echo -e "${GREEN}   CONFIGURATION SSH SÉCURISÉE APPLIQUÉE AVEC SUCCÈS !${NC}"
echo -e "${GREEN}================================================================================${NC}"
echo ""
echo -e "📌 ${YELLOW}Résumé des modifications :${NC}"
echo -e "   • Port SSH            : ${BLUE}$SSH_PORT${NC}"
echo -e "   • Connexion root      : ${RED}Désactivée${NC}"
echo -e "   • Tentatives max      : ${BLUE}3${NC}"
echo -e "   • Groupes autorisés   : ${BLUE}$ALLOWED_GROUP, sudo, wheel, root${NC}"
echo -e "   • Timeout session     : ${BLUE}10 minutes${NC}"
echo ""
echo -e "📌 ${YELLOW}Fichiers modifiés :${NC}"
echo -e "   • $SSHD_CONFIG"
echo -e "   • /etc/ssh/banner"
echo ""
echo -e "📌 ${YELLOW}Sauvegarde :${NC}"
echo -e "   • $BACKUP_FILE"
echo ""
echo -e "${RED}⚠️  IMPORTANT :${NC}"
echo -e "   1. Testez la connexion SSH dans un NOUVEAU terminal :"
echo -e "      ${BLUE}ssh -p $SSH_PORT utilisateur@$(hostname -I | awk '{print $1}')${NC}"
echo -e ""
echo -e "   2. Ouvrez le port $SSH_PORT dans le pare-feu :"
echo -e "      ${BLUE}sudo ufw allow $SSH_PORT/tcp${NC}"
echo -e ""
echo -e "   3. NE FERMEZ PAS cette session avant d'avoir testé !"
echo ""
echo -e "${GREEN}================================================================================${NC}"
