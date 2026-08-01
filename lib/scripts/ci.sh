#!/bin/sh

# Script for automating various checks and git actions for the repo.
_log() {
	printf "%s %s\n" "$(date +%F\ %T)" "$1" >>"$LOG_FILE"
	case "$?" in
	0) return 0 ;;
	*)
		printf "Failed to write to %s\n" "$LOG_FILE"
		return 1
		;;
	esac
}

_msg() {
	printf "%s\n" "$1"
	_log "$1"
}

_debugmsg() {
	_msg "DEBUG: $1"
}

_errormsg() {
	_msg "Error: $1"
	exit 1
}

_warnmsg() {
	_msg "Warning: $1" || return 1
}

_exitmsg() {
	_msg "$1"
	exit 0
}

_desktop_active() {
	[ "$XDG_CURRENT_DESKTOP" ] || [ "$DISPLAY" ] || [ "$WAYLAND_DISPLAY" ]
}

_notify() {
	STATUS="$1"
	MSG="$2"

	if [ ! ${DISABLE_NOTIFICATIONS+x} ]; then
		! _desktop_active && DISABLE_NOTIFICATIONS=1
	fi

	if [ ! ${DISABLE_NOTIFICATIONS+x} ]; then
		notify-send -a "snowglobe-lib-CI" "$STATUS" "$MSG" || _warnmsg "Failed to send desktop notification with content: $MSG"
	fi

	case $STATUS in
	"Error") _errormsg "$MSG" ;;
	"Warning") _warnmsg "$MSG" || exit 1 ;;
	"Success") _msg "Success: $MSG" || exit 1 ;;
	*) _msg "$MSG" || exit 1 ;;
	esac
}

y_or_n() {
	while :; do
		printf "%s: [y/n] " "$1"
		read -r yn

		case "$yn" in
		"Y" | "y") return 0 ;;
		"N" | "n") return 1 ;;
		*) printf "Not a valid response\n" ;;
		esac
	done
}

# main
# Nix develop with nix-command has no way that I know of to set this value to from impure to pure
# a temporary fix is mentioned here.
# https://discourse.nixos.org/t/why-doesnt-develop-or-shell-have-a-pure-mode/16745
# [ "$IN_NIX_SHELL" = "pure" ] || _errormsg "your nix development shell is not pure."

[ "$SNOWGLOBE_DEVSHELL" ] || _errormsg "You are not in the devshell. Did you run 'nix develop --unset PATH'?"

if [ ! -e "flake.nix" ] || ! cat "flake.nix" | grep -q "description = \"Core modules for the NixOS snowglobes framework.\";"; then
	printf "%s\n" "You are not in the repository root."
	exit 1
fi

PROJECT_ROOT="$PWD"
CI_ROOT="$PROJECT_ROOT/ci"
LOG_FILE="$CI_ROOT/lastrun.log"
mkdir -p "$CI_ROOT" || {
	printf "Could not create directory for ci artifacts."
	exit 1
}
cat /dev/null >"$LOG_FILE"

_add_menuoption() {
	MENU_OPTIONS="$MENU_OPTIONS""$1
"
}

_add_menuoption "Check flake"
_add_menuoption "Testbuild package"
_add_menuoption "Clear ci cache"
_add_menuoption "Build testmonkeys"
[ "$(whoami)" = "earthgman" ] && {
	_add_menuoption "Build installers"
	_add_menuoption "Git: current -> unstable"
	_add_menuoption "Git: unstable -> main"
}
_add_menuoption "Build globes"
_add_menuoption "Edit globes"
_add_menuoption "Exit"

while :; do
	[ "$SELECTED_OPTION" ] && unset SELECTED_OPTION
	SELECTED_OPTION=$(printf "%s" "$MENU_OPTIONS" |
		fzf --no-sort | tr '[:upper:]' '[:lower:]')

	case "$SELECTED_OPTION" in
	"check flake")
		nix flake check || exit 1
		exit 0
		;;

	"git: unstable -> main")
		git checkout main
		git merge unstable || ERROR=1
		[ -z "$ERROR" ] && git push
		git checkout unstable
		[ "$ERROR" ] && exit 1
		exit 0
		;;

	"git: current -> unstable")
		CURRENT_BRANCH=$(git branch | grep '\*' | cut -d' ' -f2)
		[ "$CURRENT_BRANCH" = "unstable" ] && _errormsg "You are already on unstable"
		git checkout unstable
		git merge "$CURRENT_BRANCH" || _errormsg "Branches failed to merge."
		git branch -d "$CURRENT_BRANCH" || _errormsg "Failed to delete the local branch."
		y_or_n "Delete the remote branch" && {
			git push -d origin "$CURRENT_BRANCH" || _errormsg "Failed to remove this branch from origin."
		}
		exit 0
		;;

	"clear ci cache")
		_rm_dir() {
			[ -d "$1" ] && {
				_msg "removing $1"
				rm -rf "$1" || _errormsg "Failed to remove $1."
			}
		}
		_rm_dir "$CI_ROOT/packages"
		_rm_dir "$CI_ROOT/globes"
		_msg "Successfully removed ci artifacts."
		;;

	"testbuild package")
		PACKAGE_RESULTS="$CI_ROOT/packages"
		mkdir -p "$PACKAGE_RESULTS" || _errormsg "Could not create package result directory."
		while :; do
			printf "package name: "
			read -r PACKAGE_NAME
			[ "$PACKAGE_NAME" ] || _errormsg "No package name was entered."
			while :; do
				# build the package as it would apply in a nixos configuration
				if ! nom build ".#nixosConfigurations.testmonkey.pkgs.$PACKAGE_NAME" -o "$PACKAGE_RESULTS/$PACKAGE_NAME"; then
					y_or_n "Package build failed. Try this build again?" || break
				else
					break
				fi
			done
			printf "\n"
			y_or_n "Build another package?" || break
		done
		;;

	"build testmonkeys")
		# TODO add more testmonkeys
		nh os build ".#testmonkey" || exit 1
		exit 0
		;;

	# for me only
	"build installers")
		ORIGINAL_BRANCH=$(git branch | grep '\*' | cut -d' ' -f2)
		if [ "$ORIGINAL_BRANCH" != "main" ]; then
			git checkout main || _errormsg "Could not check out main branch"
		fi
		WEBSITE_IP="homebase.internal.earthgman.dev"
		# use a temporary upload dir so I can replace all images on the website at once
		UPLOAD_DIR="/tmp/snowglobe-installers"
		WEBSITE_DIR="/srv/static-web-server/snowglobe-installers"
		SUPPORTED_ARCHES="x86_64"
		LOCAL_CACHE_DIR="$HOME/Archive/isos"

		# check if ssh can be reached
		nc -z "$WEBSITE_IP" 22 || _errormsg "Unable to reach webserver at: $WEBSITE_IP"

		# ensure the upload dir is clean before starting the builds
		ssh "earthgman@$WEBSITE_IP" "rm -f $UPLOAD_DIR/*"

		INSTALLERS=$(
			for configuration in $(nix eval ".#nixosConfigurations" --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"'); do
				printf "%s\n" "$configuration"
			done | grep 'snowglobe-installer'
		)

		mkdir -p "$LOCAL_CACHE_DIR" || exit 1

		ssh "earthgman@$WEBSITE_IP" "mkdir -p $UPLOAD_DIR" || exit 1

		_remove_cached() {
			if [ -e "$1" ]; then
				rm -f "$1" || _errormsg "Could not remove $1"
			fi
		}

		for image in $INSTALLERS; do
			# store isos so they can be shared between hosts
			ISO_OUTPATH="$LOCAL_CACHE_DIR/$image.iso"
			ISO_HASHFILE="$ISO_OUTPATH"".sha256"
			HASH_SIGFILE="$ISO_HASHFILE"".gpg"

			nixos-rebuild build-image --image-variant iso-installer --flake .\#"$image" || _errormsg "Image: $image, failed to build"

			_remove_cached "$ISO_OUTPATH"
			_remove_cached "$ISO_HASHFILE"
			_remove_cached "$HASH_SIGFILE"

			cp result/iso/* "$ISO_OUTPATH" || _errormsg "Could not copy image to $ISO_OUTPATH"

			sha256sum "$ISO_OUTPATH" | cut -d ' ' -f1 >"$ISO_HASHFILE"
			gpg --sign --default-key 'EarthGman' "$ISO_HASHFILE" || _errormsg "Failed to sign iso image hash for $image"

			scp "$ISO_OUTPATH" "$HASH_SIGFILE" "earthgman@$WEBSITE_IP:$UPLOAD_DIR" || _errormsg "Could not copy image to the server."
		done

		# move the images to the webserver directory listing
		ssh "earthgman@$WEBSITE_IP" "chmod 440 $UPLOAD_DIR/*; chgrp static-web-server $UPLOAD_DIR/*"
		for arch in $SUPPORTED_ARCHES; do
			for file in $(ssh "earthgman@$WEBSITE_IP" "ls -A $UPLOAD_DIR"); do
				if printf "%s" "$file" | grep -q "$arch"; then
					ssh "earthgman@$WEBSITE_IP" "mv -f $UPLOAD_DIR/$file" "$WEBSITE_DIR/$arch" || _notify "Error" "Could not move $file from $UPLOAD_DIR to $WEBSITE_DIR"
				fi
			done
		done

		if [ "$ORIGINAL_BRANCH" != "main" ]; then
			git checkout "$ORIGINAL_BRANCH" || _errormsg "Could not check out the original branch $ORIGINAL_BRANCH"
		fi

		exit 0
		;;

	"edit globes")
		EDITOR="${EDITOR:-"nano"}"
		$EDITOR "ci/globes.txt"
		;;

	# allows you to locally test your own repository against the current snowglobe-lib state
	# to upload things, nix-post-build-queue to be installed and configured to upload build artifacts to your remote server
	"build globes")
		GLOBES_DIR="$CI_ROOT/globes"
		mkdir -p "$GLOBES_DIR"
		ENABLE_CACHING=1
		systemctl list-units | grep -q nix-post-build-hook-queue || unset ENABLE_CACHING

		_check_service_state() {
			if ! systemctl is-active "$1"; then
				_warnmsg "$1 is not enabled."
				BUILD_UPLOADER_DISABLED=1
			fi
		}

		if [ "$ENABLE_CACHING" ]; then
			_check_service_state "nix-post-build-hook-queue.socket"
			if [ "$BUILD_UPLOADER_DISABLED" ]; then
				y_or_n "The build upload queue is disabled. Do you wish to continue?" || _errormsg "Aborted"
			fi
		fi

		if [ -e "$CI_ROOT/globes.txt" ]; then
			# can be a url or a local path each separated by newlines
			GLOBES=$(cat "$CI_ROOT/globes.txt" || _errormsg "Failed to read globes.txt")
			[ -z "$GLOBES" ] && _errormsg "No globes found. Maybe globes.txt is blank?"
		else
			_errormsg "ci/globes.txt was not found."
		fi

		_restore_flake() {
			mv -f "flake.nix.bak" "flake.nix" || _warnmsg "Could not return flake.nix for $globe to its original state!"
			mv -f "flake.lock.bak" "flake.lock" || _warnmsg "Could not return flake.lock for $globe to its original state!"
			rm -f "result" || _warnmsg "Could not remove the configuration build artifact, result, from your repo."
		}

		for globe in $GLOBES; do
			printf "Checking globe %s\n" "$globe"
			# if it contains a colon assume a url
			printf "%s" "$globe" | grep -q ":" && {
				IS_REMOTE=1
				IS_GIT=1
			}

			# assume that if it is a url you can reach it with the git cli
			if [ "$IS_REMOTE" ]; then
				REPO_DOMAIN=$(printf "%s" "$globe" | cut -d/ -f3)
				REPO_OWNER=$(printf "%s" "$globe" | cut -d/ -f4)
				GLOBE_NAME=$(printf "%s" "$globe" | cut -d/ -f5)
				# some repo layouts may have domain/project with no username
				if [ "$GLOBE_NAME" ]; then
					GLOBE_DIR="$GLOBES_DIR/$REPO_DOMAIN/$REPO_OWNER/$GLOBE_NAME"
				else
					GLOBE_NAME="$REPO_OWNER"
					GLOBE_DIR="$GLOBES_DIR/$REPO_DOMAIN/$REPO_OWNER"
				fi
			else
				GLOBE_NAME=$(printf "%s" "$globe" | tr '/' '-' | sed 's/^.\{1\}//')
				GLOBE_DIR="$GLOBES_DIR/$GLOBE_NAME"
			fi

			[ "$GLOBE_PRESENT" ] && unset GLOBE_PRESENT
			[ -d "$GLOBE_DIR" ] && GLOBE_PRESENT=1

			if [ ${GLOBE_PRESENT+x} ]; then
				if [ "$IS_REMOTE" ]; then
					cd "$GLOBE_DIR" || _errormsg "Could not enter $GLOBE_DIR."
					git pull --rebase || _errormsg "Could not git pull with rebase."
				fi
			else
				if [ "$IS_REMOTE" ]; then
					mkdir -p "$GLOBE_DIR" || _errormsg "Failed to create the repo dir for $globe."
					git clone "$globe" --depth 1 "$GLOBE_DIR" || _errormsg "Failed to clone $globe."
				else
					ln -sv "$globe" "$GLOBE_DIR" || _errormsg "Could not create link to your local repository."
				fi
			fi

			[ -d "$GLOBE_DIR/.git" ] && IS_GIT=1

			cd "$GLOBE_DIR" || _errormsg "Could not change working directory to $GLOBE_DIR"

			if [ "$IS_GIT" ]; then
				# ensure all of your local changes are staged
				git add . || _errormsg "could not add local changes to git"
			fi

			[ -e "flake.nix" ] || {
				_notify "Warning" "$GLOBE_DIR does not have a flake.nix. Skipping."
				continue
			}

			# update your flake input to the current local repo state
			cp flake.nix flake.nix.bak || _errormsg "Could not archive the current state of flake.nix"
			cp flake.lock flake.lock.bak || _errormsg "Could not archive the current state of flake.lock"
			sed -i "s|url =.*/earthgman/snowglobe-lib.*|url = \"$PROJECT_ROOT\";|" "flake.nix" || {
				_restore_flake
				_notify "Warning" "Failed to replace the snowglobe-lib input url of $GLOBE_DIR with this local repository via sed. skipping this repo."
				continue
			}

			nix flake update snowglobe-lib || {
				_restore_flake
				_notify "Warning" "Unable to update snowlobe-lib flake input of $GLOBE_DIR. skipping this repo"
				continue
			}

			HOSTS=$(nix eval "$GLOBE_DIR#nixosConfigurations" --apply builtins.attrNames | sed 's/[][]//g' | tr -d '"')
			if [ -z "$HOSTS" ]; then
				_restore_flake
				_warnmsg "No hosts detected were detected from $GLOBE_DIR. skipping this repo"
				continue
			fi

			for host in $HOSTS; do
				nh os build ".#$host" || {
					_notify "Warning" "CI Build failed for $host from $GLOBE_DIR."
					y_or_n "continue checks?" || {
						_restore_flake
						_exitmsg "Aborted"
					}
				}
			done

			_restore_flake
			cd "$OLDPWD" || _errormsg "Failed to return to the project root"
		done

		_notify "Notice" "Build jobs have completed."
		exit 0
		;;

	*) exit 0 ;;
	esac
done
