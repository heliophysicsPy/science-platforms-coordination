# Use the PyHC environment already in Docker Hub
FROM spolson/pyhc-heliocloud:v2025.02.26-temp2

# Set the working directory to /app, where `import-test.ipynb` is located
# WORKDIR /app

# USER root

# Ensure the jovyan user owns /app,
# then copy all notebooks from /app/notebooks into /home/jovyan/notebooks
# and copy the README into /home/jovyan
# RUN chown -R jovyan:users /app && \
#     mkdir -p /home/jovyan/notebooks && \
#     if [ -d "/app/notebooks" ]; then \
#         cp -r /app/notebooks/* /home/jovyan/notebooks/; \
#     fi && \
#     chown -R jovyan:users /home/jovyan/notebooks && \
#     if [ -f "/app/README.md" ]; then \
#         cp /app/README.md /home/jovyan/ && \
#         chown jovyan:users /home/jovyan/README.md; \
#     fi

# Pre-build the wmm2015 and wmm2020 packages using Bash shell
# RUN /bin/bash -c "source activate \$CONDA_ENV && \
#     python -c 'import wmm2015' && \
#     python -c 'import wmm2020'"

# Remove build cruft (TODO: figure out why they're there in the first place and remove them from pyhc-heliocloud image)
# RUN rm -rf /home/jovyan/environment.yml /home/jovyan/requirements.txt /home/jovyan/apt.txt /home/jovyan/jupyter_notebook_config.py /home/jovyan/motd /home/jovyan/start /home/jovyan/Dockerfile /home/jovyan/contents

# Go back to the default working directory
WORKDIR /home/jovyan
