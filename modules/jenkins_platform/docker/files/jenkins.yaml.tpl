jenkins:
  systemMessage: "Amazon Fargate Demo"
  numExecutors: 0
  remotingSecurity:
    enabled: true
  agentProtocols:
    - "JNLP4-connect"
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: ecsuser
          password: "${ADMIN_PWD}"
  authorizationStrategy:
    globalMatrix:
      grantedPermissions:
        - "Overall/Read:authenticated"
        - "Job/Read:authenticated"
        - "View/Read:authenticated"
        - "Overall/Administer:ecsuser"
  crumbIssuer: "standard"
  slaveAgentPort: 50000
  clouds:
    - ecs:
        name: "fargate-cloud-spot"
        credentialsId: ""
        cluster: "${ecs_cluster_fargate_spot}"
        regionName: "${cluster_region}"
        jenkinsUrl: "http://${jenkins_cloud_map_name}:${jenkins_controller_port}"
        allowedOverrides: "inheritFrom,label,memory,cpu,image"
        retentionTimeout: 10
        templates:
          - templateName: "build-example-spot"
            label: "build-example-spot"
            image: "jenkins/inbound-agent"
            cpu: "512"
            memoryReservation: 1024
            remoteFSRoot: "/home/jenkins"
            executionRole: "${execution_role_arn}"
            launchType: "FARGATE"
            networkMode: "awsvpc"
            securityGroups: "${agent_security_groups}"
            subnets: "${subnets}"
    - ecs:
        name: "fargate-cloud"
        credentialsId: ""
        cluster: "${ecs_cluster_fargate}"
        regionName: "${cluster_region}"
        jenkinsUrl: "http://${jenkins_cloud_map_name}:${jenkins_controller_port}"
        allowedOverrides: "inheritFrom,label,memory,cpu,image"
        retentionTimeout: 10
        templates:
          - templateName: "build-example"
            label: "build-example"
            image: "jenkins/inbound-agent"
            cpu: "512"
            memoryReservation: 1024
            remoteFSRoot: "/home/jenkins"
            executionRole: "${execution_role_arn}"
            launchType: "FARGATE"
            networkMode: "awsvpc"
            securityGroups: "${agent_security_groups}"
            subnets: "${subnets}"

security:
  sSHD:
    port: -1

jobs:
  - script: |
      pipelineJob('Simple job critical task') {
        definition {
          cps {
            script('''
              pipeline {
                agent {
                  ecs {
                    inheritFrom 'build-example'
                  }
                }
                stages {
                  stage('Test') {
                    steps {
                      script {
                        sh "echo this was executed on non spot instance"
                      }
                      sh 'sleep 120'
                      sh 'echo sleep is done'
                    }
                  }
                }
              }
            '''.stripIndent())
            sandbox()
          }
        }
      }
  - script: |
      pipelineJob('Simple job non critical task') {
        definition {
          cps {
            script('''
              pipeline {
                agent {
                  ecs {
                    inheritFrom 'build-example-spot'
                  }
                }
                stages {
                  stage('Test') {
                    steps {
                      script {
                        sh "echo this was executed on a spot instance"
                      }
                      sh 'sleep 120'
                      sh 'echo sleep is done'
                    }
                  }
                }
              }
            '''.stripIndent())
            sandbox()
          }
        }
      }
