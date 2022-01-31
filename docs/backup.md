# Create backups

All relevant data will be saved in a [MongoDB](https://www.mongodb.com) (NoSQL database) and on the hard drive.

## Backup MongoDB

The simplest way to backup the MongoDB data is to use `rsync` or `cp`. The `docker-compose.yaml` creates a volume in the folder `./mongo/volume`. The whole folder is relevant for the backup.

More information MongoDB backup strategies: [MongoDB Backup Methods](https://docs.mongodb.com/manual/core/backups/)

## Backup job files

By default all job files will be saved under `./jobs`. The whole folder needs to copied by `rsync` or `cp`.
