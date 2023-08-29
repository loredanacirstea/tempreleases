# Mythos Testnet 15

## Changes!

- chain id changed to `mythos_7000-15`

## Public Endpoints

  * rpc (26657): https://mythos-testnet-rpc.provable.dev
  * rest (1317): https://mythos-testnet.provable.dev/rest

  * RPC endpoint: https://testnet-rpc.mythos.chaintools.tech
  * API endpoint: https://testnet-api.mythos.chaintools.tech

## Explorers

  * https://testnet.explorer.provable.dev/mythos
  * https://testnet.explorer.chaintools.tech/mythos

## 0. Install wasmedge library v0.11.2

```
curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -v 0.11.2

```

- for installation prerequisites & troubleshooting: https://wasmedge.org/docs/start/install/


## 1. Download binaries & genesis.json

* for ubuntu, you need >= 20.04 (binary needs GLIBC >= 2.31)
* `mythosd version --long` commit `0e4109955ec06886a058765f6cf2a260d1218b59`
* `sha256sum genesis.json` is `902ae4e289f26b2ff96ac6e770475de417849c5a44b922e4faf47b9078b5a3e3`

Stop and remove previous mythos testnet
```shell==
sudo -S systemctl stop mythos

rm -rf /root/mythos
```

```shell=
mkdir mythos && cd mythos && wget "https://github.com/loredanacirstea/tempreleases/raw/main/mythos-testnet/linux_x86_64.zip?commit=c9e9038ea400a4160c3c674ba290a6b13b786f92" -O linux_x86_64.zip && unzip linux_x86_64.zip && mv linux_x86_64 ./bin && cd bin && chmod +x ./mythosd && cd ..
```

Set up the path for the mythosd executable. E.g.
```
vi ~/.bashrc
```
Add `export PATH=/root/mythos/bin:$PATH`
```
source ~/.bashrc
```

Check the mythos version. Initialize the chain:

```shell=
mythosd testnet init-files --chain-id=mythos_7000-15 --output-dir=$(pwd)/testnet --v=1 --keyring-backend=test --minimum-gas-prices="1000amyt"

```
* example service script.

```bash

sudo tee /etc/systemd/system/mythos.service > /dev/null <<EOF
[Unit]
Description=Mythos Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=/root/mythos/bin/mythosd start --home=/root/mythos/testnet/node0/mythosd
Restart=always
RestartSec=3
LimitNOFILE=infinity
Environment="LD_LIBRARY_PATH=/root/.wasmedge/lib"

[Install]
WantedBy=multi-user.target
EOF

```

```shell=
systemctl daemon-reload
systemctl enable mythos.service
```

## 2. Replace genesis.json

Replace `testnet/node0/mythosd/config/genesis.json`:

```shell=
rm ./testnet/node0/mythosd/config/genesis.json
wget -P ./testnet/node0/mythosd/config https://raw.githubusercontent.com/loredanacirstea/tempreleases/main/mythos-testnet/genesis.json
```

## 3. Setup account

Create your own account and ask for tokens in Mythos Discord. https://discord.gg/f5rbU2bkPz

```shell=
mythosd keys add mykey --home=testnet/node0/mythosd --keyring-backend=test
```

## 4. Persistent peers

* update persistent_peers in config.toml

```shell=
vi testnet/node0/mythosd/config/config.toml

# persistent_peers = "53d636a08e1362924c646b9d8acf7d0e930fc288@207.180.200.54:26656,146778a99a7ae6fe68a88b5bdcf939f6eca094dc@62.171.161.250:26656"
```

## 5. Start

```shell=
mythosd start --home=testnet/node0/mythosd

# or start your service
systemctl start mythos && journalctl -u mythos.service -f -o cat
```

## 6. Create validator

Same as any cosmos chain. First, wait until your node is synced. And then create your validator:

```shell=
mythosd tx staking create-validator --amount 100000000000000000000amyt --from mykey --pubkey=$(mythosd tendermint show-validator --home=testnet/node0/mythosd) --chain-id=mythos_7000-15 --moniker="myvalidator" --commission-rate="0.05" --commission-max-rate="0.20" --commission-max-change-rate="0.05" --min-self-delegation="1000000000000000000" --keyring-backend=test --home=testnet/node0/mythosd --fees 200000000000000amyt --gas auto --gas-adjustment 1.4
```

If you have issues with syncing and get an apphash error, try resetting the state with `mythosd tendermint unsafe-reset-all --home=testnet/node0/mythosd` and then resyncing from scratch.

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
mythos-testnet-15
mythos_7000-15
https://mythos-testnet-rpc.provable.dev
https://mythos-testnet.provable.dev/rest
mythos
amyt
18
10000000
```

- for EVM contracts, you can use any Ethereum-like system, such as remix.ethereum.org and Metamask, to deploy contracts.
- or, our general purpose dApp, that works with the Keplr wallet: https://marks.provable.dev/?ipfs=QmYZJAXCDojeeEPwXR7vvCQDqyxALkhsLAKEQE4acb38wH&rpc=https://mythos-testnet-rpc.provable.dev. This same dApp also works as a Remix plugin, if you want to deploy EVM contracts with Keplr.

(_WIP republishing for new testnet :_)
- Estonia ID dApp for registering account, for who wants to test: https://mark.provable.dev/?ipfs=QmPiruznHUeEFDxL9jiNVJMAg1h78jU8MQJLDG5HZjEFZP
- Creating a website and registering with the webserver:
https://mark.provable.dev/?ipfs=QmeRzxCtPNxUan39Pw5P6dUrvRZysgh96yp14Z2KDqGjz8&router=0x701028B38c9fe59ACE07331b545C46C34b75ed06&serverCodeId=14

### Demos

Demo video: https://youtu.be/0XEs9gltKH4
- demo of how to use the Remix plugin: https://youtu.be/Xk2hmmb5orU
- demo for the Estonia ID dApp: https://youtu.be/-OH_XMmucQI?t=230



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


# Appendix A. - Setup Mythos node with Cosmovisor

## Build Cosmovisor
```bash
cd ${HOME}
git clone https://github.com/cosmos/cosmos-sdk && cd cosmos-sdk/tools/cosmovisor/
make
sudo cp cosmovisor /usr/local/bin
```

## Service file
```
[Unit]
Description=Mythos Testnet Validator
After=network-online.target

[Service]
User=t-mythos
Group=t-mythos
ExecStart=/usr/local/bin/cosmovisor run start
Restart=always
RestartSec=3
LimitNOFILE=8192
Environment="DAEMON_NAME=mythosd"
Environment="DAEMON_HOME=/home/t-mythos/.mythos"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_LOG_BUFFER_SIZE=512"
Environment="UNSAFE_SKIP_BACKUP=true"
Environment="PATH=/home/t-mythos/.wasmedge/bin"
Environment="LD_LIBRARY_PATH=/home/t-mythos/.wasmedge/lib"

[Install]
WantedBy=multi-user.target
```
**NOTE:** Please notice that in service file example I use dedicated user account `t-mythos`. In case you running service under different account, please adjust it accordingly.
