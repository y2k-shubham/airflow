pipeline {
    agent { label "production" }

    stages {
        stage("Bundle") {
            steps {
                withAWS(profile:"JUMBO-ACCOUNT") {
                    script {
                        def branch = env.GIT_BRANCH.replaceAll("(.*)/", "")
                        if (branch == "zmaster") {
                            echo "branch is ${branch}"
                            def webserver_config = 'webserver_config-prod.py'
                            def airflow_cfg = 'airflow-prod.cfg'
                            echo "docker build -t zdp-airflow:${branch} --build-arg WEBSERVER_CONFIG ${webserver_config} \
                        --build-arg AIRFLOW_CFG ${airflow_cfg} ."
                        } else if (branch == "zstaging") {
                            echo "branch is ${branch}"
                            def webserver_config = 'webserver_config-staging.py'
                            def airflow_cfg = 'airflow-staging.cfg'
                            echo "docker build -t zdp-airflow:${branch} --build-arg WEBSERVER_CONFIG ${webserver_config} \
                        --build-arg AIRFLOW_CFG ${airflow_cfg} ."
                        } else {
                            echo "branch is ${branch}"
                            def webserver_config = 'webserver_config-dev.py'
                            def airflow_cfg = 'airflow-dev.cfg'
                            echo "docker build -t zdp-airflow:${branch} --build-arg WEBSERVER_CONFIG ${webserver_config} \
                        --build-arg AIRFLOW_CFG ${airflow_cfg} ."
                        }
                        sh "docker build -t zdp-airflow:${branch} --build-arg WEBSERVER_CONFIG ${webserver_config} \
                        --build-arg AIRFLOW_CFG ${airflow_cfg} ."
                    }
                }
            }
        }

        stage("Deploy") {
            steps {
                script {
                    withAWS(profile:"JUMBO-ACCOUNT") {
                        script {
                            def branch = env.GIT_BRANCH.replaceAll("(.*)/", "")
                            sh "\$(aws ecr get-login --no-include-email --region ap-southeast-1)"
                            sh "docker tag zdp-airflow:${branch} 125719378300.dkr.ecr.ap-southeast-1.amazonaws.com/zdp-airflow:${branch}"
                            sh "docker push 125719378300.dkr.ecr.ap-southeast-1.amazonaws.com/zdp-airflow:${branch}"
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
