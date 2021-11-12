.PHONY: bumbailiff clean deploy dialyzer setup style test unit-test update-deps
all: clean style compile dialyzer test docs bumbailiff
setup:
	mix deps.get
	mix ecto.setup
	cd assets && npm install
clean:
	mix clean
	rm -rf priv/static/assets/*
deep-clean:
	rm -rf _build assets/node_modules deps priv/static
style:
	mix format --check-formatted
	mix credo
bumbailiff:
	./bumbailiff
compile:
	mix compile --warnings-as-errors
dialyzer:
	mix dialyzer --format dialyxir
test:
	mix coveralls.html
docs:
	mix docs
update-deps:
	mix deps.update --all
	cd assets && npm update
release:
	rm -f ytd-*.gz
	docker build --tag=ytd-release -f docker/builder/Dockerfile .
	docker rm -f ytd-release
	docker create --name ytd-release ytd-release
	docker cp ytd-release:/app/_build/prod/ytd-`cat VERSION`.tar.gz .
deploy:
	scp ytd-`cat VERSION`.tar.gz ytd@ytd.kerryb.org:
	ssh ytd@ytd.kerryb.org "bash -lc './deploy-release.sh ytd-`cat VERSION`.tar.gz && rm ytd-`cat VERSION`.tar.gz'"

