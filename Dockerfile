# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-heliocloud:v2025.02.21-temp

# Set the working directory to /app, where `import-test.ipynb` is located
WORKDIR /app

USER root

# Ensure the jovyan user owns /app,
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

# Copy start into /srv/start and make it executable (TODO: this should be done in the pyhc-docker-environment repo—to put it in pyhc-heliocloud—instead of here!)
COPY start /srv/start
RUN chmod +x /srv/start

# Pre-build the wmm2015 and wmm2020 packages using Bash shell
# RUN /bin/bash -c "source activate \$CONDA_ENV && \
#     python -c 'import wmm2015' && \
#     python -c 'import wmm2020'"

# Change ownership of home dir and Python env using dynamic Python version (note: this recursive permission setting can apparently take a long time...)
RUN /bin/bash -c "source activate \$CONDA_ENV && \
    PYVERSION=\$(python -c 'import sys; print(\"python%d.%d\" % sys.version_info[:2])') && \
    echo \"Detected PYVERSION=\$PYVERSION\" && \
    chown -R jovyan:users /home/jovyan && \
    chmod -R u+w /home/jovyan && \
    chown -R jovyan:users /srv/conda/envs/\$CONDA_ENV/lib/\$PYVERSION/site-packages && \
    chmod -R u+w /srv/conda/envs/\$CONDA_ENV/lib/\$PYVERSION/site-packages"

# Go back to the default working directory
WORKDIR /home/jovyan
