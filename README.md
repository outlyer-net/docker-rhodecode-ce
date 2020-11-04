# docker-rhodecode-ce

Docker container for the [RhodeCode](https://rhodecode.com/) Community Edition source code management platform.

RhodeCode provides Git, Subversion (svn) and Mercurial (hg) support.

## WIP

This image is based on the [previous work by darneta](https://github.com/darneta/rhodecode-ce-dockerized), updated to current versions.

**PLEASE NOTE**: I'm a new RhodeCode user so I'm still figuring out the best way to make this image work.

## Set up

First of all clone the repository or download its contents, as instructed on the [GitHub Page][github].

### With Docker Compose

    $ cd docker-rhodecode-ce
    $ docker-compose up -d

(optionally run `docker-compose logs` to see the initialisation log)

That's it.
Although you may want to customise the contents of the `docker-compose.yaml` file.

### Without Docker Compose

To preserve data even when the container is destroyed you must make sure to mount at least these three paths:
   - `/home/rhodecode/repos` → The actual repositories
   - `/home/rhodecode/.rccontrol/community-1` → RhodeCode configuration
   - `/home/rhodecode/.rccontrol/vcsserver-1` → RhodeCode VCS Server configuration

Here's an example command-line to spin the container (long options are used for increased readability), named volumes are used in this example to let Docker handle volume creation (care must be taken not to unadvertedly remove the volumes or data will be lost):

    $ docker run --detach \
        --publish 8080:80 \
        --volume rhodecode_repos:/home/rhodecode/repos \
        --volume rhodecode_conf:/home/rhodecode/.rccontrol/community-1 \
        --volume rhodecode_vcs_conf:/home/rhodecode/.rccontrol/vcsserver-1 \
        --name rhodecode \
        outlyernet/rhodecode-ce

### Administrator login

By default the administrator is created with username `admin` and password `secret`.
\
Both can be changed from the administration panel after login.

## Database

By default the an sqlite database is used ([RhodeCode doesn't support unattended
installs with any other database](https://docs.rhodecode.com/RhodeCode-Control/tasks/install-cli.html#unattended-installation)), but it can be set up afterwards.
An alternative Docker Compose file is provided
to set up a database container alongside RhodeCode, but the post-install set up
is not automated, you'll have to adjust it yourself.

    $ docker-compose -f docker-compose.mariadb.yaml up
    $ # must change the RhodeCode database here

## Exposed ports

- `80`: HTTP port on which RhodeCode serves. This port is published to `8080` by default when using `docker-compose`.
- `3690`: Subversion protocol (`svn://`) on which svnserve listens. This port isn't published by default.

## Links

- [GitHub]
- [Docker Hub][dockerhub]

<!-- Aliases for urls -->

[github]: https://github.com/outlyer-net/docker-rhodecode-ce
[dockerhub]: https://hub.docker.com/repository/docker/outlyernet/rhodecode-ce