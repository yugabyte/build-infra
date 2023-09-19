FROM debian:10.9

COPY docker_setup_scripts /tmp/yb_docker_setup_scripts
RUN bash /tmp/yb_docker_setup_scripts/debian.sh

USER yugabyteci
