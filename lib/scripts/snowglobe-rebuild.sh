# wrapper around nixos-rebuild, ensuring configurations are automaically logged and commited to git
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

_exitmsg() {
	_msg "$1"
	exit 0
}

_desktop_active() {
	[ "$XDG_CURRENT_DESKTOP" ] || [ "$DISPLAY" ] || [ "$WAYLAND_DISPLAY" ]
}

_is_on_path() {
	command -v "$1" >/dev/null 2>&1
}

_notify() {
	STATUS="$1"
	MSG="$2"

	_desktop_active && ENABLE_NOTIFICATIONS=1
	if [ ${ENABLE_NOTIFICATIONS+x} ] && ! _is_on_path "notify-send"; then
		_warnmsg "notify-send not on PATH. Desktop notifications will not be sent."
		unset ENABLE_NOTIFICATIONS
	fi

	if [ ${ENABLE_NOTIFICATIONS+x} ]; then
		notify-send -a "$SCRIPT_NAME" "$STATUS" "$MSG" || _warnmsg "Failed to send desktop notification with content: $MSG"
	fi

	case $STATUS in
	"Error") _errormsg "$MSG" ;;
	"Warning") _warnmsg "$MSG" || exit 1 ;;
	"Success") _msg "Success: $MSG" || exit 1 ;;
	*) _msg "$MSG" || exit 1 ;;
	esac
}

# main
[ "$1" ] || _errormsg "Unknown usage."

case "$1" in
# TODO implement configuration via nixos module
"help" | "--help")
	printf "Wrapper around nh os and nixos-rebuild.\n"
	printf "usage: snowglobe-rebuild [options]\n\n"

	printf "Options are directly passed to one of the two programs.\n"
	printf "For commands that use can 'nh os' (boot, switch, test, repl, etc) use man nh to see options.\n"
	printf "For others use man nixos-rebuild or 'nixos-rebuild --help'\n"
	exit 0
	;;
"test")
	NEEDS_SUDO=1
	CAN_USE_NH_OS=1
	;;
"switch" | "boot")
	PERSISTENT=1
	NEEDS_SUDO=1
	CAN_USE_NH_OS=1
	;;
"info" | "rollback")
	CAN_USE_NH_OS=1
	;;
*) ;;
esac

ARG_IDX=1
for arg in "$@"; do
	NEXT_ARG=$(printf "%s " "$@" | cut -d' ' -f$((ARG_IDX + 1)))
	case "$arg" in
	"--flake") FLAKE_DIR="$(readlink -f "$(printf "%s" "$NEXT_ARG" | cut -d'#' -f1)")" ;;
	# TODO if no target host is specified, use a menu with known hosts
	# Also nh os and nixos-rebuild have different elevation strategy command syntax
	"--target-host")
		TARGET_HOST=$(printf "%s" "$NEXT_ARG" | cut -d'@' -f2)
		[ "$TARGET_HOST" ] || _errormsg "No target host was specified"
		;;
	esac
	ARG_IDX=$((ARG_IDX + 1))
done

[ "$FLAKE_DIR" ] || FLAKE_DIR="/etc/nixos"
[ -e "$FLAKE_DIR/flake.nix" ] || _errormsg "no flake found $FLAKE_DIR"

FLAKE_DIR_OWNER=$(stat -c '%U' -L "$FLAKE_DIR")
WHOAMI="$(whoami)"

if [ "$WHOAMI" = "root" ]; then
	unset CAN_USE_NH_OS
	unset NEEDS_SUDO
fi

if ! _is_on_path "nh" && [ ${CAN_USE_NH_OS+x} ]; then
	unset CAN_USE_NH_OS
fi

cd "$FLAKE_DIR" || _errormsg "Could not change working directory to $FLAKE_DIR"

[ -d "$FLAKE_DIR/.git" ] && GIT_REPO_PRESENT=1

_restore_git_stash() {
	if [ "$GIT_STASHED" ]; then
		git stash apply >/dev/null || _errormsg "Could not apply git stash. You may have to manually run git stash apply to recover your changes."
		unset GIT_STASHED
		# add applied stash to back to the work tree
		git add .
	fi
}

if [ "$GIT_REPO_PRESENT" ]; then
	[ "$WHOAMI" = "$FLAKE_DIR_OWNER" ] || _errormsg "$FLAKE_DIR is not owned by the current user. Git operations cannot continue safely."
	[ "$(git remote)" ] && REMOTE_PRESENT=1

	# attempt to pull any changes from your configured remote to ensure that you are up to date locally
	if [ "$REMOTE_PRESENT" ]; then
		git ls-remote -q && REMOTE_REACHABLE=1
		! git status | grep -q "nothing to commit, working tree clean" && DIRTY_WORKTREE=1
		if [ "$REMOTE_REACHABLE" ]; then
			git fetch || _errormsg "Failed to fetch from remote."
			# pull with rebase if your local is behind your remote
			if git status -sb | grep -q "behind"; then
				# stash any local uncommitted changes to allow pulling via rebase
				if [ "$DIRTY_WORKTREE" ]; then
					if git stash >/dev/null; then
						GIT_STASHED=1
					else
						_errormsg "Failed to stash uncommitted changes in your repo."
					fi
				fi

				if git pull --rebase; then
					_restore_git_stash
				else
					_errormsg "Could not pull with rebase"
				fi
			fi
		else
			_restore_git_stash
			[ "$PERSISTENT" ] && _errormsg "Git synchronization operations should not fail for persistent changes. Try with 'test' until issues are resolved."
			y_or_n "Continue without git synchronization features?" || _errormsg "Aborted"
			IGNORE_GIT_SYNCHRONIZATION=1
		fi

		if [ ! ${IGNORE_GIT_SYNCHRONIZATION+x} ] && [ "$DIRTY_WORKTREE" ] && [ "$PERSISTENT" ]; then
			SELECTED_OPTION=$(
				printf "Commit (recommended)\nStash\nAbort" |
					fzf \
						--border \
						--border-label-pos=1:bottom \
						--border-label="Detected a dirty worktree. What would you like to do with your uncommitted changes?" \
						--preview="git status"
			)
			case "$SELECTED_OPTION" in
			"Commit (recommended)")
				_restore_git_stash
				git status
				printf "Commit Message: "
				read -r COMMIT_MSG
				[ "$COMMIT_MSG" ] || _errormsg "No commit message was entered."
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
fi

ERRORMSG="Rebuild failed or timeout reached."
if [ "$NEEDS_SUDO" ] && [ ! ${CAN_USE_NH_OS+x} ]; then
	sudo nixos-rebuild "$@" || _notify "Error" "$ERRORMSG"
elif [ ${CAN_USE_NH_OS+x} ]; then
	NH_OS_FLAKE="$(readlink -f "$FLAKE_DIR")" export NH_OS_FLAKE
	nh os "$@" || _notify "Error" "$ERRORMSG"
else
	nixos-rebuild "$@" || _notify "Error" "$ERRORMSG"
fi

if [ "$PERSISTENT" ]; then
	# check if the flake was updated by args passed to nh or nixos-rebuild and commit it
	if git status | grep -q flake.lock; then
		git add . || _errormsg "Failed to add changes to flake.lock to git."
		git commit -m "update flake.lock" || _errormsg "Failed to commit update to flake.lock"
	fi

	# keep a log file of your system updates
	UPDATE_LOG="$FLAKE_DIR/updates.log"
	[ "$TARGET_HOST" ] || TARGET_HOST="$(cat /etc/hostname)"
	if [ ! -e "$UPDATE_LOG" ]; then
		# sudo use should already be cached from nixos-rebuild or nh os
		touch "$UPDATE_LOG" >/dev/null 2>&1 || sudo touch "$UPDATE_LOG"
	fi

	NIXOS_GENERATION_INFO=$(nixos-rebuild list-generations | grep True | tr -s ' ' | cut -d' ' -f1-5)
	GENERATION=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f1)
	TIMESTAMP=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f2-3)
	KERNEL_VERSION=$(printf "%s" "$NIXOS_GENERATION_INFO" | cut -d' ' -f5)

	PREVIOUS_GENERATION="$(nixos-rebuild list-generations | grep -v -e 'True' -e 'Generation' | cut -d' ' -f1 | head --lines 1)"
	[ "$PREVIOUS_GENERATION" ] || _errormsg "Could not obtain the previous generation number."
	LOG=1
	[ "$GENERATION" = "$PREVIOUS_GENERATION" ] && unset LOG

	if [ ${LOG+x} ]; then
		UPDATE_MSG="$(
			printf "%s\n%s
Kernel - %s%s\n" \
				"$TARGET_HOST" "$TIMESTAMP" "$KERNEL_VERSION" "$(nvd history -m "$PREVIOUS_GENERATION" | grep -v 'Contents of profile version')"
		)"
		printf "%s\n\n" "$UPDATE_MSG" | cat - "$UPDATE_LOG" >/tmp/snowglobe-system-update.log
		if [ "$(whoami)" = "$FLAKE_DIR_OWNER" ]; then
			mv /tmp/snowglobe-system-update.log "$FLAKE_DIR/updates.log" || _errormsg "Could not move updates.log into place"
		else
			sudo mv /tmp/snowglobe-system-update.log "$FLAKE_DIR/updates.log" || _errormsg "Could not move updates.log into place"
		fi

		if [ ! ${IGNORE_GIT_SYNCHRONIZATION+x} ] && [ ${GIT_REPO_PRESENT+x} ]; then
			git add . || {
				_restore_git_stash
				_errormsg "could not stage changes to the updates.log"
			}

			COMMIT_MSG="Updated: $TARGET_HOST"

			git commit -m "$COMMIT_MSG" || {
				_restore_git_stash
				_errormsg "Could not commit update to git"
			}

			if [ "$REMOTE_REACHABLE" ]; then
				git push || {
					_restore_git_stash
					_errormsg "Could not push update to remote repository"
				}
			fi

			[ "$GIT_STASHED" ] && _restore_git_stash
		fi
	fi
fi
