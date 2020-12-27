.PHONY: style dialyzer test unit-test integration-test update-deps
all: style dialyzer test docs
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
