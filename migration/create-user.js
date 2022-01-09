const http = require("http");

const API_HOST = process.env.API_HOST || "";
const API_PORT = process.env.EXPRESS_PORT || "";
const API_KEY = process.env.API_KEY || "";

const data = new TextEncoder().encode(
  JSON.stringify({
    name: "Jane Doe",
    email: "digitalpeaks@wwu.de",
    password: "cycling8",
  })
);

const options = {
  hostname: API_HOST,
  port: API_PORT,
  path: "/users",
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "Content-Length": data.length,
    "x-api-key": API_KEY,
  },
};

const req = http.request(options, (res) => {
  console.log(`statusCode: ${res.statusCode}`);

  res.on("data", (d) => {
    process.stdout.write(d);
  });
});

req.on("error", (error) => {
  console.error(error);
});

req.write(data);
req.end();
