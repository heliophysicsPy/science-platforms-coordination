ARG BASE_VERSION=0.8.0-stable
ARG REGISTRY=scidockreg.esac.esa.int:62510
FROM ${REGISTRY}/datalabs/datalabs_base:${BASE_VERSION}-20.04

LABEL org.opencontainers.image.source=https://github.com/pangeo-data/pangeo-docker-images

# Setup environment to match Pangeo's repo2docker and ESA Datalabs
ENV CONDA_ENV=notebook \
    DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    CONDA_DIR=/srv/conda \
    NB_PYTHON_PREFIX=${CONDA_DIR}/envs/${CONDA_ENV} \
    PATH=${NB_PYTHON_PREFIX}/bin:${CONDA_DIR}/bin:${PATH} \
    DASK_ROOT_CONFIG=${CONDA_DIR}/etc \
    TZ=UTC \
    JUPYTER_CONFIG_DIR=/root/.jupyterlab-$DATALAB_ID

# Install basic apt packages and python3-pip
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        python3-pip \
        apt-utils wget zip tzdata xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pip packages for JupyterLab and Jupyter client
RUN pip --no-cache-dir install \
        jupyterlab==3.6.5 \
        jupyter_client==7.1.1

# Install Miniforge and conda-lock
RUN echo "Installing Miniforge..." \
    && URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-$(uname -m).sh" \
    && wget --quiet ${URL} -O installer.sh \
    && /bin/bash installer.sh -u -b -p ${CONDA_DIR} \
    && rm installer.sh \
    && . ${CONDA_DIR}/etc/profile.d/conda.sh \
    && conda activate base \
    && mamba install conda-lock -y \
    && mamba clean -afy \
    && find ${CONDA_DIR} -follow -type f -name '*.a' -delete

# Create the init_conda.sh script
RUN echo ". ${CONDA_DIR}/etc/profile.d/conda.sh ; conda activate ${CONDA_ENV}" > /etc/profile.d/init_conda.sh

# Copy necessary configuration and scripts
COPY jupyter_notebook_config.py /etc/
COPY run.sh /opt/datalab/

# Ensure the run.sh script is executable
RUN chmod +x /opt/datalab/run.sh

CMD ["/sbin/tini", "--", "/opt/datalab/run.sh"]

WORKDIR /opt/
