ARG BASE_VERSION=0.8.0-stable
ARG REGISTRY=scidockreg.esac.esa.int:62510
FROM ${REGISTRY}/datalabs/datalabs_base:${BASE_VERSION}-20.04

LABEL org.opencontainers.image.source=https://github.com/pangeo-data/pangeo-docker-images

# Setup environment variables to match Pangeo's repo2docker and ESA Datalabs
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
    JUPYTER_CONFIG_DIR=/root/.jupyterlab-$DATALAB_ID \
    ENVIRONMENT=". ${CONDA_DIR}/etc/profile.d/conda.sh ; conda activate ${CONDA_ENV}"

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

# Copy the entire build context to /tmp/build (similar to Pangeo's approach)
COPY . /tmp/build/

# Ensure the run.sh script is executable
RUN chmod +x /opt/datalab/run.sh

# Install apt packages specified in apt.txt if it exists
RUN echo "Checking for 'apt.txt'..." \
    && if [ -f "/tmp/build/apt.txt" ]; then \
        echo "Installing packages from apt.txt..." \
        && apt-get update --fix-missing > /dev/null \
        && xargs -a /tmp/build/apt.txt apt-get install -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* \
    ; else \
        echo "No apt.txt found, skipping apt packages installation." \
    ; fi

# Create conda environment from conda-lock.yml or environment.yml if they exist
RUN echo "Checking for 'conda-lock.yml' or 'environment.yml'..." \
    && . ${CONDA_DIR}/etc/profile.d/conda.sh \
    ; if [ -f "/tmp/build/conda-lock.yml" ]; then \
        echo "Using conda-lock.yml" \
        && conda-lock install --name ${CONDA_ENV} /tmp/build/conda-lock.yml \
    ; elif [ -f "/tmp/build/environment.yml" ]; then \
        echo "Using environment.yml" \
        && mamba env create --name ${CONDA_ENV} -f /tmp/build/environment.yml \
    ; else \
        echo "No conda-lock.yml or environment.yml found! Proceeding without conda environment creation." \
    ; fi \
    && conda clean -afy \
    && find ${CONDA_DIR} -follow -type f -name '*.a' -delete \
    && find ${CONDA_DIR} -follow -type f -name '*.js.map' -delete \
    ; if ls ${NB_PYTHON_PREFIX}/lib/python*/site-packages/bokeh/server/static > /dev/null 2>&1; then \
        find ${NB_PYTHON_PREFIX}/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete \
    ; fi

# Install pip packages specified in requirements.txt if it exists.
# We don't want to save cached wheels in the image to avoid wasting space.
RUN echo "Checking for pip 'requirements.txt'..." \
    && if [ -f "/tmp/build/requirements.txt" ]; then \
         echo "Installing pip packages from requirements.txt" \
         && ${CONDA_DIR}/envs/${CONDA_ENV}/bin/pip install --no-cache --use-deprecated=legacy-resolver -r /tmp/build/requirements.txt ; \
       else \
         echo "No pip requirements.txt found" ; \
       fi

# Install (or reinstall) the necessary compiler toolchain packages into the conda environment for wmm2015 and wmm2020
RUN . ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate ${CONDA_ENV} && \
    mamba install -y gcc_linux-64 gxx_linux-64 && \
    conda clean -afy

# Pre-build the wmm2015 and wmm2020 packages using the conda environment's Python
RUN /bin/bash -c ". ${CONDA_DIR}/etc/profile.d/conda.sh && conda activate ${CONDA_ENV} && \
    python -c 'import wmm2015' && \
    python -c 'import wmm2020'"

# Change ownership of the wmm2015 and wmm2020 package directories
RUN chown -R jovyan:users ${CONDA_DIR}/envs/${CONDA_ENV}/lib/python3.11/site-packages/wmm2015 && \
    chown -R jovyan:users ${CONDA_DIR}/envs/${CONDA_ENV}/lib/python3.11/site-packages/wmm2020

# Change ownership and permissions for savic
RUN chown -R jovyan:users ${CONDA_DIR}/envs/${CONDA_ENV}/lib/python3.11/site-packages/savic && \
    chmod -R u+w ${CONDA_DIR}/envs/${CONDA_ENV}/lib/python3.11/site-packages/savic

# Install cdflib if install_cdflib.sh exists
RUN if [ -f "/tmp/build/install_cdflib.sh" ]; then \
        echo "Installing cdflib..." \
        && chmod +x /tmp/build/install_cdflib.sh \
        && /tmp/build/install_cdflib.sh \
    ; else \
        echo "No install_cdflib.sh found, skipping cdflib installation." \
    ; fi

# Set environment variable for CDF_LIB
ENV CDF_LIB=/usr/lib64/cdf/lib

# Clean up temporary data
RUN apt clean \
    && apt autoclean \
    && apt -y autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && . ${CONDA_DIR}/etc/profile.d/conda.sh \
    && conda clean -afy

# Remove all source files except README.md
RUN mkdir -p /media/home \
    && if [ -f "/tmp/build/README.md" ]; then \
        cp /tmp/build/README.md /media/home/README.md \
    ; else \
        echo "No README.md found." \
    ; fi \
    && find /media/home/ -maxdepth 1 -type f ! -name 'README.md' -exec rm -f {} +

# Create PyHC package data directories
RUN mkdir -p /media/home/.sunpy /media/home/.spacepy/data

CMD ["/sbin/tini", "--", "/opt/datalab/run.sh"]

WORKDIR /opt/
