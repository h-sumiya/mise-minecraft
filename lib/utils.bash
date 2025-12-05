#!/usr/bin/env bash

set -euo pipefail

TOOL_NAME="minecraft"
TOOL_TEST="minecraft"

VERSION_MANIFEST_URL="https://piston-meta.mojang.com/mc/game/version_manifest.json"

fail() {
	echo "asdf-$TOOL_NAME: $*" >&2
	exit 1
}

curl_opts=(-fsSL)

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

download_version_manifest() {
	curl "${curl_opts[@]}" "$VERSION_MANIFEST_URL" || fail "Could not download version manifest"
}

get_python_cmd() {
	command -v python3 >/dev/null && { command -v python3; return; }
	command -v python >/dev/null && { command -v python; return; }
	echo ""
}

list_all_versions() {
	local manifest include_snapshots py
	manifest="$(download_version_manifest)"
	include_snapshots="${MINECRAFT_INCLUDE_SNAPSHOTS:-0}"

	if command -v jq >/dev/null 2>&1; then
		env MINECRAFT_INCLUDE_SNAPSHOTS="$include_snapshots" jq -r '
			def include_snapshots: (env.MINECRAFT_INCLUDE_SNAPSHOTS // "0") | ascii_downcase | test("^(1|true|yes)$");
			.versions[] | select(.type == "release" or include_snapshots) | .id
		' <<<"$manifest"
		return
	fi

	py="$(get_python_cmd)"
	if [ -n "$py" ]; then
		MINECRAFT_INCLUDE_SNAPSHOTS="$include_snapshots" "$py" - <<'PY'
import json
import os
import sys

include = os.environ.get("MINECRAFT_INCLUDE_SNAPSHOTS", "0").lower() in {"1", "true", "yes"}
data = json.load(sys.stdin)
for version in data.get("versions", []):
    if include or version.get("type") == "release":
        vid = version.get("id")
        if vid:
            print(vid)
PY
		return
	fi

	fail "Install jq or python to list minecraft versions"
}

latest_release_version() {
	local manifest version py
	manifest="$(download_version_manifest)"

	if command -v jq >/dev/null 2>&1; then
		version=$(jq -r '.latest.release // empty' <<<"$manifest")
	else
		py="$(get_python_cmd)"
		if [ -n "$py" ]; then
			version=$(printf '%s' "$manifest" | "$py" - <<'PY'
import json
import sys

data = json.load(sys.stdin)
latest = data.get("latest", {})
print(latest.get("release", ""))
PY
)
		else
			fail "Install jq or python to parse version manifest"
		fi
	fi

	if [ -z "${version:-}" ]; then
		version="$(list_all_versions | sort_versions | tail -n1 | xargs echo)"
	fi

	printf "%s\n" "$version"
}

extract_version_manifest_url() {
	local version="$1" manifest py url
	manifest="$(download_version_manifest)"

	if command -v jq >/dev/null 2>&1; then
		url=$(jq -r --arg version "$version" '.versions[] | select(.id == $version) | .url // empty' <<<"$manifest")
	else
		py="$(get_python_cmd)"
		if [ -n "$py" ]; then
			url=$(printf '%s' "$manifest" | "$py" - "$version" <<'PY'
import json
import sys

target = sys.argv[1]
data = json.load(sys.stdin)
for version in data.get("versions", []):
    if version.get("id") == target:
        print(version.get("url", ""))
        break
PY
)
		else
			fail "Install jq or python to parse version manifest"
		fi
	fi

	[ -n "$url" ] || fail "Version $version not found in manifest"
	printf "%s" "$url"
}

fetch_version_metadata() {
	local version="$1"
	local url
	url="$(extract_version_manifest_url "$version")"
	curl "${curl_opts[@]}" "$url" || fail "Could not download metadata for $version"
}

extract_server_download() {
	local field="$1" metadata py
	metadata="$(cat)"

	if command -v jq >/dev/null 2>&1; then
		jq -r --arg field "$field" '.downloads.server[$field] // empty' <<<"$metadata"
	else
		py="$(get_python_cmd)"
		if [ -n "$py" ]; then
			printf '%s' "$metadata" | "$py" - "$field" <<'PY'
import json
import sys

field = sys.argv[1]
data = json.load(sys.stdin)
downloads = data.get("downloads", {})
server = downloads.get("server", {})
print(server.get(field, ""))
PY
		else
			fail "Install jq or python to parse version metadata"
		fi
	fi
}

verify_sha1() {
	local file="$1" expected="$2"
	[ -n "$expected" ] || return 0

	if command -v sha1sum >/dev/null 2>&1; then
		echo "$expected  $file" | sha1sum -c - >/dev/null || fail "Checksum verification failed for $file"
	elif command -v shasum >/dev/null 2>&1; then
		echo "$expected  $file" | shasum -a 1 -c - >/dev/null || fail "Checksum verification failed for $file"
	else
		echo "asdf-$TOOL_NAME: warning: sha1 utility not found; skipping checksum verification" >&2
	fi
}

download_release() {
	local version="$1"
	local download_dir="$2"
	local metadata server_url server_sha

	metadata="$(fetch_version_metadata "$version")"
	server_url="$(extract_server_download url <<<"$metadata")"
	server_sha="$(extract_server_download sha1 <<<"$metadata")"

	[ -n "$server_url" ] || fail "Server download URL not found for version $version"

	echo "* Downloading $TOOL_NAME server $version..."
	curl "${curl_opts[@]}" -o "$download_dir/minecraft-server.jar" -C - "$server_url" ||
		fail "Could not download $server_url"

	verify_sha1 "$download_dir/minecraft-server.jar" "$server_sha"

	printf "%s" "$metadata" >"$download_dir/version.json"
}

ensure_java_runtime() {
	local java_bin version_string major
	java_bin="${JAVA_BIN:-${JAVA_CMD:-java}}"

	if ! command -v "$java_bin" >/dev/null 2>&1; then
		fail "java not found. Install Java 17+ (e.g. mise use java@17)."
	fi

	version_string=$("$java_bin" -version 2>&1 | awk -F'"' '/version/ {print $2; exit}')
	major="${version_string%%.*}"

	if [[ "$major" =~ ^[0-9]+$ ]] && [ "$major" -lt 17 ]; then
		fail "minecraft requires Java 17+. Detected $version_string"
	fi
}

write_launcher() {
	local bin_dir="$1"
	local lib_dir="$2"
	local launcher="$bin_dir/$TOOL_NAME"

	cat >"$launcher" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

java_bin="${JAVA_BIN:-${JAVA_CMD:-java}}"
if ! command -v "$java_bin" >/dev/null 2>&1; then
	echo "java not found; set JAVA_BIN or install Java 17+." >&2
	exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
jar_path="${script_dir%/bin}/lib/minecraft-server.jar"

if [ ! -f "$jar_path" ]; then
	echo "minecraft server jar not found at $jar_path" >&2
	exit 1
fi

java_opts=()

if [ -n "${MINECRAFT_XMX:-}" ]; then
	java_opts+=("-Xmx${MINECRAFT_XMX}")
fi

if [ -n "${MINECRAFT_XMS:-}" ]; then
	java_opts+=("-Xms${MINECRAFT_XMS}")
fi

if [ -n "${MINECRAFT_OPTS:-}" ]; then
	read -r -a extra_opts <<<"${MINECRAFT_OPTS}"
	java_opts+=("${extra_opts[@]}")
fi

exec "$java_bin" "${java_opts[@]}" -jar "$jar_path" "$@"
EOF

	chmod +x "$launcher"
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_root="${3%/bin}"
	local bin_dir="$install_root/bin"
	local lib_dir="$install_root/lib"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	ensure_java_runtime

	(
		mkdir -p "$bin_dir" "$lib_dir"
		[ -f "$ASDF_DOWNLOAD_PATH/minecraft-server.jar" ] || fail "minecraft-server.jar not found in download directory"

		cp "$ASDF_DOWNLOAD_PATH/minecraft-server.jar" "$lib_dir/minecraft-server.jar"
		[ -f "$ASDF_DOWNLOAD_PATH/version.json" ] && cp "$ASDF_DOWNLOAD_PATH/version.json" "$lib_dir/version.json"

		write_launcher "$bin_dir" "$lib_dir"

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_root"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
