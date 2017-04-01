all: clean test style dialyzer docs
clean:
	mix clean
test:
	MIX_ENV=test mix coveralls.html --umbrella
style:
	mix credo --strict
dialyzer:
	mix dialyzer --halt-exit-status
docs:
	mix docs
