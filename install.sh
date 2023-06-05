#!/bin/sh
# A modification of the standard Deno installation script (https://deno.land/install.sh)
# Upeaeeaedated to support downloading a Linux arm64 binary from LukeChannings/deno-arm64.
# Further updated to allow for an -r | --rc flag, which will attempt to automatically 
# configure the user's shell config file with the necessary environment variables.
set -e

if ! command -v unzip >/dev/null; then
	echo "Error: unzip is required to install Deno (see: https://github.com/denoland/deno_install#unzip-is-required)." 1>&2
	exit 1
fi

if ! command -v curl >/dev/null; then
	echo "Error: curl is required to install Deno. Please install the libcurl / curl package and try again." 1>&2
	exit 1
fi

append_to_shell_config=0

for arg in "$@"
    case $arg in
        -r|--rc|-a|--auto|-c|--configure|-s|--setup|-p|--profile|-i|--init|-e|--env|-u|--update|-w|--write)
        append_to_shell_config=1
        shift
        ;;
    esac
done

repo="denoland/deno"

if [ "$OS" = "Windows_NT" ]; then
	target="x86_64-pc-windows-msvc"
else
	case $(uname -sm) in
	"Darwin x86_64") target="x86_64-apple-darwin" ;;
	"Darwin arm64") target="aarch64-apple-darwin" ;;
	"Linux aarch64")
		repo="LukeChannings/deno-arm64"
		target="linux-arm64"
		;;
	"Linux armhf")
		echo "32-bit ARM is not supported. Please check your hardware and install a 64-bit operating system."
		exit 1
		;;
	*) target="x86_64-unknown-linux-gnu" ;;
	esac
fi

if [ $# -eq 0 ]; then
	target_release="latest/download"
else 
	target_release="${1:+"download/${1}"}"
fi

deno_uri="https://github.com/${repo}/releases/${target_release}/deno-${target}.zip"
deno_install="${DENO_INSTALL:-$HOME/.deno}"
bin_dir="$deno_install/bin"
exe="$bin_dir/deno"

if [ ! -d "$bin_dir" ]; then
	mkdir -p "$bin_dir"
fi

curl --fail --location --progress-bar --output "$exe.zip" "$deno_uri"
unzip -d "$bin_dir" -o "$exe.zip"
chmod +x "$exe"
rm "$exe.zip"

echo "Deno was installed successfully to $exe"
if ! command -v deno >/dev/null; then
	case $SHELL in
	*/bin/zsh) shell_profile=".zshrc" ;;
	*/bin/bash) shell_profile=".bashrc" ;;
  */bin/tcsh) shell_profile=".tcshrc" ;;
  */bin/fish) shell_profile=".config/fish/config.fish" ;;
  *) shell_profile=".profile" ;;
	esac
	if [ $append_to_shell_config -eq 1 ]; then
	    if [ -w "$HOME/$shell_profile" ]; then
	        echo "export DENO_INSTALL=\"$deno_install\"" >> "$HOME/$shell_profile"
	        echo "export PATH=\"\$DENO_INSTALL/bin:\$PATH\"" >> "$HOME/$shell_profile"
	        echo "Successfully added deno path to $HOME/$shell_profile"
	    else
	        echo "Unable to write to $HOME/$shell_profile"
		exit 3
	    fi
	else
	    echo "Manually add the directory to your \$HOME/$shell_profile (or similar)"
	    echo "  export DENO_INSTALL=\"$deno_install\""
	    echo "  export PATH=\"\$DENO_INSTALL/bin:\$PATH\""
	fi
fi

echo "Run '$exe --help' to get started"
