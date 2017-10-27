# YTDWeb

## Compile, test, etc

```bash
make
```

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
