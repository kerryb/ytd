FROM elixir:1.4.0

MAINTAINER Kerry Buckley

ENV REFRESHED_AT 2017-04-04

RUN /usr/local/bin/mix local.hex --force && \
    /usr/local/bin/mix local.rebar --force && \
    /usr/local/bin/mix hex.info

WORKDIR /app
COPY . .

ENV MIX_ENV prod
RUN mix deps.get

CMD ["bash"]
