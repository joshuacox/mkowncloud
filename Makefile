.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

temp: init

reqs: TAG IP DB_USER DB_NAME DB_PASS NAME PORT rmall

init: reqs mysqlinitCID owncloudinitCID

run: reqs rmall mysqlCID owncloudCID

next: grab rminit run

owncloudinitCID:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-mysqlinit:mysql \
	--publish=$(IP):$(PORT):80 \
	--cidfile="owncloudinitCID" \
	$(TAG)

owncloudCID:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-mysql:mysql \
	--publish=$(IP):$(PORT):80 \
	--volume=$(DATADIR):/var/www/html \
	--cidfile="owncloudCID" \
	$(TAG)

kill:
	-@docker kill `cat owncloudCID`
	-@docker kill `cat mysqlCID`
	-@docker kill `cat postgresCID`
	-@docker kill `cat redisCID`

killinit:
	-@docker kill `cat owncloudinitCID`
	-@docker kill `cat mysqlinitCID`
	-@docker kill `cat postgresinitCID`
	-@docker kill `cat redisinitCID`

rm-redimage:
	-@docker rm `cat owncloudCID`

rm-initimage:
	-@docker rm `cat owncloudinitCID`
	-@docker rm `cat mysqlinitCID`
	-@docker rm `cat postgresinitCID`
	-@docker rm `cat redisinitCID`

rm-image:
	-@docker rm `cat owncloudCID`
	-@docker rm `cat mysqlCID`
	-@docker rm `cat postgresCID`
	-@docker rm `cat redisCID`

rm-redcids:
	-@rm owncloudCID

rm-initcids:
	-@rm owncloudinitCID
	-@rm mysqlinitCID
	-@rm postgresinitCID
	-@rm redisinitCID

rm-cids:
	-@rm owncloudCID
	-@rm mysqlCID
	-@rm postgresCID
	-@rm redisCID

rmall: kill rm-image rm-cids

rm: kill rm-redimage rm-redcids

rminit: killinit rm-initimage rm-initcids

clean:  rm rminit rmmysqlinitCID rmmysql

initenter:
	docker exec -i -t `cat owncloudinitCID` /bin/bash

enter:
	docker exec -i -t `cat owncloudCID` /bin/bash

pgenter:
	docker exec -i -t `cat postgresCID` /bin/bash

grab: grabownclouddir grabmysqldatadir

grabownclouddir:
	-@mkdir -p /exports/owncloud
	docker cp `cat owncloudinitCID`:/var/www/html  - |sudo tar -C /exports/owncloud/ -pxf -
	echo /exports/owncloud/ > DATADIR

grabmysqldatadir:
	docker cp `cat mysqlinitCID`:/var/lib/mysql  - |sudo tar -C /exports/owncloud/ -pxf -

logs:
	docker logs -f `cat owncloudCID`

initlogs:
	docker logs -f `cat owncloudinitCID`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this owncloud [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

IP:
	@while [ -z "$$IP" ]; do \
		read -r -p "Enter the IP you wish to associate with this owncloud [IP]: " IP; echo "$$IP">>IP; cat IP; \
	done ;

DB_PASS:
	@while [ -z "$$DB_PASS" ]; do \
		read -r -p "Enter the DB_PASS you wish to associate with this container [DB_PASS]: " DB_PASS; echo "$$DB_PASS">>DB_PASS; cat DB_PASS; \
	done ;

DB_NAME:
	@while [ -z "$$DB_NAME" ]; do \
		read -r -p "Enter the DB_NAME you wish to associate with this container [DB_NAME]: " DB_NAME; echo "$$DB_NAME">>DB_NAME; cat DB_NAME; \
	done ;

DB_HOST:
	@while [ -z "$$DB_HOST" ]; do \
		read -r -p "Enter the DB_HOST you wish to associate with this container [DB_HOST]: " DB_HOST; echo "$$DB_HOST">>DB_HOST; cat DB_HOST; \
	done ;

DB_USER:
	@while [ -z "$$DB_USER" ]; do \
		read -r -p "Enter the DB_USER you wish to associate with this container [DB_USER]: " DB_USER; echo "$$DB_USER">>DB_USER; cat DB_USER; \
	done ;

PORT:
	@while [ -z "$$PORT" ]; do \
		read -r -p "Enter the port you wish to associate with this container [PORT]: " PORT; echo "$$PORT">>PORT; cat PORT; \
	done ;

example:
	cp -i TAG.example TAG
	curl icanhazip.com > IP
	echo '6080' > PORT
	tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1 > DB_PASS

# MYSQL additions
# use these to generate a mysql container that may or may not be persistent

mysqlCID:
	$(eval MYSQL_DATADIR := $(shell cat DATADIR))
	ifeq ($(MYSQL_DATADIR),'')
	$(error  "try make runmysqlinitCID and then make grab once you have initialized your installation")
	endif
	docker run \
	--cidfile="mysqlCID" \
	--name `cat NAME`-mysql \
	-e MYSQL_ROOT_PASSWORD=`cat DB_PASS` \
	-d \
	-v $(MYSQL_DATADIR)/mysql:/var/lib/mysql \
	mysql:5.7

rmmysql: mysqlcid-rmkill

mysqlcid-rmkill:
	-@docker kill `cat mysqlcid`
	-@docker rm `cat mysqlcid`
	-@rm mysqlcid

# This one is ephemeral and will not persist data
mysqlinitCID:
	$(eval DB_NAME := $(shell cat DB_NAME))
	$(eval DB_PASS := $(shell cat DB_PASS))
	$(eval DB_USER := $(shell cat DB_USER))
	docker run \
	--cidfile="mysqlinitCID" \
	--name `cat NAME`-mysqlinit \
	--env="MYSQL_DATABASE=$(DB_NAME)" \
	--env="MYSQL_USER=$(DB_USER)" \
	--env="MYSQL_PASSWORD=$(DB_PASS)" \
	--env="MYSQL_ROOT_PASSWORD=$(DB_PASS)" \
	-d \
	mysql:5.7

rmmysqlinitCID: mysqlinitCID-rmkill

mysqlinitCID-rmkill:
	-@docker kill `cat mysqlinitCID`
	-@docker rm `cat mysqlinitCID`
	-@rm mysqlinitCID
