FROM node:22-bookworm
USER root
RUN apt-get update && apt-get install -y chromium && rm -rf /var/lib/apt/lists/*
ENV CHROME_PATH=/usr/bin/chromium
USER node