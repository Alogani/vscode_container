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

## Prerequisites

Install Podman:

```
sudo apt install podman
```

## Install Required Files

- Create the main folders:

  ```
  sudo mkdir -p /opt/vscode_container/config
  sudo mkdir -p /opt/vscode_container/local
  ```

- Add a custom icon of your choice to:

  ```
  /opt/vscode_container/icon.png
  ```

  For instance, a popular black-themed VSCodium icon shared by the community is shipped in the repo (but not owned by me) and can be found here:
  https://www.reddit.com/r/vsCodium/comments/q5trq1/vscodium_black_icon
   _Note: This icon does not have an identified license._

- Install the scripts:

  * `webview.py` → `/usr/local/bin/`
  * `vscode_container` → `/usr/local/bin/`

## Create a Dedicated User

Create a system user to run containers:

```
sudo adduser codeserver
```

Grant your user passwordless access to run things as `codeserver`. Run:

```
sudo visudo
```

And add:

```
<your_username> ALL=(codeserver) NOPASSWD: ALL
```

Set ownership on the base folder:

```
sudo chown -R codeserver /opt/vscode_container
```

---

# Usage

## Command Line

Absolutely. Here's the revised **Command Line** section with both commonly used commands highlighted and the wording tightened up:

---

## Command Line

Good call—here’s the updated **Command Line** section with a clear warning added for `remove`:

---

## Command Line

You can manage containers with:

```
vscode_container [--isolated] [--custom-image IMAGE] <command> <args>

Global flags:
  --isolated               copy $CONFIGS/local and $CONFIGS/config into each container dir
  --custom-image IMAGE     override default code-server image

Commands:
  create   <name>         create a new container and desktop app
  clone    <src>  [dst]   clone an existing container
  exec     <name> <cmd>   run command as root inside container (/bin/sh to get a shell)
  launch   <name>         run as gui inside a webview.
                          Will be closed with the webview
  mount    <name> <src> [dst] [...]  mount using bindfs with uid mapping 
  umount   <name> <dst>
  refresh  <name>         recreate a container but keep the config files
  remove   <name>         remove with all its configuration
  start    <name>         start in the background without gui
  stop     <name>         stop the background container
  list                    list all containers
  podman   [...]          pass through to podman
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

## Desktop Launcher

Each project gets a `.desktop` launcher with a simple embedded WebView for code-server:

![image](https://github.com/user-attachments/assets/8e9d6444-2a46-4d38-8d2c-94d00330ea58)


---

## Directory Mapping

Container-to-host folder mapping looks like this:

| Inside Container     | Host Path                                 |
| -------------------- | ----------------------------------------- |
| `project`            | `/opt/vscode_container/CONTAINER/project` |
| `.config` (default)  | `/opt/vscode_container/config`            |
| `.config` (isolated) | `/opt/vscode_container/CONTAINER/config`  |
| `.local` (default)   | `/opt/vscode_container/local`             |
| `.local` (isolated)  | `/opt/vscode_container/CONTAINER/local`   |

When using `--isolated`, the container gets its own copies of the default config and local dirs.
