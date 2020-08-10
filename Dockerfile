#FROM alpine:3.12 AS cmps

#RUN apk -U --no-cache add \
#    python3 py3-pip python3-dev \
#    make gcc musl-dev libffi-dev openssl-dev zlib-dev\
#    git && \
#    pip install pycrypto

FROM python:3.7-alpine3.11 AS cmps
RUN apk -U --no-cache add \
   make gcc musl-dev libffi-dev openssl-dev zlib-dev\
   git && \
   pip install pycrypto

ARG compose_version=1.26.2

RUN git clone --depth 1 --branch ${compose_version} https://github.com/docker/compose.git /code/compose

RUN cd /code/compose && \
    pip --no-cache-dir install -r requirements.txt -r requirements-dev.txt --ignore-installed && \
    git rev-parse --short HEAD > compose/GITSHA

# Build python-installer with bootloader for alpine/musl
RUN git clone --depth 1 --single-branch --branch master https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
    && cd /tmp/pyinstaller/bootloader \
    && CFLAGS="-Wno-stringop-overflow -Wno-stringop-truncation" python3 ./waf configure --no-lsb all \
    && pip install .. \
    && rm -Rf /tmp/pyinstaller

# NOTE that python 3.4 is required by latest pyinstaller (4.0)
# https://github.com/pyinstaller/pyinstaller/issues/4311
# https://pyinstaller.readthedocs.io/en/latest/CHANGES.html

#statically link docker-compose
RUN cd /code/compose && \
    pyinstaller --clean --windowed --onefile docker-compose.spec && \
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
  curl https://download.docker.com/linux/static/stable/x86_64/docker-19.03.12.tgz | tar xvz -C /tmp/ && \
  mv /tmp/docker/docker /usr/bin/docker
