.PHONY: all
all:
	make -C reml-demo

.PHONY: clean
clean:
	rm -rf *~ reml-popl24.tar.gz
	make -C reml-demo clean

reml-popl24.tar.gz: Dockerfile
	sudo docker build . -t reml-popl24
	sudo docker save reml-popl24:latest | gzip > $@
