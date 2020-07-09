FROM alpine:3.11 AS cmps
ARG compose_version=1.25.5

RUN apk -U --no-cache add \
    python2 py2-pip python2-dev \
    make gcc musl-dev libffi-dev openssl-dev zlib-dev\
    git && \
    pip install pycrypto

RUN git clone --depth 1 --branch ${compose_version} https://github.com/docker/compose.git /code/compose

RUN cd /code/compose && \
    pip --no-cache-dir install -r requirements.txt -r requirements-dev.txt && \
    git rev-parse --short HEAD > compose/GITSHA

# Build python-installer with bootloader for alpine/musl
RUN git clone --depth 1 --single-branch --branch master https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
    && cd /tmp/pyinstaller/bootloader \
    && CFLAGS="-Wno-stringop-overflow -Wno-stringop-truncation" python ./waf configure --no-lsb all \
    && pip install .. \
    && rm -Rf /tmp/pyinstaller

# NOTE that python > 3.6 is currently not supported
# https://github.com/pyinstaller/pyinstaller/issues/4311s
# alpine 3.11 is last to support python 2

#statically link docker-compose
RUN cd /code/compose && \
    pyinstaller --onefile docker-compose.spec && \
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
RUN  \
  curl https://download.docker.com/linux/static/stable/x86_64/docker-19.03.10.tgz | tar xvz -C /tmp/ && \
  mv /tmp/docker/docker /usr/bin/docker
