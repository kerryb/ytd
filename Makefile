.PHONY: clean dialyzer setup style test unit-test update-deps
all: style compile dialyzer test docs
setup:
	mix deps.get
	mix ecto.setup
	cd assets && yarn install
clean:
	mix clean
deep-clean:
	rm -rf _build assets/node_modules deps priv/static
style:
	mix format --check-formatted
	mix credo
compile:
	mix compile --warnings-as-errors
dialyzer:
	mix dialyzer
test:
	mix coveralls.html
docs:
	mix docs
update-deps:
	mix deps.update --all
	cd assets && rm yarn.lock && yarn install
release:
	docker build --tag=ytd-release -f docker/builder/Dockerfile .
	if [[ "$(docker ps -a)" =~ ytd-release ]] ; then docker rm ytd-release ; fi
	docker create --name ytd-release ytd-release
	docker cp ytd-release:/app/_build/prod/ytd-`cat VERSION`.tar.gz .
