FROM jenkins/jenkins:alpine

MAINTAINER trion development GmbH "info@trion.de"

ENV JENKINS_USER=jenkins
USER root
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]

RUN apk --no-cache add shadow su-exec libc6-compat
RUN curl https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar xvz -C /tmp/ && mv /tmp/docker/docker /usr/bin/docker

