# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-environment:v2024.10.09

# Set the working directory to /app, where `import-test.ipynb` is located
WORKDIR /app

USER root

# Ensure the jovyan user exists and has correct permissions
RUN useradd -m -s /bin/bash -N -u 1000 jovyan && \
    chown -R jovyan:users /app && \
    cp /app/import-test.ipynb /home/jovyan/import-test.ipynb && \
    chown jovyan:users /home/jovyan/import-test.ipynb

# Pre-build the wmm2015 package using Bash shell
RUN /bin/bash -c "source activate pyhc-all && python -c 'import wmm2015'"

# Change ownership of the wmm2015 package directory
RUN chown -R jovyan:users /opt/conda/envs/pyhc-all/lib/python3.10/site-packages/wmm2015

# Go back to the default working directory
WORKDIR /home/jovyan
