## Apache Giraph

Based on:
* <https://github.com/bigdatafoundation/docker-hadoop>
* <https://github.com/riyadparvez/giraph-yarn-cluster>
* <https://dwbi.org/etl/bigdata/183-setup-hadoop-cluster>

#### Building the image

	docker build --tag alecspopa/giraph-cluster .

or get it form the repository

    docker pull alecspopa/giraph-cluster

### Using docker-compose to start the containers

	docker-compose up -d && \
    	docker-compose logs

or just specific ones

    docker-compose up -d namenode datanode && \
        docker-compose logs

Start 2 datanodes

	docker-compose scale datanode=2

Start resourcemanager and nodemanager in namenode
	you'll need two console windows opened for this
TODO: this should start with the namenode

	docker exec -it giraphcluster_namenode /bin/bash
	yarn resourcemanager
	yarn nodemanager

## Test instalation

Debug Connection

	docker run -it --rm \
        --link=giraphcluster_namenode:giraphcluster-namenode \
        --net=giraphcluster_default \
        --volume=$(pwd)/tmp_work_dir:/tmp \
        alecspopa/giraph-cluster \
        /bin/bash

#### Put some data in HDFS

	copy Readme.md to tmp_work_dir

    docker run -it --rm \
        --link=giraphcluster_namenode:giraphcluster-namenode \
        --net=giraphcluster_default \
        --volume=$(pwd)/tmp_work_dir:/tmp \
        alecspopa/giraph-cluster \
        hadoop fs -put /tmp/Readme.md /README.txt

#### Start wordcount example

	docker run -it --rm \
        --link=giraphcluster_namenode:giraphcluster-namenode \
        --net=giraphcluster_default \
        alecspopa/giraph-cluster \
        hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar wordcount /README.txt /README.result

### If `README.result` already exists you need to remove it prior running the map reduce job.

    docker run -it --rm \
        --link=giraphcluster_namenode:giraphcluster-namenode \
        --net=giraphcluster_default \
        alecspopa/giraph-cluster \
        hadoop fs -rm -R -f /README.result

### Check the result

	docker run -it --rm \
        --link=giraphcluster_namenode:giraphcluster-namenode \
        --net=giraphcluster_default \
        alecspopa/giraph-cluster \
        hadoop fs -cat /README.result/\*
