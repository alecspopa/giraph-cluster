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

## Build Docker Swarm cluster on Digital Ocean

<https://www.digitalocean.com/community/tutorials/how-to-create-a-cluster-of-docker-containers-with-docker-swarm-and-digitalocean-on-ubuntu-16-04>

    docker-machine create -d digitalocean \
        --digitalocean-access-token="$DIGITALOCEAN_ACCESS_TOKEN" \
        --digitalocean-image="ubuntu-16-04-x64" \
        --digitalocean-size="2gb" \
        --digitalocean-region="fra1" \
        --digitalocean-private-networking=true \
        --digitalocean-ssh-key-fingerprint="20:e3:41:d8:bb:ce:5f:0b:43:99:3e:a9:1e:41:8b:f2" \
        --digitalocean-userdata=./digitalocean-manager-userdata.yml \
        swarm-manager

    docker-machine create -d digitalocean \
        --digitalocean-access-token="$DIGITALOCEAN_ACCESS_TOKEN" \
        --digitalocean-image="ubuntu-16-04-x64" \
        --digitalocean-size="2gb" \
        --digitalocean-region="fra1" \
        --digitalocean-private-networking=true \
        --digitalocean-ssh-key-fingerprint="20:e3:41:d8:bb:ce:5f:0b:43:99:3e:a9:1e:41:8b:f2" \
        --digitalocean-userdata=./digitalocean-worker-userdata.yml \
        swarm-worker-1

    docker-machine create -d digitalocean \
        --digitalocean-access-token="$DIGITALOCEAN_ACCESS_TOKEN" \
        --digitalocean-image="ubuntu-16-04-x64" \
        --digitalocean-size="2gb" \
        --digitalocean-region="fra1" \
        --digitalocean-private-networking=true \
        --digitalocean-ssh-key-fingerprint="20:e3:41:d8:bb:ce:5f:0b:43:99:3e:a9:1e:41:8b:f2" \
        --digitalocean-userdata=./digitalocean-worker-userdata.yml \
        swarm-worker-2

    docker-machine ls

	docker-machine ssh swarm-manager

	root@swarm-manager:~# docker swarm init --advertise-addr [swarm-manager IP]

	docker-machine ssh swarm-worker-1

	root@swarm-worker-1:~# docker swarm join \
	    --token [your token here] \
	    [swarm-manager IP]:2377

	docker-machine ssh swarm-worker-2

	root@swarm-worker-2:~# docker swarm join \
	    --token [your token here] \
	    [swarm-manager IP]:2377

*On manager* clone the docker repo

	cd giraph-cluster

	docker network create -d overlay giraphcluster_net

	docker service create \
		--name giraphcluster_namenode \
		--hostname giraphcluster-namenode \
		--replicas 1 \
		-p 8042:8042 \
		-p 8088:8088 \
		-p 50070:50070 \
		--network giraphcluster_net \
		alecspopa/giraph-cluster /etc/bootstrap.sh --namenode

NOTE: connet to namenode and start `yarn resourcemanager` and `yarn nodemanager`

	docker ps -a

	docker exec -it 55fda31dfe2e /bin/bash
