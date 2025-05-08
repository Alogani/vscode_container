FROM docker.io/codercom/code-server:latest

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

USER coder
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/coder/.cargo/bin:${PATH}"
RUN rustup component add clippy rustfmt

ENTRYPOINT ["/usr/bin/entrypoint.sh", "--bind-addr", "0.0.0.0:8080", "."]
