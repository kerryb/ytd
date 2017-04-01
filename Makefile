all: clean test style docs
clean:
	mix clean
test:
	mix test
style:
	mix credo --strict
docs:
	mix docs
