NS = vp
NAME = bigcouch
VERSION = 1.3
LOCAL_TAG = $(NS)/$(NAME):$(VERSION)

REGISTRY = callforamerica
ORG = vp
REMOTE_TAG = $(REGISTRY)/$(NAME):$(VERSION)

GITHUB_REPO = docker-bigcouch
DOCKER_REPO = bigcouch
# BUILD_BRANCH = master

.PHONY: all build test release shell run start stop rm rmi default

all: build

checkout:
	@git checkout $(BUILD_BRANCH)

build:
	@docker build -t $(LOCAL_TAG) --rm .
	$(MAKE) tag

load-pvs:
	kubectl create -f kubernetes/bigcouch-pvs.yaml

load-pvcs:
	kubectl create -f kubernetes/bigcouch-pvcs.yaml

clean-pvc:
	-kubectl delete pv -l app=bigcouch
	-kubectl delete pvc -l app=bigcouch

patch-two:
	kubectl patch petset bigcouch -p '{"spec": {"replicas": 2}}' 
	kubectl get po --watch

patch-three:
	kubectl patch petset bigcouch -p '{"spec": {"replicas": 3}}' 

test-down:
	-kubectl delete petset bigcouch
	-kubectl delete po bigcouch-0
	-kubectl delete po bigcouch-1
	-kubectl delete po bigcouch-2
	$(MAKE) clean-pvc

test-up:
	$(MAKE) load-pvs
	$(MAKE) load-pvcs
	sleep 10
	kubectl create -f kubernetes/bigcouch-petset.yaml
	kubectl get po --watch

retest:
	$(MAKE) test-down
	sleep 10
	$(MAKE) test-up

tag:
	@docker tag -f $(LOCAL_TAG) $(REMOTE_TAG)

rebuild:
	@docker build -t $(LOCAL_TAG) --rm --no-cache .



commit:
	@git add -A .
	@git commit

deploy:
	@docker push $(REMOTE_TAG)

push:
	@git push origin master

shell:
	@docker exec -ti $(NAME) /bin/bash

run:
	@docker run -it --rm --name $(NAME) -e "KUBERNETES_HOSTNAME_FIX=true" --entrypoint bash $(LOCAL_TAG)

launch:
	@docker run -d --name $(NAME) $(LOCAL_TAG)

logs:
	@docker logs $(NAME)

logsf:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

stop:
	@docker stop $(NAME)

rm:
	@docker rm $(NAME)

rmi:
	@docker rmi $(LOCAL_TAG)
	@docker rmi $(REMOTE_TAG)

default: build