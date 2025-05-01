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
                    label 'k8s-agent'
                    inheritFrom 'default' // Inherit from a global pod template named 'default'
                    containerTemplate(name: 'jnlp', image: 'jenkins/inbound-agent:latest', args: '${computer.jnlpmac} ${computer.name}')
                    containerTemplate(name: 'maven', image: 'maven:3.8.1-jdk-11', ttyEnabled: true, command: 'cat')
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

                stage("SonarQube: Code Analysis") {
                    steps {
                        script {
                            def sonarHome = tool "Sonar"
                            sonarqube_analysis("Sonar", "wanderlust", "wanderlust")
                        }
                    }
                }

                stage("SonarQube: Code Quality Gates") {
                    steps {
                        script {
                            sonarqube_code_quality()
                        }
                    }
                }

                stage("Docker: Build Images") {
                    steps {
                        script {
                            dir('backend') {
                                registry_build("${REGISTRY_URL}", "${PROJ_NAME}", "wanderlust-backend-beta", "${params.BACKEND_DOCKER_TAG}", "registryCred")
                            }

                            dir('frontend') {
                                registry_build("${REGISTRY_URL}", "${PROJ_NAME}", "wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}", "registryCred")
                            }
                        }
                    }
                }

                stage("Docker: Push to DockerHub") {
                    steps {
                        script {
                            registry_push("${REGISTRY_URL}", "${PROJ_NAME}", "wanderlust-backend-beta", "${params.BACKEND_DOCKER_TAG}", "registryCred")
                            registry_push("${REGISTRY_URL}", "${PROJ_NAME}", "wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}", "registryCred")
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
