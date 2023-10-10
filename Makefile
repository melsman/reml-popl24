.PHONY: all
all:
	make -C reml-demo all
	make -C reml-basis all

.PHONY: clean
clean:
	rm -rf *~ reml-popl24.tar.gz
	make -C reml-demo clean
	make -C reml-basis clean

.PHONY: docker
docker: reml-popl24.tar.gz

reml-popl24.tar.gz: Dockerfile
	docker build --platform linux/amd64 -t reml-popl24 .
	docker save reml-popl24:latest | gzip > $@

# To load and run:

# docker load -i reml-popl24.tar.gz
# docker run --platform linux/amd64 -it reml-popl24:latest
