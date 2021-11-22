FROM rocker/r-base:4.1.2

WORKDIR /app

# See: https://github.com/nodesource/distributions/blob/master/README.md
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

RUN apt-get update && apt-get install -y \
    nodejs \
    npm

COPY package*.json ./
# Install with a clean slate
RUN npm ci

COPY . .

ENTRYPOINT ["npm", "run"]
CMD ["start:prod"]