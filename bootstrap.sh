#!/bin/bash

: ${HADOOP_HOME:=/usr/local/hadoop}

$HADOOP_HOME/etc/hadoop/hadoop-env.sh

service ssh start

if [[ $1 = "--namenode" ]]; then
	hdfs namenode

	# TODO
	# !!!Run these by hand for now
	#    NOTE: to connect to the running container: docker exec -it giraphcluster_namenode /bin/bash
	# yarn resourcemanager
	# yarn nodemanager
elif [[ $1 = "--datanode" ]]; then
	hdfs datanode
fi

