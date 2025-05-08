# vscode\_container

Helper scripts to run one `code-server` container per project using rootless Podman. Each project gets its own isolated environment.

The setup is minimal but functional.

## What This Does

[`code-server`](https://github.com/coder/code-server) is an open source version of Visual Studio Code that runs in a browser. It can be containerized and run securely.

This project wraps `code-server` in a dedicated container per project, using rootless Podman. Each container:

* Has access only to one specific project folder
* Runs as a separate system user (`codeserver`) for strict isolation
* Can optionally have its own `.config` and `.local` (via `--isolated` mode)
* Is launched via a `.desktop` file using a lightweight WebView frontend

This setup prioritizes both usability and security:

* Your host system stays clean—no global installs, no shared processes
* Every project has its own sandboxed dev environment
* Code-server runs as a separate user, meaning even if compromised, it can't affect your session

## Why

* Microsoft’s Dev Container is proprietary
* DevPod is open source but doesn't integrate well with Flatpak, `bwrap`, or nested container scenarios
* This solution is simple, minimal, and works with standard Linux tools (Podman, bash, sudo)

---

# Setup

## Setup

1. Install Podman:

```
sudo apt install podman
```

2. Run or follow the installation script

```
curl -fsSL https://raw.githubusercontent.com/Alogani/vscode_container/main/setup.sh > /tmp/setup.sh
sudo bash /tmp/setup.sh
```


# Usage

## Command Line

You can manage containers with:

```
Global flags:
  --isolated               copy $APP_DIR/local and $APP_DIR/config into each container dir
  --custom-image IMAGE     override default code-server image

Commands:
  create   <name>         create a new container and desktop app
  clone    <src>  [dst]   clone an existing container
  exec     <name> <cmd>   run command as root (/bin/sh to get a shell)
  launch   [name]         run as gui inside a webview.
                          Will be closed with the webview.
			  If name is not provided, use a popup
  mount    <name> <src> [dst] [-- ...]  mount using bindfs with uid mapping 
  umount   <name> <dst>
  refresh  <name>         recreate a container but keep the config files
  remove   <name>         remove with all its configuration
  start    <name>         start in the background without gui
  stop     <name>         stop the background container
  list                    list all containers
  podman [-- ...]         pass through to podman, use -- before arguments
```

In practice, you'll mostly use:

* **Create a new container** (with optional isolation):

  ```
  vscode_container create myproject [--isolated]
  ```

* **Remove a container** when you're done:

  ```
  vscode_container remove myproject
  ```

  ⚠️ **Warning:** This will permanently delete the container **and all associated files**, including the project directory, and if isolated, configs, and local data. Make backups (or commit) if needed before running this.

Once created, just launch your project from the auto-generated desktop icon—no need to return to the terminal for day-to-day use.

---

## Directory Mapping

Container-to-host folder mapping looks like this:

| Inside Container     | Host Path                                           |
| -------------------- | --------------------------------------------------- |
| `project`            | `/opt/vscode_container/containers/<name>/project`   |
| `.config` (default)  | `/opt/vscode_container/config`                      |
| `.config` (isolated) | `/opt/vscode_container/containers/<name>/config`    |
| `.local` (default)   | `/opt/vscode_container/local`                       |
| `.local` (isolated)  | `/opt/vscode_container/containers/<name>/local`     |

When using `--isolated`, the container gets its own copies of the default config and local dirs.
