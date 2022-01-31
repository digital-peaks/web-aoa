const bcrypt = require("bcrypt");
const UserService = require("./user.service");
const User = require("./user.model");
const {
  BadRequestException,
  UnauthorizedException,
  NotFoundException,
} = require("../utils/exceptions");

describe("UserService", () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("should be defined", () => {
    expect(UserService).toBeDefined();
  });

  describe("login", () => {
    const user = {
      id: "61b5dac80ba4add9236dc231",
      email: "test@digital.peaks",
      password: "$2b$10$3mh6hBJ.uR0OkCsw/sYf4ORxd5A9JzjYbdgwllZjDJGSXjP3tqvy.",
    };

    it("should login successfully", async () => {
      const findOneSpy = jest.spyOn(User, "findOne").mockResolvedValue({
        id: "61b5dac80ba4add9236dc231",
        email: "test@digital.peaks",
        password:
          "$2b$10$3mh6hBJ.uR0OkCsw/sYf4ORxd5A9JzjYbdgwllZjDJGSXjP3tqvy.",
      });

      const result = await UserService.login({
        email: "test@digital.peaks",
        password: "digitalSecret-42",
      });

      expect(findOneSpy).toHaveBeenCalledWith({ email: user.email });
      expect(result).toEqual(
        expect.objectContaining({ token: expect.any(String) })
      );
    });
    it("should catch email not found error", async () => {
      jest.spyOn(User, "findOne").mockResolvedValue(null);

      await expect(
        UserService.login({
          email: "test@digital.peaks",
          password: "digitalSecret-44",
        })
      ).rejects.toThrowError(UnauthorizedException);
    });
    it("should catch incorrect password error", async () => {
      jest.spyOn(User, "findOne").mockResolvedValue(user);

      await expect(
        UserService.login({
          email: "test@digital.peaks",
          password: "digitalSecret-44",
        })
      ).rejects.toThrowError(UnauthorizedException);
    });
  });

  describe("createUser", () => {
    it("should create a new user", async () => {
      const spySave = jest.spyOn(User.prototype, "save").mockResolvedValue({});

      await UserService.createUser({
        name: "Digital Peaks",
        email: "test@digital.peaks",
        password: "digitalSecret-42",
      });

      expect(spySave).toHaveBeenCalledTimes(1);
    });
    it("should catch incorrect password policy error", async () => {
      jest.spyOn(User.prototype, "save").mockResolvedValue({});

      await expect(
        UserService.createUser({
          name: "Digital Peaks",
          email: "test@digital.peaks",
          password: "digitalSecret",
        })
      ).rejects.toThrow(
        new BadRequestException(
          "Password must contain at least one letter and one number"
        )
      );
    });
    it("should catch password length error", async () => {
      jest.spyOn(User.prototype, "save").mockResolvedValue({});

      await expect(
        UserService.createUser({
          name: "Digital Peaks",
          email: "test@digital.peaks",
          password: "digitA1",
        })
      ).rejects.toThrow(
        new BadRequestException(
          "Password must have a minimum length of 8 characters"
        )
      );
    });
  });

  describe("updateUser", () => {
    const user = {
      id: "61b5dac80ba4add9236dc231",
      name: "Julia Doe",
      email: "test@digital.peaks",
    };

    it("should update a user successfully", async () => {
      const hashSyncSpy = jest.spyOn(bcrypt, "hashSync");
      User.updateOne = jest.fn().mockResolvedValue({ matchedCount: 1 });
      User.findOne = jest.fn().mockResolvedValue({});

      await UserService.updateUser(user);

      expect(User.updateOne).toHaveBeenCalledTimes(1);
      expect(User.findOne).toHaveBeenCalledTimes(1);
      expect(User.updateOne).toHaveBeenCalledWith(
        { _id: "61b5dac80ba4add9236dc231" },
        expect.objectContaining({
          name: user.name,
          email: user.email,
        })
      );
      expect(hashSyncSpy).toHaveBeenCalledTimes(0);
    });

    it("should update a user with new password successfully", async () => {
      const hashSyncSpy = jest.spyOn(bcrypt, "hashSync");
      User.updateOne = jest.fn().mockResolvedValue({ matchedCount: 1 });
      User.findOne = jest.fn().mockResolvedValue({});

      await UserService.updateUser({ ...user, password: "NEWdigitalSecret1" });

      expect(User.updateOne).toHaveBeenCalledWith(
        { _id: "61b5dac80ba4add9236dc231" },
        expect.objectContaining({
          name: user.name,
          email: user.email,
          password: expect.any(String),
        })
      );
      expect(hashSyncSpy).toHaveBeenCalledTimes(1);
      expect(hashSyncSpy).toHaveBeenCalledWith("NEWdigitalSecret1", 10);
    });

    it("should catch user not found error", async () => {
      User.updateOne = jest.fn().mockResolvedValue({ matchedCount: 0 });

      await expect(UserService.updateUser(user)).rejects.toThrow(
        new NotFoundException("Unable to update unknown user")
      );
    });
  });

  describe("getUsers", () => {
    const users = [{ id: "61b5dac80ba4add9236dc231" }];

    it("should get all users", async () => {
      const sortMock = jest.fn().mockResolvedValue(users);
      User.find = jest.fn().mockReturnValue({ sort: sortMock });

      const result = await UserService.getUsers();

      expect(User.find).toHaveBeenCalledTimes(1);
      expect(sortMock).toHaveBeenCalledWith({ created: "desc" });

      expect(result).toEqual(users);
    });
  });

  describe("deleteUser", () => {
    const userId = "61b5dac80ba4add9236dc231";

    it("should get all users", async () => {
      User.deleteOne = jest.fn().mockResolvedValue({});

      const result = await UserService.deleteUser(userId);

      expect(User.deleteOne).toHaveBeenCalledTimes(1);
      expect(User.deleteOne).toHaveBeenCalledWith({ _id: userId });

      expect(result).toEqual({});
    });
  });
});
