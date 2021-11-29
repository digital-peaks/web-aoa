test_e2e:
	docker-compose down -v
	docker-compose -f docker-compose.yaml -f docker-compose.e2e.yaml up --detach mongodb api
	sleep 5
	docker-compose -f docker-compose.yaml -f docker-compose.e2e.yaml run api e2e