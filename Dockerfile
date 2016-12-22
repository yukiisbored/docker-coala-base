FROM dock0/arch:latest
MAINTAINER Fabian Neuschmidt fabian@neuschmidt.de

# Set the locale
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en PATH=$PATH:/root/pmd/bin GOPATH=/root/go

# Add archlinuxfr to pacman.conf
RUN echo -e "[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/\$arch" >> /etc/pacman.conf && \
  # Install dependencies and linters that are available on Arch's official repos
  pacman -Sy --noconfirm base-devel python python-pip yaourt cppcheck hlint suitesparse npm \
                         go julia ruby-bundler shellcheck r texlive-bin dart jre8-openjdk wget && \
  # Setup 'regular' user for AUR
  useradd user -m && echo "user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
  # Install liinters that are available on AUR
  su user -c \
  'yaourt -S --noconfirm --nocolor flawfinder luacheck perl-critic php-codesniffer tailor' && \
  # Remove unused packages (orphans)
  pacman -Rns --noconfirm $(pacman -Qtdq) && \
  # Remove every downloaded packages
  rm -fv /var/cache/pacman/pkg/*

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
RUN go get -u github.com/golang/lint/golint \
  && go get -u golang.org/x/tools/cmd/goimports \
  && go get -u sourcegraph.com/sqs/goreturns \
  && go get -u golang.org/x/tools/cmd/gotype \
  && go get -u github.com/kisielk/errcheck

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
RUN wget https://github.com/pmd/pmd/releases/download/pmd_releases%2F5.4.1/pmd-bin-5.4.1.zip -O /root/pmd.zip && \
  unzip /root/pmd.zip -d /root/ && \
  rm -rf /root/pmd.zip

# R setup
RUN mkdir -p ~/.RLibrary && \
  echo '.libPaths( c( "~/.RLibrary", .libPaths()) )' >> ~/.Rprofile && \
  echo 'options(repos=structure(c(CRAN="http://cran.rstudio.com")))' >> ~/.Rprofile && \
  R -e "install.packages('lintr', dependencies=TRUE,  verbose=FALSE)" && \
  R -e "install.packages('formatR', dependencies=TRUE, verbose=FALSE)"
