FROM ubuntu

# Install baseline dependencies:
RUN apt-get update
RUN apt-get install -y curl wget unzip xvfb

# Install ruby-2.0:
RUN apt-get -y install build-essential zlib1g-dev libssl-dev libreadline6-dev libyaml-dev
RUN wget http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p353.tar.gz
RUN tar -xvzf ruby-2.0.0-p353.tar.gz
WORKDIR /ruby-2.0.0-p353/
RUN ./configure --prefix=/usr/local --disable-install-doc
RUN make
RUN make install
WORKDIR /

# Install bundler & project gem-deps:
RUN gem install bundler
ADD Gemfile /Gemfile
RUN bundle install

# Install Firefox:
ADD firefox-mozilla-build_24.0-0ubuntu1_amd64.deb /firefox-mozilla-build_24.0-0ubuntu1_amd64.deb
RUN dpkg -i /firefox-mozilla-build_24.0-0ubuntu1_amd64.deb
RUN apt-get -y -f install
RUN apt-get install -y firefox

# Install Chrome:
RUN apt-get install -y wget gconf-service libgconf-2-4 libxss1 xdg-utils libcap2 libnspr4 libnss3 libasound2 libatk1.0-0 libcairo2 libcups2 libgdk-pixbuf2.0-0 libgtk2.0-0 libpango1.0-0
ADD google-chrome-stable_current_amd64-30.0.1599.66.deb /google-chrome-stable_current_amd64.deb
RUN dpkg -i /google-chrome-stable_current_amd64.deb
RUN apt-get -y -f install
RUN mkdir -p /chrome-profile

# Install ChromeDriver:
ADD chromedriver-v2.4.226074 /usr/local/bin/chromedriver

# Set up the entrypoint script:
ADD entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh
ENV DISPLAY :1
ENTRYPOINT ["/entrypoint.sh"]

# Usage example:
# $ docker build -t test-runner .
# $ docker run -v $(pwd)/temp/:/temp:rw -v $(pwd)/test/:/test:ro test-runner test/integration/

# grabbed from https://groups.google.com/forum/#!topic/docker-user/XRzHRfjI_dA