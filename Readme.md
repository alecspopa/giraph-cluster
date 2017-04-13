#### Building the image

	docker build --tag alecspopa/giraph-cluster .

or get it form the repository

    docker pull alecspopa/giraph-cluster

### Using docker-compose to start the containers

	docker-compose up -d && \
    	docker-compose logs

or just specific ones

    docker-compose up -d namenode datanode yarn && \
        docker-compose logs

## Test instalation

Run Page Rank Benchmark

	docker run -it \
        --link=giraphcluster_namenode:giraphcluster-namenode \
        --link=yarn:yarn \
        --net=giraphcluster_default \
        --volume=$(pwd)/tmp_work_dir:/tmp \
        alecspopa/giraph-cluster \
        /bin/bash


inside the container get the shortestPaths example

		cd /tmp
		wget http://ece.northwestern.edu/~aching/shortestPathsInputGraph.tar.gz
		tar zxvf shortestPathsInputGraph.tar.gz


		hadoop jar $GIRAPH_HOME/giraph-examples-1.1.0-hadoop2.jar org.apache.giraph.benchmark.PageRankBenchmark -e 1 -s 3 -v -V 50000 -w 1

#### Put some data in HDFS

    docker run -it \
        --link=giraphcluster_namenode:giraphcluster-namenode \
        --link=yarn:yarn \
        --net=giraphcluster_default \
        --volume=$(pwd)/sample:/tmp \
        alecspopa/giraph-cluster \
        hadoop fs -put /tmp/tiny-graph.txt /tiny-graph.txt

#### Start wordcount example

	docker run --rm \
        --link yarn:yarn \
        --link=hdfs-namenode:hdfs-namenode \
        alecspopa/giraph-cluster \
        hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar wordcount  /README.txt /README.result

### If `word-cound.result` already exists you need to remove it prior running the map reduce job.

    docker run --rm --link=hdfs-namenode:hdfs-namenode \
        --link=hdfs-datanode1:docker_datanode_1 \
        alecspopa/giraph-cluster \
        hadoop fs -rm -R -f /word-cound.result

### Check the result

	docker run --rm --link=hdfs-namenode:hdfs-namenode \
        --link=hdfs-datanode1:hdfs-datanode1 \
        alecspopa/giraph-cluster \
        hadoop fs -cat /word-cound.result/\*

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
        --token SWMTKN-1-0gb5x2vw3z7z6qscbsp2c6k5b683fp6fykbov9nfvptrbit27n-4klu9e0t2cxtmw6352n8gujyk \
        $MANAGER_NODE_IP_ADDRESS:2377
