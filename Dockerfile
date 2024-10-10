# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-environment:v2024.10.09

# Install necessary build tools
USER root
RUN apt-get update && apt-get install -y gcc g++ gfortran ncurses-dev build-essential cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure the jovyan user exists and has correct permissions
RUN useradd -m -s /bin/bash -N -u 1000 jovyan && \
    chown -R jovyan:users /app && \
    cp /app/import-test.ipynb /home/jovyan/import-test.ipynb && \
    chown jovyan:users /home/jovyan/import-test.ipynb

# Switch to the jovyan user and set the working directory
USER jovyan
WORKDIR /home/jovyan
