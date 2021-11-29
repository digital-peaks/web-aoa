const axios = require("axios");

describe("Jobs", () => {
  it("should be empty", async () => {
    const { data } = await axios.get("http://api:9000/jobs", {
      name: "Job",
    });
    expect(data).toEqual([]);
  });
  it("should create a job", async () => {
    const { data } = await axios.post("http://api:9000/jobs", {
      name: "Job",
    });
    console.log(data);

    expect(data).toBeDefined();
  });
});
