FROM ruby:2.7
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN apt-get install -y yarn
RUN mkdir /zinger
WORKDIR /zinger
COPY Gemfile /zinger/Gemfile
COPY Gemfile.lock /zinger/Gemfile.lock
RUN bundle install
COPY . /zinger
# Add a script to be executed every time the container starts.
COPY run.sh /usr/bin/
RUN chmod +x /usr/bin/run.sh

#ENTRYPOINT ["run.sh"]
#EXPOSE 3000
# Start the main process.
#CMD ["rails", "server", "-b", "0.0.0.0"]