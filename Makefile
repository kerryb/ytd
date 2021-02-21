.PHONY: clean dialyzer setup style test unit-test update-deps
all: style dialyzer test docs
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
dialyzer:
	mix dialyzer
test:
	mix coveralls.html
docs:
	mix docs
update-deps:
	mix deps.update --all
	cd assets && rm yarn.lock && yarn install
