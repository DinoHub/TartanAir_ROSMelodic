### Instructions for Docker
## build image from this dockerfile. E.g. IMAGE_NAME = tartanair, IMAGE_TAG = rosmelodic
# docker build -t <IMAGE_NAME>:<IMAGE_TAG> --build-arg GITHUB_USER=<user> --build-arg GITHUB_PWD=<password> .

## run a container from the built image. vol should include TartanAir Codes
# xhost +local:docker && docker run --rm -it -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" -v "/path/to/your/vol:/workspace/TartanAir" -e "DISPLAY=${DISPLAY}" --ipc="host" <IMAGE_NAME>:<IMAGE_TAG>
# xhost +local:docker && docker run --rm -it -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" -v "/mnt/hdd/workspace_tartanair/docker_vol:/workspace" -e "DISPLAY=${DISPLAY}" --ipc="host" tartanair:rosmelodic

## save the container settings
# docker container ls -a		(to get CONTAINER_NAME)
# docker commit <CONTAINER_NAME> <IMAGE_NAME>:<IMAGE_TAG> 

## Open another bash
# docker exec -it <CONTAINER_NAME> bash

## Open another bash with display
# xhost +local:docker && docker exec -it -e "DISPLAY=${DISPLAY}" <CONTAINER_NAME> bash


FROM osrf/ros:melodic-desktop-full
SHELL ["/bin/bash", "-c"]

USER root


# ==============================
# Configurable params
# ==============================
ARG GITHUB_USER
ARG GITHUB_PWD
RUN env


# ==============================
# Replace with local SG mirrors
# ==============================
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1sg.\2/" /etc/apt/sources.list
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ Asia/Singapore
RUN apt-get update
RUN apt-get install -y --no-install-recommends sudo curl tzdata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && sudo dpkg-reconfigure -f noninteractive tzdata


# ==============================
# UI Support
# ==============================
# Enable Vulkan support
RUN sudo apt-get install -y --no-install-recommends libvulkan1 && \
	VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9|\.]+'` && \
	mkdir -p /etc/vulkan/icd.d/ && \
	echo \
	"{\
		\"file_format_version\" : \"1.0.0\",\
		\"ICD\": {\
			\"library_path\": \"libGLX_nvidia.so.0\",\
			\"api_version\" : \"${VULKAN_API_VERSION}\"\
		}\
	}" > /etc/vulkan/icd.d/nvidia_icd.json

# Enable X11 support (including the libraries required by CEF) and xvfb so we can create a dummy display if needed
RUN sudo apt-get install -y --no-install-recommends \
	libasound2 \
	libatk1.0-0 \
	libcairo2 \
	libfontconfig1 \
	libfreetype6 \
	libglu1 \
	libnss3 \
	libnspr4 \
	libpango-1.0-0 \
	libpangocairo-1.0-0 \
	libsm6 \
	libxcomposite1 \
	libxcursor1 \
	libxi6 \
	libxrandr2 \
	libxrender1 \
	libxss1 \
	libxv1 \
	x11-xkb-utils \
	xauth \
	xfonts-base \
	xkb-data \
	xvfb


# ============================== 
# User Setup
# ==============================
# add a user with the same USERID as the user outside the container
ARG USERID=1000
ENV USERNAME dev
ENV USER=developer
RUN useradd -U $USERNAME --uid $USERID -ms /bin/bash \
 && echo "$USERNAME:$USERNAME" | chpasswd \
 && adduser $USERNAME sudo \
 && echo "$USERNAME ALL=NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME
RUN sudo chown --recursive $USERNAME:$USERNAME /home/$USERNAME
# Commands below run as the dev user
USER $USERNAME
# When running a container start in the dev's home folder
WORKDIR /home/$USERNAME


# ============================== 
# Install General Tools
# ============================== 
RUN sudo apt-get update \
	&& sudo apt-get install -y --no-install-recommends \
  	build-essential \
  	software-properties-common \
 	cmake \
  	cppcheck \
  	git \
	wget \
	curl \
	gedit \
	vim \
	tmux \
	python-pip \
	python-requests \
	ros-melodic-catkin \
	python-catkin-pkg


RUN sudo apt-get install ros-melodic-octomap ros-melodic-octomap-mapping ros-melodic-octomap-msgs ros-melodic-octomap-ros ros-melodic-octomap-rviz-plugins ros-melodic-octomap-server ros-melodic-dynamic-edt-3d -y --no-install-recommends
RUN sudo apt-get install ros-melodic-catkin ros-melodic-teleop-twist-keyboard python-pip python-setuptools python-wstool python-catkin-tools -y --no-install-recommends
RUN sudo apt-get install ros-melodic-cmake-modules 
RUN sudo apt-get update && sudo apt-get install python-tk python-numba python-pandas -y --no-install-recommends
RUN pip install pip wheel msgpack-rpc-python pyquaternion scipy networkx


# ============================== 
# Configuration
# ============================== 
# Add to bashrc
RUN echo "source /opt/ros/melodic/setup.bash" >> ~/.bashrc


# ==========================
# Cleanup
# ==========================
RUN sudo apt-get clean autoremove


# ============================== 
# HW Accelerate
# ============================== 
# run xhost +local:docker on your host machine if any issues opening UI
# test with cmd: roscore & rviz
# enable NVIDIA Container Toolkit (https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/user-guide.html#dockerfiles)
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES all
# ENV SDL_VIDEODRIVER=offscreen
ENV SDL_HINT_CUDA_DEVICE=0
ENV QT_X11_NO_MITSHM=1


# =================================== 
# Set working directory for container
# =================================== 
WORKDIR /$FOLDER_NAME
