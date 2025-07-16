@Library('Shared') _

pipeline {
    agent {
        kubernetes {
            inheritFrom 'kaniko-agent-pod'
            defaultContainer 'jnlp'
        }
    }

    environment {
        SONAR_HOME = tool "Sonar"
        REGISTRY_PATH = "docker-hosted.needoo.in/wanderlust"
        NVD_API_KEY = credentials('nvd-api-key')
        OWASP_CACHE_DIR = "/cache/dependency-check-data"
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Frontend Docker tag of the image built by the CI job')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Backend Docker tag of the image built by the CI job')
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

        stage("Workspace Cleanup") {
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
                    code_checkout("https://github.com/saleejkuruniyan/Wanderlust-Mega-Project.git", "aks")
                }
            }
        }

        stage("Trivy: Filesystem Scan") {
            steps {
                container('trivy') {
                    script {
                        retry(3) {
                            sh 'mkdir -p ${WORKSPACE}'
                            dir("${WORKSPACE}") {
                                trivy_scan()
                            }
                        }
                    }
                }
            }
        }
        
        stage("OWASP: Dependency check") {
            steps {
                container('owasp') {
                    script {
                        owasp_dependency_api(env.NVD_API_KEY, env.OWASP_CACHE_DIR)
                    }
                }
            }
        }

        stage("SonarQube: Code Analysis") {
            options {
                timeout(time: 10, unit: 'MINUTES')
            }
            steps {
                container('maven') {
                    script {
                        sonarqube_analysis("Sonar", "wanderlust", "wanderlust")
                    }
                }
            }
        }

        stage("Docker: Build & Push with Kaniko") {
            steps {
                container('kaniko') {
                    script {
                        def builds = [
                            ["backend", "wanderlust-backend-beta", "${params.BACKEND_DOCKER_TAG}"],
                            ["frontend", "wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}"]
                        ]
                        kaniko_build_push_registry("${REGISTRY_PATH}", builds)
                    }
                }
            }
        }

        stage("Update: Kubernetes Manifests") {
            steps {
                script {
                    dir('kubernetes') {
                        sh """
                            sed -i -e s/wanderlust-backend-beta.*/wanderlust-backend-beta:${params.BACKEND_DOCKER_TAG}/g backend.yaml
                        """
                    }

                    dir('kubernetes') {
                        sh """
                            sed -i -e s/wanderlust-frontend-beta.*/wanderlust-frontend-beta:${params.FRONTEND_DOCKER_TAG}/g frontend.yaml
                        """
                    }
                }
            }
        }

        stage("Git: Code Update and Push to GitHub") {
            steps {
                script {
                    withCredentials([gitUsernamePassword(credentialsId: 'Github-cred', gitToolName: 'Default')]) {
                        sh '''
                        echo "Checking repository status: "
                        git status

                        echo "Adding changes to git: "
                        git add kubernetes/

                        echo "Configuring Git identity: "
                        git config user.name "Jenkins CI"
                        git config user.email "saleejkuruniyan@gmail.com"

                        echo "Committing changes: "
                        git commit -m "Updated environment variables"

                        echo "Pushing changes to GitHub: "
                        git push https://github.com/saleejkuruniyan/Wanderlust-Mega-Project.git aks
                        '''
                    }
                }
            }
        }
    }


    post {
        success {
            archiveArtifacts artifacts: '*.xml', followSymlinks: false
        }
        failure {
            script {
                emailext(
                    attachLog: true,
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
                )
            }
        }
    }
}
