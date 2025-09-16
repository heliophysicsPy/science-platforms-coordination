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

# Clean up: remove everything in /home/$NB_USER (default: /home/jovyan) except requirements.txt and Welcome.ipynb
RUN find /home/$NB_USER/ -mindepth 1 -maxdepth 1 \
    ! -name 'requirements.txt' \
    ! -name 'Welcome.ipynb' \
    -exec rm -rf {} +

# Extract notebooks archive into notebooks directory
COPY notebooks.tar.gz /tmp/
RUN mkdir -p /home/$NB_USER/notebooks && \
    tar -xzf /tmp/notebooks.tar.gz -C /home/$NB_USER/notebooks && \
    rm -f /tmp/notebooks.tar.gz

# create PyHC package data dirs (needed?)
RUN mkdir -p /home/$NB_USER/.sunpy /home/$NB_USER/.spacepy/data

# Ensure user (default: jovyan) owns everything with full permissions
RUN chown -R $NB_USER /home/$NB_USER && \
    chmod -R 777 /home/$NB_USER

USER $NB_USER

EXPOSE 8888

# CMD to run JupyterLab (this will be passed to exec "$@" in the start script)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
