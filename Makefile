.PHONY: clean dialyzer integration-test setup style test unit-test update-deps
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
unit-test:
	mix test --exclude=integration
integration-test:
	mix test --only=integration
docs:
	mix docs
update-deps:
	mix deps.update --all
	cd assets && yarn up
