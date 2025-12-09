.PHONY: up down dev scale clean

up:
	docker compose up -d

down:
	docker compose down
	rm -rf data/output

dev:
	docker exec -it spark-master bash


scale:
ifndef N
	$(error N is not set. Example: make scale N=2)
endif
	docker compose up -d --scale spark-worker=$(N)
