pipeline {
    agent { label "production" }

    environment {
        ecrImageUri = "125719378300.dkr.ecr.ap-southeast-1.amazonaws.com"
        ecrRepo = "zdp-airflow"
        branch = env.GIT_BRANCH.replaceAll("(.*)/", "")
        if (branch == "zmaster") {
            webserver_config = "webserver_config-prod.py"
            airflow_cfg = "airflow-prod.cfg"
        } else if (branch == "zstaging") {
            webserver_config = "webserver_config-staging.py"
            airflow_cfg = "airflow-staging.cfg"
        } else {
            webserver_config = "webserver_config-dev.py"
            airflow_cfg = "airflow-dev.cfg"
        }
    }

    stages {
        stage("Bundle") {
            steps {
                withAWS(profile:"JUMBO-ACCOUNT") {
                    script {
                        sh "docker build -t $ecrRepo:$branch --build-arg WEBSERVER_CONFIG $webserver_config \
                        --build-arg AIRFLOW_CFG $airflow_cfg ."
                    }
                }
            }
        }

        stage("Deploy") {
            steps {
                script {
                    withAWS(profile:"JUMBO-ACCOUNT") {
                        script {
                            sh "\$(aws ecr get-login --no-include-email --region ap-southeast-1)"
                            sh "docker tag $ecrRepo:${branch} $ecrImageUri/$ecrRepo:${branch}"
                            sh "docker push $ecrImageUri/$ecrRepo:${branch}"
                        }
                    }
                }
            }
        }

        stage("Clean") {
            steps {
                script {
                    withAWS(profile:"JUMBO-ACCOUNT") {
                        script {
                            sh "docker system prune -f"
                        }
                    }
                }
            }
        }
    }
}
