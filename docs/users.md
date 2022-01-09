# Users

The following endpoints are protected with a `X-API-KEY` header:

- `POST /users`
- `GET /users`
- `PUT /users`
- `DELETE /users/{id}`

Any other endpoints are protected by a Bearer token which is associated with an user. You will get a Bearer token by using `POST /users/login`.

## Add new user

1. Open the Swagger documentation in your browser: http://localhost/api/docs/
   > For production: https://web-aoa.schnierer.info:8780/api/docs/
2. Click on "Authorize"
3. Add the X-API-KEY value and click "Authorize"
   > You are able to specify or view the value (`API_KEY=12345...`) in the `.env` file. Please ask the administrator for the API Key to create a user on a production system.
4. Open the request `POST /users` and and click on "Try it out"
5. Enter your name, email and password
   > The password must be at least 8 characters long and contains letters and a numbers.
6. Click "Execute" and make sure you user is created properly (status 201)
