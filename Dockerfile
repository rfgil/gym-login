FROM ruby:3.4.1

ENV APP_ENV=production

WORKDIR /app

RUN apt-get update -y && \
    apt-get -qy autoremove  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY ./Gemfile /app/
RUN bundle install

COPY ./sinatra.rb /app/

EXPOSE 4567
CMD ["bundle", "exec", "ruby", "sinatra.rb", "-o", "0.0.0.0"]
