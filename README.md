<div align="center">

# mise-minecraft

**The easiest way to manage Minecraft Servers with [mise](https://mise.jdx.dev) or [asdf](https://asdf-vm.com).**

</div>

## Why use this?

- **Zero Friction**: Install any Minecraft version with a single command.
- **Version Management**: Switch between server versions (e.g., 1.20.4, 1.19) instantly.
- **Automated Setup**: Automatically downloads the official server JAR and verifies checksums.
- **Flexible Config**: Easily configure memory (`Xmx`, `Xms`) and JVM flags via environment variables.

## Quick Start

Get a Minecraft server running in seconds:

```shell
# 1. Add the plugin
mise plugins install minecraft https://github.com/h-sumiya/mise-minecraft.git

# 2. Install Java (Required) & Minecraft
mise use -g java@17 minecraft@1.20.4

# 3. Start the server
minecraft --nogui
```

*(Accept the EULA in `eula.txt` after the first run, then run it again!)*

## Dependencies

- **Java 17+**: Required to run modern Minecraft servers.
- **Utilities**: `curl`, `jq` (or `python3`), `sha1sum` (or `shasum`).

## Usage

### Listing Versions

See all available versions (releases only by default):

```shell
# List releases
mise ls-remote minecraft

# List ALL versions (including snapshots)
MINECRAFT_INCLUDE_SNAPSHOTS=1 mise ls-remote minecraft
```

### Installing Specific Versions

```shell
mise install minecraft@1.20.1
mise install minecraft@1.16.5
```

### Configuration

Configure your server performance using standard environment variables. You can set these in your shell or `mise.toml`.

| Variable | Description | Example |
| :--- | :--- | :--- |
| `MINECRAFT_XMX` | Max memory allocation | `4G` |
| `MINECRAFT_XMS` | Initial memory allocation | `1G` |
| `MINECRAFT_OPTS` | Additional JVM arguments | `-XX:+UseG1GC` |

**Example `mise.toml`:**

```toml
[env]
MINECRAFT_XMX = "4G"
MINECRAFT_XMS = "2G"
MINECRAFT_OPTS = "-XX:+UseG1GC -XX:+ParallelRefProcEnabled"

[tools]
java = "17"
minecraft = "1.20.4"
```

## Contributing

Contributions welcome! See [contributing.md](contributing.md).

## License

[LICENSE](LICENSE) © [h-sumiya](https://github.com/h-sumiya/)
