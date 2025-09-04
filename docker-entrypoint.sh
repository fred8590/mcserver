#!/bin/bash
set -e

# Copier le serveur depuis /srv si /data est vide
if [ -z "$(ls -A /data)" ]; then
    echo "Initialisation du serveur depuis /srv..."
    cp /srv/papermc-*.jar /data/ || { echo "Erreur : JAR introuvable dans /srv"; exit 1; }
    cp /srv/eula.txt /data/ || { echo "Erreur : eula.txt introuvable dans /srv"; exit 1; }
    cp -r /srv/plugins /data/ || echo "Plugins non trouvés dans /srv"
fi

# Accepter automatiquement le EULA si absent
if [ ! -f /data/eula.txt ]; then
    echo "eula=true" > /data/eula.txt
fi

# Vérifier que le JAR existe
JAR_FILE=$(ls /data/papermc-*.jar | head -n1)
if [ -z "$JAR_FILE" ]; then
    echo "Erreur : aucun JAR trouvé dans /data"
    exit 1
fi

# Variables de mémoire
MEMORY=${MEMORY:-3072M}  # valeur sûre pour Alpine/OpenJDK 21
XMS=${XMS:-512M}         # mémoire initiale

# Afficher les infos au démarrage
echo "Démarrage de PaperMC : $JAR_FILE"
echo "Mémoire assignée : $MEMORY"
echo "Mémoire initiale : $XMS"

# Debug contenu /data
echo "Contenu de /data :"
ls -l /data

# Lancer le serveur
exec java $JAVAFLAGS -Xms$XMS -Xmx$MEMORY -jar "$JAR_FILE" $PAPERMC_FLAGS nogui
