
pipeline {
    agent any

    parameters {
        string(
            name: 'PARAM_ID_DOCKER',
            defaultValue: 'mtt2023',
            description: 'Nom utilisateur Docker Hub'
        )
        string(
            name: 'PARAM_PORT_EXPOSED',
            defaultValue: '8081',
            description: 'Port expose sur la machine hote'
        )
    }

    environment {
        ID_DOCKER = "${params.PARAM_ID_DOCKER}"
        IMAGE_NAME = "alpinehelloworld"
        IMAGE_TAG = "latest"
        PORT_EXPOSED = "${params.PARAM_PORT_EXPOSED}"
        STAGING = "${params.PARAM_ID_DOCKER}-staging"
        PRODUCTION = "${params.PARAM_ID_DOCKER}-production"
    }

    stages {
        stage('Build image') {
            steps {
                sh 'docker build -t ${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Run container based on built image') {
            steps {
                sh '''
                    echo "Clean Environment"
                    docker rm -f "$IMAGE_NAME" || echo "container does not exist"
                    docker run --name "$IMAGE_NAME" -d \
                      -p "${PORT_EXPOSED}:5000" \
                      -e PORT=5000 \
                      "${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sleep 5
                '''
            }
        }

        stage('Test image') {
            steps {
                sh '''
                    echo "Test de l'application depuis Jenkins"
        
                    curl --fail --silent --show-error \
                        --retry 5 \
                        --retry-connrefused \
                        --retry-delay 2 \
                        "http://172.17.0.1:${PORT_EXPOSED}" |
                        grep -q 'Hello world!'
        
                    echo "Test HTTP réussi"
                '''
            }
        }

        stage('Clean Container') {
            steps {
                sh '''
                    docker stop "$IMAGE_NAME" || true
                    docker rm "$IMAGE_NAME" || true
                '''
            }
        }

        stage('Login and Push Image on Docker Hub') {
            environment {
                DOCKERHUB_PASSWORD = credentials('fc5dbe4f-0db3-40ec-a9e8-9d64669e3e56')
            }
            steps {
                sh '''
                    echo "$DOCKERHUB_PASSWORD_PSW" |
                      docker login -u "$ID_DOCKER" --password-stdin
                    docker push "${ID_DOCKER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    docker logout
                '''
            }
        }

        stage('Push image in staging and deploy it') {
            when {
                expression {
                    env.GIT_BRANCH == 'origin/master' ||
                    env.BRANCH_NAME == 'master'
                }
            }
            environment {
                HEROKU_API_KEY = credentials('heroku_api_key')
            }
            steps {
                sh '''
                    npm install -g heroku@7.68.0
                    heroku container:login
                    heroku create "$STAGING" || echo "project already exists"
                    heroku container:push -a "$STAGING" web
                    heroku container:release -a "$STAGING" web
                '''
            }
        }

        stage('Push image in production and deploy it') {
            when {
                expression {
                    env.GIT_BRANCH == 'origin/production' ||
                    env.BRANCH_NAME == 'production'
                }
            }
            environment {
                HEROKU_API_KEY = credentials('heroku_api_key')
            }
            steps {
                sh '''
                    npm install -g heroku@7.68.0
                    heroku container:login
                    heroku create "$PRODUCTION" || echo "project already exists"
                    heroku container:push -a "$PRODUCTION" web
                    heroku container:release -a "$PRODUCTION" web
                '''
            }
        }
    }
}
