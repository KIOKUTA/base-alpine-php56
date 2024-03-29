name = kiokuta/base-alpine-php56
tags = 1.0.0-base-php5.6-alpine3.8

clean:
	docker rmi -f $$(docker images  $(name) -q)

build:
	docker build --rm -t $(name) .

tag:
	echo $(tags) | awk '{for(i=1;i<=NF;i++){print $$i}}' | xargs -I % docker tag $(name):latest $(name):%

push:
	echo "latest $(tags)" | awk '{for(i=1;i<=NF;i++){print $$i}}' | xargs -I % docker push $(name):%
