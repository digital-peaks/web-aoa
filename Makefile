migrate:
	docker-compose run --rm migration

test:
	docker-compose run --rm tests_unit

clean-db:
	docker-compose down -v
	docker-compose rm -f mongodb
	rm -rf ./mongo/volume

dev-run:
	docker-compose down
	docker-compose pull
	docker-compose --env-file .env up --no-build

prod-pull-run:
	docker-compose down
	git pull
	docker-compose pull
	docker-compose --env-file .env.production up --no-build -d
