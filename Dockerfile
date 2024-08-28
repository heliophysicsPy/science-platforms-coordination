ARG JL_BASE_VERSION=stable
ARG REGISTRY=scidockreg.esac.esa.int:62510
FROM ${REGISTRY}/datalabs/datalabs_base:${JL_BASE_VERSION}-20.04

LABEL org.opencontainers.image.source=https://github.com/pangeo-data/pangeo-docker-images

# Setup environment to match variables set by Pangeo's repo2docker
ENV CONDA_ENV=notebook \
    DEBIAN_FRONTEND=noninteractive \
    NB_USER=jovyan \
    NB_UID=1000 \
    SHELL=/bin/bash \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    CONDA_DIR=/srv/conda \
    NB_PYTHON_PREFIX=${CONDA_DIR}/envs/${CONDA_ENV} \
    HOME=/home/${NB_USER} \
    PATH=${NB_PYTHON_PREFIX}/bin:${CONDA_DIR}/bin:${PATH} \
    DASK_ROOT_CONFIG=${CONDA_DIR}/etc \
    TZ=UTC

# Create the jovyan user
RUN echo "Creating ${NB_USER} user..." \
    && groupadd --gid ${NB_UID} ${NB_USER}  \
    && useradd --create-home --gid ${NB_UID} --no-log-init --uid ${NB_UID} ${NB_USER} \
    && chown -R ${NB_USER}:${NB_USER} /srv

# Install basic apt packages
RUN echo "Installing Apt-get packages..." \
    && apt-get update --fix-missing > /dev/null \
    && apt-get install -y apt-utils wget zip tzdata > /dev/null \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Miniforge and conda-lock as root
USER root
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

# Create the init_conda.sh script as root
RUN echo ". ${CONDA_DIR}/etc/profile.d/conda.sh ; conda activate ${CONDA_ENV}" > /etc/profile.d/init_conda.sh

# Switch back to jovyan user
USER ${NB_USER}
WORKDIR ${HOME}

# Expose port 8888 for JupyterLab access
EXPOSE 8888

# Start JupyterLab by default
CMD ["jupyter", "lab", "--ip", "0.0.0.0"]
