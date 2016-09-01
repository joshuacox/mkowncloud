.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container

temp: init

init: TAG IP DB_PASS NAME PORT rmall mysqltemp owncloudinitCID

run: TAG IP DB_PASS NAME PORT rmall mysqlCID owncloudCID

next: grab rminit run

owncloudinitCID:
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	$(eval IP := $(shell cat IP))
	$(eval PORT := $(shell cat PORT))
	docker run --name=$(NAME) \
	-d \
	--link=$(NAME)-mysqltemp:mysql \
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

clean:  rm rminit rmmysqltemp rmmysql

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
	$(error  "try make runmysqltemp and then make grab once you have initialized your installation")
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
mysqltemp:
	docker run \
	--cidfile="mysqltemp" \
	--name `cat NAME`-mysqltemp \
	-e MYSQL_ROOT_PASSWORD=`cat DB_PASS` \
	-d \
	mysql:5.7

rmmysqltemp: mysqltemp-rmkill

mysqltemp-rmkill:
	-@docker kill `cat mysqltemp`
	-@docker rm `cat mysqltemp`
	-@rm mysqltemp

