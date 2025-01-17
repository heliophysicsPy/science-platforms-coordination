# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-environment:v2025.01.17

# Set the working directory to /app, where `import-test.ipynb` is located
WORKDIR /app

USER root

# Ensure the jovyan user exists and has correct permissions, copy two notebooks from /app
RUN useradd -m -s /bin/bash -N -u 1000 jovyan && \
    chown -R jovyan:users /app && \
    cp /app/import-test.ipynb /home/jovyan/import-test.ipynb && \
    cp /app/unit-tests.ipynb /home/jovyan/unit-tests.ipynb && \
    chown jovyan:users /home/jovyan/import-test.ipynb && \
    chown jovyan:users /home/jovyan/unit-tests.ipynb
    

# Pre-build the wmm2015 and wmm2020 packages using Bash shell
RUN /bin/bash -c "source activate pyhc-all && \
    python -c 'import wmm2015' && \
    python -c 'import wmm2020'"

# Install jupyterhub package so the image will work on authenticated binderhubs
RUN conda install -c conda-forge -n pyhc-all -y jupyterhub-singleuser

# Change ownership of the wmm2015 and wmm2020 package directories
RUN chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/python3.10/site-packages/wmm2015 && \
    chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/python3.10/site-packages/wmm2020

# Change ownership and permissions for savic
RUN chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/python3.10/site-packages/savic && \
    chmod -R u+w /opt/conda/envs/pyhc-all/lib/python3.10/site-packages/savic

# Go back to the default working directory
WORKDIR /home/jovyan
