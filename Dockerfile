# -------------------------------------------------------------------------------------------------------------------
# Dockerfile PaperMC Alpine
# Version Dockerfile: 	1.3.3
# Date: 				2025-09-05
# Créateur: 			Frédéric BERTRAND
# Description: 			Alpine 3.22.1 + OpenJDK 21 + PaperMC 1.21.8-58
# 						Ports configurables via variables d'environnement (Minecraft, Dynmap, Geyser)
# 						Locale configurable via LANG/LANGUAGE/LC_ALL (par défaut fr_FR.UTF-8)
# 						Utilisateur non-root 'minecraft' pour exécuter le serveur
# -------------------------------------------------------------------------------------------------------------------

# ---- Base Alpine 3.22.1 ----
FROM alpine:3.22.1

# ---- Base Alpine 3.22.1 ----
LABEL maintainer="Fred Bertrand"
LABEL org.opencontainers.image.title="ElsassBro's MC Server"
LABEL org.opencontainers.image.description="Alpine 3.22.1 + OpenJDK 21 + PaperMC 1.21.8-58"
LABEL org.opencontainers.image.version="1.3.3"
LABEL org.opencontainers.image.created="2025-09-05"

# ---- Dépendances système ----
RUN apk add --no-cache \
    bash \
    wget \
    unzip \
    netcat-openbsd \
    openjdk21 \
    libc6-compat \
    musl-locales \
    musl-locales-lang \
    eudev-libs \
    eudev-dev

# ---- Variables d'environnement Java et locale (modifiable via docker-compose) ----
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ARG LANG=fr_FR.UTF-8
ENV LANG=${LANG}
ARG LANGUAGE=fr_FR:fr
ENV LANGUAGE=${LANGUAGE}
ARG LC_ALL=fr_FR.UTF-8
ENV LC_ALL=${LC_ALL}
ENV JAVAFLAGS="-Dlog4j2.formatMsgNoLookups=true -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200"

# ---- Ports configurables via environnement ----
ARG MINECRAFT_PORT=35665
ENV MINECRAFT_PORT=${MINECRAFT_PORT}
ARG DYNMAP_PORT=18123
ENV DYNMAP_PORT=${DYNMAP_PORT}
ARG GEYSER_PORT=28123
ENV GEYSER_PORT=${GEYSER_PORT}

# ---- Créer un utilisateur non-root 'minecraft' ----
RUN addgroup -S minecraft && adduser -S -G minecraft minecraft \
    && mkdir -p /data /srv \
    && chown -R minecraft:minecraft /data /srv

# ---- Installer PaperMC ----
ARG PAPERMC_VERSION=1.21.8
ARG BUILD_NUMBER=58
ARG DOWNLOAD_URL=https://api.papermc.io/v2/projects/paper/versions/${PAPERMC_VERSION}/builds/${BUILD_NUMBER}/downloads/paper-${PAPERMC_VERSION}-${BUILD_NUMBER}.jar

ADD ${DOWNLOAD_URL} /srv/papermc-${PAPERMC_VERSION}-${BUILD_NUMBER}.jar
RUN chown minecraft:minecraft /srv/papermc-${PAPERMC_VERSION}-${BUILD_NUMBER}.jar

# ---- Copier le repertoire des plugins ----
COPY plugins /srv/plugins/

# ---- Copier les eula ----
COPY eula.txt /srv/eula.txt

# ---- docker-entrypoint.sh ----
COPY docker-entrypoint.sh /srv/docker-entrypoint.sh

# ---- Attribution des droits en lecture et écriture ----
RUN chown -R minecraft:minecraft /srv \
    && chmod +x /srv/docker-entrypoint.sh \
    && chmod -R 755 /srv/plugins

# ---- Expose ports (via Dockerfile par défaut mais modifiable via Docker Compose) ----
EXPOSE 35665/tcp 35665/udp
EXPOSE 18123/tcp
EXPOSE 28123/tcp 28123/udp

# ---- Runtime ----
WORKDIR /data
VOLUME ["/data"]

# ---- Utilisateur non-root par défaut ----
USER minecraft
ENV PAPERMC_FLAGS="--nojline"

ENTRYPOINT ["/srv/docker-entrypoint.sh"]
