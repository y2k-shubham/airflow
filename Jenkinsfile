pipeline {
    agent { label "production" }

    environment {
        ecrImageUri = "125719378300.dkr.ecr.ap-southeast-1.amazonaws.com"
        ecrRepo = "zdp-airflow"
    }

    stages {
        stage("Bundle") {
            steps {
                withAWS(profile:"JUMBO-ACCOUNT") {
                    script {
                        def branch = env.GIT_BRANCH.replaceAll("(.*)/", "")
                        sh "docker build -t $ecrRepo:${branch} ."
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
