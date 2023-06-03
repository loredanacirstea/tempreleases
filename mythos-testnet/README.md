# Mythos Testnet 13

## Changes!

- chain id changed to `mythos_7000-13`

## Public Endpoints

  * rpc (26657): https://mythos-testnet-rpc.provable.dev
  * rest (1317): https://mythos-testnet.provable.dev/rest

## Explorers

  * https://testnet.explorer.provable.dev/mythos

## 0. Install wasmedge library v0.11.2

```
curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -v 0.11.2

```

- for installation prerequisites & troubleshooting: https://wasmedge.org/book/en/quick_start/install.html


## 1. Download binaries & genesis.json

* for ubuntu, you need >= 20.04 (binary needs GLIBC >= 2.31)
* `mythos version --long` commit `e7c10d4817d6d3e3496d9fbb62e8787ca8bb9f7f`
* `sha256sum genesis.json` is `313cac5c697c4e93084b24db18d9f9a6395b72b9c77316fe4d5132cca498a039`

```shell=
mkdir mythos && cd mythos
wget "https://github.com/loredanacirstea/tempreleases/raw/main/mythos-testnet/linux_x86_64.zip?commit=e5540101518e243a50865df890ad115a5413a748" -O linux_x86_64.zip && unzip linux_x86_64.zip && mv linux_x86_64 ./bin && cd bin && chmod +x ./mythos && cd ..
```

Set up the path for the mythos executable. E.g.
```
vi ~/.bashrc
```
Add `export PATH=/root/mythos/bin:$PATH`
```
source ~/.bashrc
```

Check the mythos version. Initialize the chain:

```shell=
mythos testnet init-files --chain-id=mythos_7000-13 --output-dir=$(pwd)/testnet --v=1 --keyring-backend=test --minimum-gas-prices="1000amyt"

```
* example service script.

```bash

sudo tee /etc/systemd/system/mythos.service > /dev/null <<EOF
[Unit]
Description=Mythos Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=/root/mythos/bin/mythos start --home=/root/mythos/testnet/node0/mythosd
Restart=always
RestartSec=3
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target
EOF

```

## 2. Replace genesis.json

Replace `testnet/node0/mythosd/config/genesis.json`

```shell=
rm ./testnet/node0/mythosd/config/genesis.json
wget -P ./testnet/node0/mythosd/config https://raw.githubusercontent.com/loredanacirstea/tempreleases/main/mythos-testnet/genesis.json
```

## 3. Setup account

Create your own account and ask for tokens in Mythos Discord. https://discord.gg/f5rbU2bkPz

```shell=
mythos keys add mykey --home=testnet/node0/mythosd --keyring-backend=test
```

## 4. Persistent peers

* update persistent_peers in config.toml

```shell=
vi testnet/node0/mythosd/config/config.toml

# persistent_peers = "7641c2d8e0c2c69abb3a37b4246006d01436a865@207.180.200.54:26656,6eed5f8f41200bb3fa815dd89efc232eb73fc703@62.171.161.250:26656"
```

## 5. Start

```shell=
mythos start --home=testnet/node0/mythosd

# or start your service
systemctl start mythos && journalctl -u mythos.service -f -o cat
```

## 6. Create validator

Same as any cosmos chain. First, wait until your node is synced. And then create your validator:

```shell=
mythos tx staking create-validator --amount 100000000000000000000amyt --from mykey --pubkey=$(mythos tendermint show-validator --home=testnet/node0/mythosd) --chain-id=mythos_7000-13 --moniker="myvalidator" --commission-rate="0.05" --commission-max-rate="0.20" --commission-max-change-rate="0.05" --min-self-delegation="1000000000000000000" --keyring-backend=test --home=testnet/node0/mythosd --fees 200000000000000amyt --gas auto --gas-adjustment 1.4
```

If you have issues with syncing and get an apphash error, try resetting the state with `mythos tendermint unsafe-reset-all --home=testnet/node0/mythosd` and then resyncing from scratch.

## 7. Serving the Dokia Web Server

Dokia Web Server is by default enabled and running on port `9999`. You can change this from `app.toml`, under `[websrv]` settings.

## 8. Resetting the chain

```shell=
cd mythos
rm -rf testnet
rm -rf bin

## repeat point 1
```

## 9. Compile, Upload & interact with contracts

You can add the chain to Keplr from https://testnet.explorer.provable.dev/mythos -> "Connect Wallet"

Or from https://cosmwasm.tools/, with:

```
mythos-testnet-13
mythos_7000-13
https://mythos-testnet-rpc.provable.dev
https://mythos-testnet.provable.dev/rest
mythos
amyt
18
10000000
```

Demo video: https://youtu.be/0XEs9gltKH4


# How to create Mythos Testnet docker container and run it

1. Install [Docker](https://docs.docker.com/get-docker/)
2. Build a container (run from the current directory): `docker build -t mythos:testnet -f Dockerfile .`
3. Run the container:

```
docker run -d --name mythos-testnet \
  -p 26656:26656 \
  -p 26657:26657 \
  -p 1317:1317 \
  mythos:testnet
```

If you would like to monitor the logs, then run: `docker logs -f mythos-testnet`

Add `-v yourhostdir:/mythos/testnet` at step 3 to bind your host directory to the testnet data directory inside the container.

If you would like to run your node as validator, you can do further steps by running commands inside running container:

`docker exec -it mythos-testnet bash`

^ then run create key and validator commands inside newly created shell

