FROM ruby:2.7
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN apt-get install -y yarn
RUN mkdir /zinger
WORKDIR /zinger
ADD . /zinger
RUN bundle install
