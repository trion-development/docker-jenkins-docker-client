# Jenkins Docker Image including the docker client
This docker image includes the docker command to enable Jenkins to interact with a docker daemon.
It includes a build of docker-compose working on alpine as well.

## Docker Socket integration

If a bind-mount of the docker daemon socket is detected, appropriate permissions will be set to allow jenkins to access docker via the socket.
In order for this to work the container must be run as root.
To configure the uid to switch to the environment variable JENKINS_USER must be used instead `docker -u`

Example usage

```
docker run -it -e JENKINS_USER=$(id -u) --rm -p 8080:8080 -p 50000:50000 \
-v $HOME/.jenkins:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock \
--name jenkins trion/jenkins-docker-client
```
