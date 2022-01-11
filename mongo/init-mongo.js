db.createUser({
  user: _getEnv("MONGO_INITDB_API_USERNAME"),
  pwd: _getEnv("MONGO_INITDB_API_PASSWORD"),
  roles: [
    {
      role: "readWrite",
      db: _getEnv("MONGO_INITDB_DATABASE"),
    },
  ],
});
