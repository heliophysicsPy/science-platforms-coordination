# -*- coding: utf-8 -*-

import os

datalabs_url = os.getenv("DATALABS_URL", "https://datalabs.esa.int")

c.Spawner.args = [f'--NotebookApp.allow_origin={"*"}']
c.NotebookApp.tornado_settings = {  # noqa
    "headers": {
        "Content-Security-Policy": "frame-ancestors %s 'self' ;" % datalabs_url,
        'Access-Control-Allow-Origin': '*'
    }
}

c.NotebookApp.terminado_settings = {  # noqa
    "shell_command": ["bash", "-i"]
}

# Configure nb_conda_kernels to avoid registering Jupyter kernels in our conda environment again.
c.CondaKernelSpecManager.env_filter = f'.*envs/{os.environ["CONDA_ENV"]}.*'
