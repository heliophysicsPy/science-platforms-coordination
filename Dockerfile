FROM spolson/pyhc-environment:v2024.10.09

# Use a RUN command to copy the file from /app to /home/jovyan inside the image
USER root
RUN cp /app/import-test.ipynb /home/jovyan/import-test.ipynb && \
    chown jovyan:users /home/jovyan/import-test.ipynb

# Switch back to jovyan user
USER jovyan
