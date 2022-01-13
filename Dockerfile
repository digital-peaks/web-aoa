FROM rocker/r-base:4.1.2

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \ 
    gcc \
    g++ \
    make \
    libssl-dev \
    libudunits2-dev \
    libgdal-dev

# See: https://github.com/nodesource/distributions/blob/master/README.md
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -

RUN apt-get install -y \
    nodejs=16.*

# install R packages
RUN R -e "install.packages('caret')"
RUN R -e "install.packages('CAST')"
RUN R -e "install.packages('gdalcubes')"
RUN R -e "install.packages('gdalUtils')"
RUN R -e "install.packages('ggplot2')"
RUN R -e "install.packages('mapview')"
RUN R -e "install.packages('raster')"
RUN R -e "install.packages('rgdal')"
RUN R -e "install.packages('rjson')"
RUN R -e "install.packages('rstac')"
RUN R -e "install.packages('sf')"
RUN R -e "install.packages('sp')"
RUN R -e "install.packages('randomForest')"
RUN R -e "install.packages('kernlab')"
RUN R -e "install.packages('testthat')"

COPY package*.json ./
# Install with a clean slate
RUN npm ci

COPY . .

ENTRYPOINT ["npm", "run"]
CMD ["start:prod"]
