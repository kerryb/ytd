all: clean test style
clean:
	mix clean
test:
	mix test
style:
	mix credo --strict
