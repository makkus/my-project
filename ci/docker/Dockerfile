FROM debian:stable

RUN \
   apt update -y && \
   apt install -y wget git

COPY my-project /usr/bin/my-project

RUN \
   chmod +x /usr/bin/my-project
