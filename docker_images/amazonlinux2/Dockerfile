FROM amazonlinux:2

COPY docker_setup_scripts /tmp/yb_docker_setup_scripts

RUN bash /tmp/yb_docker_setup_scripts/amzn.sh

USER yugabyteci
