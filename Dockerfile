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

# Clean up: remove everything in /home/jovyan except notebooks and Welcome.ipynb
RUN find /home/jovyan/ -mindepth 1 -maxdepth 1 \
    ! -name 'notebooks' \
    ! -name 'Welcome.ipynb' \
    -exec rm -rf {} +

USER $NB_USER

# create PyHC package data dirs (needed?)
RUN mkdir -p /home/$NB_USER/.sunpy /home/$NB_USER/.spacepy/data

EXPOSE 8888

# CMD to run JupyterLab (this will be passed to exec "$@" in the start script)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
