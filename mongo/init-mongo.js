db.createUser({
    user: "webaoa",
    pwd: "webaoapw",
    roles: [
      {
        role: "readWrite",
        db: "webaoa",
      },
    ],
  });