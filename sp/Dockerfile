FROM --platform=$TARGETPLATFORM rockylinux:8.6

# Define args and set a default value
ARG maintainer=tier
ARG imagename=shibboleth_sp
ARG version=3.4.1
ARG TIERVERSION=20230612-Rocky8-MA

MAINTAINER $maintainer
LABEL Vendor="Internet2"
LABEL ImageType="Base"
LABEL ImageName=$imagename
LABEL ImageOS=rocky8
LABEL Version=$version

LABEL Build docker build --rm --tag $maintainer/$imagename .

#For logging customization
ENV ENV=dev \
    USERTOKEN=nothing

RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && echo "NETWORKING=yes" > /etc/sysconfig/network

RUN rm -fr /var/cache/yum/* && yum clean all && yum -y install --setopt=tsflags=nodocs epel-release && yum -y update && \
    yum -y install net-tools wget curl tar unzip mlocate logrotate strace telnet man vim rsyslog httpd mod_ssl dos2unix cronie supervisor && \
    yum clean all

#install shibboleth, cleanup httpd
COPY container_files/shibboleth/shibboleth.repo /etc/yum.repos.d/security:shibboleth.repo
RUN yum -y install shibboleth-$version-\* \
      && yum clean all

ADD ./container_files/httpd/*.conf /etc/httpd/conf.d/
ADD ./container_files/shibboleth/* /etc/shibboleth/

RUN openssl req -new -nodes -newkey rsa:2048 -subj "/commonName=localhost.localdomain" -batch -keyout /etc/pki/tls/private/localhost.key -out localhost.csr
RUN openssl x509 -req -days 1825 -in localhost.csr -signkey /etc/pki/tls/private/localhost.key -out /etc/pki/tls/certs/localhost.crt
RUN sed -i '/^[[:space:]]*CustomLog/s/^/#/' /etc/httpd/conf/httpd.conf

# add a basic page to shibd's default protected directory
RUN mkdir -p /var/www/html/secure/; mkdir -p /opt/tier/
ADD container_files/httpd/index.html /var/www/html/secure/

# setup crond and supervisord
ADD container_files/system/startup.sh /usr/local/bin/
ADD container_files/system/setupcron.sh /usr/local/bin/
ADD container_files/system/setenv.sh /opt/tier/
ADD container_files/system/sendtierbeacon.sh /usr/local/bin/
ADD container_files/system/supervisord.conf /etc/supervisord.conf
RUN mkdir -p /etc/supervisor/conf.d  \
    && chmod +x /usr/local/bin/setupcron.sh \
    && chmod +x /usr/local/bin/sendtierbeacon.sh \
# setup cron
    && /usr/local/bin/setupcron.sh

#set cron to not require a login session
RUN sed -i '/session    required   pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/crond

# Link the old location of the file for compatibility
RUN cd /etc/supervisor && ln -s ../supervisord.conf supervisord.conf

EXPOSE 80 443

HEALTHCHECK --interval=1m --timeout=30s \
  CMD curl -k -f https://127.0.0.1/Shibboleth.sso/Status || exit 1

CMD ["/usr/local/bin/startup.sh"]

# ------------------------------------------------------------------------------

# Install necessary packages for rbenv, ruby, and Reciprocal Borrowing
RUN yum update -y && \
    dnf -y install git make gcc curl openssl-devel zlib-devel libffi-devel readline-devel sqlite-devel && \
    yum -y --enablerepo=powertools install libyaml-devel && \
    yum -y install gcc-c++ && \
    yum install -y yum-utils && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(< /etc/redhat-release tr -dc '0-9.'|cut -d \. -f1).noarch.rpm && \
    yum-config-manager --enable epel && \
    yum clean all

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version of
# umd-lib/reciprocal-borrowing
ARG RUBY_VERSION=3.4.7

# Install rbenv and ruby
RUN  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    source ~/.bashrc && \
    rbenv install ${RUBY_VERSION} && \
    rbenv global ${RUBY_VERSION}

# Install Passenger Phusion
RUN yum update -y && \
    curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo && \
    yum install -y mod_passenger || { yum-config-manager --enable cr && sudo yum install -y mod_passenger ; } && \
    yum clean all

ARG NODE_VERSION=24
ARG YARN_VERSION=1.22.22

# Install NVM and Node
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" && \
    nvm install ${NODE_VERSION}

# Install yarn and nodemon for local development
RUN npm install -g yarn@${YARN_VERSION} nodemon

# Set permissions to /root to enable Apache to access it
RUN chmod 755 /root
