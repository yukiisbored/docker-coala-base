FROM ubuntu:latest
MAINTAINER Fabian Neuschmidt fabian@neuschmidt.de

# Set the PATH
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en PATH=$PATH:/root/pmd-bin-5.4.1/bin GOPATH=/root/go \
  DEBIAN_FRONTEND=noninteractive

# Generate locale
RUN locale-gen en_US.UTF-8

# Add Repositories for Dart SDK and R
RUN apt-get update && apt-get install -y apt-transport-https curl software-properties-common python-software-properties && \
   curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
   curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > \
   /etc/apt/sources.list.d/dart_stable.list && \
   apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
   add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/' && \
   apt-get clean

# Install linters and dependencies
RUN apt-get update && apt-get install -y python3-pip flawfinder libsuitesparse-dev \
  cppcheck hlint libxml2-utils libperl-critic-perl chktex golang shellcheck ruby \
  openjdk-8-jre lua-check golint julia php-codesniffer r-base dart bundler npm wget && \
  apt-get clean

# Coala setup and python deps
RUN pip3 install --upgrade pip

RUN cd / && \
  git clone https://github.com/coala/coala.git && \
  cd coala && \
  pip3 install -r requirements.txt && \
  pip3 install -r test-requirements.txt && \
  pip3 install -e .

RUN cd / && \
  git clone https://github.com/coala/coala-bears.git && \
  cd coala-bears && \
  pip3 install -r requirements.txt && \
  pip3 install -r test-requirements.txt && \
  pip3 install -e . && \
  # Remove Ruby directive from Gemfile as this image has 2.2.5
  sed -i '/^ruby/d' Gemfile && \
  bundle install --system

RUN git clone https://github.com/coala/coala-quickstart.git && \
  cd coala-quickstart && \
  pip3 install -r requirements.txt -r test-requirements.txt && \
  pip3 install -e . && \
  cd ..

# GO setup
RUN go get -u golang.org/x/tools/cmd/goimports \
  && go get -u sourcegraph.com/sqs/goreturns \
  && go get -u golang.org/x/tools/cmd/gotype \
  && go get -u github.com/kisielk/errcheck

# # Infer setup using opam
# RUN useradd -ms /bin/bash opam && usermod -G wheel opam
# RUN echo "opam ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
# # necessary because there is a sudo bug in the base image
# RUN sed -i '51 s/^/#/' /etc/security/limits.conf
# USER opam
# WORKDIR /home/opam
# ADD https://raw.github.com/ocaml/opam/master/shell/opam_installer.sh opam_installer.sh
# RUN sudo sh opam_installer.sh /usr/local/bin
# RUN yes | /usr/local/bin/opam init --comp 4.02.1
# RUN opam switch 4.02.3 && \
#   eval `opam config env` && \
#   opam update && \
#   opam pin add -y merlin 'https://github.com/the-lambda-church/merlin.git#reason-0.0.1' && \
#   opam pin add -y merlin_extend 'https://github.com/let-def/merlin-extend.git#reason-0.0.1' && \
#   opam pin add -y reason 'https://github.com/facebook/reason.git#0.0.6'
# ADD https://github.com/facebook/infer/releases/download/v0.9.0/infer-linux64-v0.9.0.tar.xz infer-linux64-v0.9.0.tar.xz
# RUN sudo tar xf infer-linux64-v0.9.0.tar.xz
# WORKDIR /home/opam/infer-linux64-v0.9.0
# RUN opam pin add -y --no-action infer . && \
#   opam install --deps-only --yes infer && \
#   ./build-infer.sh java
# USER root
# WORKDIR /
# ENV PATH=$PATH:/home/opam/infer-linux64-v0.9.0/infer/bin

# Julia setup
RUN julia -e 'Pkg.add("Lint")'

# NPM setup
# Extract dependencies from coala-bear package.json
# typescript is a peer dependency
RUN npm install -g typescript \
    $(sed -ne '/~/{s/^[^"]*"//;s/".*"~/@/;s/",*//;p}' coala-bears/package.json)

# Nltk data
RUN python3 -m nltk.downloader punkt maxent_treebank_pos_tagger averaged_perceptron_tagger

# PMD setup
RUN wget -q https://github.com/pmd/pmd/releases/download/pmd_releases%2F5.4.1/pmd-bin-5.4.1.zip -O /root/pmd.zip && \
  unzip /root/pmd.zip -d /root/ && \
  rm -rf /root/pmd.zip

# R setup
RUN mkdir -p ~/.RLibrary && \
  echo '.libPaths( c( "~/.RLibrary", .libPaths()) )' >> ~/.Rprofile && \
  echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' >> ~/.Rprofile && \
  R -e "install.packages('lintr', dependencies=TRUE,  verbose=FALSE)" && \
  R -e "install.packages('formatR', dependencies=TRUE, verbose=FALSE)"

# Tailor (Swift) setup
RUN curl -fsSL https://tailor.sh/install.sh | sed 's/read -r CONTINUE < \/dev\/tty/CONTINUE=y/' > install.sh && \
  /bin/bash install.sh

# # VHDL Bakalint Installation
# ADD http://downloads.sourceforge.net/project/fpgalibre/bakalint/0.4.0/bakalint-0.4.0.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Ffpgalibre%2Ffiles%2Fbakalint%2F0.4.0%2F&ts=1461844926&use_mirror=netcologne /root/bl.tar.gz
# RUN tar xf /root/bl.tar.gz -C /root/
# ENV PATH=$PATH:/root/bakalint-0.4.0

