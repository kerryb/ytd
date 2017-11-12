all: clean database test style security dialyzer docs
.PHONY: clean database test style security dialyzer docs build-release \
  build-upgrade assets docker-build deploy-release deploy-upgrade
clean:
	mix clean
database: Mnesia.nonode@nohost
Mnesia.nonode@nohost:
	mix amnesia.create -d YTD.Database --disk
test:
	MIX_ENV=test mix coveralls.html
style:
	mix credo --strict
security:
	mix sobelow --exit low --router lib/ytd_web/router.ex
dialyzer:
	MIX_ENV=dev mix compile --debug-info
	mix dialyzer --halt-exit-status
docs:
	mix docs
build-release: assets docker-build
	docker run -e MIX_ENV=prod -e YTD_ERLANG_COOKIE='${YTD_ERLANG_COOKIE}' \
		-v `pwd`:`pwd` -w `pwd` build-elixir mix release
build-upgrade: assets docker-build
	docker run -e MIX_ENV=prod -e YTD_ERLANG_COOKIE='${YTD_ERLANG_COOKIE}' \
		-v `pwd`:`pwd` -w `pwd` build-elixir mix release --upgrade
assets:
	cd assets && npm install && ./node_modules/brunch/bin/brunch b -p
	MIX_ENV=prod mix phx.digest
docker-build:
	docker build --tag=build-elixir -f docker/builder/Dockerfile .
deploy-release:
	ssh root@ytd.kerryb.org mkdir -p /opt/ytd/releases/$(version)
	scp _build/prod/rel/ytd/releases/$(version)/ytd.tar.gz root@ytd.kerryb.org:/opt/ytd/releases/$(version)
	ssh root@ytd.kerryb.org "bash -lc 'REPLACE_OS_VARS=true /opt/ytd/bin/ytd install $(version)'"
	ssh root@ytd.kerryb.org "bash -lc 'REPLACE_OS_VARS=true /opt/ytd/bin/ytd restart'"
	ssh root@ytd.kerryb.org ln -s /etc/letsencrypt/webroot/.well-known /opt/ytd/lib/ytd-$(version)/priv/static/.well-known
deploy-upgrade:
	ssh root@ytd.kerryb.org mkdir -p /opt/ytd/releases/$(version)
	scp _build/prod/rel/ytd/releases/$(version)/ytd.tar.gz root@ytd.kerryb.org:/opt/ytd/releases/$(version)
	ssh root@ytd.kerryb.org "bash -lc 'REPLACE_OS_VARS=true /opt/ytd/bin/ytd upgrade $(version)'"
	ssh root@ytd.kerryb.org ln -s /etc/letsencrypt/webroot/.well-known /opt/ytd/lib/ytd-$(version)/priv/static/.well-known
