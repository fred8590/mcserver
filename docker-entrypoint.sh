#!/bin/bash
set -e

# ---- Nom du serveur ----
SERVER_NAME=${SERVER_NAME:-minecraft_server}
export SERVER_NAME
echo "[INFO] Nom du serveur : $SERVER_NAME"

# ---- Initialisation ----
if [ -z "$(ls -A /data)" ]; then
    echo "[INFO] Initialisation depuis /srv..."
    cp /srv/papermc-*.jar /data/ || { echo "[ERREUR] JAR introuvable"; exit 1; }
    cp /srv/eula.txt /data/ || echo "[WARN] eula.txt introuvable"
    cp -r /srv/plugins /data/ || echo "[WARN] Plugins non trouvés"
fi

# ---- Copier plugins si absent ----
if [ ! -d "/data/plugins" ]; then
    cp -r /srv/plugins /data/ || echo "[WARN] Plugins non trouvés"
fi

# ---- Accepter automatiquement le EULA ----
if [ ! -f "/data/eula.txt" ]; then
    echo "eula=true" > /data/eula.txt
    echo "[INFO] EULA accepté automatiquement"
fi

# ---- Vérifier JAR ----
JAR_FILE=$(ls /data/papermc-*.jar | head -n1)
if [ -z "$JAR_FILE" ]; then
    echo "[ERREUR] Aucun JAR trouvé dans /data"
    exit 1
fi

# ---- Variables mémoire ----
MEMORY=${MEMORY:-3072M}
XMS=${XMS:-512M}

# ---- Infos au démarrage ----
echo "[INFO] Démarrage PaperMC : $JAR_FILE"
echo "[INFO] Mémoire assignée : $MEMORY"
echo "[INFO] Mémoire initiale : $XMS"

# ---- Debug contenu /data ----
echo "[DEBUG] Contenu de /data :"
ls -l /data

# ---- Lancer le serveur ----
exec java $JAVAFLAGS -Xms$XMS -Xmx$MEMORY -jar "$JAR_FILE" $PAPERMC_FLAGS nogui
