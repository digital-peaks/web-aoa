const express = require("express");
const asyncHandler = require("express-async-handler");
const UserService = require("./user.service");
const auth = require("../auth/auth.middleware");
const apiKey = require("../auth/api-key.middleware");

const router = express.Router();

/**
 * @swagger
 * tags:
 *   name: Users
 */

/**
 * @swagger
 * /users/login:
 *   post:
 *     summary: Login
 *     tags: [Users]
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *              email:
 *                type: string
 *                format: email
 *              password:
 *                type: string
 *             example:
 *               {
 *                 "email": "jane.doe@example.com",
 *                 "password": "cycling-sorority-YUMMY-toaster-42",
 *               }
 *     responses:
 *       "201":
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *                type: object
 *                properties:
 *                  token:
 *                    type: string
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.post(
  "/users/login",
  asyncHandler(async (req, res) => {
    const result = await UserService.login(req.body);
    res.status(201).json(result);
  })
);

/**
 * @swagger
 * /users/me:
 *   get:
 *     summary: Get current user.
 *     tags: [Users]
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       "401":
 *         $ref: '#/components/responses/UnauthorizedException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/users/me",
  auth(),
  asyncHandler(async (req, res) => {
    res.json(req.user);
  })
);

/**
 * @swagger
 * /users:
 *   post:
 *     summary: Create a user
 *     tags: [Users]
 *     security:
 *       - ApiKeyAuth: []
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - email
 *               - password
 *             properties:
 *              name:
 *                type: string
 *              email:
 *                type: string
 *                format: email
 *              password:
 *                type: string
 *             example:
 *               {
 *                 "name": "Jane Doe",
 *                 "email": "jane.doe@example.com",
 *                 "password": "cycling-sorority-YUMMY-toaster-42",
 *               }
 *     responses:
 *       "201":
 *         description: Created
 *         content:
 *           application/json:
 *             schema:
 *                $ref: '#/components/schemas/User'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "401":
 *         $ref: '#/components/responses/UnauthorizedException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.post(
  "/users",
  apiKey(),
  asyncHandler(async (req, res) => {
    const result = await UserService.createUser(req.body);
    res.status(201).json(result);
  })
);

/**
 * @swagger
 * /users:
 *   get:
 *     summary: Get all users
 *     tags: [Users]
 *     security:
 *       - ApiKeyAuth: []
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *                type: array
 *                items:
 *                  $ref: '#/components/schemas/User'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "401":
 *         $ref: '#/components/responses/UnauthorizedException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.get(
  "/users",
  apiKey(),
  asyncHandler(async (req, res) => {
    const result = await UserService.getUsers();
    res.json(result);
  })
);

/**
 * @swagger
 * /users:
 *   put:
 *     summary: Update user.
 *     tags: [Users]
 *     security:
 *       - ApiKeyAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - id
 *               - name
 *               - email
 *             properties:
 *              id:
 *                type: string
 *              name:
 *                type: string
 *              email:
 *                type: string
 *                format: email
 *              password:
 *                type: string
 *             example:
 *               {
 *                 "id": "61b5dac80ba4add8236ed488",
 *                 "name": "Jane Doe",
 *                 "email": "jane.doe@example.com",
 *                 "password": "cycling-sorority-YUMMY-toaster-42",
 *               }
 *     responses:
 *       "200":
 *         description: OK
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       "400":
 *         $ref: '#/components/responses/BadRequestException'
 *       "401":
 *         $ref: '#/components/responses/UnauthorizedException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.put(
  "/users",
  asyncHandler(async (req, res) => {
    const result = await UserService.updateUser(req.body);
    res.json(result);
  })
);

/**
 * @swagger
 * /users/{id}:
 *   delete:
 *     summary: Delete user by id.
 *     tags: [Users]
 *     security:
 *       - ApiKeyAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: User id
 *     responses:
 *       "200":
 *         description: No content
 *       "401":
 *         $ref: '#/components/responses/UnauthorizedException'
 *       "404":
 *         $ref: '#/components/responses/NotFoundException'
 *       "500":
 *         $ref: '#/components/responses/InternalServerErrorException'
 */
router.delete(
  "/users/:id",
  apiKey(),
  asyncHandler(async (req, res) => {
    const result = await UserService.deleteUser(req.params.id);
    res.json(result);
  })
);

module.exports = router;
