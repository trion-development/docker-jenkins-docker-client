# Jenkins Docker Image including the docker client
This docker image includes the docker command to enable Jenkins to interact with a docker daemon.

It includes a build of docker-compose working on alpine as well.



## Docker Socket integration

If a bind-mount of the docker daemon socket is detected, appropriate permissions will be set to allow jenkins to access docker via the socket.
In order for this to work the container must be run as `root`.
To configure the uid to switch to, the environment variable JENKINS_USER must be used instead `docker -u`

Example usage: Make sure the directory `$HOME/.jenkins` exists, then run

```
docker run -it --name=jenkins -e JENKINS_USER=$(id -u) --rm -p 8080:8080 -p 50000:50000 \
-v $HOME/.jenkins:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock \
--name jenkins trion/jenkins-docker-client
```


## Configuration as code

When setting `JENKINS_CAC=true` the container does not start the initial Jenkins Setup Wizard.
Instead the ```Configuration as Code``` plugin is pre-installed and an initial location and admin credentials can be set using environment variables.

To provide your initial configuration, you can mount it to `/provisioning/config.yaml`

Plugins to be installed can be added to a textfile and mounted to `/provisioning/plugins.txt`.
The following plugins should be provided

```
authorize-project:latest
configuration-as-code:latest
role-strategy:latest
```

More details: https://plugins.jenkins.io/configuration-as-code/

Afterwards, the server can be managed as usual.


```
docker run -it --name=jenkins -e JENKINS_USER=$(id -u) --rm -p 8080:8080 -p 50000:50000 \
--env JENKINS_ADMIN_ID=username --env JENKINS_ADMIN_PASSWORD=password --env JENKINS_LOCATION=http://localhost:8080 \
-v $HOME/.jenkins:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock \
--name jenkins trion/jenkins-docker-client
```


