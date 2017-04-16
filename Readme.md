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

## Build Docker Swarm cluster on Digital Ocean

<https://www.digitalocean.com/community/tutorials/how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04>

    docker-machine create -d digitalocean \
        --digitalocean-access-token="$DIGITALOCEAN_ACCESS_TOKEN" \
        --digitalocean-image="ubuntu-16-04-x64" \
        --digitalocean-size="1gb" \
        --digitalocean-region="fra1" \
        --digitalocean-private-networking=true \
        --digitalocean-ssh-key-fingerprint="20:e3:41:d8:bb:ce:5f:0b:43:99:3e:a9:1e:41:8b:f2" \
        --digitalocean-userdata=./digitalocean-namenode-userdata.yml \
        namenode

    docker-machine create -d digitalocean \
        --digitalocean-access-token="$DIGITALOCEAN_ACCESS_TOKEN" \
        --digitalocean-image="ubuntu-16-04-x64" \
        --digitalocean-size="1gb" \
        --digitalocean-region="fra1" \
        --digitalocean-private-networking=true \
        --digitalocean-ssh-key-fingerprint="20:e3:41:d8:bb:ce:5f:0b:43:99:3e:a9:1e:41:8b:f2" \
        --digitalocean-userdata=./digitalocean-datanode-userdata.yml \
        datanode-1

    docker-machine ls

    docker-machine ssh namenode

    root@namenode:~# docker swarm init --advertise-addr $MANAGER_NODE_IP_ADDRESS

    docker-machine ssh datanode-1

    root@datanode-1:~# docker swarm join \
        --token [your token here] \
        $MANAGER_NODE_IP_ADDRESS:2377
