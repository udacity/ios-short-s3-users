# Users Microservice

The users microservice for the Game Night app. The [users microservice specification](http://docs.s3users.apiary.io/#) is defined using the [OpenAPI (Swagger) Specification](https://swagger.io/specification/) and hosted on [Apiary.io](https://apiary.io).

## How to Use

There are Docker images for the development web server and database environments, Dockerfile-web and Dockerfile-db. You can build the images using the make targets defined in `Makefile`. For example, if you'd like to build and start a MySQL server with seeded user data, then use the `db_run_seed` target:

```bash
$ make db_run_seed
```

During development, we recommend that you run three Docker containers:

1. database
2. web server
3. MySQL shell

These containers can be run using the following make targets:

```bash
# run (seeded) database container
$ make db_run_seed

# run web server container (starts an interactive shell)
$ make web_dev

# run MySQL shell container
$ make db_connect_shell
```

> **Note**: Since some of the make targets start interactive shells, you will need to run the above commands from different terminal windows.

## How to Test

`Makefile` targets are also included for manual and automated testing with [CircleCI](https://circleci.com).

- `web_unit_test` - run unit tests (assumes you are already in the web server environment)
- `web_functional_test` - run functional tests (assumes you are already in the web server environment)
- `web_unit_test_docker` - create a web server container and then run unit tests
- `web_functional_test_docker` - create a web server container and then run functional tests
