.PHONY: style dialyzer test
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
