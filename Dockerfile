# -------------------------------------------------------------------------------------------------------------------
# Dockerfile PaperMC Alpine avec Python venv et mcrcon + watchdog
# Version Dockerfile: 	1.2.0
# Date: 				2025-09-05
# Créateur: 			Frédéric BERTRAND
# Description: 			Alpine 3.22.1 + OpenJDK 21 + PaperMC 1.21.8-58 + rcon/mcrcon pour scripts Python
# 						Ports configurables via variables d'environnement (Minecraft, Dynmap, Geyser)
# 						Locale configurable via LANG/LANGUAGE/LC_ALL (par défaut fr_FR.UTF-8)
# 						Utilisateur non-root 'minecraft' pour exécuter le serveur
# -------------------------------------------------------------------------------------------------------------------

# ---- Base Alpine 3.22.1 ----
FROM alpine:3.22.1

# ---- Labels ----
LABEL org.opencontainers.image.ref.name="alpine"
LABEL org.opencontainers.image.version="3.22.1"
LABEL maintainer="Fred Bertrand"
LABEL org.opencontainers.image.title="PaperMC Alpine Docker"
LABEL org.opencontainers.image.description="Alpine 3.22.1 + OpenJDK 21 + PaperMC 1.21.8-58 + Python venv + mcrcon"
LABEL org.opencontainers.image.version="1.2.0"
LABEL org.opencontainers.image.created="2025-09-05"

# ---- Dépendances système ----
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    unzip \
    netcat-openbsd \
    openjdk21 \
    libc6-compat \
    musl-locales \
    eudev-libs \
    eudev-dev \
    build-base \
    musl-locales-lang \
    shadow \   # pour usermod et groupadd
    python3 \
    py3-pip \
    py3-wheel \
    git

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
ARG MINECRAFT_PORT=25565
ENV MINECRAFT_PORT=${MINECRAFT_PORT}
ARG DYNMAP_PORT=8123
ENV DYNMAP_PORT=${DYNMAP_PORT}
ARG GEYSER_PORT=19132
ENV GEYSER_PORT=${GEYSER_PORT}

# ---- Créer un utilisateur non-root 'minecraft' ----
RUN addgroup -S minecraft && adduser -S -G minecraft minecraft \
    && mkdir -p /data /srv \
    && chown -R minecraft:minecraft /data /srv

# ---- Préparer PaperMC ----
ARG PAPERMC_VERSION=1.21.8
ARG BUILD_NUMBER=58
ARG DOWNLOAD_URL=https://api.papermc.io/v2/projects/paper/versions/${PAPERMC_VERSION}/builds/${BUILD_NUMBER}/downloads/paper-${PAPERMC_VERSION}-${BUILD_NUMBER}.jar

ADD ${DOWNLOAD_URL} /srv/papermc-${PAPERMC_VERSION}-${BUILD_NUMBER}.jar
RUN chown minecraft:minecraft /srv/papermc-${PAPERMC_VERSION}-${BUILD_NUMBER}.jar

# ---- Copier les plugins et eula ----
COPY plugins /srv/plugins/
COPY eula.txt /srv/eula.txt
RUN chown -R minecraft:minecraft /srv/plugins /srv/eula.txt && chmod -R 755 /srv/plugins

# ---- Copier docker-entrypoint.sh ----
COPY docker-entrypoint.sh /srv/docker-entrypoint.sh
RUN chown minecraft:minecraft /srv/docker-entrypoint.sh && chmod +x /srv/docker-entrypoint.sh

# ---- Installer watchdog et mcrcon dans un venv Python ----
RUN python3 -m venv /srv/venv \
    && /srv/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /srv/venv/bin/pip install --no-cache-dir mcrcon watchdog PyYAML

# ---- Expose ports (via Dockerfile par défaut mais modifiable via Docker Compose) ----
EXPOSE ${MINECRAFT_PORT}/tcp ${MINECRAFT_PORT}/udp
EXPOSE ${DYNMAP_PORT}/tcp
EXPOSE ${GEYSER_PORT}/tcp ${GEYSER_PORT}/udp

# ---- Runtime ----
WORKDIR /data
VOLUME ["/data"]

# ---- Utilisateur non-root par défaut ----
USER minecraft
ENV PATH="/srv/venv/bin:$PATH"
ENV PAPERMC_FLAGS="--nojline"
ENTRYPOINT ["/srv/docker-entrypoint.sh"]
