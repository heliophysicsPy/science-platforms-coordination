ARG UBUNTU_VERSION=20.04
ARG REGISTRY=scidockreg.esac.esa.int:62510
FROM ${REGISTRY}/datalabs/datalabs_base:${UBUNTU_VERSION}

# Set the environment to non-interactive to avoid prompts during package installations
ENV DEBIAN_FRONTEND noninteractive

# Update and install essential packages (if needed)
RUN apt-get update && apt-get install -y \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Launch a terminal session
CMD ["/bin/bash"]
