# Launching Airflow on ecs

- Bootstrap file - add S3FS steps.
- Create airflow DB in staging-rds
- Create a redis
- S3 folder structure for prod and staging
- ECR - Image
- ECS - Create cluster. 
- Update task definition and cf template(add s3 location for staging)

### Bootstrap

Update the bootstrap file to add steps for mounting s3fs

Choose the relevant s3 folder structure for placing the bootstrap file and mounting directory

	#!/bin/bash
	sudo yum update -y
	sudo amazon-linux-extras install epel -y
	sudo yum install s3fs-fuse -y
	sudo mkdir /mnt/airflow
	echo "s3fs#bucket_name:/airflow/ /mnt/airflow fuse _netdev,iam_role=auto,umask=0022,uid=0,gid=0,allow_other" | sudo tee -a /etc/fstab
	sudo mount -a

### Create infra 

- Create airflow db in rds
- Create a redis queue in elastic cache

### ECR image

Use the [zomato fork of apache/airflow](https://github.com/zomato/airflow "zomato fork of apache/airflow"). It is hosted on ecr repo `zdp-airflow`

### ECS cluster

Create a ecs cluster and it will create a cloudformation template which we will need to update and add the following lines 

Update the following line to disable allocation of public ips to the ec2 instances

	"AssociatePublicIpAddress": false

Add the following section in the users data

	{
	  "Fn::Base64": {
		  "Fn::Join":[
			"",
			[
			  "#!/bin/bash -xe\n",
			  "echo ECS_CLUSTER=CLUSTER_NAME >> /etc/ecs/ecs.config\n",
			  "echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config\n",
			  "yum -y install aws-cli\n",
			  "mkdir -p /usr/lib/docker-airflow/bootstrap/\n",
			  "aws s3 cp s3://path/to/bootstrap/bootstrap_airflow.sh /usr/lib/docker-airflow/bootstrap/bootstrap_airflow.sh \n",
			  "source /usr/lib/docker-airflow/bootstrap/bootstrap_airflow.sh \n"
			]
		  ]
	  }
	}

Now we will create task definitions for the airflow
- webserver
- scheduler
- worker
- flower
- initdb (In case launching a new cluster with diff metastore)

**We will first generate fernet key and same key will be used in all the task definitions** 

To generate fernet key use this python code 

    from cryptography.fernet import Fernet
    FERNET_KEY = Fernet.generate_key().decode()
    print(FERNET_KEY)

We will need to update the following variables in the below json to their respective values

    YOUR_COMMAND => webserver/scheduler/flower/worker
    YOUR_FERNET_KEY => your generated fernet key
    s3://path/to/logs => path to s3 logs directory
    YOUR_REDIS_QUEUE => your redis queue
    YOUR_CONTAINER_NAME => your container name
    YOUR_TASK_NAME => your task name

We will be using this task_definition json 

	{
	  "ipcMode": null,
	  "executionRoleArn": "arn:aws:iam::125719378300:role/ecsTaskExecutionRole",
	  "containerDefinitions": [
		{
		  "dnsSearchDomains": null,
		  "logConfiguration": {
			"logDriver": "json-file",
			"secretOptions": null,
			"options": null
		  },
		  "entryPoint": null,
		  "portMappings": [
			{
			  "hostPort": 0,
			  "protocol": "tcp",
			  "containerPort": 8080
			}
		  ],
		  "command": [
			"YOUR_COMMAND"
		  ],
		  "linuxParameters": null,
		  "cpu": 0,
		  "environment": [
			{
			  "name": "PYTHONPATH",
			  "value": "/home/airflow/airflow/dags/dagster"
			},
			{
			  "name": "AIRFLOW__CORE__LOAD_EXAMPLES",
			  "value": "False"
			},
			{
			  "name": "AIRFLOW__CORE__FERNET_KEY",
			  "value": "YOUR_FERNET_KEY"
			},
			{
			  "name": "AIRFLOW__CORE__REMOTE_BASE_LOG_FOLDER",
			  "value": "s3://path/to/logs"
			},
			{
			  "name": "AIRFLOW__WEBSERVER__WORKERS",
			  "value": "8"
			},
			{
			  "name": "AIRFLOW__CORE__LOGGING_LEVEL",
			  "value": "INFO"
			},
			{
			  "name": "AIRFLOW__CELERY__BROKER_URL",
			  "value": "redis://YOUR_REDIS_QUEUE:6379/1"
			},
			{
			  "name": "AIRFLOW__CORE__EXECUTOR",
			  "value": "CeleryExecutor"
			}
		  ],
		  "resourceRequirements": null,
		  "ulimits": [
			{
			  "name": "nofile",
			  "softLimit": 1048576,
			  "hardLimit": 1048576
			},
			{
			  "name": "nproc",
			  "softLimit": 1048576,
			  "hardLimit": 1048576
			}
		  ],
		  "dnsServers": null,
		  "mountPoints": [
			{
			  "readOnly": true,
			  "containerPath": "/home/airflow/airflow/plugins/",
			  "sourceVolume": "airflow-plugins"
			},
			{
			  "readOnly": true,
			  "containerPath": "/home/airflow/airflow/dags/",
			  "sourceVolume": "airflow-dags"
			}
		  ],
		  "workingDirectory": null,
		  "secrets": [
			{
			  "valueFrom": "dataplatform.staging.airflow.result_backend",
			  "name": "AIRFLOW__CELERY__RESULT_BACKEND"
			},
			{
			  "valueFrom": "dataplatform.staging.airflow.sql_alchemy_url",
			  "name": "AIRFLOW__CORE__SQL_ALCHEMY_CONN"
			},
			{
			  "valueFrom": "dataplatform.production.airflow.google_client_id",
			  "name": "AIRFLOW__GOOGLE__CLIENT_ID"
			},
			{
			  "valueFrom": "dataplatform.production.airflow.google_client_secret",
			  "name": "AIRFLOW__GOOGLE__CLIENT_SECRET"
			}
		  ],
		  "dockerSecurityOptions": null,
		  "memory": 3072,
		  "memoryReservation": 1024,
		  "volumesFrom": [

		  ],
		  "stopTimeout": null,
		  "image": "125719378300.dkr.ecr.ap-southeast-1.amazonaws.com/zdp-airflow:zstaging",
		  "startTimeout": null,
		  "firelensConfiguration": null,
		  "dependsOn": null,
		  "disableNetworking": null,
		  "interactive": null,
		  "healthCheck": {
			"retries": 3,
			"command": [
			  "CMD-SHELL",
			  "[ -f /home/airflow/airflow/airflow-webserver.pid ]"
			],
			"timeout": 5,
			"interval": 30,
			"startPeriod": null
		  },
		  "essential": true,
		  "links": null,
		  "hostname": null,
		  "extraHosts": null,
		  "pseudoTerminal": null,
		  "user": null,
		  "readonlyRootFilesystem": null,
		  "dockerLabels": {
			"es_index_prefix": "zdp-airflow-webserver-",
			"service": "zdp-airflow-webserver",
			"kafka_topic": "logs.zdp.airflow.ecs.docker"
		  },
		  "systemControls": null,
		  "privileged": null,
		  "name": "YOUR_CONTAINER_NAME"
		}
	  ],
	  "memory": null,
	  "taskRoleArn": "arn:aws:iam::125719378300:role/ZAnalyticsAirflowRole",
	  "family": "YOUR_TASK_NAME",
	  "pidMode": null,
	  "requiresCompatibilities": [
		"EC2"
	  ],
	  "networkMode": null,
	  "cpu": null,
	  "inferenceAccelerators": null,
	  "proxyConfiguration": null,
	  "volumes": [
		{
		  "name": "airflow-plugins",
		  "host": {
			"sourcePath": "/mnt/airflow/plugins"
		  },
		  "dockerVolumeConfiguration": null
		},
		{
		  "name": "airflow-dags",
		  "host": {
			"sourcePath": "/mnt/airflow/dags"
		  },
		  "dockerVolumeConfiguration": null
		}
	  ],
	  "placementConstraints": [

	  ],
	  "tags": [

	  ]
	}

Now we will add these task definition in the ecs cluster we created
