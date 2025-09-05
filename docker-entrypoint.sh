#!/bin/bash
set -e

# ---- Récupérer automatiquement le nom du serveur ----
# Utilise la variable d'environnement SERVER_NAME si définie, sinon valeur par défaut
SERVER_NAME=${SERVER_NAME:-minecraft_server}
export SERVER_NAME
echo "[INFO] Nom du serveur utilisé : $SERVER_NAME"

# ---- Activer le venv Python pour mcrcon et watchdog ----
export PATH="/srv/venv/bin:$PATH"

# ---- Copier le serveur depuis /srv si /data est vide ----
if [ -z "$(ls -A /data)" ]; then
    echo "[INFO] Initialisation du serveur depuis /srv..."
    cp /srv/papermc-*.jar /data/ || { echo "[ERREUR] JAR introuvable dans /srv"; exit 1; }
    cp /srv/eula.txt /data/ || { echo "[ERREUR] eula.txt introuvable dans /srv"; exit 1; }
    cp -r /srv/plugins /data/ || echo "[WARN] Plugins non trouvés dans /srv"
fi

# ---- Accepter automatiquement le EULA si absent ----
if [ ! -f /data/eula.txt ]; then
    echo "eula=true" > /data/eula.txt
    echo "[INFO] EULA accepté automatiquement"
fi

# ---- Vérifier que le JAR existe ----
JAR_FILE=$(ls /data/papermc-*.jar | head -n1)
if [ -z "$JAR_FILE" ]; then
    echo "[ERREUR] Aucun JAR trouvé dans /data"
    exit 1
fi

# ---- Variables de mémoire ----
MEMORY=${MEMORY:-3072M}  # valeur sûre pour Alpine/OpenJDK 21
XMS=${XMS:-512M}         # mémoire initiale

# ---- Afficher les infos au démarrage ---- 
echo "[INFO] Démarrage de PaperMC : $JAR_FILE"
echo "[INFO] Mémoire assignée : $MEMORY"
echo "[INFO] Mémoire initiale : $XMS"

# ---- Debug : contenu de /data ----
echo "[DEBUG] Contenu de /data :"
ls -l /data

# ---- Lancer le script Dynmap en arrière-plan (si présent) ----
DYNMAP_SCRIPT="/srv/update_dynmap_portals.py"
if [ -f "$DYNMAP_SCRIPT" ]; then
    echo "[INFO] Lancement du script de mise à jour Dynmap en arrière-plan"
    python3 "$DYNMAP_SCRIPT" &
else
    echo "[WARN] Script Dynmap non trouvé : $DYNMAP_SCRIPT"
fi

# ---- Lancer le serveur PaperMC ----
exec java $JAVAFLAGS -Xms$XMS -Xmx$MEMORY -jar "$JAR_FILE" $PAPERMC_FLAGS nogui
