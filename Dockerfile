# Build tetracorder in docker
FROM ubuntu:20.04

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install core dependencies and Davinci requirements
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    ratfor \
    gcc \
    g++ \
    make \
    java-common \
    default-jdk \
    default-jdk-doc \
    libx11-dev \
    glibc-doc \
    glibc-doc-reference \
    inotify-tools \
    imagemagick \
    netpbm \
    libxpm-dev \
    libxt-dev \
    libpng-dev \
    libjbig-dev \
    libjpeg8-dev \
    zlib1g-dev \
    libmotif-dev \
    libhdf5-dev \
    libcfitsio-dev \
    libreadline-dev \
    zlib1g \
    libcurl4-openssl-dev \
    gnuplot \
    gnuplot-x11 \
    libice6 \
    libxmu6 \
    libsm6 \
    libncurses5 \
    libltdl7 \
    flex \
    bison \
    && rm -rf /var/lib/apt/lists/*

# Create required directories and set permissions
RUN mkdir -p /t1 /sl1 /src/local /usr/spool/gplot /usr/local/bin && \
    chmod 777 /usr/spool/gplot && \
    touch /usr/spool/plot.log && \
    chmod 666 /usr/spool/plot.log

# Install Davinci
COPY davinci_2.27-1_amd64_ubuntu20_04.deb /tmp/
RUN apt-get update && \
    apt-get install -y /tmp/davinci_2.27-1_amd64_ubuntu20_04.deb && \
    rm /tmp/davinci_2.27-1_amd64_ubuntu20_04.deb

# Copy source code and spectral libraries
COPY etc /src/local/etc
COPY specpr /src/local/specpr
COPY tetracorder5.27 /src/local/tetracorder5.27
COPY sl1/usgs /sl1/usgs
COPY tetracorder.cmds /t1/tetracorder.cmds

# Create required directories
RUN mkdir -p /src/local/specpr/lib \
             /src/local/specpr/obj && \
    chmod -R 755 /src/local/specpr

# specpr config wrapper
RUN echo '#!/bin/bash\n\
    source /src/local/etc/bash.bashrc\n\
    exec "$@"' > /usr/local/bin/env_setup.sh && \
    chmod +x /usr/local/bin/env_setup.sh

# Compile specpr
WORKDIR /src/local/specpr
RUN chmod +x AAA.INSTALL.specpr+support-progs-linux-upgrade.1.7.sh

# Install script asks for return so we echo ""
RUN echo "" | /usr/local/bin/env_setup.sh ./AAA.INSTALL.specpr+support-progs-linux-upgrade.1.7.sh

# Compile tetracorder
WORKDIR /src/local/tetracorder5.27

# Compile single spectrum mode: sed to uncomment block B in multmap.h
RUN /usr/local/bin/env_setup.sh bash -c '\
    sed -i "/^# A/,+4 {/^#[[:space:]]*parameter/s/^#[[:space:]]*/# /}; /^# B/,+4 {/^[[:space:]]*parameter/s/^[[:space:]]*/         /}" multmap.h && \
    make installsingle'

# Compile cube mode: sed to uncomment block A in multmap.h
RUN /usr/local/bin/env_setup.sh bash -c '\
    sed -i "/^# A/,+4 {/^#[[:space:]]*parameter/s/^#[[:space:]]*/         /}; /^# B/,+4 {/^[[:space:]]*parameter/s/^[[:space:]]*/# /}" multmap.h && \
    make install'


# Create rclark user first
RUN useradd -m -s /bin/bash rclark
RUN chown rclark:rclark /t1

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    libx11-6 \
    libgfortran5 \
    libxcb1 \
    libxau6 \
    libxdmcp6 \
    libbsd0 \
    imagemagick \
    netpbm \
    alsa-utils \
    default-jre \
    && rm -rf /var/lib/apt/lists/*

USER rclark
WORKDIR /home/rclark

# Default command
CMD ["/bin/bash"]