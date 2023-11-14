def directoryToImageMap = [:]
def changeddirs = []
pipeline {
    agent none
    stages {
        stage('Run this inside docker container') {
            agent {
                docker {
                    image 'moodysan/gobaseimage:latest'
                    args '--user root -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            stages{
                stage('Checkout Application Repo') {
                    when {
                        expression { currentBuild.number == 29 }
                    }
                    steps {
                        script {
                            dir("apps"){
                                git branch: 'main', url: 'https://github.com/Moody-san/microservice-backend'
                            }
                        }
                    }
                }
                stage('Check for changed dirs'){
                    steps {
                        script {
                            dir("apps"){
                                sh "git fetch origin main"
                                def directories = sh(script: 'ls -1 -d */', returnStdout: true).split('\n')
                                for (def dir in directories) {
                                    dir = dir.replaceAll('/$', '')
                                    def nochanges = sh(script: "git diff --name-only main origin/main | grep $dir -q",returnStatus: true)
                                    if (!nochanges) {
                                        changeddirs.add(dir)
                                    } 
                                    else {
                                        sh "echo No changes detected in directory: ${dir}"
                                    }
                                }
                                sh "echo changes detected in $changeddirs"
                            }
                        }
                    }
                }
                stage ('Checkout changes , build and push image'){
                    steps{
                        script{
                            dir("apps"){
                                if (!changeddirs.isEmpty()){
                                    sh "git pull origin main:main"
                                    changeddirs.each(){
                                        dir("${it}") {
                                            def image_name = "moodysan/${it}:${BUILD_NUMBER}"
                                            sh "docker build -t ${image_name} ."
                                            def dockerImage = docker.image("${image_name}")
                                            docker.withRegistry('https://registry.hub.docker.com','docker-cred') {
                                                dockerImage.push()
                                            }
                                            directoryToImageMap["${it}"] = "${image_name}"
                                        }
                                    }
                                }
                                else{
                                    sh "echo No changes in any directories"
                                }
                            }
                        }
                    }
                }
            }
        }
        stage('Run this outside docker container') {
            agent any
            environment {
                GIT_REPO_NAME = "k8s-manifests"
            }
            stages {
                stage('Get Manifest Repo'){
                    steps {
                        dir("manifests"){
                            git branch: 'main', url: 'https://github.com/Moody-san/k8s-manifests'
                        }
                    }
                }
                stage('Update Manifest with newly create docker image') {
                    steps {
                        script {
                            dir("manifests"){
                                withCredentials([usernamePassword(credentialsId: 'GITHUB_TOKEN', passwordVariable: 'PASSWORD', usernameVariable: 'USERNAME')]) {
                                    for (dir in directoryToImageMap){
                                        sh '''
                                            git config user.email "jenkins@gmail.com"
                                            git config user.name "jenkins"
                                            sed -i "s|moodysan/${dir.key}.*|${dir.value}|" "${dir.key}"/deployment.yml
                                            git add "${dir.key}"/deployment.yml
                                            git commit -m "Update ${dir.key} deployment image to version ${BUILD_NUMBER}"
                                            git push https://${PASSWORD}@github.com/${USERNAME}/${GIT_REPO_NAME}.git HEAD:main
                                        '''
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    options {
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }
}  
