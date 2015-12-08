FROM ubuntu:trusty

# https://github.com/ampervue/docker-python27-opencv

MAINTAINER David Karchmer <dkarchmer@gmail.com>

########################################
#
# Image based on Ubuntu:trusty
#
#   with Python 2.7
#   and OpenCV 3 (built)
#   plus a bunch of build essencials
#######################################

# Set Locale

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

#RUN apt-get -qq remove ffmpeg

RUN echo deb http://archive.ubuntu.com/ubuntu precise universe multiverse >> /etc/apt/sources.list; \
    apt-get update -qq && apt-get install -y --force-yes \
    curl \
    git \
    g++ \
    autoconf \
    automake \
    mercurial \
    libopencv-dev \
    build-essential \
    checkinstall \
    cmake \
    pkg-config \
    yasm \
    libtiff4-dev \
    libpng-dev \
    libjpeg-dev \
    libjasper-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libdc1394-22-dev \
    libxine-dev \
    libgstreamer0.10-dev \
    libgstreamer-plugins-base0.10-dev \
    libv4l-dev \
    libtbb-dev \
    libgtk2.0-dev \
    libfaac-dev \
    libmp3lame-dev \
    libopencore-amrnb-dev \
    libopencore-amrwb-dev \
    libtheora-dev \
    libvorbis-dev \
    libxvidcore-dev \
    libtool \
    v4l-utils \
    python2.7 \
    python2.7-dev \
    python-numpy \
    default-jdk \
    ant \
    wget \
    unzip; \
    apt-get clean

ENV YASM_VERSION    1.3.0
ENV OPENCV_VERSION  2.4.10

WORKDIR /usr/local/src

RUN git clone --depth 1 https://github.com/l-smash/l-smash
RUN git clone --depth 1 git://git.videolan.org/x264.git
RUN hg clone https://bitbucket.org/multicoreware/x265
#RUN git clone --depth 1 git://source.ffmpeg.org/ffmpeg
RUN git clone https://github.com/Itseez/opencv.git
RUN git clone https://github.com/Itseez/opencv_contrib.git
RUN git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git
RUN git clone --depth 1 https://chromium.googlesource.com/webm/libvpx
RUN git clone --depth 1 git://git.opus-codec.org/opus.git
RUN git clone --depth 1 https://github.com/mulx/aacgain.git
RUN curl -Os http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VERSION}.tar.gz
RUN tar xzvf yasm-${YASM_VERSION}.tar.gz

# Build YASM
# =================================
WORKDIR /usr/local/src/yasm-${YASM_VERSION}
RUN ./configure --enable-static
RUN make -j 4
RUN make install
# =================================


# Build L-SMASH
# =================================
WORKDIR /usr/local/src/l-smash
RUN ./configure
RUN make -j 4
RUN make install
# =================================


# Build libx264
# =================================
WORKDIR /usr/local/src/x264
RUN ./configure --enable-static
RUN make -j 4
RUN make install
# =================================


# Build libx265
# =================================
WORKDIR  /usr/local/src/x265/build/linux
RUN cmake -D CMAKE_INSTALL_PREFIX:PATH=/usr \
          -D BUILD_SHARED_LIBS=OFF \
          ../../source
RUN make -j 4
RUN make install
# =================================

# Build libfdk-aac
# =================================
WORKDIR /usr/local/src/fdk-aac
RUN autoreconf -fiv
RUN ./configure --disable-shared --enable-static
RUN make -j 4
RUN make install
# =================================

# Build libvpx
# =================================
WORKDIR /usr/local/src/libvpx
RUN ./configure --disable-examples --enable-static
RUN make -j 4
RUN make install
# =================================

# Build libopus
# =================================
WORKDIR /usr/local/src/opus
RUN ./autogen.sh
RUN ./configure --disable-shared --enable-static
RUN make -j 4
RUN make install
# =================================

# Build OpenCV 3.x
# =================================
RUN apt-get update -qq && apt-get install -y --force-yes libopencv-dev
WORKDIR /usr/local/src
RUN mkdir -p opencv/release
WORKDIR /usr/local/src/opencv/release
RUN cmake -D OPENCV_EXTRA_MODULES_PATH=/usr/local/src/opencv_contrib/modules \
          -D CMAKE_BUILD_TYPE=RELEASE \
          -D BUILD_SHARED_LIBS=OFF \
          -D WITH_FFMPEG=OFF \
          -D BUILD_PNG=ON \
          -D BUILD_JPEG=ON \
          -D BUILD_ZLIB=ON \
          -D WITH_GTK=OFF \
          -D WITH_GTK_2_X=OFF \
          -D WITH_1394=OFF \
          -D WITH_V4L=OFF \
          -D WITH_LIBV4L=OFF \
          -D WITH_TBB=OFF \
          -D BUILD_PYTHON_SUPPORT=OFF \
          -D BUILD_DOCS=OFF \
          -D BUILD_TESTS=OFF \
          -D BUILD_PERF_TESTS=OFF \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          ..

RUN make -j4
RUN make install
RUN sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
RUN ldconfig
# =================================


# Build ffmpeg.
# =================================
#RUN apt-get update -qq && apt-get install -y --force-yes \
#    libass-dev

#WORKDIR /usr/local/src/ffmpeg
#RUN ./configure --pkg-config-flags="--static" \
#            --extra-libs="-ldl" \
#            --enable-gpl \
#            --enable-libass \
#            --enable-libfdk-aac \
#            --enable-libfontconfig \
#            --enable-libfreetype \
#            --enable-libfribidi \
#            --enable-libmp3lame \
#            --enable-libopus \
#            --enable-libtheora \
#            --enable-libvorbis \
#            --enable-libvpx \
#            --enable-libx264 \
#            --enable-libx265 \
#            --enable-nonfree
#RUN make -j 4
#RUN make install
# =================================


# Remove all tmpfile
# =================================
WORKDIR /usr/local/
RUN rm -rf /usr/local/src
# =================================

# Install pip
# =================================
#RUN curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | python
