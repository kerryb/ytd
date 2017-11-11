# YTDWeb

## Compile, test, etc

```bash
make
```

## Initialise the database

From `iex` or a remote console:

```elixir
Amnesia.Schema.destroy # only if overwriting an existing db
Amnesia.Schema.create [node()]
Amnesia.start
YTD.Database.create! disk: [node()]
```

Data can be exported and imported using `Amnesia.dump "some-file"` and
`Amnesia.load "some-file"`.

## Build and deploy a release or upgrade

Update the `VERSION` file, then:

```bash
make build-release
make deploy-release version=x.y.z
```

or

```bash
make build-upgrade
make deploy-upgrade version=x.y.z
```
