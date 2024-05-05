#FROM alpine:3.12 AS cmps

#RUN apk -U --no-cache add \
#    python3 py3-pip python3-dev \
#    make gcc musl-dev libffi-dev openssl-dev zlib-dev\
#    git && \
#    pip install pycrypto

# python 3.12: module imp was renamed
# python 3.11: KeyError: 'CALL_FUNCTION'
# python 3.10 requires pyinstaller v5.x

FROM python:3.10-alpine3.19 AS cmps
RUN apk -U --no-cache add \
   make gcc musl-dev libffi-dev openssl-dev zlib-dev\
   git \
   rust cargo && \
   pip install pycrypto

ARG compose_version=1.29.2

RUN git clone --depth 1 --branch ${compose_version} https://github.com/docker/compose.git /code/compose

RUN cd /code/compose && \
    sed -i "s/PyYAML==5.4.1/PyYAML>=5.3,<7/g" requirements.txt && \
    pip --no-cache-dir install -r requirements.txt -r requirements-dev.txt --ignore-installed && \
    git rev-parse --short HEAD > compose/GITSHA

# Build python-installer with bootloader for alpine/musl
RUN git clone --depth 1 --single-branch --branch v5.13.2 https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
    && cd /tmp/pyinstaller/bootloader \
    && CFLAGS="-Wno-stringop-overflow -Wno-stringop-truncation" python3 ./waf configure --no-lsb all \
    && pip install .. \
    && rm -Rf /tmp/pyinstaller

# NOTE that python 3.4 is required by latest pyinstaller (4.0)
# https://github.com/pyinstaller/pyinstaller/issues/4311
# https://pyinstaller.readthedocs.io/en/latest/CHANGES.html

#statically link docker-compose
RUN cd /code/compose && \
    pyinstaller --clean docker-compose.spec && \
    mv dist/docker-compose /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose



FROM jenkins/jenkins:alpine

MAINTAINER trion development GmbH "info@trion.de"

ENV JENKINS_USER=jenkins CASC_JENKINS_CONFIG=/var/jenkins_home/config.yaml
USER root
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
RUN apk --no-cache add shadow su-exec

COPY --from=cmps /usr/local/bin/docker-compose /usr/bin/docker-compose
RUN  \
  curl https://download.docker.com/linux/static/stable/x86_64/docker-20.10.17.tgz | tar xvz -C /tmp/ && \
  mv /tmp/docker/docker /usr/bin/docker

COPY plugins.txt config.yaml /provisioning/
COPY entrypoint.sh /usr/local/bin/
