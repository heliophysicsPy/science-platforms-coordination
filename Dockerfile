ARG PANGEO_BASE_IMAGE_TAG=2024.08.07
FROM pangeo/base-image:${PANGEO_BASE_IMAGE_TAG}

USER root

# install CDFLIB
RUN sh install_cdflib.sh
ENV CDF_LIB=/usr/lib64/cdf/lib

# Clean up temporary data
RUN apt clean \
   && apt autoclean \
   && apt -y autoremove \
   && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
   && conda clean -afy

# Create directory for repo content in /opt
RUN mkdir -p /opt/survey-core

# Copy Welcome.ipynb and requirements.txt to the opt directory
COPY Welcome.ipynb /opt/survey-core/
COPY requirements.txt /opt/survey-core/

# Extract notebooks archive into notebooks directory in opt
COPY notebooks.tar.gz /tmp/
RUN mkdir -p /opt/survey-core/notebooks && \
    tar -xzf /tmp/notebooks.tar.gz -C /opt/survey-core/notebooks && \
    rm -f /tmp/notebooks.tar.gz

# create PyHC package data dirs in opt directory
RUN mkdir -p /opt/survey-core/.sunpy /opt/survey-core/.spacepy/data

# Copy start script to the branch-specific directory and make it executable
COPY start /opt/survey-core/start
RUN chmod +x /opt/survey-core/start

# Ensure user (default: jovyan) owns everything in opt with full permissions
RUN chown -R $NB_USER /opt/survey-core && \
    chmod -R 777 /opt/survey-core

# Clean up /home/$NB_USER completely since files will be symlinked from /opt
RUN rm -rf /home/$NB_USER/*

USER $NB_USER

EXPOSE 8888

# Use the branch-specific start script as entrypoint
ENTRYPOINT ["/opt/survey-core/start"]

# CMD to run JupyterLab (this will be passed to exec "$@" in the start script)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
