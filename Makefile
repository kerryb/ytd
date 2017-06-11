all: clean test style dialyzer docs
clean:
	mix clean
test:
	MIX_ENV=test mix coveralls.html --umbrella
style:
	mix credo --strict
dialyzer:
	MIX_ENV=dev mix compile --debug-info
	mix dialyzer --halt-exit-status
docs:
	mix docs
build-release: assets docker-build
	docker run -e YTD_ERLANG_COOKIE='${YTD_ERLANG_COOKIE}' \
		-v $(shell pwd)/releases:/app/releases build-elixir mix release --env=prod
build-upgrade: assets docker-build
	docker run -e YTD_ERLANG_COOKIE='${YTD_ERLANG_COOKIE}' \
		-v $(shell pwd)/releases:/app/releases build-elixir mix release --env=prod --upgrade
assets:
	cd apps/ytd_web/assets && npm install && ./node_modules/brunch/bin/brunch b -p
	cd apps/ytd_web && MIX_ENV=prod mix phx.digest
docker-build:
	docker build --tag=build-elixir -f docker/builder/Dockerfile .
deploy-release:
	ssh root@ytd.kerryb.org mkdir -p /opt/ytd/releases/$(version)
	scp releases/ytd/releases/$(version)/ytd.tar.gz root@ytd.kerryb.org:/opt/ytd/releases/$(version)
	ssh root@ytd.kerryb.org "bash -lc 'REPLACE_OS_VARS=true /opt/ytd/bin/ytd install $(version)'"
	ssh root@ytd.kerryb.org "bash -lc 'REPLACE_OS_VARS=true /opt/ytd/bin/ytd restart'"
	ssh root@ytd.kerryb.org ln -s /etc/letsencrypt/webroot/.well-known /opt/ytd/lib/ytd_web-$(version)/priv/static/.well-known
deploy-upgrade:
	ssh root@ytd.kerryb.org mkdir -p /opt/ytd/releases/$(version)
	scp releases/ytd/releases/$(version)/ytd.tar.gz root@ytd.kerryb.org:/opt/ytd/releases/$(version)
	ssh root@ytd.kerryb.org "bash -lc 'REPLACE_OS_VARS=true /opt/ytd/bin/ytd upgrade $(version)'"
	ssh root@ytd.kerryb.org ln -s /etc/letsencrypt/webroot/.well-known /opt/ytd/lib/ytd_web-$(version)/priv/static/.well-known
