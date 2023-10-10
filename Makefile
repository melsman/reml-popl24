.PHONY: all
all:
	make -C reml-demo all
	make -C reml-basis all

.PHONY: clean
clean:
	rm -rf *~ reml-popl24.tar.gz
	make -C reml-demo clean
	make -C reml-basis clean

reml-popl24.tar.gz: Dockerfile
	sudo docker build . -t reml-popl24
	sudo docker save reml-popl24:latest | gzip > $@
