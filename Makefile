SHELL=/bin/bash
GITHUB_RUN_ID ?=123
SBT_VERSION ?= 1.8.3
NPM_MODULE_LOCATIONS := bl-bridge-server/bl-bridge-humidity-mqtt \
						bl-bridge-server/bl-bridge-temperature-coap
PYTHON_MODULE_LOCATIONS := bl-demo-server \
						   bl-simulation-data
ALL_IMAGES := bridge-logistics-bl-train-01-rabbitmq-server \
              bridge-logistics-bl-central-kafka-server \
              bridge-logistics-bl-train-01-zookeeper-server \
              bridge-logistics-bl-central-kafka-server \
              bridge-logistics-bl-bridge-01-rabbitmq-server \
              bridge-logistics-bl-bridge-01-temperature_coap_server \
              bridge-logistics-bl-bridge-01-humidity_mqtt_server \
              bridge-logistics-bl-vehicle-01-server \
              bridge-logistics-bl-central-server \
              bridge-logistics_postgres \
              bridge-logistics-bl-central-server-apps

b: build
coverage-npm:
	@for location in $(NPM_MODULE_LOCATIONS); do \
		export CURRENT=$(shell pwd); \
		echo "Running coverage for $$location..."; \
		cd $$location; \
		yarn; \
		jest --coverage; \
		cd $$CURRENT; \
	done
coverage-python:
	coverage run --source=bl-demo-server -m pytest && coverage json -o coverage-demo.json
	coverage run --source=bl-simulation-data -m pytest && coverage json -o coverage-simulation.json
coverage-maven:
	mvn clean install jacoco:prepare-agent package jacoco:report
coverage: coverage-npm coverage-python coverage-maven
build-npm:
	@for location in $(NPM_MODULE_LOCATIONS); do \
		export CURRENT=$(shell pwd); \
		echo "Building $$location..."; \
		cd $$location; \
		yarn; \
		npm run build; \
		cd $$CURRENT; \
	done
build-npm-cypress:
	cd e2e && yarn
build-maven: create-demo-data
	mvn clean install -Pdemo -DskipTests
build-python:
	cd bl-demo-server && python bl-core-service/launch_generate_people.py
build: build-npm build-python build-maven
test-maven:
	mvn test
local: no-test
	mkdir -p bin
test-node:
	@for location in $(NPM_MODULE_LOCATIONS); do \
		export CURRENT=$(shell pwd); \
		echo "Testing $$location..."; \
		cd $$location; \
		npm run test; \
		cd $$CURRENT; \
	done
test: test-maven test-node
no-test:
	mvn clean install -DskipTests
docker-clean: docker-delete
	docker-compose -p ${GITHUB_RUN_ID} rm -svf
docker:
	rm -rf out
	docker-compose -p ${GITHUB_RUN_ID} up -d --build --remove-orphans
docker-restart: stop-jars stop docker
start-readers: stop-jars
	cd bl-central-server/bl-central-readings/bl-passengers-readings-service && make start-readings &
	cd bl-central-server/bl-central-readings/bl-meters-readings-service && make start-readings &
docker-databases: stop local
build-images:
build-docker: stop b
	docker-compose -p ${GITHUB_RUN_ID} up -d --build --remove-orphans
clean-docker: docker-clean docker
show:
	docker ps -a  --format '{{.ID}} - {{.Names}} - {{.Status}}'
logs-central-server:
	docker logs bl-central-server
logs-central-server-tail:
	docker logs -f bl-central-server
logs-apps-server:
	docker logs bl-central-server-apps
logs-apps-server-tail:
	docker logs -f bl-central-server-apps
logs-central-kafka-server:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker logs
logs-central-kafka-server-tail:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker logs -f
logs-zookeeper-server:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-train-01-zookeeper-server" | xargs docker logs
logs-zookeeper-server-tail:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-train-01-zookeeper-server" | xargs docker logs -f
logs-rabbitmq-server:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-train-01-rabbitmq-server" | xargs docker logs
logs-rabbitmq-server-tail:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-train-01-rabbitmq-server" | xargs docker logs -f
logs-cassandra-server:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-cassandra" | xargs docker logs
logs-cassandra-server-tail:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-cassandra" | xargs docker logs -f
docker-apps:
	docker restart bl-central-server-apps
docker-dependent:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker restart
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker restart
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-cassandra" | xargs docker restart
docker-train:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker stop
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker start
docker-bridge:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker stop
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-kafka-server" | xargs docker start
docker-cassandra:
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-cassandra" | xargs docker stop
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-cassandra" | xargs docker start
docker-stats:
	docker stats bl-central-server bl-central-server bl-central-kafka-server bl-bridge-01-sensors-server bl-bridge-01-mosquitto_server bl-bridge-01-rabbitmq-server bl-central-kafka-server bl-central-psql bl-central-server-apps bl-central-cassandra bl-train-01-rabbitmq-server
docker-stats-simple:
	docker stats bl-central-server bl-central-server bl-central-kafka-server bl-bridge-01-sensors-server bl-bridge-01-mosquitto_server bl-bridge-01-rabbitmq-server bl-central-kafka-server bl-central-psql bl-central-server-apps bl-train-01-rabbitmq-server
docker-delete-idle:
	docker ps --format '{{.ID}}' -q --filter="name=bl-" | xargs docker rm
docker-delete: stop
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-" | xargs -I {} docker stop {}
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-" | xargs -I {} docker rm {}
docker-cleanup: stop-containers docker-delete
	docker images -q | xargs -I {} docker rmi {}
	@for image in $(ALL_IMAGES); do \
		echo "Stopping image $$image..."; \
		docker rmi $$image; \
	done
docker-action:
	docker-compose -p ${GITHUB_RUN_ID} -f docker-compose.yml up -d
docker-delete-apps: stop
	docker ps -a --format '{{.ID}}' -q --filter="name=bl-central-server-apps" | xargs docker rm
	docker rmi bridge-logistics-bl-central-server-apps
prune-all: stop
	docker ps -a --format '{{.ID}}' -q | xargs docker stop
	docker ps -a --format '{{.ID}}' -q | xargs docker rm
	docker system prune --all
	docker builder prune
	docker system prune --all --volumes
stop: stop-jars
	docker-compose -p ${GITHUB_RUN_ID} down --remove-orphans
stop-containers:
	docker ps -a -q --filter="name=bl-" | xargs -I {} docker stop {}
	docker ps -a -q --filter="name=bl-" | xargs -I {} docker rm {}
stop-jars:
	./stopRunningJars.sh
venv-install:
	pip install virtualenv
	pip install virtualenvwrapper
venv-login:
	virtualenv venv --python=python3.7
	echo "Please run source venv/bin/activate now"
# Start Python Env - https://www.python.org/downloads/release/python-2718/
install-python37-macos:
	brew install python@3.7
install:
	pip3 install requests
	pip3 install pika
	pip3 install kafka-python
	pip3 install aiocoap
	pip3 install mqtt
	pip3 install paho-mqtt
	pip3 install asyncio
	pip3 install distlib
	pip3 install --upgrade pip
# End Python Env
end-logs:
	docker-compose -p ${GITHUB_RUN_ID} logs --tail 100
demo:
	python3 bl-demo-server/launch_demo_server.py
remove-lock-files:
	find . -name "package-lock.json" | xargs -I {} rm {}; \
	find . -name "yarn.lock" | xargs -I {} rm {};
update: remove-lock-files
	cd bl-bridge-server/bl-bridge-humidity-mqtt && npx browserslist --update-db && ncu -u && yarn
	cd bl-bridge-server/bl-bridge-temperature-coap && npx browserslist --update-db && ncu -u && yarn
npm-test:
	cd bl-bridge-server/bl-bridge-humidity-mqtt && npm run coverage
	cd bl-bridge-server/bl-bridge-temperature-coap && npm run coverage
report:
	mvn omni-coveragereporter:report
log-all:
	docker-compose -p ${GITHUB_RUN_ID} logs
cypress-install:
	npm i -g cypress
	cd e2e && make build
cypress-open: log-all
	cd e2e && make cypress-open
cypress-open-docker: log-all
	cd e2e && make cypress-open-docker
cypress-electron: log-all
	cd e2e && make cypress-electron
cypress-chrome: log-all
	cd e2e && make cypress-chrome
cypress-firefox: log-all
	cd e2e && make cypress-firefox
cypress-firefox-full: log-all
	cd e2e && make cypress-firefox-full
cypress-edge: log-all
	cd e2e && make cypress-edge
local-pipeline: build-maven build-npm test-maven test-node coverage report
bl-wait:
	bash bl_wait.sh
create-demo-data:
	cd bl-simulation-data && make create-demo-data
	cd bl-demo-server && make create-demo-data
build-kafka:
	docker-compose -p ${GITHUB_RUN_ID} stop bl-central-kafka-server
	docker-compose -p ${GITHUB_RUN_ID} rm bl-central-kafka-server
	docker-compose -p ${GITHUB_RUN_ID} build --no-cache bl-central-kafka-server
	docker-compose -p ${GITHUB_RUN_ID} up -d bl-central-kafka-server
build-readers:
	docker-compose -p ${GITHUB_RUN_ID} stop bl-readers
	docker-compose -p ${GITHUB_RUN_ID} rm bl-readers
	docker-compose -p ${GITHUB_RUN_ID} build --no-cache bl-readers
	docker-compose -p ${GITHUB_RUN_ID} up -d bl-readers
dcd: dc-migration
	docker-compose -p ${GITHUB_RUN_ID} down --remove-orphans
	docker-compose -p ${GITHUB_RUN_ID} rm -fsva
	docker volume ls -qf dangling=true | xargs -I {} docker volume rm  {}
dcp:
	docker-compose -p ${GITHUB_RUN_ID} stop
dcup: dcd docker-clean docker bl-wait
dcup-full-action: dcd docker-clean build-maven build-npm docker bl-wait
dcup-action: dcp docker-action bl-wait
dcup-light: dcd
	docker-compose -p ${GITHUB_RUN_ID} up -d bl-central-psql
docker-prune:
	docker ps -a --format ''{{.ID}}'' | xargs -I {}  docker stop {}
	docker ps -a --format ''{{.ID}}'' | xargs -I {}  docker rm {}
	docker network prune -f
	docker system prune --all -f
	docker builder prune -f
	docker system prune --all --volumes -fl
install-coverage-python:
	sudo apt install python3-pip -y
	sudo pip3 install coverage
	sudo pip3 install pytest
upgrade-sbt:
	sudo apt upgrade
	sudo apt update
	export SDKMAN_DIR="$(HOME)/.sdkman"; \
	[[ -s "$(HOME)/.sdkman/bin/sdkman-init.sh" ]]; \
	source "$(HOME)/.sdkman/bin/sdkman-init.sh"; \
	sdk update; \
	sbtVersion=$(shell sbt --version |  tr '\n' ' ' | cut -f6 -d' '); \
	if [[ -z "$$sbtVersion" ]]; then \
		sdk install sbt $(SBT_VERSION); \
		sdk use gradle $(SBT_VERSION); \
	else \
		(yes "" 2>/dev/null || true) | sdk install sbt; \
	fi; \
	export SBT_VERSION=$(shell sbt --version |  tr '\n' ' ' | cut -f6 -d' ');
deps-npm-update: update
revert-deps-cypress-update:
	if [ -f  e2e/docker-composetmp.yml ]; then rm e2e/docker-composetmp.yml; fi
	if [ -f  e2e/packagetmp.json ]; then rm e2e/packagetmp.json; fi
	git checkout e2e/docker-compose.yml
	git checkout e2e/package.json
deps-cypress-update:
	curl -sL https://raw.githubusercontent.com/jesperancinha/project-signer/master/cypressUpdateOne.sh | bash
deps-plugins-update:
	curl -sL https://raw.githubusercontent.com/jesperancinha/project-signer/master/pluginUpdatesOne.sh | bash -s -- $(PARAMS)
deps-java-update:
	curl -sL https://raw.githubusercontent.com/jesperancinha/project-signer/master/javaUpdatesOne.sh | bash
deps-node-update:
	curl -sL https://raw.githubusercontent.com/jesperancinha/project-signer/master/nodeUpdatesOne.sh | bash
deps-quick-update: deps-cypress-update deps-plugins-update deps-java-update deps-node-update
accept-prs:
	curl -sL https://raw.githubusercontent.com/jesperancinha/project-signer/master/acceptPR.sh | bash
update-repo-prs:
	curl -sL https://raw.githubusercontent.com/jesperancinha/project-signer/master/update-all-repo-prs.sh | bash
dc-migration:
	curl -sL https://raw.githubusercontent.com/jesperancinha/project-signer/master/setupDockerCompose.sh | bash
