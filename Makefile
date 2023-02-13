.PHONY: bumbailiff check-working-dir-clean check-version-up-to-date clean deploy dialyzer \
	setup style test unit-test update-deps
all: clean style compile dialyzer test docs bumbailiff
setup:
	mix deps.get
	mix ecto.setup
	cd assets && npm install
clean:
	MIX_ENV=test mix clean
	rm -rf priv/static/assets/*
deep-clean:
	rm -rf _build assets/node_modules deps priv/static/assets
style:
	mix format --check-formatted
	mix credo
bumbailiff:
	./bumbailiff
compile:
	mix compile --warnings-as-errors
dialyzer:
	mix dialyzer --format dialyxir
test:
	mix coveralls.html
docs:
	mix docs
outdated:
	mix hex.outdated
update-deps:
	mix deps.update --all
	cd assets && npm update
release: check-working-dir-clean check-version-up-to-date
	rm -f ytd-*.gz
	docker build --tag=ytd-release -f docker/builder/Dockerfile .
	docker rm -f ytd-release
	docker create --name ytd-release ytd-release
	docker cp ytd-release:/app/_build/prod/ytd-`cat VERSION`.tar.gz .
check-working-dir-clean:
	[[ -z "`git status --porcelain`" ]] || (echo "There are uncommitted changes" >&2 ; exit 1)
check-version-up-to-date:
	[[ `git log -1 --pretty=format:'%h'` == `git log -1 --pretty=format:'%h' VERSION` ]] \
	  || (echo "There have been changes since VERSION was updated" >&2 ; exit 1)
deploy:
	scp ytd-`cat VERSION`.tar.gz ytd@ytd.kerryb.org:
	ssh ytd@ytd.kerryb.org "bash -lc './deploy-release.sh ytd-`cat VERSION`.tar.gz && rm ytd-`cat VERSION`.tar.gz'"

