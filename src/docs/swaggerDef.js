const { version } = require("../../package.json");

const { EXPRESS_PORT } = process.env;

const swaggerDef = {
  openapi: "3.0.0",
  info: {
    title: "Web AOA API",
    version,
    license: {
      name: "MIT",
    },
  },
  servers: [
    {
      url: `http://localhost:${EXPRESS_PORT}/`,
    },
  ],
};

module.exports = swaggerDef;
