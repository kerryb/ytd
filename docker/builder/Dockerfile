FROM centos:7

SHELL ["/bin/bash", "-lc"]

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN locale

RUN yum update -y

RUN yum install -y gcc-c++ git curl make unzip openssl-devel ncurses-devel \
                   glibc-locale-source glibc-langpack-en

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3 \
  && echo 'export ASDF_DIR="$HOME/.asdf"' >> ~/.bashrc \
  && echo '. "$HOME/.asdf/asdf.sh"' >> ~/.bashrc

RUN mkdir /app
WORKDIR /app

COPY .tool-versions ./

RUN asdf plugin add erlang \
  && asdf plugin add elixir

RUN asdf install erlang \
  && asdf install elixir

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

COPY assets assets
COPY config config
COPY lib lib
COPY priv priv
COPY VERSION VERSION
COPY rel rel

RUN mix compile

RUN mix esbuild default --minify
RUN mix phx.digest

RUN set -xe \
  && rm -rf _build/prod/rel/ytd/releases/* \
  && mix release
