all: clean test style dialyzer docs
clean:
	mix clean
test:
	mix test
style:
	mix credo --strict
dialyzer:
	mix dialyzer --halt-exit-status
docs:
	mix docs
