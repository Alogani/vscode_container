#!/bin/sh
set -e

APP_NAME="org.alogani.vscode_container"
TARGET_USER="codeserver"
APP_DIR="/opt/vscode_container"
CONTAINERS="$APP_DIR/containers"
BIN="/usr/local/bin/vscode_container"
ICON="$APP_DIR/icon.png"
# default image
IMAGE="docker.io/codercom/code-server:latest"
CUSTOM_IMAGE="false"

usage() {
  cat <<EOF
Usage: $0 [--isolated] [--custom-image IMAGE] <command> <args>

Global flags:
  --isolated               copy $APP_DIR/local and $APP_DIR/config at creation
  --custom-image IMAGE     override default code-server image

Commands:
  create   <name>         create a new container and desktop app
  clone    <src>  [dst]   clone an existing container
  exec     <name> <cmd>   run command as root (/bin/sh to get a shell)
  launch   [name]         run as gui inside a webview.
                          The container will stop when the webview closes.
			  If name is not provided, use a popup
  mount    <name> <src> [dst] [-- ...]  mount using bindfs with uid mapping 
  umount   <name> <dst>
  refresh  <name>         recreate a container but keep the config files
  remove   <name>         remove with all its configuration
  start    <name>         start in the background without gui
  stop     <name>         stop the background container
  list                    list all containers
  podman [-- ...]         pass through to podman, use -- before arguments
EOF
  exit 1
}

#––– parse global flags –––#
OPTS=$(getopt -o '' --long isolated,custom-image: -n 'vscode_container' -- "$@")
[ $? -eq 0 ] || usage
eval set -- "$OPTS"

ISOLATED="false"
while true; do
  case "$1" in
    --isolated)    ISOLATED="true"; shift ;;
    --custom-image) IMAGE="$2"; CUSTOM_IMAGE="true"; shift 2 ;;
    --)            shift; break ;;
    *)             usage ;;
  esac
done

# now $1 is the command, $2... are its args
COMMAND="$1"; shift || true

#––– common helpers –––#
require() { [ -n "$1" ] || { echo "Error: missing argument"; exit 1; }; }

su_codeserver() {
    sudo -u "$TARGET_USER" --login "$@"
}

# prepare the directory structure (but never rm -rf it!)
setup_dirs() {
  NAME="$1"
  D="$CONTAINERS/$NAME"
  su_codeserver mkdir -p "$D/project"
  mkdir -p "$D/shared"
  chown ":$TARGET_USER" "$D/shared"
  chmod 750 "$D/shared"
  if [ "$ISOLATED" = "true" ]; then
    su_codeserver cp -a "$APP_DIR/local" "$D/local"
    su_codeserver cp -a "$APP_DIR/config" "$D/config"
  else
    su_codeserver ln -sf "$APP_DIR/local"  "$D/local"
    su_codeserver ln -sf "$APP_DIR/config" "$D/config"
  fi
}

# action = "run" | "create", name = container name
new_container() {
  ACTION="$1"; NAME="$2"
  D="$CONTAINERS/$NAME"
  [ "$ACTION" = "create" ] && CMD="podman create" || CMD="podman run -d"
  su_codeserver $CMD --name "$NAME" \
    -p 127.0.0.1::8080 \
    -v "$D/local:/home/coder/.local" \
    -v "$D/config:/home/coder/.config" \
    -v "$D/project:/home/coder/project" \
    -v "$D/shared:/home/coder/shared:rshared" \
    -e "DOCKER_USER=$TARGET_USER" \
    -u "$(id -u $TARGET_USER):$(id -g $TARGET_USER)" \
    --userns=keep-id \
    $IMAGE
}

reapply_mounts() {
  NAME="$1"
  MFILE="$CONTAINERS/$NAME/mounts"
  [ -f "$MFILE" ] || return 0
  while IFS='|' read -r SRC ALIAS OPTS; do
    DST="$CONTAINERS/$NAME/shared/$ALIAS"
    mkdir -p "$DST"
    if ! mountpoint -q "$DST"; then
      # re-bindfs with saved options
      eval bindfs -u "$(id -u $TARGET_USER)" -g "$(id -g $TARGET_USER)" $OPTS "$SRC" "$DST"
      echo "Re-mounted $SRC → $DST"
    fi
  done < "$MFILE"
}

#––– commands –––#
case "$COMMAND" in

  create)
    NAME="$1"; require "$NAME"
    setup_dirs   "$NAME"
    new_container run "$NAME"
    su_codeserver podman stop "$NAME"
    echo "Config at $CONTAINERS/$NAME/config/code-server/config.yaml:"
    su_codeserver cat "$CONTAINERS/$NAME/config/code-server/config.yaml"
    ;;

  clone)
    SRC="$1"; require "$SRC"
    DST="${2:-${SRC}_clone}"
    # fail if dst already exists
    if su_codeserver podman container exists "$DST" 2>/dev/null; then
      echo "Error: target container '$DST' already exists." >&2
      exit 1
    fi
    cp -ra "$CONTAINERS/$SRC" "$CONTAINERS/$DST"
    new_container create "$DST"
    echo "Cloned '$SRC' → '$DST'"
    ;;

  exec)
    NAME="$1"; require "$NAME"; shift
    CMD=$@; require "$CMD"
    su_codeserver podman exec -u 0 -it "$NAME" $CMD
    ;;

  launch)
    NAME="$1"
    if [ -z "$NAME" ]; then
      containers=$(ls "$CONTAINERS")
      NAME=$("$APP_DIR/src/combobox.py" "VSCode container" "Select a VSCode Environment:" $containers)
      if [ $? -ne 0 ]; then
        exit $?
      fi
    fi
    reapply_mounts "$NAME"
    su_codeserver podman start "$NAME" >/dev/null
    PORT=$(su_codeserver podman port "$NAME" | awk -F: '{print $2}')
    "$APP_DIR/src/webview.py" "$APP_NAME" "$NAME" "$PORT"
    su_codeserver podman stop "$NAME"
    ;;

  mount)
    NAME="$1"; require "$NAME"; shift
    SRC="$1"; require "$SRC"; shift
    FULL_PATH="$(realpath $SRC)"

    # Determine alias path
    case "$1" in
      -*) ALIAS="$(basename "$SRC")" ;;
      "") ALIAS="$(basename "$SRC")" ;;
      *)  ALIAS="$1"; shift ;;
    esac

    DST="$CONTAINERS/$NAME/shared/$ALIAS"

    # Collect options into a list (positional parameters)
    OPTS=""
    while [ $# -gt 0 ] && echo "$1" | grep -q '^-'; do
      OPTS="$OPTS \"$1\""
      shift
    done

    mkdir -p "$DST"
    echo "$FULL_PATH|$ALIAS|$OPTS" >> "$CONTAINERS/$NAME/mounts"
    bindfs -u $(id -u $TARGET_USER) -g $(id -g $TARGET_USER) \
       $OPTS "$FULL_PATH" "$DST"

    echo "Mounted $FULL_PATH → $DST"
    ;;
  
  umount)
    NAME="$1"; require "$NAME"
    DST="$CONTAINERS/$NAME/shared/$2"; require "$DST"
    fusermount -u "$DST" 
    rmdir "$DST"
    MFILE="$CONTAINERS/$NAME/mounts"
    grep -v "|$2|" "$MFILE" > "$MFILE.tmp" && mv "$MFILE.tmp" "$MFILE"
    ;;

  refresh)
    NAME="$1"; require "$NAME"
    echo "Inspecting current container image..."
    if [ $CUSTOM_IMAGE = "false" ]; then
      IMAGE=$(su_codeserver podman inspect "$NAME" --format '{{.Config.Image}}')
    fi
    echo "Removing old container..."
    su_codeserver podman rm -f "$NAME"
    echo "Re-creating container with image '$IMAGE' (preserving $CONTAINERS/$NAME)…"
    new_container run "$NAME"
    su_codeserver podman stop "$NAME"
    echo "Refreshed '$NAME'."
    ;;

  remove)
    NAME="$1"; require "$NAME"
    su_codeserver podman rm -f "$NAME"
    su_codeserver rm -rf "$CONTAINERS/$NAME"
    ;;

  start)
    NAME="$1"; require "$NAME"
    reapply_mounts "$NAME"
    su_codeserver podman start "$NAME"
    PORT=$(su_codeserver podman port "$NAME" | awk -F: '{print $2}')
    echo "Listening on port $PORT"
    ;;

  stop)
    NAME="$1"; require "$NAME"
    su_codeserver podman stop "$NAME"
    ;;

  list)
    su_codeserver podman ps --all
    ;;

  podman)
    # pass everything to podman
    su_codeserver podman $@
    ;;

  *)
    usage
    ;;
esac

