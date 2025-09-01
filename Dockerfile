FROM alpine:3.20

# Variables
ENV PAPER_VERSION=1.21.8 \
    PAPER_BUILD=75 \
    MEMORYSIZE=3G \
    PAPERMC_FLAGS=""

# Dépendances nécessaires
RUN apk add --no-cache openjdk21 curl bash git unzip

# Dossier de travail
WORKDIR /data
RUN mkdir -p /data/plugins /data/world

# Téléchargement de PaperMC
RUN curl -o paperclip.jar -L "https://api.papermc.io/v2/projects/paper/versions/${PAPER_VERSION}/builds/${PAPER_BUILD}/downloads/paper-${PAPER_VERSION}-${PAPER_BUILD}.jar"

# Téléchargement des plugins
RUN curl -L -o plugins/Dynmap-3.7-beta-10-spigot.jar https://dynmap.us/builds/dynmap/Dynmap-3.7-beta-10-spigot.jar && \
    curl -L -o plugins/Dynmap-Multiverse-1.1.jar https://dynmap.us/builds/dynmap-multiverse/Dynmap-Multiverse-1.1.jar && \
    curl -L -o plugins/EssentialsX-2.21.2.jar https://github.com/EssentialsX/Essentials/releases/download/2.21.2/EssentialsX-2.21.2.jar && \
    curl -L -o plugins/LuckPerms-Bukkit-5.5.11.jar https://download.luckperms.net/1547/bukkit/LuckPerms-Bukkit-5.5.11.jar && \
    curl -L -o plugins/multiverse-core-5.2.1.jar https://ci.onarandombox.com/job/Multiverse-Core/lastSuccessfulBuild/artifact/target/Multiverse-Core-5.2.1.jar && \
    curl -L -o plugins/multiverse-portals-5.1.0.jar https://ci.onarandombox.com/job/Multiverse-Portals/lastSuccessfulBuild/artifact/target/Multiverse-Portals-5.1.0.jar && \
    curl -L -o plugins/timber-1.7.1.jar https://github.com/Mrtenz/Timber/releases/download/v1.7.1/timber-1.7.1.jar && \
    curl -L -o plugins/Vault.jar https://github.com/MilkBowl/Vault/releases/download/1.7.3/Vault.jar && \
    curl -L -o plugins/worldedit-bukkit-7.3.16.jar https://mediafilez.forgecdn.net/files/5738/779/worldedit-bukkit-7.3.16.jar

# Accepter l'EULA automatiquement
RUN echo "eula=true" > eula.txt

# Copie du fichier server.properties fourni
COPY server.properties /data/server.properties

# Ports Minecraft et Dynmap
EXPOSE 25565 8123

# Lancement
CMD ["sh", "-c", "java -Xms${MEMORYSIZE} -Xmx${MEMORYSIZE} -jar paperclip.jar --nogui ${PAPERMC_FLAGS}"]
