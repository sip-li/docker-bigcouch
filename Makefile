NS = vp
NAME = bigcouch
APP_VERSION = 0.4.2
IMAGE_VERSION = 2.0
VERSION = $(APP_VERSION)-$(IMAGE_VERSION)
LOCAL_TAG = $(NS)/$(NAME):$(VERSION)

REGISTRY = callforamerica
ORG = vp
REMOTE_TAG = $(REGISTRY)/$(NAME):$(VERSION)

GITHUB_REPO = docker-bigcouch
DOCKER_REPO = bigcouch
BUILD_BRANCH = master

VOLUME_ARGS = --tmpfs /volumes/bigcouch:size=512M
PORT_ARGS = -p "5984:5984" -p "5986:5986"
SHELL = bash -l

-include ../Makefile.inc

.PHONY: all build test release shell run start stop rm rmi default

all: build

checkout:
	@git checkout $(BUILD_BRANCH)

build:
	@docker build -t $(LOCAL_TAG) --force-rm .
	@$(MAKE) tag
	@$(MAKE) dclean

clean-pvc:
	@-kubectl delete pv -l app=$(NAME)
	@-kubectl delete pvc -l app=$(NAME)

patch-two:
	@kubectl patch petset $(NAME) -p '{"spec": {"replicas": 2}}' 
	@kubectl get po --watch

patch-three:
	@kubectl patch petset $(NAME) -p '{"spec": {"replicas": 3}}' 

test-down:
	@-kubectl delete petset $(NAME)
	@-kubectl delete po $(NAME)-0
	@-kubectl delete po $(NAME)-1
	@-kubectl delete po $(NAME)-2
	@$(MAKE) clean-pvc

test-up:
	@$(MAKE) load-pvs
	@$(MAKE) load-pvcs
	@sleep 10
	@kubectl create -f kubernetes/$(NAME)-petset.yaml
	@kubectl get po --watch

retest:
	@$(MAKE) test-down
	@sleep 10
	@$(MAKE) test-up

tag:
	@docker tag $(LOCAL_TAG) $(REMOTE_TAG)

rebuild:
	@docker build -t $(LOCAL_TAG) --force-rm --no-cache .
	@$(MAKE) tag
	@$(MAKE) dclean

commit:
	@git add -A .
	@git commit

push:
	@git push origin master

shell:
	@docker exec -ti $(NAME) $(SHELL)

run:
	@docker run -it --rm --name $(NAME) -h $(NAME).local $(LOCAL_TAG) $(SHELL)

launch:
	@docker run -d --name $(NAME) -h $(NAME).local $(VOLUME_ARGS) $(PORT_ARGS) $(LOCAL_TAG)

launch-net:
	@docker run -d --name $(NAME) -h $(NAME).local  $(VOLUME_ARGS) $(PORT_ARGS) --network=local --net-alias $(NAME).local $(LOCAL_TAG)

create-network:
	@docker network create -d bridge local

logs:
	@docker logs $(NAME)

logsf:
	@docker logs -f $(NAME)

start:
	@docker start $(NAME)

kill:
	@docker kill $(NAME)

stop:
	@docker stop $(NAME)

rm:
	@docker rm $(NAME)

rmi:
	@docker rmi $(LOCAL_TAG)
	@docker rmi $(REMOTE_TAG)

rmf:
	@docker rm -f $(NAME)

# dclean:
# 	@-docker ps -aq | gxargs -I{} docker rm {} 2> /dev/null || true
# 	@-docker images -f dangling=true -q | xargs docker rmi
# 	@-docker volume ls -f dangling=true -q | xargs docker volume rm

kube-deploy-pvs:
	@kubectl create -f kubernetes/$(NAME)-pvs.yaml

kube-deploy-pvcs:
	@kubectl create -f kubernetes/$(NAME)-pvcs.yaml

kube-deploy:
	@$(MAKE) kube-deploy-petset
	
kube-deploy-petset:
	@kubectl create -f kubernetes/$(NAME)-petset.yaml

kube-edit-petset:
	@kubectl edit petset/$(NAME)

kube-delete-petset:
	@kubectl delete petset/$(NAME)

kube-deploy-service:
	@kubectl create -f kubernetes/$(NAME)-service.yaml
	@kubectl create -f kubernetes/$(NAME)-service-balanced.yaml

kube-delete-service:
	@kubectl delete svc $(NAME)
	@kubectl delete svc $(NAME)bal

kube-apply-service:
	@kubectl apply -f kubernetes/$(NAME)-service.yaml
	@kubectl apply -f kubernetes/$(NAME)-service-balanced.yaml

kube-load-pvs:
	@kubectl create -f kubernetes/$(NAME)-pvs.yaml

kube-load-pvcs:
	@kubectl create -f kubernetes/$(NAME)-pvcs.yaml

kube-delete-pvs:
	@kubectl delete -f kubernetes/$(NAME)-pvs.yaml

kube-delete-pvcs:
	@kubectl delete -f kubernetes/$(NAME)-pvcs.yaml

kube-logsf:
	@kubectl logs -f $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-logsft:
	@kubectl logs -f --tail=25 $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1)

kube-shell:
	@kubectl exec -ti $(shell kubectl get po | grep $(NAME) | cut -d' ' -f1) -- bash


default: build