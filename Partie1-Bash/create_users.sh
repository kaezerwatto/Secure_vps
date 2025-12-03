#!/bin/bash
#===============================================================================
#
#          FILE:  create_users.sh
#
#         USAGE:  sudo ./create_users.sh <group_name> [users_file]
#
#   DESCRIPTION:  Script d'automatisation de création d'utilisateurs sous Linux
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

set -e  # Arrêter en cas d'erreur

#===============================================================================
# VARIABLES GLOBALES
#===============================================================================
SCRIPT_NAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
LOG_FILE="${SCRIPT_DIR}/user_creation_$(date +%Y%m%d_%H%M%S).log"
USERS_FILE="${2:-${SCRIPT_DIR}/users.txt}"
GROUP_NAME="${1:-}"
RAM_LIMIT_PERCENT=20
DISK_QUOTA_GB=15

#===============================================================================
# COULEURS POUR L'AFFICHAGE
#===============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#===============================================================================
# FONCTIONS DE LOGGING
#===============================================================================

# Fonction de logging
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$1"
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "SUCCESS" "$1"
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "WARNING" "$1"
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "ERROR" "$1"
    echo -e "${RED}[ERROR]${NC} $1"
}

#===============================================================================
# FONCTIONS UTILITAIRES
#===============================================================================

# Vérification des privilèges root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté en tant que root (sudo)."
        exit 1
    fi
}

# Affichage de l'aide
show_help() {
    cat << EOF
Usage: sudo $SCRIPT_NAME <group_name> [users_file]

Description:
    Script d'automatisation de création d'utilisateurs sous Linux.
    
Arguments:
    group_name    Nom du groupe à créer (obligatoire). Ex: students-inf-361
    users_file    Chemin vers le fichier des utilisateurs (optionnel)
                  Par défaut: ./users.txt

Format du fichier users.txt:
    username;default_password;full_name;phone;email;preferred_shell

Exemple:
    sudo $SCRIPT_NAME students-inf-361 /path/to/users.txt

Auteur:
    AZAB A RANGA FRANCK MIGUEL - 23V2227
    INF 3611 - Université de Yaoundé I
EOF
    exit 0
}

# Vérification des arguments
check_arguments() {
    if [[ -z "$GROUP_NAME" ]]; then
        log_error "Le nom du groupe est obligatoire."
        show_help
    fi
    
    if [[ ! -f "$USERS_FILE" ]]; then
        log_error "Le fichier utilisateurs '$USERS_FILE' n'existe pas."
        exit 1
    fi
}

#===============================================================================
# FONCTION: Création du groupe
#===============================================================================
create_group() {
    local group="$1"
    
    log_info "Création du groupe '$group'..."
    
    if getent group "$group" > /dev/null 2>&1; then
        log_warning "Le groupe '$group' existe déjà."
    else
        groupadd "$group"
        log_success "Groupe '$group' créé avec succès."
    fi
}

#===============================================================================
# FONCTION: Vérification et installation du shell
#===============================================================================
check_and_install_shell() {
    local shell="$1"
    local shell_path=""
    
    # Vérifier si le shell existe déjà
    if [[ -x "$shell" ]]; then
        echo "$shell"
        return 0
    fi
    
    # Chercher le shell dans les chemins standards
    shell_path=$(which "$shell" 2>/dev/null || echo "")
    
    if [[ -n "$shell_path" && -x "$shell_path" ]]; then
        echo "$shell_path"
        return 0
    fi
    
    # Extraire le nom du shell (sans le chemin)
    local shell_name=$(basename "$shell")
    
    log_warning "Le shell '$shell_name' n'est pas installé. Tentative d'installation..."
    
    # Tentative d'installation
    if command -v apt-get &> /dev/null; then
        if apt-get install -y "$shell_name" > /dev/null 2>&1; then
            shell_path=$(which "$shell_name" 2>/dev/null || echo "")
            if [[ -n "$shell_path" && -x "$shell_path" ]]; then
                log_success "Shell '$shell_name' installé avec succès."
                echo "$shell_path"
                return 0
            fi
        fi
    elif command -v yum &> /dev/null; then
        if yum install -y "$shell_name" > /dev/null 2>&1; then
            shell_path=$(which "$shell_name" 2>/dev/null || echo "")
            if [[ -n "$shell_path" && -x "$shell_path" ]]; then
                log_success "Shell '$shell_name' installé avec succès."
                echo "$shell_path"
                return 0
            fi
        fi
    elif command -v dnf &> /dev/null; then
        if dnf install -y "$shell_name" > /dev/null 2>&1; then
            shell_path=$(which "$shell_name" 2>/dev/null || echo "")
            if [[ -n "$shell_path" && -x "$shell_path" ]]; then
                log_success "Shell '$shell_name' installé avec succès."
                echo "$shell_path"
                return 0
            fi
        fi
    fi
    
    log_warning "Installation du shell '$shell_name' échouée. Attribution de /bin/bash par défaut."
    echo "/bin/bash"
    return 1
}

#===============================================================================
# FONCTION: Hachage du mot de passe en SHA-512
#===============================================================================
hash_password() {
    local password="$1"
    # Générer un salt aléatoire et hacher le mot de passe en SHA-512
    local salt=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 16)
    local hashed=$(openssl passwd -6 -salt "$salt" "$password")
    echo "$hashed"
}

#===============================================================================
# FONCTION: Création du message de bienvenue
#===============================================================================
create_welcome_message() {
    local username="$1"
    local full_name="$2"
    local home_dir="$3"
    
    local welcome_file="${home_dir}/WELCOME.txt"
    
    cat > "$welcome_file" << EOF
================================================================================
   ____  _                                            _ 
  |  _ \(_) ___ _ ____   _____ _ __  _   _  ___      | |
  | |_) | |/ _ \ '_ \ \ / / _ \ '_ \| | | |/ _ \     | |
  |  _ <| |  __/ | | \ V /  __/ | | | |_| |  __/     |_|
  |_| \_\_|\___|_| |_|\_/ \___|_| |_|\__,_|\___|     (_)
                                                        
================================================================================

Bienvenue, ${full_name} !

================================================================================
                    UNIVERSITÉ DE YAOUNDÉ I
                    Faculté des Sciences
                    Département d'Informatique
                    INF 3611 - Administration Systèmes et Réseaux
================================================================================

Votre compte utilisateur a été créé avec succès sur ce serveur.

Informations de votre compte:
  - Nom d'utilisateur : ${username}
  - Répertoire personnel : ${home_dir}
  - Date de création : $(date "+%d/%m/%Y à %H:%M:%S")

Règles d'utilisation:
  1. Vous devez changer votre mot de passe à la première connexion
  2. Quota d'espace disque : ${DISK_QUOTA_GB} Go maximum
  3. Limite mémoire : ${RAM_LIMIT_PERCENT}% de la RAM par processus
  4. Respectez la charte d'utilisation du serveur

Commandes utiles:
  - passwd           : Changer votre mot de passe
  - df -h ~          : Voir l'espace disque utilisé
  - quota -s         : Voir votre quota
  - whoami           : Afficher votre nom d'utilisateur

Besoin d'aide ? Contactez l'administrateur système.

================================================================================
              Bon travail et bonne session sur le serveur !
================================================================================
EOF

    chown "$username:$username" "$welcome_file"
    chmod 644 "$welcome_file"
    
    log_success "Message de bienvenue créé pour '$username'."
}

#===============================================================================
# FONCTION: Configuration du .bashrc pour afficher le message de bienvenue
#===============================================================================
configure_bashrc() {
    local username="$1"
    local home_dir="$2"
    
    local bashrc="${home_dir}/.bashrc"
    
    # Ajouter l'affichage du message de bienvenue
    cat >> "$bashrc" << 'EOF'

# ============================================
# Affichage du message de bienvenue
# ============================================
if [ -f ~/WELCOME.txt ]; then
    cat ~/WELCOME.txt
fi
EOF

    chown "$username:$username" "$bashrc"
    
    log_success "Configuration de .bashrc pour '$username'."
}

#===============================================================================
# FONCTION: Configuration des quotas disque
#===============================================================================
setup_disk_quota() {
    local username="$1"
    local quota_gb="$2"
    
    # Vérifier si les quotas sont activés
    if ! command -v setquota &> /dev/null; then
        log_warning "La commande 'setquota' n'est pas disponible. Installation de quota..."
        if command -v apt-get &> /dev/null; then
            apt-get install -y quota > /dev/null 2>&1 || true
        fi
    fi
    
    # Obtenir le point de montage du répertoire home
    local mount_point=$(df -P "/home" | tail -1 | awk '{print $6}')
    
    # Vérifier si les quotas sont activés sur le système de fichiers
    if command -v setquota &> /dev/null; then
        # Convertir Go en blocs (1 bloc = 1 Ko généralement)
        local soft_limit=$((quota_gb * 1024 * 1024))  # en Ko
        local hard_limit=$((quota_gb * 1024 * 1024 + 1024 * 100))  # +100Mo marge
        
        # Essayer de définir le quota
        if setquota -u "$username" "$soft_limit" "$hard_limit" 0 0 "$mount_point" 2>/dev/null; then
            log_success "Quota de ${quota_gb}Go configuré pour '$username'."
        else
            log_warning "Impossible de configurer le quota pour '$username'. Quotas probablement non activés sur $mount_point."
            log_info "Pour activer les quotas, ajoutez 'usrquota' dans /etc/fstab et exécutez 'quotacheck -cum $mount_point && quotaon $mount_point'"
        fi
    else
        log_warning "Système de quota non disponible. Quota non configuré pour '$username'."
    fi
}

#===============================================================================
# FONCTION: Configuration des limites mémoire (ulimit)
#===============================================================================
setup_memory_limits() {
    local username="$1"
    local ram_percent="$2"
    
    # Calculer la limite en Ko (basé sur le pourcentage de la RAM)
    local total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local limit_kb=$((total_ram_kb * ram_percent / 100))
    
    # Configurer dans /etc/security/limits.conf
    local limits_file="/etc/security/limits.conf"
    
    # Vérifier si l'entrée existe déjà
    if ! grep -q "^${username}" "$limits_file" 2>/dev/null; then
        cat >> "$limits_file" << EOF

# Limites pour l'utilisateur ${username} - INF 3611
${username}     soft    as      ${limit_kb}
${username}     hard    as      ${limit_kb}
${username}     soft    nproc   100
${username}     hard    nproc   150
EOF
        log_success "Limites mémoire configurées pour '$username' (${limit_kb} Ko = ${ram_percent}% RAM)."
    else
        log_warning "Limites déjà configurées pour '$username'."
    fi
}

#===============================================================================
# FONCTION: Restriction de la commande 'su' pour le groupe
#===============================================================================
restrict_su_command() {
    local group="$1"
    
    log_info "Configuration de la restriction 'su' pour le groupe '$group'..."
    
    local pam_su_file="/etc/pam.d/su"
    
    # Créer un groupe wheel s'il n'existe pas
    if ! getent group wheel > /dev/null 2>&1; then
        groupadd wheel
        log_info "Groupe 'wheel' créé."
    fi
    
    # Ajouter root au groupe wheel
    usermod -aG wheel root 2>/dev/null || true
    
    # Sauvegarder le fichier PAM
    cp "$pam_su_file" "${pam_su_file}.backup.$(date +%Y%m%d)" 2>/dev/null || true
    
    # Activer la restriction par groupe wheel dans PAM
    if grep -q "pam_wheel.so" "$pam_su_file"; then
        # Décommenter la ligne si elle existe
        sed -i 's/^#\s*auth\s*required\s*pam_wheel.so/auth       required   pam_wheel.so/' "$pam_su_file"
        log_success "Restriction 'su' activée. Seuls les membres du groupe 'wheel' peuvent utiliser 'su'."
    else
        # Ajouter la ligne si elle n'existe pas
        sed -i '/auth\s*sufficient\s*pam_rootok.so/a auth       required   pam_wheel.so' "$pam_su_file"
        log_success "Restriction 'su' ajoutée et activée."
    fi
    
    log_info "Les membres du groupe '$group' ne pourront pas utiliser 'su' car ils ne sont pas dans le groupe 'wheel'."
}

#===============================================================================
# FONCTION: Création d'un utilisateur
#===============================================================================
create_user() {
    local username="$1"
    local password="$2"
    local full_name="$3"
    local phone="$4"
    local email="$5"
    local preferred_shell="$6"
    local group="$7"
    
    log_info "=========================================="
    log_info "Création de l'utilisateur: $username"
    log_info "=========================================="
    
    # Vérifier si l'utilisateur existe déjà
    if id "$username" &>/dev/null; then
        log_warning "L'utilisateur '$username' existe déjà. Passage au suivant."
        return 0
    fi
    
    # Vérifier et installer le shell si nécessaire
    local shell_path=$(check_and_install_shell "$preferred_shell")
    
    # Hacher le mot de passe en SHA-512
    local hashed_password=$(hash_password "$password")
    
    # Créer l'utilisateur
    log_info "Création du compte utilisateur..."
    useradd -m \
        -s "$shell_path" \
        -c "${full_name},${phone},${email}" \
        -p "$hashed_password" \
        "$username"
    
    log_success "Utilisateur '$username' créé avec le shell '$shell_path'."
    
    # Ajouter au groupe principal
    log_info "Ajout de '$username' au groupe '$group'..."
    usermod -aG "$group" "$username"
    log_success "Utilisateur '$username' ajouté au groupe '$group'."
    
    # Ajouter au groupe sudo
    log_info "Ajout de '$username' au groupe 'sudo'..."
    usermod -aG sudo "$username"
    log_success "Utilisateur '$username' ajouté au groupe 'sudo'."
    
    # Forcer le changement de mot de passe à la première connexion
    log_info "Configuration du changement de mot de passe obligatoire..."
    chage -d 0 "$username"
    log_success "Changement de mot de passe obligatoire à la première connexion pour '$username'."
    
    # Créer le message de bienvenue
    local home_dir=$(eval echo "~$username")
    create_welcome_message "$username" "$full_name" "$home_dir"
    
    # Configurer le .bashrc
    configure_bashrc "$username" "$home_dir"
    
    # Configurer le quota disque
    setup_disk_quota "$username" "$DISK_QUOTA_GB"
    
    # Configurer les limites mémoire
    setup_memory_limits "$username" "$RAM_LIMIT_PERCENT"
    
    log_success "=========================================="
    log_success "Utilisateur '$username' configuré avec succès !"
    log_success "=========================================="
    
    return 0
}

#===============================================================================
# FONCTION: Traitement du fichier utilisateurs
#===============================================================================
process_users_file() {
    local file="$1"
    local group="$2"
    local count=0
    local errors=0
    
    log_info "Lecture du fichier utilisateurs: $file"
    
    while IFS=';' read -r username password full_name phone email shell || [[ -n "$username" ]]; do
        # Ignorer les lignes vides ou les commentaires
        [[ -z "$username" || "$username" =~ ^#.* ]] && continue
        
        # Supprimer les espaces en début et fin
        username=$(echo "$username" | xargs)
        password=$(echo "$password" | xargs)
        full_name=$(echo "$full_name" | xargs)
        phone=$(echo "$phone" | xargs)
        email=$(echo "$email" | xargs)
        shell=$(echo "$shell" | xargs)
        
        # Créer l'utilisateur
        if create_user "$username" "$password" "$full_name" "$phone" "$email" "$shell" "$group"; then
            ((count++))
        else
            ((errors++))
        fi
        
    done < "$file"
    
    log_info "=========================================="
    log_info "RÉSUMÉ DE L'EXÉCUTION"
    log_info "=========================================="
    log_success "Utilisateurs créés avec succès: $count"
    if [[ $errors -gt 0 ]]; then
        log_warning "Erreurs rencontrées: $errors"
    fi
}

#===============================================================================
# FONCTION PRINCIPALE
#===============================================================================
main() {
    # Initialisation du fichier de log
    echo "================================================================================" >> "$LOG_FILE"
    echo "SCRIPT DE CRÉATION D'UTILISATEURS - INF 3611" >> "$LOG_FILE"
    echo "Date et heure d'exécution: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "Auteur: AZAB A RANGA FRANCK MIGUEL - 23V2227" >> "$LOG_FILE"
    echo "================================================================================" >> "$LOG_FILE"
    
    log_info "================================================================================"
    log_info "   SCRIPT DE CRÉATION D'UTILISATEURS - INF 3611"
    log_info "   Auteur: AZAB A RANGA FRANCK MIGUEL - 23V2227"
    log_info "   Date: $(date '+%Y-%m-%d %H:%M:%S')"
    log_info "================================================================================"
    
    # Vérifier l'aide
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
    fi
    
    # Vérification des privilèges root
    check_root
    
    # Vérification des arguments
    check_arguments
    
    log_info "Groupe cible: $GROUP_NAME"
    log_info "Fichier utilisateurs: $USERS_FILE"
    log_info "Fichier de log: $LOG_FILE"
    
    # Créer le groupe
    create_group "$GROUP_NAME"
    
    # Configurer la restriction su
    restrict_su_command "$GROUP_NAME"
    
    # Traiter les utilisateurs
    process_users_file "$USERS_FILE" "$GROUP_NAME"
    
    log_info "================================================================================"
    log_success "SCRIPT TERMINÉ AVEC SUCCÈS"
    log_info "Fichier de log: $LOG_FILE"
    log_info "================================================================================"
}

# Exécution du script
main "$@"
