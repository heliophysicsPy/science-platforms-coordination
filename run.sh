#!/bin/bash
# ----------------------------------------------------------
# © Copyright 2021 European Space Agency, 2021
# This file is subject to the terms and conditions defined
# in file 'LICENSE.txt', which is part of this
# [source code/executable] package. No part of the package,
# including this file, may be copied, modified, propagated,
# or distributed except according to the terms contained in
# the file ‘LICENSE.txt’.
# -----------------------------------------------------------

. /.datalab/init.sh

wait_interface & # emit state change to API when the interface is ready

#Create user home directory as a symlink to the user persistent area volume (pending correction related to SEPPPCR-191).
ln -s /media/home /home/$USER
# chmod -R go+rwx /media/home/.local

cd $HOME

export JUPYTER_CONFIG_DIR=$HOME/.jupyterlab-$DATALAB_ID

JUPYTER_DEBUG=""
if [ "$LOG_LEVEL" == 'debug' ];then
    JUPYTER_DEBUG="--debug"
fi
debug "Start Jupyterlab server"

Xvfb :1 &

# Determine the current Python version (e.g. "python3.11" or "python3.13")
PYVERSION=$(python -c 'import sys; print("python%d.%d" % sys.version_info[:2])')

# Adjust ownership and permissions for pre-built packages.
# These commands ensure that the package directories for wmm2015,
# wmm2020, and savic have the correct ownership based on the runtime user.
debug "Adjusting ownership and permissions for pre-built packages"
chown -R $(id -u):$(id -g) ${CONDA_DIR}/envs/${CONDA_ENV}/lib/${PYVERSION}/site-packages/wmm2015
chown -R $(id -u):$(id -g) ${CONDA_DIR}/envs/${CONDA_ENV}/lib/${PYVERSION}/site-packages/wmm2020
chown -R $(id -u):$(id -g) ${CONDA_DIR}/envs/${CONDA_ENV}/lib/${PYVERSION}/site-packages/savic
chmod -R u+w ${CONDA_DIR}/envs/${CONDA_ENV}/lib/${PYVERSION}/site-packages/savic
# # Fix ownership and permissions for notebooks if the directory exists
# if [ -d "/media/notebooks" ]; then
#   echo "Adjusting ownership and permissions for /media/notebooks..."
#   chown -R "$(id -u):$(id -g)" /media/notebooks
#   chmod -R u+w /media/notebooks
# else
#   echo "/media/notebooks not found, skipping ownership adjustments."
# fi

# for f in /opt/datalabs/init.d/*.sh; do
#   chown $UID:$UID $f
#   chmod u+x $f
#   su - $USER -c "bash +euo pipefail -cl \"HOME=/home/$USER $f\""
# done
debug "ENVIRONMENT => $ENVIRONMENT"
api_emit_running
if su - $USER -c " bash -cl \"HOME=/home/$USER jupyter lab --ip=0.0.0.0  $JUPYTER_DEBUG --port=$IF_main_port \
  --JupyterApp.config_file='/etc/jupyter_notebook_config.py' \
  --ServerApp.disable_check_xsrf=True \
  --NotebookApp.base_url=\"/datalabs/$IF_main_id\" \
  --NotebookApp.token='' --NotebookApp.password=''\""
then
  api_emit_finished
else
  api_emit_error
fi

api_emit_if_done
