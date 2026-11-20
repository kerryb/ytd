# For local testing of setup script. Run from setup diresctory with `docker
# build .`
FROM ubuntu:latest
RUN apt-get update -y
COPY setup-server.sh setup-server.sh 
COPY files files
RUN ./setup-server.sh
