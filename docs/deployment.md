# Production Deployment

All relevant commands will be run with the following build command. For more information see the `Makefile`.

```sh
make prod-pull-run
```

> Please use the `.env` for your `.env.production` and change the credentials!

> For more information about the environment variables see the section [Configuration](../README.md#configuration).

### Prepare certificate for HAProxy

```
sudo cat "/etc/letsencrypt/live/domain.com/fullchain.pem" \
    "/etc/letsencrypt/live/domain.com/privkey.pem" > "/etc/ssl/domain.com.pem"
```

The path `/etc/ssl/domain.com.pem` should be mounted via `HAPROXY_CERT`.
