# Start from 2024 PyHC Summer School HelioCloud environment
FROM public.ecr.aws/q3h7b4o8/heliocloud/helio-notebook:2024.05.15

WORKDIR /notebook
COPY . /notebook

RUN pip install jupyterlab

# Install missing ESA Datalabs packages
RUN pip install \
    aiosqlite==0.20.0 \
    archspec==0.2.1 \
    arrow==1.3.0 \
    boltons==23.0.0 \
    conda-package-handling==2.2.0 \
    conda_package_streaming==0.9.0 \
    configparser==5.2.0 \
    fqdn==1.5.1 \
    importlib-metadata==7.0.1 \
    ipyevents==2.0.1 \
    isoduration==20.11.0 \
    jsonpatch==1.32 \
    jsonpointer==2.1 \
    jupyter-events==0.9.0 \
    jupyter_server_fileid==0.9.1 \
    jupyter_server_ydoc==0.8.0 \
    jupyter-ydoc==0.2.5 \
    jupyterlab_git==0.42.0 \
    jupyterlab_pygments==0.3.0 \
    jupyterlab-widgets==3.0.8 \
    nest-asyncio==1.6.0 \
    pycosat==0.6.6 \
    pyesasky==1.9.5 \
    qtconsole==5.2.2 \
    QtPy==2.0.0 \
    rfc3339-validator==0.1.4 \
    rfc3986-validator==0.1.1 \
    truststore==0.8.0 \
    types-python-dateutil==2.8.19.20240106 \
    uri-template==1.3.0 \
    webcolors==1.13 \
    y-py==0.6.2 \
    ypy-websocket==0.8.4 \
    zstandard==0.19.0

EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
