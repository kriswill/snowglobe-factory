#!/bin/sh

# wrapper around nixos-rebuild, ensuring configurations are automaically logged and commited to git
set -u
set -o pipefail

SCRIPT_NAME="snowglobe-rebuild"

y_or_n() {
	while true; do
		printf "%s [y/n]: " "$@"
		read -r yn
		case $yn in
		[Yy]) return 0 ;;
		[Nn]) return 1 ;;
		*) printf "Not a valid response\n" ;;
		esac
	done
}

_msg() {
	printf "%s\n" "$1"
}

_errormsg() {
	_msg "Error: $1"
	exit 1
}

_warnmsg() {
	_msg "Warning: $1" || return 1
}

_desktop_active() {
	[ "${DISPLAY-}" ] || [ "${WAYLAND_DISPLAY-}" ]
}

_is_on_path() {
	command -v "$1" >/dev/null 2>&1
}

_notify() {
	STATUS="$1"
	MSG="$2"

	if [ ! "${DONT_NOTIFY-}" ]; then
		_desktop_active || DONT_NOTIFY=1
		if [ ! "${DONT_NOTIFY-}" ] && ! _is_on_path "notify-send"; then
			_warnmsg "notify-send not on PATH. Desktop notifications will not be sent."
			DONT_NOTIFY=1
		fi

		if [ ! "${DONT_NOTIFY-}" ]; then
			if ! notify-send -a "$SCRIPT_NAME" "$STATUS" "$MSG"; then
				_warnmsg "Failed to send desktop notification with content: $MSG. Disabling notifications."
				DONT_NOTIFY=1
			fi
		fi
	fi

	case $STATUS in
	"Error") _errormsg "$MSG" ;;
	"Warning") _warnmsg "$MSG" || exit 1 ;;
	"Success") _msg "Success: $MSG" || exit 1 ;;
	*) _msg "$MSG" || exit 1 ;;
	esac
}

# main
[ "${1-}" ] || _errormsg "Unknown usage."

case "$1" in
"help" | "--help")
	printf "Wrapper around nixos-rebuild that automatically tracks your configuration changes through git.\n"
	printf "Usage: $SCRIPT_NAME [options]\n"

	printf "\nOptions are directly passed to nixos-rebuild.\n"
	printf "to see them use: man nixos-rebuild or 'nixos-rebuild --help'\n"

	printf "\nEnvironment:\n"
	printf "  FLAKE_DIR: Configured by --flake. Defaults to /etc/nixos.\n"
	printf "  ELEVATION_PROGRAM: Configured by --elevate. Defaults to run0.\n"
	printf "  DONT_NOTIFY: Set to any value (example DONT_NOTIFY=1) to prevent notification spam for desktop environments if notify-send is installed.\n"
	printf "  IGNORE_GIT_SYNCHRONIZATION set to any value to disable git synchronization checks.\n"
	exit 0
	;;
"test") NEEDS_PRIVILEGES=1 ;;
"switch" | "boot")
	PERSISTENT=1
	NEEDS_PRIVILEGES=1
	;;
esac

_restore_git_stash() {
	if [ "${GIT_STASHED-}" ]; then
		git stash apply >/dev/null || _notify "Error" "Could not apply git stash. You may have to manually run git stash apply to recover your changes."
		unset GIT_STASHED
		# add applied stash to back to the work tree
		git add . || _notify "Error" "Could not add stashed changes to the working git tree."
	fi
}

_sigint_cleanup() {
	_restore_git_stash
	printf "\nInterrupted" >"$(tty)"
	exit 1
}

trap '_sigint_cleanup' INT

ARG_IDX=1
for arg in "$@"; do
	NEXT_ARG=$(printf "%s " "$@" | cut -d' ' -f$((ARG_IDX + 1)))
	case "$arg" in
	"--flake") FLAKE_DIR="$(readlink -f "$(printf "%s" "$NEXT_ARG" | cut -d'#' -f1)")" ;;
	# TODO if no target host is specified, use a menu with known hosts
	"--target-host")
		TARGET_HOST=$(printf "%s" "$NEXT_ARG" | cut -d'@' -f2)
		[ "${TARGET_HOST-}" ] || _notify "Error" "No target host was specified"
		;;
	"--elevate")
		ELEVATION_PROGRAM="$NEXT_ARG"
		_is_on_path "$ELEVATION_PROGRAM" || _notify "Error" "Elevation program: $ELEVATION_PROGRAM is not on path."
		;;
	"--ask-sudo-password") ELEVATION_PROGRAM="sudo" ;;
	esac
	ARG_IDX=$((ARG_IDX + 1))
done

[ "${FLAKE_DIR-}" ] || FLAKE_DIR="/etc/nixos"
[ -e "$FLAKE_DIR/flake.nix" ] || _notify "Error" "no flake found in $FLAKE_DIR"

cd "$FLAKE_DIR" || _notify "Error" "Could not change working directory to $FLAKE_DIR"

UPDATE_LOG_FILE="$FLAKE_DIR/updates.log"
FLAKE_DIR_OWNER="$(stat -c '%U' -L "$FLAKE_DIR")"
WHOAMI="$(whoami)"

[ "$WHOAMI" = "root" ] && unset NEEDS_PRIVILEGES

# default to run0 due to its integration with polkit
# Note run0 can break in tmux sessions that have DISPLAY or WAYLAND_DISPLAY set while a desktop is not actually active.
[ "${ELEVATION_PROGRAM-}" ] || ELEVATION_PROGRAM="run0"

[ -d "$FLAKE_DIR/.git" ] && GIT_REPO_PRESENT=1

# every time the flake lock updates, commit with git
_commit_flake_lock() {
	if git status | grep -q flake.lock; then
		git add flake.lock || _notify "Error" "Failed to add changes to flake.lock to git."
		git commit -m "update flake.lock" || _notify "Error" "Failed to commit update to flake.lock"
	fi
}

if [ "${GIT_REPO_PRESENT-}" ] && [ ! "${IGNORE_GIT_SYNCHRONIZATION-}" ]; then
	# bail if flake directory is not owned by the current user.
	# TODO I dont really like this behavior in very specific situations but it should be fine for now.
	[ "$WHOAMI" = "$FLAKE_DIR_OWNER" ] || _notify "Error" "$FLAKE_DIR is not owned by the current user invoking $SCRIPT_NAME. Git operations cannot continue safely."
	[ "$(git remote)" ] && REMOTE_PRESENT=1
	[ "${PERSISTENT-}" ] && _commit_flake_lock

	# attempt to pull any changes from your configured remote to ensure that you are up to date locally
	if [ "${REMOTE_PRESENT-}" ]; then
		git ls-remote -q && REMOTE_REACHABLE=1
		git status | grep -q "nothing to commit, working tree clean" || DIRTY_WORKTREE=1
		if [ "${REMOTE_REACHABLE-}" ]; then
			git fetch || _notify "Error" "Failed to fetch repository from configured remote."
			if git status -sb | grep -q "behind"; then
				# stash any local uncommitted changes to allow pulling via rebase
				if [ "${DIRTY_WORKTREE-}" ]; then
					if git stash >/dev/null; then
						GIT_STASHED=1
					else
						_notify "Error" "Failed to stash uncommitted changes in your repo."
					fi
				fi

				if git pull --rebase; then
					_restore_git_stash
				else
					_restore_git_stash
					_notify "Error" "Could not pull with rebase"
				fi
			fi
		else
			_restore_git_stash
			[ "${PERSISTENT-}" ] && _notify "Error" "Git synchronization operations should not fail for persistent changes. Try switching configuration using '$SCRIPT_NAME test' until git issues are resolved."
			y_or_n "Continue without git synchronization features?" || _errormsg "Aborted"
			IGNORE_GIT_SYNCHRONIZATION=1
		fi
	fi

	if [ ! "${IGNORE_GIT_SYNCHRONIZATION-}" ] && [ "${DIRTY_WORKTREE-}" ] && [ "${PERSISTENT-}" ]; then
		SELECTED_OPTION=$(
			printf "Commit (recommended)\nStash\nAbort" |
				fzf \
					--border \
					--border-label-pos=1:bottom \
					--border-label="Detected a dirty worktree. What would you like to do with your uncommitted changes?" \
					--preview="git status"
		)
		case "${SELECTED_OPTION-}" in
		"Commit (recommended)")
			_restore_git_stash
			git status
			printf "Commit Message: "
			read -r COMMIT_MSG
			[ "${COMMIT_MSG-}" ] || _errormsg "No commit message was entered."
			git add . || _errormsg "Could not add changes to git"
			git commit -m "$COMMIT_MSG" || _errormsg "Could not commit these changes to git."
			;;
		"Stash")
			git stash >/dev/null || _errormsg "Could not stash your local changes."
			GIT_STASHED=1
			;;
		*)
			_restore_git_stash
			_errormsg "Aborted"
			;;
		esac
	fi
fi

[ "${TARGET_HOST-}" ] || TARGET_HOST="$(cat /etc/hostname)"
[ "${TARGET_HOST-}" ] || _notify "Error" "Failed to retrieve hostname from /etc/hostname."

XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-"/run/user/$(id -u)"}"
SCRIPT_RUNTIME_DIR="$XDG_RUNTIME_DIR/$SCRIPT_NAME"
mkdir -p "$SCRIPT_RUNTIME_DIR" || _notify "Error" "Failed to create temporary configuration directory."

case "$1" in
"switch" | "test" | "boot")
	cd "$SCRIPT_RUNTIME_DIR" || _notify "Error" "Failed to change the working directory to $SCRIPT_RUNTIME_DIR."
	# build the system and use nix-output-monitor to make the build output prettier
	# note: pipefail must be set for this to work properly
	2>&1 nixos-rebuild build --flake "$FLAKE_DIR#$TARGET_HOST" | nom || _notify "Error" "System failed to build."
	# use nvd to get the difference between the current system and the system that was just built.
	# The user can review the configuration differences before authenticating the activation
	CURRENT_GENERATION_NUMBER="$(nixos-rebuild list-generations | grep -v "Generation" | head --lines 1 | cut -d' ' -f1)"
	[ "${CURRENT_GENERATION_NUMBER-}" ] || _notify "Error" "Failed to obtain the current generation number."

	# TODO figure out how to get color output.
	NVD_DIFF="$(nvd diff /nix/var/nix/profiles/system-"$CURRENT_GENERATION_NUMBER"-link result)"
	printf "%s\n\n" "$NVD_DIFF"
	[ "${NVD_DIFF-}" ] || _notify "Error" "Failed to retrieve the nvd diff for this generation."

	cd "$FLAKE_DIR" || _notify "Error" "Failed to return working directory to $FLAKE_DIR"

	_notify "Success" "Nixos system build is complete. Review the changes and authenticate to continue."
	y_or_n "Continue?" || _errormsg "Aborted"
	;;
esac

if [ "${NEEDS_PRIVILEGES-}" ]; then
	$ELEVATION_PROGRAM nixos-rebuild "$@" || _notify "Error" "nixos-rebuild exited with errors"
else
	nixos-rebuild "$@" || _notify "Error" "nixos-rebuild exited with errors"
fi

if [ "${PERSISTENT-}" ]; then
	[ "${GIT_REPO_PRESENT-}" ] && _commit_flake_lock
	if [ ! -e "$UPDATE_LOG_FILE" ]; then
		touch "$UPDATE_LOG_FILE" >/dev/null 2>&1 || $ELEVATION_PROGRAM touch "$UPDATE_LOG_FILE"
	fi

	NIXOS_GENERATION_INFO=$(nixos-rebuild list-generations | grep True | tr -s ' ' | cut -d' ' -f1-5)
	GENERATION=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f1)
	TIMESTAMP=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f2-3)
	KERNEL_VERSION=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f5)

	PREVIOUS_GENERATION="$(nixos-rebuild list-generations | grep -v -e 'True' -e 'Generation' | cut -d' ' -f1 | head --lines 1)"
	LOG=1
	[ "${GENERATION-}" = "${PREVIOUS_GENERATION-}" ] && unset LOG

	if [ "${LOG-}" ]; then
		TMP_LOGFILE="$SCRIPT_RUNTIME_DIR/system-update.log"
		UPDATE_MSG="$(
			printf "%s\nHost: %s\nKernel - %s\n%s\n" \
				"$TIMESTAMP" "$TARGET_HOST" "$KERNEL_VERSION" "$NVD_DIFF"
		)"
		printf "%s\n\n" "$UPDATE_MSG" | cat - "$UPDATE_LOG_FILE" >"$TMP_LOGFILE" || _notify "Error" "Could not write to temporary log file $TMP_LOGFILE"
		if [ "$WHOAMI" = "$FLAKE_DIR_OWNER" ]; then
			mv "$TMP_LOGFILE" "$UPDATE_LOG_FILE" || _notify "Error" "Could not move $TMP_LOGFILE to $UPDATE_LOG_FILE"
		else
			$ELEVATION_PROGRAM mv "$TMP_LOGFILE" "$UPDATE_LOG_FILE" || _notify "Error" "Could not move updates.log into place"
		fi

		if [ ! "${IGNORE_GIT_SYNCHRONIZATION-}" ] && [ "${GIT_REPO_PRESENT-}" ]; then
			if ! git add .; then
				_restore_git_stash
				_notify "Error" "could not stage changes to the updates.log"
			fi

			if ! git commit -m "Updated: $TARGET_HOST"; then
				_restore_git_stash
				_notify "Error" "Could not commit update to git"
			fi

			if [ "${REMOTE_REACHABLE-}" ]; then
				if ! git push; then
					_restore_git_stash
					_notify "Error" "Could not push update to remote repository"
				fi
			fi

			[ "${GIT_STASHED-}" ] && _restore_git_stash
		fi
	fi
fi

exit 0
