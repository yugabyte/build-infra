FROM centos:8

COPY docker_setup_scripts /tmp/yb_docker_setup_scripts

RUN bash /tmp/yb_docker_setup_scripts/redhat.sh

USER yugabyteci
