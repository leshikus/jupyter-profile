FROM python:3.9-bullseye as python_builder

WORKDIR /app

RUN set -ex; \
    git clone https://github.com/dirkcgrunwald/jupyter_codeserver_proxy-.git; \
    cd jupyter_codeserver_proxy-; \
    make build-package

FROM ubuntu:22.04
ENV USER=jovyan
ENV HOME=/home/${USER}
ENV SHELL=/bin/bash

COPY --chown=${USER}:${USER} requirements.txt /tmp/requirements.txt
COPY --from=python_builder --chown=${USER}:${USER} /app/jupyter_codeserver_proxy-/dist/*.whl /opt/jupyter_codeserver_proxy/dist/

# install all dependencies
# disable JupyterLab announcement pop-up (https://jupyterlab.readthedocs.io/en/stable/user/announcements.html)
RUN pip install --no-cache-dir -r /tmp/requirements.txt /opt/jupyter_codeserver_proxy/dist/*.whl infractl; \
    jupyter labextension disable "@jupyterlab/apputils-extension:announcements"

RUN set -ex; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update -y; \
    apt-get install -y software-properties-common curl; \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg > /usr/share/keyrings/githubcli-archive-keyring.gpg; \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update -y; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gh jq \
        git \
        bash-completion \
        cmake gcc g++ ninja-build git clang-format \
        sudo \
        pixz \
        ; \
    rm -rf /var/lib/apt/lists/*

RUN set -ex; \
    adduser \
        --disabled-password \
        --gecos "Default user" \
        --uid 1000 \
        --home ${HOME} \
        --force-badname \
        ${USER}; \
    usermod -aG sudo ${USER}; \
    echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers

COPY entrypoint.sh /template/

USER ${USER}

WORKDIR ${HOME}

RUN curl -fsSL https://code-server.dev/install.sh | sh && rm -rf "${HOME}/.cache"

EXPOSE 8888

ENTRYPOINT ["/bin/bash", "/template/entrypoint.sh"]

