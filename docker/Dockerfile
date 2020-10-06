FROM ruby:2.7.2
RUN wget -q -O - https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get update -qq && apt-get install -y build-essential nodejs postgresql-client
RUN apt-get install -y yarn
RUN mkdir /zinger
WORKDIR /zinger
ADD . /zinger
RUN yarn add webpack
RUN yarn install
RUN bundle install
