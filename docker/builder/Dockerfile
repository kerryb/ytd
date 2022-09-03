FROM centos:7

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN locale

RUN set -xe \
  && yum install -y gcc-c++ git make unzip

RUN set -xe \
  && curl -sL https://rpm.nodesource.com/setup_17.x | bash - \
  && yum install -y nodejs

WORKDIR /app

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

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY assets/package.json assets/package.json
COPY assets/package-lock.json assets/package-lock.json
RUN cd assets && npm install

COPY assets assets
COPY config config
COPY lib lib
COPY priv priv
COPY VERSION VERSION
COPY rel rel

RUN mix compile

RUN cd assets && npx postcss css/app.css -o ../priv/static/assets/app.css
RUN mix esbuild default --minify
RUN mix phx.digest

RUN set -xe \
  && rm -rf _build/prod/rel/ytd/releases/* \
  && mix release
