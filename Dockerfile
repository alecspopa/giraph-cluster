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
    DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common wget openssh-client iputils-ping && \
    add-apt-repository ppa:openjdk-r/ppa

# Passwordless SSH
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# JAVA
ENV JAVA_HOME		/usr/lib/jvm/java-7-openjdk-amd64

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-7-jdk && \
    rm -rf /var/lib/apt/lists/*

# HADOOP
ENV HADOOP_VERSION	2.7.1
ENV HADOOP_HOME		/usr/local/hadoop
ENV HADOOP_OPTS		-Djava.library.path=$HADOOP_HOME/lib/native
ENV PATH		    $PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libzip4 libsnappy1v5 libssl-dev && \
    wget --quiet http://archive.apache.org/dist/hadoop/core/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz && \
    tar -zxf hadoop-$HADOOP_VERSION.tar.gz && \
    rm hadoop-$HADOOP_VERSION.tar.gz && \
    mv hadoop-$HADOOP_VERSION $HADOOP_HOME && \
    mkdir -p $HADOOP_HOME/logs

# Overwrite default HADOOP configuration files with our config files
COPY conf           $HADOOP_HOME/etc/hadoop/
RUN chown root:root $HADOOP_HOME/etc/hadoop/* && \
    chmod 700 $HADOOP_HOME/etc/hadoop/*

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
WORKDIR $HADOOP_HOME

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
