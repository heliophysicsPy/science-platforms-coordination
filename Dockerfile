ARG PANGEO_BASE_IMAGE_TAG=2024.08.07
FROM pangeo/base-image:${PANGEO_BASE_IMAGE_TAG}

USER root

# install CDFLIB, removing its build directory in the same layer (the later /tmp cleanup can't
# remove files from an earlier layer)
RUN sh install_cdflib.sh && rm -rf /tmp/cdf38_1-dist
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

# create PyHC package data dirs in opt directory
RUN mkdir -p /opt/survey-core/.sunpy /opt/survey-core/.spacepy/data

# Copy start script to the branch-specific directory and make it executable
COPY start /opt/survey-core/start
RUN chmod +x /opt/survey-core/start

# Download and verify the notebooks archive, extract it into the notebooks directory in opt, delete
# it, then ensure user (default: jovyan) owns everything in opt with full permissions, all in one
# layer so neither the archive nor a second copy of the notebooks is stored in the image. The archive
# is excluded from the build context (see .dockerignore), so Pangeo's ONBUILD step doesn't copy it in.
# When notebooks.tar.gz changes, set NOTEBOOKS_COMMIT to a commit containing the new archive and
# NOTEBOOKS_SHA256 to the oid in its Git LFS pointer file.
ARG NOTEBOOKS_COMMIT=e2a9d76f93b543f026d9f74843ac6c095cb67297
ARG NOTEBOOKS_SHA256=0ec9095c3788b508a24ad4667e7758ec034e6dd3d35983558fd934f5f934837b
RUN wget -nv --no-hsts -O /tmp/notebooks.tar.gz \
        https://media.githubusercontent.com/media/heliophysicsPy/science-platforms-coordination/${NOTEBOOKS_COMMIT}/notebooks.tar.gz && \
    echo "${NOTEBOOKS_SHA256}  /tmp/notebooks.tar.gz" | sha256sum -c - && \
    mkdir -p /opt/survey-core/notebooks && \
    tar -xzf /tmp/notebooks.tar.gz -C /opt/survey-core/notebooks && \
    rm /tmp/notebooks.tar.gz && \
    chown -R $NB_USER /opt/survey-core && \
    chmod -R 777 /opt/survey-core

# Clean up /home/$NB_USER completely since files will be symlinked from /opt
RUN rm -rf /home/$NB_USER/*

USER $NB_USER

EXPOSE 8888

# Use the branch-specific start script as entrypoint
ENTRYPOINT ["/opt/survey-core/start"]

# CMD to run JupyterLab (this will be passed to exec "$@" in the start script)
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--no-browser", "--allow-root"]
