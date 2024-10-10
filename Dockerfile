# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-environment:v2024.10.09

# Set the working directory to /app, where `import-test.ipynb` is located
WORKDIR /app

# Ensure the jovyan user exists and has correct permissions
USER root
RUN id jovyan || useradd -m -s /bin/bash -N -u 1000 jovyan && \
    chown -R jovyan:users /app

# Switch to the jovyan user
USER jovyan
