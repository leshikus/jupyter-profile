#!/bin/bash

set -e
set -vx

jupyterlab_env="base"
kernel_env="python-3.9"

# Fix the owner and permissions for /home/jovyan
# TODO: check if passwordless sudo is enabled
sudo chmod 00700 /home/jovyan

cd ~

rm -rf $HOME/.conda

if [[ ! -f ~/.jupyter/jupyter_config.json ]]; then
  echo "no .jupyter/jupyter_config.json in $HOME, creating one"
  mkdir -p ~/.jupyter
  # Use kernel display_name, filter out a kernel from jupyterlab environment
  cat <<EOF > ~/.jupyter/jupyter_config.json
{
  "CondaKernelSpecManager": {
    "conda_only": false,
    "name_format": "{display_name}"
  }
}
EOF

  # Use environment name for display_name
  kernel_json=$conda_prefix/envs/$kernel_env/share/jupyter/kernels/python3/kernel.json
  jq ".display_name = \"$kernel_env\"" $kernel_json > /tmp/kernel.json
  mv /tmp/kernel.json $kernel_json
  unset kernel_json
fi

unset jupyterlab_env
unset kernel_env

# Remove default kernel
jupyter kernelspec remove -y python3 || true

# Remove lost+found
rm -rf lost+found

exec jupyterhub-singleuser
