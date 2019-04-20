FROM dlanguage/dmd AS build-stage
RUN apt-get update && apt-get -y install \
        git \
        libevent-dev \
        libssl-dev \
        python-setuptools

# Install dockerize from GIT submodule
RUN git clone --depth=1 https://github.com/larsks/dockerize.git
WORKDIR dockerize
RUN python setup.py install

WORKDIR /
COPY hello.d .
RUN dmd -of=hello hello.d
RUN dockerize -o /output -n /hello

FROM scratch
COPY --from=build-stage /output /
CMD ["./hello"]
