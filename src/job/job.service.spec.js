const fs = require("fs");
// eslint-disable-next-line
const child_process = require("child_process");
const JobService = require("./job.service");
const Job = require("./job.model");
const {
  BadRequestException,
  NotFoundException,
  InternalServerErrorException,
} = require("../utils/exceptions");

jest.mock("fs", () => {
  return {
    promises: {
      rm: jest.fn(),
      mkdir: jest.fn(),
      copyFile: jest.fn(),
      writeFile: jest.fn(),
    },
    createWriteStream: jest.fn().mockReturnValue({
      write: jest.fn(),
      end: jest.fn(),
    }),
  };
});

jest.mock("child_process", () => {
  return {
    spawn: jest.fn().mockReturnValue({
      stdout: { on: jest.fn() },
      stderr: { on: jest.fn() },
      on: jest.fn(),
    }),
  };
});

describe("JobService", () => {
  const sessionUser = {
    id: "61b5dac80ba4add9236dc231",
    name: "Julia Doe",
    email: "test@digital.peaks",
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it("should be defined", () => {
    expect(JobService).toBeDefined();
  });

  describe("getJob", () => {
    it("should get a job by id", async () => {
      Job.findOne = jest.fn().mockResolvedValue({ id: "123" });

      const result = await JobService.getJob("123", sessionUser);

      expect(Job.findOne).toHaveBeenCalledTimes(1);
      expect(Job.findOne).toHaveBeenCalledWith({
        _id: "123",
        user_id: sessionUser.id,
      });

      expect(result).toEqual({ id: "123" });
    });

    it("should catch not found error", async () => {
      Job.findOne = jest.fn().mockResolvedValue(null);

      await expect(JobService.getJob("123", sessionUser)).rejects.toThrowError(
        NotFoundException
      );
    });
  });

  describe("getJobs", () => {
    const jobs = [
      { id: "61b5dac80ba4add9236dc111" },
      { id: "61b5dac80ba4add9236dc222" },
    ];

    it("should get all job", async () => {
      const sortMock = jest.fn().mockResolvedValue(jobs);
      Job.find = jest.fn().mockReturnValue({ sort: sortMock });

      const result = await JobService.getJobs(sessionUser);

      expect(Job.find).toHaveBeenCalledTimes(1);
      expect(Job.find).toHaveBeenCalledWith({ user_id: sessionUser.id });

      expect(sortMock).toHaveBeenCalledWith({ created: "desc" });

      expect(result).toEqual(jobs);
    });
  });

  describe("deleteJob", () => {
    const job = { id: "61b5dac80ba4add9236dc111" };

    it("should delete a job", async () => {
      Job.deleteOne = jest.fn().mockResolvedValue({});

      const result = await JobService.deleteJob(job.id, sessionUser);

      expect(Job.deleteOne).toHaveBeenCalledTimes(1);
      expect(Job.deleteOne).toHaveBeenCalledWith({
        _id: job.id,
        user_id: sessionUser.id,
      });

      expect(fs.promises.rm).toHaveBeenCalledTimes(1);
      expect(fs.promises.rm).toHaveBeenCalledWith(
        expect.stringContaining(`/jobs/${job.id}`),
        { force: true, recursive: true }
      );

      expect(result).toEqual({});
    });
  });

  describe("createJob", () => {
    const newJobId = "61f673757e9a8dc05e4c7108";
    const newJob = {
      name: "Job name",
      use_lookup: false,
      resolution: 10,
      cloud_cover: 15,
      start_timestamp: "2020-01-01T00:00:00.000Z",
      end_timestamp: "2020-06-01T00:00:00.000Z",
      sampling_strategy: "regular",
      use_pretrained_model: false,
      random_forrest: {
        n_tree: 800,
        cross_validation_folds: 5,
      },
      area_of_interest: {
        type: "Feature",
        properties: {},
        geometry: {
          type: "Polygon",
          coordinates: [
            [
              [7.571640014648437, 51.93653958505235],
              [7.608976364135742, 51.93653958505235],
              [7.608976364135742, 51.96521171889782],
              [7.571640014648437, 51.96521171889782],
              [7.571640014648437, 51.93653958505235],
            ],
          ],
        },
      },
    };

    const jobFileSamples = {
      originalname: "samples.geojson",
      mimetype: "application/geo+json",
      size: 1024 * 500,
      buffer: "bufferSamples",
    };

    const jobFileModel = {
      originalname: "sample.rds",
      mimetype: "application/octet-stream",
      size: 1024 * 500,
      buffer: "bufferModel",
    };

    it("should create a job with random forrest", async () => {
      Job.create = jest.fn().mockResolvedValue({
        id: newJobId,
        user_id: sessionUser.id,
        ...newJob,
        toJSON: jest.fn().mockReturnValue(newJob),
      });

      // use stringify because multipart/form-data
      await JobService.createJob(
        JSON.stringify(newJob),
        { samples: [jobFileSamples] },
        sessionUser
      );

      // it should pass the session user
      expect(Job.create).toHaveBeenCalledWith(
        expect.objectContaining({ user_id: sessionUser.id })
      );

      // make sure the job folder is created correctly
      expect(fs.promises.mkdir).toHaveBeenCalledWith(
        expect.stringContaining(`/jobs/${newJobId}`)
      );

      // Check job_params file
      expect(fs.promises.writeFile.mock.calls[0]).toEqual([
        expect.stringContaining(`/${newJobId}/job_param.json`),
        JSON.stringify(
          {
            name: "Job name",
            resolution: 10,
            cloud_cover: 15,
            start_timestamp: "2020-01-01",
            end_timestamp: "2020-06-01",
            samples_class: "class",
            sampling_strategy: "regular",
            obj_id: "PID",
            model: "model.rds",
            samples: "samples.geojson",
            aoi: "aoi.geojson",
            use_lookup: "false",
            use_pretrained_model: "false",
            random_forrest: { n_tree: 800, cross_validation_folds: 5 },
          },
          null,
          2
        ),
        "utf8",
      ]);

      // Check aoi file
      expect(fs.promises.writeFile.mock.calls[1]).toEqual([
        expect.stringContaining(`/${newJobId}/aoi.geojson`),
        JSON.stringify(newJob.area_of_interest, null, 2),
        "utf8",
      ]);

      // Check samples file
      expect(fs.promises.writeFile.mock.calls[2]).toEqual([
        expect.stringContaining(`/${newJobId}/samples.geojson`),
        jobFileSamples.buffer,
      ]);

      expect(fs.promises.writeFile).toHaveBeenCalledTimes(3);

      expect(child_process.spawn).toHaveBeenCalledWith("R", [
        "-e",
        'source("/app/r/aoa_script.R")',
        "--args",
        newJobId,
      ]);
    });

    it("should create a job with existing model", async () => {
      const newJobModel = { ...newJob, use_pretrained_model: true };
      delete newJobModel.random_forrest;

      Job.create = jest.fn().mockResolvedValue({
        id: newJobId,
        user_id: sessionUser.id,
        ...newJobModel,
        toJSON: jest.fn().mockReturnValue(newJobModel),
      });

      // use stringify because multipart/form-data
      await JobService.createJob(
        JSON.stringify(newJobModel),
        { model: [jobFileModel] },
        sessionUser
      );

      // Check job_params file
      expect(fs.promises.writeFile.mock.calls[0]).toEqual([
        expect.stringContaining(`/${newJobId}/job_param.json`),
        JSON.stringify(
          {
            name: "Job name",
            resolution: 10,
            cloud_cover: 15,
            start_timestamp: "2020-01-01",
            end_timestamp: "2020-06-01",
            samples_class: "class",
            sampling_strategy: "regular",
            obj_id: "PID",
            model: "model.rds",
            samples: "samples.geojson",
            aoi: "aoi.geojson",
            use_lookup: "false",
            use_pretrained_model: "true",
          },
          null,
          2
        ),
        "utf8",
      ]);

      // Check model file
      expect(fs.promises.writeFile.mock.calls[2]).toEqual([
        expect.stringContaining(`/${newJobId}/model.rds`),
        jobFileModel.buffer,
      ]);

      expect(fs.promises.writeFile).toHaveBeenCalledTimes(3);
    });

    it("should create a job with different samples_class and obj_id", async () => {
      const newJobModel = { ...newJob, samples_class: "type", obj_id: "id" };

      Job.create = jest.fn().mockResolvedValue({
        id: newJobId,
        user_id: sessionUser.id,
        ...newJobModel,
        toJSON: jest.fn().mockReturnValue(newJobModel),
      });

      await JobService.createJob(
        JSON.stringify(newJobModel),
        { samples: [jobFileSamples] },
        sessionUser
      );

      // Check job_params file
      expect(fs.promises.writeFile.mock.calls[0]).toEqual([
        expect.stringContaining(`/${newJobId}/job_param.json`),
        JSON.stringify(
          {
            name: "Job name",
            resolution: 10,
            cloud_cover: 15,
            start_timestamp: "2020-01-01",
            end_timestamp: "2020-06-01",
            samples_class: "type",
            sampling_strategy: "regular",
            obj_id: "id",
            model: "model.rds",
            samples: "samples.geojson",
            aoi: "aoi.geojson",
            use_lookup: "false",
            use_pretrained_model: "false",
            random_forrest: { n_tree: 800, cross_validation_folds: 5 },
          },
          null,
          2
        ),
        "utf8",
      ]);
    });

    it("should check samples file MIME-Type and size", async () => {
      await expect(
        JobService.createJob(
          JSON.stringify(newJob),
          { samples: [{ ...jobFileSamples, mimetype: "application/pdf" }] },
          sessionUser
        )
      ).rejects.toThrowError(BadRequestException);

      await expect(
        JobService.createJob(
          JSON.stringify(newJob),
          { samples: [{ ...jobFileSamples, size: 1024 * 1024 * 20 }] },
          sessionUser
        )
      ).rejects.toThrow(
        new BadRequestException("Maximum upload file size: 10 MB")
      );
    });

    it("should check model file MIME-Type and size", async () => {
      await expect(
        JobService.createJob(
          JSON.stringify(newJob),
          { model: [{ ...jobFileModel, mimetype: "application/pdf" }] },
          sessionUser
        )
      ).rejects.toThrowError(BadRequestException);

      await expect(
        JobService.createJob(
          JSON.stringify(newJob),
          { model: [{ ...jobFileModel, size: 1024 * 1024 * 20 }] },
          sessionUser
        )
      ).rejects.toThrow(
        new BadRequestException("Maximum upload file size: 10 MB")
      );
    });

    it("should catch missing machine learning parameters", async () => {
      const newJobModel = { ...newJob, use_pretrained_model: false };
      delete newJobModel.random_forrest;
      await expect(
        JobService.createJob(
          JSON.stringify(newJobModel),
          { samples: [jobFileModel] },
          sessionUser
        )
      ).rejects.toThrowError(BadRequestException);
    });

    it("should catch missing files", async () => {
      const newJobModel = { ...newJob, use_pretrained_model: false };
      delete newJobModel.random_forrest;
      await expect(
        JobService.createJob(JSON.stringify(newJobModel), {}, sessionUser)
      ).rejects.toThrowError(BadRequestException);
    });

    it("should cleanup existing job, if something went wrong", async () => {
      fs.promises.writeFile = jest
        .fn()
        .mockRejectedValue(new Error("Something went wrong..."));
      const deleteOneSpy = jest.spyOn(Job, "deleteOne").mockResolvedValue({});

      await expect(
        JobService.createJob(JSON.stringify(newJob), {}, sessionUser)
      ).rejects.toThrowError(InternalServerErrorException);

      expect(deleteOneSpy).toHaveBeenCalledTimes(1);
    });
  });
});
