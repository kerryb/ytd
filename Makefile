.PHONY: style dialyzer test update-deps
all: style dialyzer test docs
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
	npm upgrade --prefix assets
