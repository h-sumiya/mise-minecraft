<div align="center">

# asdf-minecraft [![Build](https://github.com/h-sumiya/asdf-minecraft/actions/workflows/build.yml/badge.svg)](https://github.com/h-sumiya/asdf-minecraft/actions/workflows/build.yml) [![Lint](https://github.com/h-sumiya/asdf-minecraft/actions/workflows/lint.yml/badge.svg)](https://github.com/h-sumiya/asdf-minecraft/actions/workflows/lint.yml)

[minecraft](https://github.com/h-sumiya/mise-minecraft) plugin for the [asdf](https://asdf-vm.com) and [mise](https://mise.jdx.dev) version managers.

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `sha1sum`/`shasum`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- `jq` **or** `python3` for parsing Mojang manifests.
- Java 17+ available on `PATH` (`mise use -g java@17` works well).

# Install

## asdf

```shell
asdf plugin add minecraft
asdf plugin add minecraft https://github.com/h-sumiya/mise-minecraft.git
```

## mise

```shell
mise plugins install minecraft https://github.com/h-sumiya/mise-minecraft.git
```

# Usage

- List releases: `asdf list-all minecraft` or `mise ls-remote minecraft`  
  Set `MINECRAFT_INCLUDE_SNAPSHOTS=1` to include snapshots/pre-releases.
- Install with Java 17: `mise install java@17 minecraft@1.20.4` or `asdf install java 17 && asdf install minecraft 1.20.4`
- Set defaults globally: `mise use -g java@17 minecraft@1.20.4` or `asdf global java 17 && asdf global minecraft 1.20.4`
- Run the dedicated server jar: `minecraft --nogui` (accept `eula.txt` on first launch as usual)

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/h-sumiya/asdf-minecraft/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [h-sumiya](https://github.com/h-sumiya/)
