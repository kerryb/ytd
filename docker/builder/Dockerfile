FROM centos:7

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN locale

RUN set -xe \
  && yum install -y gcc-c++ git make unzip

RUN set -xe \
  && curl -sL https://rpm.nodesource.com/setup_12.x | bash - \
  && yum install -y nodejs \
  && npm install --global yarn

COPY .tool-versions ./

RUN set -xe \
  && yum install -y http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm \
  && version=`awk '/^erlang / { print $2 }' .tool-versions` \
  && yum install -y -v $version esl-erlang

RUN set -xe \
  && version=`awk '/^elixir / { sub(/-.*/, "", $2) ; print $2 }' .tool-versions` \
  && curl -fSL -o elixir-precompiled.zip https://github.com/elixir-lang/elixir/releases/download/v${version}/Precompiled.zip \
  && unzip -d /usr/local elixir-precompiled.zip \
  && rm elixir-precompiled.zip

RUN mkdir /app
WORKDIR /app

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get
RUN mix deps.compile

COPY assets/package.json assets/yarn.lock assets/.yarnrc.yml assets/
COPY assets/.yarn/releases assets/.yarn/releases
RUN cd assets && yarn install

COPY assets assets
RUN mix assets.deploy
RUN mix phx.digest

COPY priv priv
COPY lib lib
COPY VERSION VERSION
RUN mix compile

COPY rel rel
RUN set -xe \
  && rm -rf _build/prod/rel/ytd/releases/* \
  && mix release
