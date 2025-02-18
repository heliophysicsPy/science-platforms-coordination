# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-environment:v2025.02.15

USER root

# Create and configure user "jovyan" (if it doesn’t already exist in the base image)
RUN useradd -m -s /bin/bash -N -u 1000 jovyan

###############################################################################
# Copy all files from the repo context into /tmp/build, so we can check them.
###############################################################################
WORKDIR /tmp/build
COPY . /tmp/build

###############################################################################
# 1. Install apt packages specified in apt.txt if it exists
###############################################################################
RUN echo "Checking for 'apt.txt'..." \
    && if [ -f "apt.txt" ]; then \
        echo "Installing packages from apt.txt..." \
        && apt-get update -qq \
        && xargs -a apt.txt apt-get install -y \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*; \
    else \
        echo "No apt.txt found, skipping apt packages installation."; \
    fi

###############################################################################
# 2. Update conda environment (pyhc-all) from environment.yml if present
###############################################################################
RUN echo "Checking for 'environment.yml'..." \
    && if [ -f "environment.yml" ]; then \
        echo "Using environment.yml to update pyhc-all..." \
        && conda env update -n pyhc-all -f environment.yml; \
    else \
        echo "No environment.yml found, skipping."; \
    fi \
    && conda clean -afy \
    && find /opt/conda -follow -type f -name '*.a' -delete \
    && find /opt/conda -follow -type f -name '*.js.map' -delete \
    && if ls /opt/conda/envs/pyhc-all/lib/python*/site-packages/bokeh/server/static > /dev/null 2>&1; then \
       find /opt/conda/envs/pyhc-all/lib/python*/site-packages/bokeh/server/static -follow -type f -name '*.js' ! -name '*.min.js' -delete; \
    fi

###############################################################################
# 3. Install pip packages (within pyhc-all) from requirements.txt if present
###############################################################################
RUN echo "Checking for 'requirements.txt'..." \
    && if [ -f "requirements.txt" ]; then \
        echo "Installing pip packages from requirements.txt..." \
        && /opt/conda/envs/pyhc-all/bin/pip install --no-cache-dir -r requirements.txt; \
    else \
        echo "No requirements.txt found, skipping."; \
    fi

###############################################################################
# 4. Copy jupyter_notebook_config.py if present
###############################################################################
RUN echo "Checking for 'jupyter_notebook_config.py'..." \
    && if [ -f "jupyter_notebook_config.py" ]; then \
        echo "Installing jupyter_notebook_config.py to /etc/jupyter/..." \
        && mkdir -p /etc/jupyter \
        && cp jupyter_notebook_config.py /etc/jupyter/; \
    else \
        echo "No jupyter_notebook_config.py found, skipping."; \
    fi

###############################################################################
# 5. Install custom start script if present
###############################################################################
RUN echo "Checking for 'start' script..." \
    && if [ -f "start" ]; then \
        echo "Installing start script to /srv/start..." \
        && chmod +x start \
        && cp start /srv/start; \
    else \
        echo "No start script found, skipping."; \
    fi

###############################################################################
# 6. Run install_cdflib.sh if present
###############################################################################
RUN echo "Checking for 'install_cdflib.sh'..." \
    && if [ -f "install_cdflib.sh" ]; then \
        echo "Installing CDF libraries..." \
        && chmod +x install_cdflib.sh \
        && /bin/sh install_cdflib.sh; \
    else \
        echo "No install_cdflib.sh found, skipping."; \
    fi

###############################################################################
# 7. Copy notebooks into /home/jovyan/notebooks if "notebooks/" folder is present
###############################################################################
RUN mkdir -p /home/jovyan/notebooks \
    && if [ -d "notebooks" ]; then \
        cp -r notebooks/* /home/jovyan/notebooks/; \
    fi \
    && chown -R jovyan:users /home/jovyan/notebooks

###############################################################################
# Original steps from pyhc Dockerfile (pre-build wmm, jupyterhub install, etc.)
# Dynamically detect Python version to get correct paths to site-packages/
###############################################################################

# Install jupyterhub package so the image works on authenticated BinderHubs
RUN conda install -c conda-forge -n pyhc-all -y jupyterhub-singleuser

# Pre-build the wmm2015 and wmm2020 packages using Bash shell,
# Change ownership of the wmm2015, wmm2020, and savic package directories
RUN /bin/bash -c "source activate pyhc-all && \
    python -c 'import wmm2015' && \
    python -c 'import wmm2020' && \
    PYVERSION=\$(python -c 'import sys; print(\"python%d.%d\" % sys.version_info[:2])') && \
    echo \"Detected PYVERSION=\$PYVERSION\" && \
    chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/wmm2015 && \
    chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/wmm2020 && \
    chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/savic && \
    chmod -R u+w /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/savic"

# create PyHC package data dirs (needed?)
RUN mkdir -p $NB_USER/.sunpy $NB_USER/.spacepy/data

# Default back to /home/jovyan
WORKDIR /home/jovyan
