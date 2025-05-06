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
        REGISTRY_PATH = "harbor.needoo.in/library"
        NVD_API_KEY = credentials('nvd-api-key')
        OWASP_CACHE_DIR = "/cache/dependency-check-data"
    }

    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
        string(name: 'BACKEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
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
                    steps {
                        container('trivy') {
                            script {
                                trivy_scan()
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

        stage("SonarQube: Code Quality Gates") {
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
                        def builds = [
                            ["backend", "wanderlust-backend-beta", "${params.BACKEND_DOCKER_TAG}"],
                            ["frontend", "wanderlust-frontend-beta", "${params.FRONTEND_DOCKER_TAG}"]
                        ]
                        kaniko_build_push_registry("${REGISTRY_PATH}", builds)
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
