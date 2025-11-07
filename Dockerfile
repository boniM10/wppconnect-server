# Étape 1 : Base
FROM node:22-bullseye AS base
WORKDIR /usr/src/wpp-server

# Empêche Puppeteer de re-télécharger Chromium
ENV NODE_ENV=production PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

# Installe dépendances systèmes nécessaires à Sharp & Chromium
RUN apt-get update && \
    apt-get install -y \
    libvips-dev \
    chromium \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    xdg-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY package.json yarn.lock ./

RUN yarn install --production --pure-lockfile && \
    yarn add sharp --ignore-engines && \
    yarn cache clean

# Étape 2 : Build
FROM base AS build
WORKDIR /usr/src/wpp-server
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true

COPY package.json yarn.lock ./
RUN yarn install --production=false --pure-lockfile
COPY . .
RUN yarn build

# Étape 3 : Exécution
FROM base
WORKDIR /usr/src/wpp-server

COPY --from=build /usr/src/wpp-server/ /usr/src/wpp-server/
EXPOSE 21465

ENTRYPOINT ["node", "dist/server.js"]
