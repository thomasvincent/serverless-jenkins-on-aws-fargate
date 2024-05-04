import jenkins.model.Jenkins
import jenkins.install.InstallState
import jenkins.model.JenkinsLocationConfiguration

def jenkins = Jenkins.get()

// Disable executors on the Jenkins controller
jenkins.numExecutors = 0

// Mark the initial setup as completed
InstallState.INITIAL_SETUP_COMPLETED.initializeState()

// Configure the Jenkins URL
def env = System.getenv()
def jenkinsUrl = env['JENKINS_URL']
def locationConfig = JenkinsLocationConfiguration.get()
locationConfig.url = jenkinsUrl
locationConfig.save()

// Save the Jenkins configuration to disk
jenkins.save()
