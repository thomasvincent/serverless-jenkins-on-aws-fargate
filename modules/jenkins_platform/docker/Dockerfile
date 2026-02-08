FROM jenkins/jenkins:lts-jdk17

ENV JENKINS_HOME /var/jenkins_home
ENV CASC_JENKINS_CONFIG $JENKINS_HOME/casc_configs/jenkins.yaml

USER root

# Install required plugins
COPY files/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Copy Jenkins Configuration as Code (JCasC) file
COPY files/jenkins.yaml $JENKINS_HOME/casc_configs/jenkins.yaml

# Disable Jenkins setup wizard
RUN echo $JENKINS_VERSION > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state

# Copy custom initialization script
COPY files/InitialConfig.groovy /usr/share/jenkins/ref/init.groovy.d/InitialConfig.groovy

# Switch back to the Jenkins user
USER jenkins

# Expose the Jenkins port
EXPOSE 8080 50000
