const { version } = require("../../package.json");

const { EXPRESS_PORT } = process.env;
const { API_URL = `http://localhost:${EXPRESS_PORT}` } = process.env;

const swaggerDef = {
  openapi: "3.0.0",
  info: {
    title: "Web AOA API",
    version,
    license: {
      name: "MIT",
      url: "https://github.com/digital-peaks/web-aoa/blob/main/LICENSE",
    },
  },
  servers: [
    {
      url: API_URL,
    },
  ],
};

module.exports = swaggerDef;
