# vscode_container
Helper scripts to create one container instance by project using code-server

The goal is to create:
- create one container instance of code-server https://github.com/coder/code-server by project
- this container will have limited access to host, only to one project
- by default, configuration are shared but --isolation flag make them independent
- a .desktop launcher is created for each container and use a siple webview

setup and cli are not polished but works fine.

# Setup of vscode_container

## Install prerequisites

- Install podman `apt install podman`
- create a dedicated user `adduser code-server`
- Install webview.py in /usr/local/bin
- Install vscode_container.sh in /usr/local/bin
- Create /opt/vscode_container, /opt/vscode_container/config, /opt/vscode_container/local
- chown -R code-server /opt/vscode_container

## Grant you access to the code-server user

$ visudo
`<myuser> ALL=(code-server) NOPASSWD: ALL`
