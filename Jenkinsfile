// 
// https://github.com/jenkinsci/pipeline-model-definition-plugin/wiki/Syntax-Reference
// https://jenkins.io/doc/book/pipeline/syntax/#parallel
// https://jenkins.io/doc/book/pipeline/syntax/#post
pipeline {
    agent any
    environment {
        REPO = 'fjudith/waarp-r66'
        PRIVATE_REPO = "${PRIVATE_REGISTRY}/${REPO}"
        DOCKER_PRIVATE = credentials('docker-private-registry')
    }
    stages {
        stage ('Checkout') {
            steps {
                script {
                    COMMIT = "${GIT_COMMIT.substring(0,8)}"

                    if ("${BRANCH_NAME}" == "master"){
                        TAG = "latest"
                    }
                    else {
                        TAG = "${BRANCH_NAME}"                       
                    }
                }
                sh 'printenv'
            }
        }
        stage ('Build Waarp R66 application server') {
            agent { label 'docker'}
            steps {
                sh "docker build -f ./Dockerfile -t ${REPO}:${COMMIT} ./"
            }
            post {
                success {
                    echo 'Tag for private registry'
                    sh "docker tag ${REPO}:${COMMIT} ${PRIVATE_REPO}:${TAG}"
                }
            }
        }
        stage ('Run  Waarp R66'){
            agent { label 'docker' }
            steps {
                // Create Network
                sh "docker network create waarp-r66-${BUILD_NUMBER}"
                // Start database
                sh "docker run -d --name 'waarp-r66-pg-${BUILD_NUMBER}' -e PORSTGRES_DB=waarp -e POSTGRES_USER=waarp -e POSTGRES_PASSWORD=V3ry1ns3cur3P4ssw0rd --network waarp-r66-${BUILD_NUMBER} postgres:9.4"
                sleep 60
                // Start application
                sh "docker run -d --name 'waarp-r66-${BUILD_NUMBER}' --link waarp-r66-pg-${BUILD_NUMBER}:postgres --network waarp-r66-${BUILD_NUMBER} ${REPO}:${COMMIT}"
                // Get container ID
                script{
                    DOCKER_WAARP    = sh(script: "docker ps -qa -f ancestor=${REPO}:${COMMIT}", returnStdout: true).trim()
                }
            }
        }
        stage ('Test Waarp R66'){
            agent { label 'docker' }
            steps {
                sleep 30
                input 'Start testins ?'
                // internal
                sh "docker exec 'waarp-r66-${BUILD_NUMBER}' /bin/bash -c 'curl -i -X GET -L http://localhost:8066'"
                // External
                sh "docker run --rm --network waarp-r66-${BUILD_NUMBER} blitznote/debootstrap-amd64:17.04 bash -c 'curl -ik -X GET -L https://${DOCKER_WAARP}:8067'"
            }
            post {
                always {
                    echo 'Remove slim stack'
                    sh "docker rm -vf waarp-r66-pg-${BUILD_NUMBER}"
                    sh "docker rm -vf waarp-r66-${BUILD_NUMBER}"
                    sh "docker network rm waarp-r66-${BUILD_NUMBER}"
                }
                success {
                    sh "docker login -u ${DOCKER_PRIVATE_USR} -p ${DOCKER_PRIVATE_PSW} ${PRIVATE_REGISTRY}"
                    sh "docker push ${PRIVATE_REPO}:${TAG}"
                }
            }
        }
    }
    post {
        always {
            echo 'Run regardless of the completion status of the Pipeline run.'
        }
        changed {
            echo 'Only run if the current Pipeline run has a different status from the previously completed Pipeline.'
        }
        success {
            echo 'Only run if the current Pipeline has a "success" status, typically denoted in the web UI with a blue or green indication.'

        }
        unstable {
            echo 'Only run if the current Pipeline has an "unstable" status, usually caused by test failures, code violations, etc. Typically denoted in the web UI with a yellow indication.'
        }
        aborted {
            echo 'Only run if the current Pipeline has an "aborted" status, usually due to the Pipeline being manually aborted. Typically denoted in the web UI with a gray indication.'
        }
    }
}