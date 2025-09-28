FROM ubuntu:22.04

ENV APP_PATH=/mythos
WORKDIR $APP_PATH

# set up the environment variables
ENV PATH="$PATH:$APP_PATH"
ENV LD_LIBRARY_PATH=$APP_PATH
ENV CHAIN_ID=mythos_7000-27

# install necessary dependencies
RUN apt-get update -y && \
    apt-get install -y \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# download the binaries and the genesis file
RUN wget https://raw.githubusercontent.com/loredanacirstea/tempreleases/main/mythos-testnet/genesis.json && \
    wget https://github.com/ark-us/wasmx/releases/download/v0.3.4/mythos-wz-v0.3.4-linux-amd64.tar.gz && \
    tar -xzvf mythos-wz-v0.3.4-linux-amd64.tar.gz && \
    rm mythos-wz-v0.3.4-linux-amd64.tar.gz

# init mythos and put the genesis file
RUN chmod +x mythos && \
    mythos testnet --chain-id=$CHAIN_ID --output-dir=testnet --v=1 --keyring-backend=test --commit-timeout=3000ms --minimum-gas-prices="" && \
    rm ./testnet/node0/mythos/config/genesis.json && \
    mv genesis.json ./testnet/node0/mythos/config/genesis.json

# update peers and cors
RUN sed -i '/^persistent_peers /s/=.*$/= "d4c522577b305675fc421f544fb0ef53d733f20b@207.180.200.54:26656"/' ./testnet/node0/mythos/config/config.toml && \
    sed -i '/^cors_allowed_origins /s/=.*$/= ["*"]/' ./testnet/node0/mythos/config/config.toml && \
    sed -i '/^enabled-unsafe-cors /s/=.*$/= true/' ./testnet/node0/mythos/config/app.toml

EXPOSE 26656
EXPOSE 26657
EXPOSE 1317

# start the node
ENTRYPOINT ["mythos", "start", "--home=testnet/node0/mythos"]
