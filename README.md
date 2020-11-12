<!-- shields.io -->
[![Docker Image Size (latest by date)][badge_image_size]][dockerhub]
[![Docker Cloud Build Status][badge_cloud_build_status]][dockerhub]
[![MicroBadger Layers][badge_microbadger_layers]][microbadger]
[![GitHub last commit][badge_github_last_commit]][github_commits]
[![MIT License][badge_github_license]][github_license]

# RhodeCode Community Edition in Docker

Docker container for the [RhodeCode] Community Edition source code management platform.

RhodeCode provides Git, Subversion (svn) and Mercurial (hg) support.

## WIP

This image is based on the [previous work by darneta][github_upstream], updated to current versions and heavily modified.

**PLEASE NOTE**: I'm a new RhodeCode user so I'm still figuring out the best way to make this image work.

## Set up

### With Docker Compose

    $ git --clone https://github.com/outlyer-net/docker-rhodecode-ce.git
    $ cd docker-rhodecode-ce
    $ docker-compose up -d

(optionally run `docker-compose logs` to see the initialisation log)

That's it.
\
Although you may want to customise the contents of the `docker-compose.yaml` file.

#### Tweaks

* The compose file will use named docker volumes by default, that will be created on the fly,
  it may be advisable to change those to bind mounts to ensure they aren't removed accidentally
  with `docker volume prune`.
* By default the compose file will use `rhodecode` as the name for the container and prefix for generated volumes' names (e.g. `rhodecode_conf`).
\
This can be changed by setting the `RHODECODE_CONTAINER_NAME` environment variable before running docker-compose, e.g.:

      $ env RHODECODE_CONTAINER_NAME=reposerver docker-compose up -d

### Without Docker Compose

To preserve data even when the container is destroyed you must make sure to mount at least these paths:
   - `/repos` → The actual repositories
   - `/rhodecode` → RhodeCode configuration and logs

Here's an example command-line to spin the container (long options are used for increased readability), named volumes are used in this example to let Docker handle volume creation (care must be taken not to unadvertedly remove the volumes or data will be lost):

    $ docker run --detach \
        --publish 8080:8080 \
        --volume rhodecode_repos:/repos \
        --volume rhodecode_data:/rhodecode \
        --name rhodecode \
        outlyernet/rhodecode-ce

### Administrator login

By default the RhodeCode administrator is created with username `admin` and password `secret`.
\
Both can be changed from the administration panel after login.

## Database

By default an sqlite database is used ([RhodeCode doesn't support unattended
installs with any other database](https://docs.rhodecode.com/RhodeCode-Control/tasks/install-cli.html#unattended-installation)), but it can be set up afterwards.
An override Docker Compose file is provided
to set up a database container alongside RhodeCode, but the post-install set up
is not automated, you'll have to adjust it yourself.

    $ docker-compose -f docker-compose.yaml -f docker-compose.mariadb.yaml up
    $ # must change the RhodeCode database here

## Exposed ports

- `8080`: HTTP port on which RhodeCode serves. This port is published by default when using `docker-compose`.
- `3690`: VCS port. This port isn't published by default.

## Links

- [GitHub]
- [Docker Hub][dockerhub]

<!-- Aliases for urls -->

[github_upstream]: https://github.com/darneta/rhodecode-ce-dockerized
[github]: https://github.com/outlyer-net/docker-rhodecode-ce
[dockerhub]: https://hub.docker.com/repository/docker/outlyernet/rhodecode-ce
[microbadger]: https://microbadger.com/images/outlyernet/rhodecode-ce
[github_commits]: https://github.com/outlyer-net/docker-rhodecode-ce/commits/master
[github_license]: https://github.com/outlyer-net/docker-rhodecode-ce/blob/master/LICENSE
[rhodecode]: https://rhodecode.com/

<!-- Aliases for images -->

[badge_image_size]: https://img.shields.io/docker/image-size/outlyernet/rhodecode-ce
[badge_cloud_build_status]: https://img.shields.io/docker/cloud/build/outlyernet/rhodecode-ce
[badge_microbadger_layers]: https://img.shields.io/microbadger/layers/outlyernet/rhodecode-ce
[badge_github_last_commit]: https://img.shields.io/github/last-commit/outlyer-net/docker-rhodecode-ce
[badge_github_license]: https://img.shields.io/github/license/outlyer-net/docker-rhodecode-ce
