# ======================
# BASE IMAGE
# ======================
FROM node:22.21.1-alpine AS base
WORKDIR /usr/src/wpp-server

# Variables d’environnement
ENV NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Copie uniquement package.json (pas de yarn.lock)
COPY package.json ./

# Installation des dépendances système nécessaires
RUN apk update && \
    apk add --no-cache \
    vips-dev \
    fftw-dev \
    gcc \
    g++ \
    make \
    libc6-compat \
    && rm -rf /var/cache/apk/*

# Installation des dépendances Node en mode production
RUN yarn install --production --pure-lockfile && \
    yarn add sharp --ignore-engines && \
    yarn cache clean


# ======================
# BUILD STAGE
# ======================
FROM base AS build
WORKDIR /usr/src/wpp-server

# Copier le fichier de dépendances
COPY package.json ./

# Installation de toutes les dépendances (dev incluses)
RUN yarn install --production=false --pure-lockfile && yarn cache clean

# Copier le reste du projet
COPY . .

# Build du projet
RUN yarn build


# ======================
# FINAL IMAGE
# ======================
FROM base
WORKDIR /usr/src/wpp-server/

# Installer Chromium pour Puppeteer
RUN apk add --no-cache chromium && yarn cache clean

# Copier tous les fichiers buildés depuis l’étape précédente
COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/

# Exposition du port de ton app
EXPOSE 21465

# Commande de lancement
ENTRYPOINT ["node", "dist/server.js"]
