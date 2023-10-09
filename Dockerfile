FROM debian:bullseye-slim
LABEL description="Artifact for the paper *Explicit Effects and Effect Constraints in ReML* submitted to POPL 2024"

# Install tools
RUN apt-get update
RUN apt-get install -y sudo make gcc libgmp-dev time automake patch git bsdextrautils

# Clean up image.
RUN apt-get clean autoclean
RUN apt-get autoremove --yes
RUN rm -rf /var/lib/{apt,dpkg,cache,log}/

# Set up user
RUN adduser --gecos '' --disabled-password art
RUN echo "art ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers
USER art
WORKDIR /home/art/

# Install MLKit
ADD --chown=art https://github.com/melsman/mlkit/releases/download/v4.7.4/mlkit-bin-dist-linux.tgz ./
RUN tar xf mlkit-bin-dist-linux.tgz
RUN make -C mlkit-bin-dist-linux install PREFIX=/home/art/mlkit
ENV PATH=/home/art/mlkit/bin:$PATH
ENV SML_LIB=/home/art/mlkit/lib/mlkit
RUN rm -rf mlkit-bin-dist-linux*

WORKDIR /home/art

# Copy artifact files into image.
RUN mkdir reml-popl24
COPY --chown=art ./ reml-popl24/

WORKDIR /home/art/reml-popl24

# Install MLKit src
ADD --chown=art https://github.com/melsman/mlkit/archive/refs/tags/v4.7.4.tar.gz ./
RUN tar xf v4.7.4.tar.gz
RUN rm -f v4.7.4.tar.gz

CMD bash
