@Library('Shared') _

pipeline {
    agent none

    environment {
        REGISTRY_URL = "harbor.needoo.in"
        PROJ_NAME = "library"
        NVD_API_KEY = credentials('nvd-api-key')
        OWASP_CACHE_DIR = "/cache/dependency-check-data"
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
    command: ["sleep"]
    args: ["infinity"]
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker/config.json
      subPath: .dockerconfigjson
      
  - name: maven
    image: maven:3.8.6-eclipse-temurin-17
    command: ["sleep"]
    args: ["infinity"]
    tty: true
    
  - name: trivy
    image: aquasec/trivy:latest
    command: ["sleep"]
    args: ["infinity"]
    tty: true
  
  - name: owasp
    image: owasp/dependency-check:latest
    command: ["sleep"]
    args: ["infinity"]
    tty: true
    volumeMounts:
    - name: owasp-cache
      mountPath: /cache
        
  volumes:
  - name: docker-config
    secret:
      secretName: docker-config
      items:
      - key: .dockerconfigjson
        path: .dockerconfigjson
  - name: owasp-cache
    persistentVolumeClaim:
      claimName: dependency-check-cache
"""
                }
            }
            stages {
                stage("Validate Parameters") {
                    steps {
                        script {
                            if (!params.FRONTEND_DOCKER_TAG) {
                                error("FRONTEND_DOCKER_TAG must be provided.")
                            }
                            if (!params.BACKEND_DOCKER_TAG) {
                                error("BACKEND_DOCKER_TAG must be provided.")
                            }
                        }
                    }
                }

                stage("Workspace cleanup") {
                    steps {
                        script {
                            try {
                                cleanWs()
                            } catch (e) {
                                echo "Workspace cleanup failed: ${e}"
                            }
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
                
                stage("Security Scans") {
                    parallel {
                        stage("Trivy: Filesystem scan") {
                            steps{
                                container('trivy') {
                                    script{
                                        trivy_scan()
                                    }
                                }
                            }
                        }
                        stage("OWASP: Dependency check") {
                            steps {
                                container('owasp') {
                                    script {
                                        owasp_dependency_api("$env.NVD_API_KEY", "$env.OWASP_CACHE_DIR")
                                    }
                                }
                            }
                        }
                    }
                }
                
                stage("SonarQube: Code Analysis"){
                    options {
                        timeout(time: 10, unit: 'MINUTES')
                    }
                    steps {
                        container('maven') {
                            script {
                                env.SONAR_HOME = tool "Sonar"
                                withEnv(["PATH+SONAR=${env.SONAR_HOME}/bin"]) {
                                    sonarqube_analysis("Sonar","wanderlust","wanderlust")
                                }
                            }
                        }
                    }
                }
                
                stage("SonarQube: Code Quality Gates"){
                    steps {
                        script {
                            sonarqube_code_quality()
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
                                /kaniko/executor \\
                                  --dockerfile=backend/Dockerfile \\
                                  --context=\$(pwd)/backend \\
                                  --destination=${backendDest} \\
                                  --skip-tls-verify
                                 
                                 rm -rf /kaniko/0/*

                                /kaniko/executor \\
                                  --dockerfile=frontend/Dockerfile \\
                                  --context=\$(pwd)/frontend \\
                                  --destination=${frontendDest} \\
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
            build job: "Wanderlust-CD", parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
                string(name: 'BACKEND_DOCKER_TAG', value: "${params.BACKEND_DOCKER_TAG}")
            ]
        }
        failure {
            script {
                emailext attachLog: true,
                from: 'saleejkuruniyan@gmail.com',
                subject: "Wanderlust CI failed - '${currentBuild.result}'",
                body: """
                    <html>
                    <body>
                        <div style="background-color: #FFA07A; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                        </div>
                        <div style="background-color: #90EE90; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                        </div>
                        <div style="background-color: #87CEEB; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">URL: ${env.BUILD_URL}</p>
                        </div>
                    </body>
                    </html>
                """,
                to: 'saleejkuruniyan@gmail.com',
                mimeType: 'text/html'
            }
        }
    }
}
