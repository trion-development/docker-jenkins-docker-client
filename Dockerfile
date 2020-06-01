FROM alpine AS cmps
ARG compose_version=1.25.5

RUN apk --no-cache add \
    pwgen gcc g++ musl-dev libc-dev python-dev libffi-dev openssl-dev make\
    python py-pip git && \
    pip install pycrypto pyinstaller

RUN git clone --depth 1 --branch ${compose_version} https://github.com/docker/compose.git /code/compose

RUN cd /code/compose && \
    pip --no-cache-dir install -r requirements.txt -r requirements-dev.txt && \
    git rev-parse --short HEAD > compose/GITSHA

  # NOTE that python 3.8 is currently not supported
  # https://github.com/pyinstaller/pyinstaller/issues/4311

#statically link docker-compose
RUN cd /code/compose && \
    pyinstaller docker-compose.spec && \
    mv dist/docker-compose /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose



FROM jenkins/jenkins:alpine

MAINTAINER trion development GmbH "info@trion.de"

ENV JENKINS_USER=jenkins
USER root
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
RUN apk --no-cache add shadow su-exec

COPY --from=cmps /usr/local/bin/docker-compose /usr/bin/docker-compose
RUN ln -s /lib /lib64 && \
  ln -s /lib/ld-musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
  curl https://get.docker.com/builds/Linux/x86_64/docker-latest.tgz | tar xvz -C /tmp/ && \
  mv /tmp/docker/docker /usr/bin/docker
