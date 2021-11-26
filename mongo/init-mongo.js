db.createUser({
  user: "admin",
  pwd: "adminpw",
  roles: [
    {
      role: "readWrite",
      db: "webaoa",
    },
  ],
});
