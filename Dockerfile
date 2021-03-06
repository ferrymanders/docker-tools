FROM katoma/base

MAINTAINER Katoma

ENV TERRAFORM_VERSION=0.11.7
ENV PACKER_VERSION=1.2.4
ENV DOCKER_VERSION=18.03.1-ce
ENV GCLOUD_VERSION=208.0.2
ENV OC_VERSION=v3.9.0
ENV OC_HASH=191fece
ENV GLIBC_VERSION=2.27-r0
ENV GLIBC_URL=https://github.com/sgerrand/alpine-pkg-glibc/releases/download
ENV GLIBC_PUB=https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master/sgerrand.rsa.pub
ENV PUID=1001
ENV USER=ferry
ENV PGID=20
ENV GROUP=staff
ENV HOSTOS=mac
ENV LANG=C.UTF-8

ADD docker-entrypoint.sh /docker-entrypoint.sh

RUN echo "## Install Basic Tools" \
    && apk add --no-cache \
            curl \
            vim \
            coreutils \
            shadow \
            openssh \
            git \
            rsync \
            sudo \
            ca-certificates \
    && echo "## Install glibc" \
    && curl -s -L -o /tmp/glibc-${GLIBC_VERSION}.apk ${GLIBC_URL}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    && curl -s -L -o /tmp/glibc-bin-${GLIBC_VERSION}.apk ${GLIBC_URL}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
    && curl -s -L -o /tmp/glibc-i18n-${GLIBC_VERSION}.apk ${GLIBC_URL}/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk \
    && curl -s -L -o /etc/apk/keys/sgerrand.rsa.pub ${GLIBC_PUB} \
    && apk add --no-cache \
            /tmp/glibc-${GLIBC_VERSION}.apk \
            /tmp/glibc-bin-${GLIBC_VERSION}.apk \
            /tmp/glibc-i18n-${GLIBC_VERSION}.apk \
    && rm /etc/apk/keys/sgerrand.rsa.pub \
    && /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true \
    && echo "export LANG=$LANG" > /etc/profile.d/locale.sh \
    && apk del glibc-i18n \
    && echo "### Install Tool : Bash Completion" \
    && apk add --no-cache \
            bash-completion \
            docker-bash-completion \
            git-bash-completion \
    && echo "### Install Tool : Ansible" \
    && apk add --no-cache \
            ansible \
    && echo "### Install Tool : Terraform" \
    && curl -s -o /tmp/terraform.zip \
          https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip -q -d /usr/local/bin /tmp/terraform.zip \
    && echo "### Install Tool : Packer" \
    && curl -s -o /tmp/packer.zip \
          https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip -q -d /usr/local/bin /tmp/packer.zip \
    && echo "### Install Tool : Docker" \
    && curl -s -L -o /tmp/docker.tgz \
          https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
    && tar -zx -C /tmp -f /tmp/docker.tgz \
    && mv /tmp/docker/docker /usr/local/bin \
    && echo "### Install Tool : Google SDK" \
    && curl -s -o /tmp/gcloud.tgz \
          https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_VERSION}-linux-x86_64.tar.gz \
    && tar -zx -C /tmp -f /tmp/gcloud.tgz \
    && /tmp/google-cloud-sdk/install.sh \
          -q \
          --usage-reporting false \
          --additional-components \
              beta \
              app-engine-php \
              container-builder-local \
              docker-credential-gcr \
    && cp -r /tmp/google-cloud-sdk /usr/local/share/ \
    && echo "### Install Tool : OpenShift Client" \
    && curl -s -L -o /tmp/oc.tgz \
          https://github.com/openshift/origin/releases/download/${OC_VERSION}/openshift-origin-client-tools-${OC_VERSION}-${OC_HASH}-linux-64bit.tar.gz \
    && tar -zx -C /tmp -f /tmp/oc.tgz \
    && cp /tmp/openshift-origin-client-tools-${OC_VERSION}-${OC_HASH}-linux-64bit/oc /usr/local/bin/ \
    && echo "## Add User" \
    && if [ "$HOSTOS" == "mac" ]; then groupdel dialout; fi \
    && groupadd -g ${PGID} ${GROUP} \
    && useradd -u ${PUID} -U -d /home/${USER} -s /bin/bash ${USER} \
    && usermod -G ${GROUP} ${USER} \
    && echo "${USER} ALL=NOPASSWD: ALL" >> /etc/sudoers \
    && echo "## Adjust Rights" \
    && chmod +x /docker-entrypoint.sh \
    && echo "## Clean-up" \
    && rm -rf /tmp/*

WORKDIR /home/${USER}

USER ${USER}

CMD /docker-entrypoint.sh
