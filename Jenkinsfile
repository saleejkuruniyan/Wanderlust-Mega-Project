@Library('Shared') _

pipeline {
    agent none

    environment {
        REGISTRY_URL = "harbor.needoo.in"
        PROJ_NAME = "library"
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }

    stages {
        stage('Prepare Agent') {
            agent {
                kubernetes {
                    label 'kaniko-agent'
                    defaultContainer 'jnlp'
yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:debug
      command:
        - cat
      tty: true
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker/config.json
          subPath: .dockerconfigjson
    - name: maven
      image: maven:3.8.1-jdk-11
      command:
        - cat
      tty: true
  volumes:
    - name: docker-config
      secret:
        secretName: docker-config
        items:
          - key: .dockerconfigjson
            path: .dockerconfigjson
"""
                }
            }
            stages {
                stage("Validate Parameters") {
                    steps {
                        script {
                            if (params.FRONTEND_DOCKER_TAG == '' || params.BACKEND_DOCKER_TAG == '') {
                                error("FRONTEND_DOCKER_TAG and BACKEND_DOCKER_TAG must be provided.")
                            }
                        }
                    }
                }

                stage("Workspace cleanup") {
                    steps {
                        script {
                            cleanWs()
                        }
                    }
                }

                stage('Git: Code Checkout') {
                    steps {
                        script {
                            code_checkout("https://github.com/saleejkuruniyan/Wanderlust-Mega-Project.git", "nutanix")
                        }
                    }
                }
                
                stage("Docker: Build & Push with Kaniko") {
                    steps {
                        container('kaniko') {
                            script {
                                def backendDest = "${REGISTRY_URL}/${PROJ_NAME}/wanderlust-backend-beta:${params.BACKEND_DOCKER_TAG}"
                                def frontendDest = "${REGISTRY_URL}/${PROJ_NAME}/wanderlust-frontend-beta:${params.FRONTEND_DOCKER_TAG}"

                                sh """
                                /kaniko/executor \
                                  --dockerfile=backend/Dockerfile \
                                  --context=`pwd`/backend \
                                  --destination=${backendDest} \
                                  --skip-tls-verify
                                """

                                sh """
                                /kaniko/executor \
                                  --dockerfile=frontend/Dockerfile \
                                  --context=`pwd`/frontend \
                                  --destination=${frontendDest} \
                                  --skip-tls-verify
                                """
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            archiveArtifacts artifacts: '*.xml', followSymlinks: false
            build job: "Wanderlust-CD", parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
                string(name: 'BACKEND_DOCKER_TAG', value: "${params.BACKEND_DOCKER_TAG}")
            ]
        }
    }
}
