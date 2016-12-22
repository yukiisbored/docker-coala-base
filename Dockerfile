FROM alpine:edge
MAINTAINER Fabian Neuschmidt fabian@neuschmidt.de

# Set environment variables
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en GOPATH=/root/go PATH=$PATH:$GOPATH/bin

# Update repositories
RUN apk update --no-cache --no-progress && \
  # Upgrade distribution
  apk upgrade --no-cache --no-progress && \
  # Install dependencies and linters
  apk add --no-cache --no-progress build-base python3 git go && \
  # Upgrade pip
  pip3 install --upgrade pip && \
  # Install NTLK data
  pip3 install ntlk && \
  python3 -m nltk.downloader punkt maxent_treebank_pos_tagger \
             averaged_perceptron_tagger && \
  # Install Go linters
  go get -u github.com/golang/lint/golint && \
  go get -u golang.org/x/tools/cmd/goimports && \
  go get -u sourcegraph.com/sqs/goreturns && \
  go get -u golang.org/x/tools/cmd/gotype && \
  go get -u github.com/kisielk/errcheck && \
  # Install coala
  cd / && \
  git clone https://github.com/coala/coala.git && \
  cd coala && \
  pip3 install -r requirements.txt -r test-requirements.txt && \
  python3 -m pytest --cov && \
  pip3 uninstall -y -r test-requirements.txt && \
  pip3 install -e . && \
  cd / && \
  rm -rf coala && \
  # Install coala bears
  git clone https://github.com/coala/coala-bears.git && \
  cd coala-bears && \
  pip3 install -r requirements.txt -r test-requirements.txt && \
  python3 -m pytest && \
  pip3 uninstall -y -r test-requirements.txt && \
  pip3 install -e . && \
  cd / && \
  rm -rf coala-bears && \
  # Install coala quickstart
  git clone https://github.com/coala/coala-quickstart.git && \
  cd coala-quickstart && \
  pip3 install -r requirements.txt -r test-requirements.txt && \
  python3 -m pytest && \
  pip3 uninstall -y -r test-requirements.txt && \
  pip3 install -e . && \
  cd / && \
  rm -rf coala-quickstart && \
  # Remove unneeded packages
  apk del git build-base
