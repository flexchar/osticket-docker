# file: Makefile
SHELL := bash

NAME   := osticket
TAG    := $$(git log -1 --pretty=%h)
IMG    := ${NAME}:${TAG}
LATEST := ${NAME}:latest

REGISTRY  := ghcr.io/flexchar

# Runtime presets
PROJECT_NAME 	:= osticket
CONTAINER_NAME	:= osticket
CONTAINER_ID 	= $$(docker ps -f name=${CONTAINER_NAME} -q -n 1)

help:           ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'
	@printf "\nImage name: ${NAME} \nCurrent commit hash: ${TAG} \nTarget tag: ${IMG} | ${LATEST}\n"


# ---------------------------------------------
# Commands for building the image
# ---------------------------------------------

build:		## Build Laravel image and tag w/commit hash and :latest
	@export DOCKER_BUILDKIT=1 && docker build -t ${IMG} --build-arg BUILDKIT_INLINE_CACHE=1 .
	@docker tag ${IMG} ${LATEST}
	@docker image ls ${IMG}

push: 		## Push image to REGISTRY Registry
	@docker tag ${IMG} ${REGISTRY}/${IMG} 
	@docker tag ${IMG} ${REGISTRY}/${LATEST}
	@docker push ${REGISTRY}/${IMG}
	@docker push ${REGISTRY}/${LATEST}

	@echo "Registry available at https://${REGISTRY}/${NAME}"

tag:		## Get image path with short commit tag
	@echo "${REGISTRY}/${IMG}"

pull:		## Pull latest image from GCR
	@docker pull ${REGISTRY}/${LATEST}


# ---------------------------------------------
# Commands for running the service
# ---------------------------------------------

stop:		## Stop containers
	@./down

start:		## Start containers
	@./up


# ---------------------------------------------
# Commands for interacting w/Docker
# ---------------------------------------------

ps:		## List containers for this project
	@docker ps -f name=${PROJECT_NAME} --format "table {{.ID}} {{.Image}}\t {{.Names}} \t {{.Status}} \t {{.Ports}} \t {{.Networks}}"

shell:		## Enter container shell
	@[ -n "${CONTAINER_ID}" ] && \
	docker exec -it ${CONTAINER_ID} zsh || \
	echo "Container is not running"

health: 	## Show health messages
	@docker inspect ${CONTAINER_ID} --format "{{json .State.Health }}" | json_pp

history:	## Show build history
	@docker image history ${IMG}

logs:		## Show logs
	@-docker logs ${CONTAINER_ID} -f || docker logs ${CONTAINER_NAME} -f

prune:		## Purge Datahub containers & volumes
	@[[ -n $$(docker ps -a -f name=${PROJECT_NAME} -q) ]] && docker rm $$(docker ps -a -f name=${PROJECT_NAME} -q) || exit 0
	@[[ -n $$(docker volume ls -f name=${PROJECT_NAME} -q) ]] && docker volume rm $$(docker volume ls -f name=${PROJECT_NAME} -q) || exit 0
