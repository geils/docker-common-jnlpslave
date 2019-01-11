### ALPINE LINUX BASED JENKINS BUILD SLAVE INCLUDE ORACLE JDK8
### VERSION COMMON(JAVA, MAVEN, GO, RUBY, NPM, NODE)
### LAST AUDIT DATE : 2019. 01. 11

FROM alpine:3.8
LABEL maintainer Github:geils <isgenez@gmail.com>

ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
    M2_HOME=/usr/local/maven \
    GOROOT=/usr/local/go \
    LANG=C.UTF-8 \
    GLIBC_VER=2.28-r0
    

RUN apk update && \
    apk add --no-cache wget ca-certificates alpine-sdk autoconf automake \
                       unzip bash coreutils openssl libstdc++ zip su-exec \
                       ruby ruby-bundler nodejs openssh-client npm

RUN addgroup jenkins && adduser -G jenkins -G root -s /bin/bash -D jenkins && \
    mkdir -p /home/jenkins/workspace && chown -R jenkins:jenkins /home/jenkins && \
    npm config set prefix '~/.npm~global'

#############################
### INSTALL GLIBC 2.28-r0 ###
#############################
RUN echo \
    "-----BEGIN PUBLIC KEY-----\
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
    y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
    tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
    m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
    KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
    Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
    1QIDAQAB\
    -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget --no-check-certificate --progress=bar:force https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
         https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
         https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk && \
    apk add --no-cache glibc-${GLIBC_VER}.apk glibc-bin-${GLIBC_VER}.apk glibc-i18n-${GLIBC_VER}.apk && \
    rm /etc/apk/keys/sgerrand.rsa.pub && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "${LANG}" || true && \
    echo "export LANG=${LANG}" > /etc/profile.d/locale.sh && \
    apk del glibc-i18n && \
    rm /root/.wget-hsts && \
    rm glibc-${GLIBC_VER}.apk glibc-bin-${GLIBC_VER}.apk glibc-i18n-${GLIBC_VER}.apk

 
########################
### TIMEZONE SETTING ###
########################
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    echo "Asia/Seoul" > /etc/timezone && \
    date && apk del tzdata


##############################
### DOWNLOAD OPENJDK 8u191 ###
##############################
RUN apk add --no-cache openjdk8=8.191.12-r0

###########################
### INSTALL MAVEN 3.5.4 ###
###########################
RUN apk add --no-cache maven=3.5.4-r1

#########################
### INSTALL GO 1.10.7 ###
#########################
RUN apk add --no-cache go=1.10.7-r0

##########################
### INSTALL JNLP AGENT ###
##########################
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/3.27/remoting-3.27.jar && \
    chmod -R 755 /usr/share/jenkins && \
    chown -R jenkins:jenkins /usr/share/jenkins/slave.jar && \
    chown -R jenkins:jenkins /usr/local


### SET ENV
ENV PATH=~/.npm-global/bin:$PATH:${JAVA_HOME}/bin:${M2_HOME}/bin:${GOROOT}/bin \
    LANG=C.UTF-8


EXPOSE 50000
VOLUME /home/jenkins
COPY jenkins-slave /usr/local/bin/jenkins-slave
WORKDIR /home/jenkins
ENTRYPOINT ["jenkins-slave"]
