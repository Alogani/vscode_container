# vscode_container
Helper scripts to create one container instance by project using code-server

setup and cli are not polished but works fine.

## Goals

- create one container instance of code-server https://github.com/coder/code-server by project
- this container will have limited access to host, only to one project
- by default, configuration are shared but --isolation flag make them independent
- a .desktop launcher is created for each container and use a siple webview

## Why
- Microsoft's Dev Container is not open source
- DevPod is open source but I can't make it work nicely using flatpak, bwrap or a container

# Setup of vscode_container

## Install prerequisites

- Have podman `apt install podman`

## Add necessary files and dependencies
- Create /opt/vscode_container, /opt/vscode_container/config, /opt/vscode_container/local
- Install webview.py in /usr/local/bin
- Install vscode_container.sh in /usr/local/bin

## Create a dedicated user and grant yourself access
- should be named codeserver`adduser codeserver`
- $ visudo
`<myuser> ALL=(code-server) NOPASSWD: ALL`
- chown -R code-server /opt/vscode_container

## Have fun

### With the command line
```sh
$ vscode_container.sh
Usage: /usr/local/bin/vscode_container.sh <create|launch|start|stop|remove|list> [container_name] [--isolated]
```

### With the launcher
![image](https://github.com/user-attachments/assets/8dd314fd-cbac-47d1-b97b-65946b8b148a)
