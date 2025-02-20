# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-heliocloud:v2025.02.20

# Set the working directory to /app, where `import-test.ipynb` is located
WORKDIR /app

USER root

# Ensure the jovyan user has correct permissions,
# then copy all notebooks from /app/notebooks into /home/jovyan/notebooks
# and copy the README into /home/jovyan
RUN chown -R jovyan:users /app && \
    mkdir -p /home/jovyan/notebooks && \
    if [ -d "/app/notebooks" ]; then \
        cp -r /app/notebooks/* /home/jovyan/notebooks/; \
    fi && \
    chown -R jovyan:users /home/jovyan/notebooks && \
    if [ -f "/app/README.md" ]; then \
        cp /app/README.md /home/jovyan/ && \
        chown jovyan:users /home/jovyan/README.md; \
    fi

# Ensure jupyterhub-singleuser is installed so the image will work on authenticated binderhubs (commented out because base image already contains it!) 
# RUN conda install -c conda-forge -n pyhc-all -y jupyterhub-singleuser

# Pre-build the wmm2015 and wmm2020 packages using Bash shell
RUN /bin/bash -c "source activate pyhc-all && \
    python -c 'import wmm2015' && \
    python -c 'import wmm2020'"

# Change ownership of wmm2015, wmm2020, and savic directories using dynamic Python version
RUN /bin/bash -c "source activate pyhc-all && \
    PYVERSION=\$(python -c 'import sys; print(\"python%d.%d\" % sys.version_info[:2])') && \
    echo \"Detected PYVERSION=\$PYVERSION\" && \
    # chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/wmm2015 && \
    # chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/wmm2020 && \
    chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/savic && \
    chmod -R u+w /opt/conda/envs/pyhc-all/lib/\$PYVERSION/site-packages/savic"

# Go back to the default working directory
WORKDIR /home/jovyan
