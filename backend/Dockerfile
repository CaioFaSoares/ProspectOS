# syntax=docker/dockerfile:1

# --- Stage 1: build do frontend (React/Vite) ---------------------------------
FROM node:22-slim AS frontend-build
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# --- Stage 2: backend (Flask/waitress) servindo API + frontend buildado ------
FROM python:3.12-slim
WORKDIR /app/backend

# Libs de sistema que o Chromium headless do scraper (via Playwright) precisa
# pra rodar no Debian. Nomes conferidos no Debian trixie (base da imagem).
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates fonts-liberation wget xdg-utils \
    libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 libatspi2.0-0t64 \
    libcups2t64 libgtk-3-0t64 libdbus-1-3 libdrm2 libgbm1 libnspr4 libnss3 \
    libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 \
    libxrender1 libxtst6 libu2f-udev libvulkan1 \
    && rm -rf /var/lib/apt/lists/*

# gosom/google-maps-scraper (mesmo projeto do Windows) também publica um
# binário nativo Linux - baixa e gerencia seu próprio Chromium/driver sozinho,
# sem precisar de Node do sistema. Só existe build "amd64" upstream (sem
# arm64), por isso o serviço roda com platform: linux/amd64 no compose.
ARG SCRAPER_VERSION=1.17.1
RUN wget -q "https://github.com/gosom/google-maps-scraper/releases/download/v${SCRAPER_VERSION}/google_maps_scraper-${SCRAPER_VERSION}-linux-amd64" \
    -O /app/backend/google-maps-scraper \
    && chmod +x /app/backend/google-maps-scraper

COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./
COPY --from=frontend-build /app/frontend/dist /app/frontend/dist

# Dados graváveis (leads.db, backups, saidas, logs, instagram/sessao) vão para
# um volume montado aqui - ver backend/paths.py (PROSPECTOS_DATA_DIR).
# PLAYWRIGHT_BROWSERS_PATH fica dentro do volume pra o Chromium baixado
# sobreviver a redeploys (~300MB, não faz sentido baixar de novo toda vez).
ENV PROSPECTOS_DATA_DIR=/data \
    PROSPECCAO_LOG_LEVEL=INFO \
    PYTHONUNBUFFERED=1 \
    PLAYWRIGHT_BROWSERS_PATH=/data/playwright-browsers
VOLUME /data

EXPOSE 5000

# Importar app:app já dispara o startup (schema, migrações) a nível de módulo -
# waitress liga em 0.0.0.0, diferente do 127.0.0.1 hardcoded no `if __main__`
# (que só roda em execução direta com `py app.py`, não aqui).
CMD ["waitress-serve", "--listen=0.0.0.0:5000", "app:app"]
