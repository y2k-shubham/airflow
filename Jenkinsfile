pipeline {
    agent { label "production" }

    stages {
        stage("BUILD") {
            steps {
                withAWS(profile:"JUMBO-ACCOUNT") {
                    script {
                        def branch = env.GIT_BRANCH.replaceAll("(.*)/", "")
                        def webserver_config
                        def airflow_cfg
                        def airflow_prometheus_exporter
                        if (branch == "zmaster") {
                            webserver_config = 'webserver_config-prod.py'
                            airflow_cfg = 'airflow-prod.cfg'
                            airflow_prometheus_exporter = 'git+https://github.com/Zomato/airflow-prometheus-exporter.git@v1.0.8'
                        } else if (branch == "zstaging") {
                            webserver_config = 'webserver_config-staging.py'
                            airflow_cfg = 'airflow-staging.cfg'
                            airflow_prometheus_exporter = 'git+https://github.com/Zomato/airflow-prometheus-exporter.git@v1.0.8'
                        } else {
                            webserver_config = 'webserver_config-dev.py'
                            airflow_cfg = 'airflow-dev.cfg'
                            airflow_prometheus_exporter = 'git+https://github.com/Zomato/airflow-prometheus-exporter.git@v1.0.8'
                        }
                        sh "docker build -t zdp-airflow:${branch} --build-arg WEBSERVER_CONFIG=${webserver_config} " +
                                "--build-arg AIRFLOW_CFG=${airflow_cfg} --build-arg " +
                                "ADDITIONAL_PYTHON_DEPS=${airflow_prometheus_exporter} ."
                    }
                }
            }
        }

        stage("ECR PUSH") {
            steps {
                withAWS(profile:"JUMBO-ACCOUNT") {
                    script {
                        def branch = env.GIT_BRANCH.replaceAll("(.*)/", "")
                        def tag = "${branch}_${GIT_COMMIT}"
                        image_tags = ["${branch}", "${tag}"]
                        sh "\$(aws ecr get-login --no-include-email --region ap-southeast-1)"
                        image_tags.each{ image_tag ->
                            sh "docker tag zdp-airflow:${branch} \
                                125719378300.dkr.ecr.ap-southeast-1.amazonaws.com/zdp-airflow:${image_tag}"
                            sh "docker push 125719378300.dkr.ecr.ap-southeast-1.amazonaws.com/zdp-airflow:${image_tag}"
                        }
                    }
                }
            }
        }

        // TODO: Update services/task-definitions after each deployment
        /* stage("ECS UPDATE") {
            steps {
                withAWS(profile:"JUMBO-ACCOUNT") {
                    script {
                        def branch = env.GIT_BRANCH.replaceAll("(.*)/", "")
                        def services = ['apache-webserver','apache-scheduler','apache-flower','apache-worker']
                        def cluster
                        if (branch == "zmaster") {
                            cluster = "zdp-airflow"
                        } else if (branch == "zstaging") {
                            cluster = "zdp-staging-airflow"
                        } else {
                            cluster = "zdp-dev-airflow"
                        }
                        services.each { service ->
                            sh "aws ecs update-service --cluster ${cluster} --service ${service} --force-new-deployment"
                        }
                    }
                }
            }
        } */

        stage("CLEAN") {
            steps {
                withAWS(profile:"JUMBO-ACCOUNT") {
                    script {
                        sh "docker system prune -f"
                    }
                }
            }
        }
    }
}
