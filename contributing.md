# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

# TODO: adapt this
asdf plugin test minecraft https://github.com/h-sumiya/asdf-minecraft.git "minecraft --help"
```

Tests are automatically run in GitHub Actions on push and PR.
