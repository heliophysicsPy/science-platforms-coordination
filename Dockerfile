# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-environment:v2024.10.09

# Ensure the jovyan user exists and has correct permissions
USER root
RUN id jovyan || useradd -m -s /bin/bash -N -u 1000 jovyan && \
    chown -R jovyan:users /app

# Copy the import-test.ipynb file from /app to /home/jovyan and set proper permissions
COPY /app/import-test.ipynb /home/jovyan/import-test.ipynb
RUN chown jovyan:users /home/jovyan/import-test.ipynb

# Switch to the jovyan user
USER jovyan
