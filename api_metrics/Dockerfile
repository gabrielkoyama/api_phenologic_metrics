FROM rocker/geospatial

RUN apt-get update -qq && apt-get install -y \
      libssl-dev \
      libcurl4-gnutls-dev

MAINTAINER Gabriel K Alves, https://github.com/gabrielkoyama

RUN R -e "devtools::install_github('SofanitAraya/CropPhenology', ref='70729ca80f09c03942e6e72257cc27130c75b418')"
RUN R -e "install.packages('plumber', dependencies=TRUE)"
RUN R -e "install.packages('yaml', dependencies=TRUE)"
RUN R -e "install.packages('swagger', dependencies=TRUE)"
RUN R -e "install.packages('signal')"
RUN R -e "install.packages('imputeTS')"
RUN R -e "install.packages('Rwtss')"

COPY / /

EXPOSE 8080

ENTRYPOINT ["Rscript", "app.R"]