# VSCode container

A lightweight, sandboxed wrapper around `podman` for running [code-server](https://github.com/coder/code-server) containers with isolated environments.
This script enables easy management of per-project VSCode containers, complete with GUI access through a minimal webview.

---

## 🧭 Overview

`vscode_container` is a shell-based tool to create and manage rootless containers using `podman`, running [code-server](https://hub.docker.com/r/codercom/code-server) inside each container for isolated, sandboxed VSCode sessions.

Each container behaves like its own development environment — fully isolated by default, with optional shared configuration directories or external volume mounts.

---

## 🚀 Features

* **Wrapper around `podman`**, leveraging rootless containers for safety and separation.
* **No modified images** – uses the official, unmodified `codercom/code-server` Docker image.
* **Runs as a dedicated unprivileged user** (`codeserver`) for additional security.
* **No access to the host network**, no `$HOME` sharing — enforces strong sandboxing boundaries.
* **Supports both shared and isolated config/local directories** (`~/.config`, `~/.local`) depending on your workflow.
* **Per-project isolation** — containers are mapped to project-specific directories.
* **CLI-first**, no YAML, no JSON, no abstraction.
* **Simple, minimal**, built on standard Linux tools: `python`, `bash` and `podman`.
* **GUI launcher** — starts a lightweight Python-based webview to connect to code-server over a local port.

---

## 📁 Directory Layout

Each container lives under `/opt/vscode_container/containers/<name>`:

```
project/       ← Your working directory
shared/        ← Bind-mounted resources, optional
config/        ← ~/.config inside the container (linked or copied)
local/         ← ~/.local inside the container (linked or copied)
```

Depending on the `--isolated` flag, `config/` and `local/` are either:

* **Linked** to global shared directories, or
* **Copied** into the container directory for complete separation (only at creation).

---

## 🧠 Why This Exists

### The Alternatives Fall Short:

* **Microsoft Dev Containers** is proprietary.
* **DevPod** is open-source but fails to integrate well with Flatpak, Bubblewrap, or nonstandard sandbox environments.

### This project:

* Works everywhere `podman` and `bash` work.
* Offers dead-simple integration into custom workflows.
* Keeps your system clean and predictable, with **no daemon**, **no Docker**, **no root access**.

---

## 🔒 Security & Sandboxing

* Containers are started **rootless** as the `codeserver` user.
* No host networking.
* No access to your `$HOME` directory.
* Optional `bindfs` volume mounting with UID/GID mapping for secure external access.

This makes it ideal for high-assurance workflows, development on shared systems, or integrating into containerized desktop environments.

---

## 🖥️ Requirements

* `podman`
* `sudo`
* `git`
* Python + Gtk/WebKit (for GUI launcher)
* `bindfs` (for volume mounting)


---

## 🧪 Example

```bash
# Create a new isolated container
vscode_container --isolated create myproject

# Mount a local folder into it
vscode_container mount myproject ~/dev/stuff code

# Launch the GUI using the command line (or you can use the launcher)
vscode_container launch myproject

# Delete completely the project and all its files
vscode_container remove myproject
```

---

# Setup

1. Install Podman and git:

```
sudo apt install podman git
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

Once created, just launch your project using the desktop icon—no need to return to the terminal for day-to-day use.

---

## Directory Mapping

Here is the list of folders shared with the host:

| Inside Container           | Host Path                                           |
| -------------------------- | --------------------------------------------------- |
| `$HOME/project`            | `/opt/vscode_container/containers/<name>/project`   |
| `$HOME/shared`             | `/opt/vscode_container/containers/<name>/shared` (empty by default)   |
| `$HOME/.config` (default)  | `/opt/vscode_container/config`                      |
| `$HOME/.config` (isolated) | `/opt/vscode_container/containers/<name>/config`    |
| `$HOME/.local`  (default)  | `/opt/vscode_container/local`                       |
| `$HOME/.local`  (isolated) | `/opt/vscode_container/containers/<name>/local`     |

### Mounting with `bindfs`

* **Mounts work only if `bindfs` is installed**. When mounting external directories into the container using the `mount` command, the `bindfs` tool will be used to ensure secure access by mapping the UID and GID of the `codeserver` user in the container to the corresponding values on the host system.

* All mounts are placed inside the **`shared/`** directory in the container, under `/opt/vscode_container/containers/<name>/shared`.
