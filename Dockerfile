FROM ubuntu:16.04
MAINTAINER Alecs Popa <Alecs Popa>

# Based on:
#    https://github.com/bigdatafoundation/docker-hadoop
#    https://github.com/riyadparvez/giraph-yarn-cluster
#    https://dwbi.org/etl/bigdata/183-setup-hadoop-cluster

RUN mkdir /root/install
WORKDIR /root/install

# Global dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common wget openssh-server openssh-client iputils-ping && \
    add-apt-repository ppa:openjdk-r/ppa

# SSH and user equivalence
RUN rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_ed25519_key && \
	ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key && \
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key && \
    sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config

RUN mkdir -p /root/.ssh
COPY ssh/id_rsa /root/.ssh/id_rsa
COPY ssh/id_rsa.pub /root/.ssh/id_rsa.pub
COPY ssh/id_rsa.pub /root/.ssh/authorized_keys
COPY ssh/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config && chown root:root /root/.ssh/config

RUN mkdir -p /var/run/sshd && \
	chmod 0755 /var/run/sshd

# JAVA
ENV JAVA_HOME		/usr/lib/jvm/java-7-openjdk-amd64

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-7-jdk && \
    rm -rf /var/lib/apt/lists/*

# HADOOP
ENV HADOOP_PREFIX /usr/local/hadoop
ENV HADOOP_COMMON_HOME /usr/local/hadoop
ENV HADOOP_HDFS_HOME /usr/local/hadoop
ENV HADOOP_MAPRED_HOME /usr/local/hadoop
ENV HADOOP_YARN_HOME /usr/local/hadoop
ENV HADOOP_CONF_DIR /usr/local/hadoop/etc/hadoop
ENV HADOOP_MAPRED_IDENT_STRING root
ENV YARN_CONF_DIR $HADOOP_PREFIX/etc/hadoop

ENV HADOOP_VERSION	2.7.1
ENV HADOOP_OPTS		-Djava.library.path=$HADOOP_COMMON_HOME/lib/native
ENV PATH		    $PATH:$HADOOP_COMMON_HOME/bin:$HADOOP_COMMON_HOME/sbin

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libzip4 libsnappy1v5 libssl-dev && \
    wget --quiet http://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -zxf hadoop-$HADOOP_VERSION.tar.gz && \
    rm hadoop-$HADOOP_VERSION.tar.gz && \
    mv hadoop-$HADOOP_VERSION $HADOOP_COMMON_HOME && \
    mkdir -p $HADOOP_COMMON_HOME/logs

# Overwrite default HADOOP configuration files with our config files
COPY conf           $HADOOP_COMMON_HOME/etc/hadoop/
RUN chown root:root $HADOOP_COMMON_HOME/etc/hadoop/* && \
    chmod 700 $HADOOP_COMMON_HOME/etc/hadoop/*

# Giraph
ENV GIRAPH_VERSION	1.1.0
ENV GIRAPH_HADOOP   2.5.1
ENV GIRAPH_HOME     /usr/local/giraph

RUN wget --quiet http://archive.apache.org/dist/giraph/giraph-$GIRAPH_VERSION/giraph-dist-$GIRAPH_VERSION-hadoop2-bin.tar.gz && \
    tar -zxf giraph-dist-$GIRAPH_VERSION-hadoop2-bin.tar.gz && \
    rm giraph-dist-$GIRAPH_VERSION-hadoop2-bin.tar.gz && \
    mv giraph-$GIRAPH_VERSION-hadoop2-for-hadoop-$GIRAPH_HADOOP $GIRAPH_HOME && \
    mkdir -p $GIRAPH_HOME/logs

# Formatting HDFS
RUN mkdir -p /hadoop_work/hdfs/namenode /hadoop_work/hdfs/secondarynamenode /hadoop_work/hdfs/datanode && \
	mkdir -p /hadoop_work/yarn/local /hadoop_work/yarn/log && \
    hdfs namenode -format
VOLUME /hadoop_work

# Cleanup APT
RUN apt-get remove -y software-properties-common wget && \
    rm -rf /var/lib/apt/lists/*

# Set working dir to Hadoop home
WORKDIR $HADOOP_COMMON_HOME

# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090
# Mapred ports
EXPOSE 10020 19888
#Yarn ports
EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh && \
    chmod 700 /etc/bootstrap.sh

CMD ["/etc/bootstrap.sh"]
