#!/bin/bash

: ${HADOOP_HOME:=/usr/local/hadoop}

$HADOOP_HOME/etc/hadoop/hadoop-env.sh

if [[ $1 = "--namenode" ]]; then
	hdfs namenode
elif [[ $1 = "--secondarynamenode" ]]; then
	hdfs secondarynamenode
elif [[ $1 = "--datanode" ]]; then
	hdfs datanode
elif [[ $1 = "--yarn" ]]; then
	$HADOOP_COMMON_HOME/sbin/yarn-daemon.sh start resourcemanager
	$HADOOP_COMMON_HOME/sbin/mr-jobhistory-daemon.sh start historyserver
	/usr/sbin/sshd -D
fi

if [[ $2 = "--init-dfs-dirs" ]]; then
	# Create HDFS directories will be used by YARN Map Reduce Staging, YARN Log & Job History Server
	hdfs dfs -mkdir /tmp && \
	hdfs dfs -chmod -R 1777 /tmp && \
	hdfs dfs -mkdir /user/app && \
	hdfs dfs -chmod -R 1777 /user && \
	hdfs dfs -mkdir -p /var/log/hadoop-yarn/apps && \
	hdfs dfs -chmod -R 1777 /var/log/hadoop-yarn
fi
