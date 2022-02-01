# Web AOA

## Getting started

> Make sure you are using Docker 20.x and Docker Compose 1.29.x

1. Run the services without building the docker containers:
   ```sh
   make dev-run
   ```
   > This will pull all docker images from DockerHub.
2. The following services should be available:
   - Frontend: http://localhost/
   - API: http://localhost/api
   - API Swagger Documentation: http://localhost/api/docs
3. Migrate a dummy user (for local usage only)
   ```sh
   make migrate
   ```
   User credentials:  
   Email: digitalpeaks@wwu.de  
   Password: cycling8
4. Login and run a job: http://localhost/

> **Clean you local data:** Sometimes it's useful to reset all local data (troubleshoots). With `make clean-db` the whole MongoDB will be deleted. And all files in the `./job` folder needs to be removed.

## Useful documents

- [R Script](./docs/r_script.md)
- [Manage users](./docs/users.md)
- [Production Deployment](./docs/deployment.md)
- [Backup](./docs/backup.md)

## Development

```sh
docker-compose up
```

Or add the build flag to make sure, that everything is up to date.

```sh
docker-compose up --build
```

> All changes in `src` will be reloaded after the code (file) is changed. No need to restart the docker container.

## Tests

### Unit

The following command will run unit tests with Jest:

```
make test
```

> See `package.json` command `npm run test:unit`

## Configuration

There are a few environment variables (see `.env`) that can be set to configure the services dynamically.

| Variable                    | Default                | Description                                                              |
| --------------------------- | ---------------------- | ------------------------------------------------------------------------ |
| `NODE_ENV`                  | `dev`                  | Please use `production` for the use in production.                       |
| `HAPROXY_PORT`              | `80`                   | Bind services to a port.                                                 |
| `HAPROXY_CONFIG`            | `local`                | See Haproxy configs in /ops/haproxy.                                     |
| `HAPROXY_CERT`              | `-`                    | Path to the the certificate file which is used by Haproxy.               |
| `API_URL`                   | `http://localhost/api` | Used by the frontend and Swagger.                                        |
| `API_COMMAND`               | `start`                | Npm commands. Please use `start:prod` in production.                     |
| `MONGODB_CONNECTION_STRING` | `-`                    | For the API.                                                             |
| `JWT_SECRET`                | `-`                    | The secret for the JWT tokens which are generated by the API.            |
| `API_KEY`                   | `-`                    | Specifies the `X-API-KEY` for the API which is required to manage users. |
| `MAX_UPLOAD_FILE_SIZE_MB`   | `10`                   | Max upload file size (e.g. \*.rds files).                                |

The following environment variables are required for the first start. It's not possible to change these values afterwards.

| Variable                     | Default | Description            |
| ---------------------------- | ------- | ---------------------- |
| `MONGO_INITDB_ROOT_USERNAME` | `-`     | MongoDB root username. |
| `MONGO_INITDB_ROOT_PASSWORD` | `-`     | MongoDB root password. |
| `MONGO_INITDB_DATABASE`      | `-`     | Database name.         |
| `MONGO_INITDB_API_USERNAME`  | `-`     | MongoDB API username.  |
| `MONGO_INITDB_API_PASSWORD`  | `-`     | MongoDB API password.  |

> Please make sure you're using the right credentials (`MONGO_INITDB_API_*`) for `MONGODB_CONNECTION_STRING`.
