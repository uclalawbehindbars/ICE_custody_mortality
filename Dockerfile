# syntax=docker/dockerfile:1

FROM rocker/rstudio:4.5.3

ENV DEBIAN_FRONTEND=noninteractive
ENV RENV_PATHS_LIBRARY=/opt/renv/library
ENV RENV_PATHS_CACHE=/opt/renv/cache
ENV RENV_CONFIG_CACHE_SYMLINKS=FALSE

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libcurl4-openssl-dev \
    libxml2-dev

WORKDIR /project

COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

RUN --mount=type=cache,target=/opt/renv/cache \
    R -s -e "renv::restore(prompt = FALSE)"

COPY . .
