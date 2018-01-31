### ALPINE LINUX BASED JENKINS BUILD SLAVE INCLUDE ORACLE JDK8
### VERSION COMMON(JAVA, MAVEN, GO, RUBY, NPM, NODE) 
FROM alpine:3.7
LABEL maintainer Github:geils <isgenez@gmail.com>

ENV JDK_VER=8u161 \
    JAVA_HOME=/usr/lib/jvm/java-8-oracle \
    M2_HOME=/usr/local/maven \
    GOROOT=/usr/local/go
    

RUN apk update && \
    apk add --no-cache wget ca-certificates alpine-sdk autoconf automake \
                       unzip bash coreutils openssl libstdc++ zip su-exec \
                       ruby ruby-bundler nodejs openssh-client

RUN addgroup jenkins && adduser -G jenkins -G root -s /bin/bash -D jenkins && \
    mkdir -p /home/jenkins/workspace && chown -R jenkins:jenkins /home/jenkins

##########################
### INSTALL GLIBC 2.26 ###
##########################
RUN wget --no-check-certificate --progress=bar:force https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub \
    -O /etc/apk/keys/sgerrand.rsa.pub && \
    wget --no-check-certificate --progress=bar:force https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-2.26-r0.apk \
         https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-bin-2.26-r0.apk \
         https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.26-r0/glibc-i18n-2.26-r0.apk && \
    apk add --no-cache glibc-2.26-r0.apk glibc-bin-2.26-r0.apk glibc-i18n-2.26-r0.apk && \
    rm /etc/apk/keys/sgerrand.rsa.pub && \
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 C.UTF-8 && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    apk del glibc-i18n && \
    rm /root/.wget-hsts && \
    rm glibc-2.26-r0.apk glibc-bin-2.26-r0.apk glibc-i18n-2.26-r0.apk

 
########################
### TIMEZONE SETTING ###
########################
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Seoul /etc/localtime && \
    echo "Asia/Seoul" > /etc/timezone && \
    date && apk del tzdata


##########################
### DOWNLOAD JDK 8u161 ###
##########################
RUN wget --progress=bar:force --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
    "http://download.oracle.com/otn-pub/java/jdk/8u161-b12/2f38c3b165be4555a1fa6e98c45e0808/jdk-8u161-linux-x64.tar.gz" -O /tmp/jdk-${JDK_VER}-linux-x64.tar.gz && \
    tar -xvf /tmp/jdk-${JDK_VER}-linux-x64.tar.gz -C /tmp/ && \
    mkdir -p /usr/lib/jvm && mv /tmp/jdk1.8.0_161 ${JAVA_HOME} && \
    rm -rf "${JAVA_HOME}/"src.zip && \
    rm -rf "${JAVA_HOME}/lib/missioncontrol" \
           "${JAVA_HOME}/lib/visualvm" \
           "${JAVA_HOME}/lib/"*javafx* \
           "${JAVA_HOME}/jre/lib/plugin.jar" \
           "${JAVA_HOME}/jre/lib/ext/jfxrt.jar" \
           "${JAVA_HOME}/jre/bin/javaws" \
           "${JAVA_HOME}/jre/lib/javaws.jar" \
           "${JAVA_HOME}/jre/lib/desktop" \
           "${JAVA_HOME}/jre/plugin" \
           "${JAVA_HOME}/jre/lib/"deploy* \
           "${JAVA_HOME}/jre/lib/"*javafx* \
           "${JAVA_HOME}/jre/lib/"*jfx* \
           "${JAVA_HOME}/jre/lib/amd64/libdecora_sse.so" \
           "${JAVA_HOME}/jre/lib/amd64/"libprism_*.so \
           "${JAVA_HOME}/jre/lib/amd64/libfxplugins.so" \ 
           "${JAVA_HOME}/jre/lib/amd64/libglass.so" \
           "${JAVA_HOME}/jre/lib/amd64/libgstreamer-lite.so" \
           "${JAVA_HOME}/jre/lib/amd64/"libjavafx*.so \
           "${JAVA_HOME}/jre/lib/amd64/"libjfx*.so && \
    rm -rf "${JAVA_HOME}/jre/bin/jjs" \
           "${JAVA_HOME}/jre/bin/keytool" \
           "${JAVA_HOME}/jre/bin/orbd" \
           "${JAVA_HOME}/jre/bin/pack200" \
           "${JAVA_HOME}/jre/bin/policytool" \
           "${JAVA_HOME}/jre/bin/rmid" \
           "${JAVA_HOME}/jre/bin/rmiregistry" \
           "${JAVA_HOME}/jre/bin/servertool" \
           "${JAVA_HOME}/jre/bin/tnameserv" \
           "${JAVA_HOME}/jre/bin/unpack200" \
           "${JAVA_HOME}/jre/lib/ext/nashorn.jar" \
           "${JAVA_HOME}/jre/lib/jfr.jar" \
           "${JAVA_HOME}/jre/lib/jfr" \
           "${JAVA_HOME}/jre/lib/oblique-fonts" && \
    wget --progress=bar:force --header "Cookie: oraclelicense=accept-securebackup-cookie;" \
        "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip" -O /tmp/jce_policy-8.zip && \
    unzip -jo -d "${JAVA_HOME}/jre/lib/security" "/tmp/jce_policy-8.zip" && \
    rm /tmp/*
    

###########################
### INSTALL MAVEN 3.5.2 ###
###########################
RUN wget --progress=bar:force http://apache.tt.co.kr/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz -O /tmp/maven.tar.gz && \
    cd /tmp && tar -xvf maven.tar.gz && mv /tmp/apache-maven-3.5.2 /usr/local/maven && \
    rm -rf /tmp/maven*


########################
### INSTALL GO 1.9.3 ###
########################
RUN wget --progress=bar:force https://dl.google.com/go/go1.9.3.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    cd /tmp && tar -xvf go.tar.gz && mv /tmp/go /usr/local/ && \
    rm -rf /tmp/go*


##########################
### INSTALL JNLP AGENT ###
##########################
RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/3.16/remoting-3.16.jar && \
    chmod -R 755 /usr/share/jenkins && \
    chown -R jenkins:jenkins /usr/share/jenkins/slave.jar && \
    chown -R jenkins:jenkins /usr/local


### SET ENV
ENV PATH=$PATH:${JAVA_HOME}/bin:${M2_HOME}/bin:${GOROOT}/bin \
    LANG=C.UTF-8


EXPOSE 50000
VOLUME /home/jenkins
COPY jenkins-slave /usr/local/bin/jenkins-slave
WORKDIR /home/jenkins
ENTRYPOINT ["jenkins-slave"]
