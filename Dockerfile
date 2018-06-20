# Copyright 2018 Netflix, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM ubuntu:xenial
MAINTAINER Netflix Open Source Development <talent@netflix.com>

ENV SECURITY_MONKEY_VERSION=v1.0 

SHELL ["/bin/bash", "-c"]
WORKDIR /usr/local/src/security_monkey
COPY requirements.txt /usr/local/src/security_monkey/

RUN echo "UTC" > /etc/timezone

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl apt-transport-https && \
    curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential python-pip python-dev util-linux && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y wget postgresql postgresql-contrib libpq-dev libffi-dev libxml2-dev libxmlsec1-dev dart nginx && \
    apt-get clean -y && \
    pip install setuptools --upgrade && \
    pip install pip --upgrade && \
    hash -d pip && \
    pip install "urllib3[secure]" --upgrade && \
    pip install google-compute-engine && \
    pip install cloudaux\[gcp\] && \
    pip install cloudaux\[openstack\] && \
    pip install python-saml && \
    pip install -r requirements.txt
    
COPY . /usr/local/src/security_monkey
RUN pip install ."[onelogin]" && \
    /bin/mkdir -p /var/log/security_monkey/ && \
    /usr/bin/touch /var/log/security_monkey/securitymonkey.log && \
    cd /usr/local/src/security_monkey/dart && \
    /usr/lib/dart/bin/pub get && \
    /usr/lib/dart/bin/pub build && \
    mkdir -p /usr/local/src/security_monkey/security_monkey/static/ && \
    /bin/cp -R /usr/local/src/security_monkey/dart/build/web/* /usr/local/src/security_monkey/security_monkey/static/ && \
    chgrp -R www-data /usr/local/src/security_monkey && \
    cp /usr/local/src/security_monkey/nginx/security_monkey.conf /etc/nginx/sites-available/security_monkey.conf && \
    ln -s /etc/nginx/sites-available/security_monkey.conf /etc/nginx/sites-enabled/security_monkey.conf && \
    rm /etc/nginx/sites-enabled/default

EXPOSE 5000 8080
