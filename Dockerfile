FROM ubuntu:21.10

LABEL org.opencontainers.image.authors="docker_android_studio_860dd6@egli.online, yoep.kortekaas@gmail.com"


ARG USER=android

RUN dpkg --add-architecture i386
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential git neovim wget unzip sudo \
        libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386 \
        libxrender1 libxtst6 libxi6 libfreetype6 libxft2 \
        qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils libnotify4 libglu1 libqt5widgets5 openjdk-8-jdk xvfb \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -g 1000 -r $USER
RUN useradd -u 1000 -g 1000 --create-home -r $USER
RUN adduser $USER libvirt
RUN adduser $USER kvm
#Change password
RUN echo "$USER:$USER" | chpasswd
#Make sudo passwordless
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USER
RUN usermod -aG sudo $USER
RUN usermod -aG plugdev $USER

VOLUME /androidstudio-data
RUN chown $USER:$USER /androidstudio-data

COPY provisioning/docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
COPY provisioning/ndkTests.sh /usr/local/bin/ndkTests.sh
RUN chmod +x /usr/local/bin/*
COPY provisioning/51-android.rules /etc/udev/rules.d/51-android.rules

### Android Studio Install
# Set user to $USER
USER $USER

# Change to $USER's homedir
WORKDIR /home/$USER

# Android Studio version
ENV ANDROID_STUDIO_VERSION=2021.1.1.22

# Download Android Studio binary
RUN wget --no-verbose https://dl.google.com/dl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz

# Unpack Android Studio tar
RUN tar xf android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz

# Remove Android Studio tar
RUN rm android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz

# Add android studio to path
ENV PATH="${PATH}:/opt/android-studio/bin"

# Create symlinks
RUN ln -s /studio-data/profile/AndroidStudio$ANDROID_STUDIO_VERSION .AndroidStudio$ANDROID_STUDIO_VERSION
RUN ln -s /studio-data/Android Android
RUN ln -s /studio-data/profile/android .android
RUN ln -s /studio-data/profile/java .java
RUN ln -s /studio-data/profile/gradle .gradle
ENV ANDROID_EMULATOR_USE_SYSTEM_LIBS=1

### /Android Studio Install

WORKDIR /home/$USER

ENTRYPOINT [ "/usr/local/bin/docker_entrypoint.sh" ]
