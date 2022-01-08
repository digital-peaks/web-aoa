serve:
	docker-compose pull frontend
	docker-compose up --build

migrate:
	docker-compose run --rm migration

clean-db:
	docker-compose down -v
	docker-compose rm -f mongodb
	rm -rf ./mongo/volume

prod-pull-run:
	sudo docker-compose down
	git pull
	sudo docker-compose pull
	sudo docker-compose --env-file .env.production up --no-build -d
