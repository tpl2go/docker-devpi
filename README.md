Docker image for devpi
======================

A ready to use Docker image for [devpi](http://doc.devpi.net/latest/). It includes
the following plugins and components:

* devpi-server, devpi-web and devpi-client
* [devpi-findlinks](https://pypi.python.org/pypi/devpi-findlinks)
* [devpi-cleaner](https://pypi.python.org/pypi/devpi-cleaner)
* [devpi-lockdown](https://pypi.python.org/pypi/devpi-lockdown)
* [devpi-json](https://pypi.org/project/devpi-json-info/)

Fork Modifications
------------------
This repository is a fork of [LordGaav/docker-devpi](https://github.com/LordGaav/docker-devpi).

Main Changes:
* Smaller base image (python:slim)
* No devpi-slack
* Pulls latest devpi

I have simplified the `entrypoint.sh` such that `devpi-server` runs as the main process instead of a background process in the container. 
As such, there is no need to call special commands like `pgrep` to check if `devpi-server` is still alive. 
Without the need for `pgrep`, we can use `python:slim` as the base image instead of usual `python:latest`. 
The final docker image size reduced from >1GB to 209MB, a space saving of about 80%.


Building the image
------------------
On an internet connected computer, build the docker image using:

```bash
docker build -t tpl2go/devpi:$(date '+%Y-%m-%d') .
```

Running the image
------------------
Within the container,`devpi-server` stores its packages and data within the root directory `/devpi`.
We can use a bind mount from `<devpi-vol-path>` to `/devpi` to provision this directory as a persistent storage space within container.
Additionally, we need to map port 3141 from within the container to whatever `<external-port>` you want the container to serve.

```bash
docker run -d -p <external-port>:3141 -v <devpi-vol-path>:/devpi \
--name devpi-server tpl2go/devpi:<dateofimagebuild>
```

The first time it runs, the startup script will generate a password for the root
user and store it in `.root_password` in its storage volume.

If you want to use the LDAP plugin, you need to map the YAML configuration file
into the Docker and tell `devpi-server` to use it:

```bash
docker run -d -p <external-port>:3141 -v <devpi-vol-path>:/devpi -v /path/to/ldap.yml:/ldap.yml \
--name devpi-server tpl2go/devpi:<dateofimagebuild> --ldap-config=/ldap.yml
```

By default devpi-server has a 1GB package size limit. 
To change this limit, add the arguments `--max-request-body-size <integer size>` to the docker run command.

For example, to increase size limit to 5GB:
```bash
docker run -d -p <external-port>:3141 -v <devpi-vol-path>:/devpi \
--name devpi-server tpl2go/devpi:<dateofimagebuild> --max-request-body-size 5000000000
```

devpi-client helper
-------------------
A small helper script is provided to manipulate the running container. The
script will automatically log in as the `root` user for running commands.

```bash
$ docker exec -it devpi-server devpi-client -h
logged in 'root', credentials valid for 10.00 hours
usage: /usr/local/bin/devpi [-h] [--version] [--debug] [-y] [-v]
                            [--clientdir DIR]
                            {quickstart,use,getjson,patchjson,list,remove,user,login,logoff,index,upload,test,push,install,refresh}
...
```

Alternatively, you can start an interactive shell.

```bash
$ docker exec -it devpi-server devpi-client bash
logged in 'root', credentials valid for 10.00 hours
root@c4fa8a7b14cf:/#
```
