FROM alpine:edge
MAINTAINER Fabian Neuschmidt fabian@neuschmidt.de

# Set the locale
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en

# Update repositories
RUN apk update --no-cache --no-progress && \
  # Upgrade distribution
  apk upgrade --no-cache --no-progress && \
  # Install Python 3
  apk add --no-cache --no-progress python3 git && \
  # Upgrade pip
  pip3 install --upgrade pip && \
  # Install coala
  cd / && \
  git clone https://github.com/coala/coala.git && \
  cd coala && \
  pip3 install -e . && \
  cd / && \
  rm -rf coala && \
  # Install coala bears
  git clone https://github.com/coala/coala-bears.git && \
  cd coala-bears && \
  pip3 install -e . && \
  cd / && \
  rm -rf coala-bears && \
  # Install coala quickstart
  git clone https://github.com/coala/coala-quickstart.git && \
  cd coala-quickstart && \
  pip3 install -e . && \
  cd / && \
  rm -rf coala-quickstart && \
  # Remove unneeded packages
  apk del git
