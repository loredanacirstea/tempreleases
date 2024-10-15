# Mythos Testnet 25

## Changes!

- chain id changed to `mythos_7000-25`

## Public Endpoints

  * rpc (26657): https://mythos-testnet-rpc.provable.dev
  * rest (1317): https://mythos-testnet.provable.dev/rest

  * RPC endpoint: https://testnet-rpc.mythos.chaintools.tech
  * API endpoint: https://testnet-api.mythos.chaintools.tech

## Explorers

  * https://testnet.explorer.provable.dev/mythos
  * https://testnet.explorer.chaintools.tech/mythos

## 0. Install wasmedge library v0.13.4

```
curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash -s -- -v 0.13.4

# run the command shown, to apply the env file, e.g.:
source /root/.bashrc
# or:
source $HOME/.wasmedge/env

```

- for installation prerequisites & troubleshooting: https://wasmedge.org/docs/start/install/


## 1. Download binaries & genesis.json

* for ubuntu, you need >= 22.04


Stop and remove previous mythos testnet (if installed)
```shell==
sudo -S systemctl stop mythos

rm -rf /root/mythos
```

```shell=
mkdir mythos && cd mythos && wget "https://github.com/loredanacirstea/tempreleases/raw/main/mythos-testnet/linux_x86_64.zip?commit=37ea86f283427f9522d4699262dffc1ab1e8754f" -O linux_x86_64.zip && unzip linux_x86_64.zip && mv linux_x86_64 ./bin && cd bin && chmod +x ./mythosd && cd ..
```

Set up the path for the mythosd executable. E.g.
```
vi ~/.bashrc
```
Add `export PATH=/root/mythos/bin:$PATH`
```
source ~/.bashrc
```

Check the mythos version to be the same as below.

```sh
mythosd version --long

# commit `37ea86f283427f9522d4699262dffc1ab1e8754f`
```

Initialize the chain:

```shell=
rm -rf ./testnet && mythosd testnet init-files --network.initial-chains=mythos,level0 --output-dir=$(pwd)/testnet --v=1 --keyring-backend=test --minimum-gas-prices="1000amyt" --same-machine=true --libp2p --min-level-validators=2 --enable-eid=false --chain-id=mythos_7000-25

```
* example service script for starting mythos as a service for Linux.

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
rm ./testnet/node0/mythosd/config/genesis.json && rm ./testnet/node0/mythosd/config/genesis_mythos_7000-25.json && wget -P ./testnet/node0/mythosd/config https://raw.githubusercontent.com/loredanacirstea/tempreleases/main/mythos-testnet/genesis.json && cp ./testnet/node0/mythosd/config/genesis.json ./testnet/node0/mythosd/config/genesis_mythos_7000-25.json
```

Check genesis checksum!

```
sha256sum ./testnet/node0/mythosd/config/genesis.json
# 0d12fba769c1cd5dc9291edaa94023e468a924c65e88f7c87f56a14409fb0f00
```

## 3. Setup account

An account has been created for you with the name `node0`. Get the public address (starts with `mythos1`) and paste it in the Mythos Discord and ask for tokens. https://discord.gg/f5rbU2bkPz

```shell=
mythosd keys list --keyring-backend test --home ./testnet/node0/mythosd

```

## 4. Node IDS (important!)

* go to app.toml, under `Network Configuration` (bottom page) and update `ips` with your EXTERNAL IP (replace localhost) and the URI of a trusted peer node.

```shell=
vi ./testnet/node0/mythosd/config/app.toml
```
```
# Comma separated list of node ips
ips = "mythos_7000-14:YOUR_mythos1_ADDRESS@/ip4/YOUR_EXTERNAL_IP/tcp/5001/p2p/generated_libp2p_id,mythos1xffspezxgs668l2xjq2cl5nrzl28atgm79vtav@/ip4/217.76.51.233/tcp/5001/p2p/12D3KooWKD1FjsbaWxn3k5SQg8LfFG4QxPPQFmLyax7sXetSLvHy;level0_1000-1:YOUR_mythos1_ADDRESS@/ip4/YOUR_EXTERNAL_IP/tcp/5001/p2p/generated_libp2p_id"
```

## 5. External ports

* 8090, 5001, 9900, 1317, 26657, 8545

```
sudo ufw allow 5001
sudo ufw allow 26657
sudo ufw allow 1317
```

# 6. Sync Node Settings

```shell=

RPC="http://217.76.51.233:26657"
RECENT_HEIGHT=$(curl -s $RPC/block | jq -r .result.block.header.height)
TRUST_HEIGHT=$((RECENT_HEIGHT - 1))
TRUST_HASH=$(curl -s "$RPC/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)

HOMEMAIN=/root/mythos/testnet/node0/mythosd

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$RPC,$RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$TRUST_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOMEMAIN/config/config.toml

```

## 7. Start Node

```shell=
# start your service
systemctl start mythos && journalctl -u mythos.service -f -o cat
```

Start your node and let it sync. After your node is synced, disable the state sync:

```shell=
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1false|" $HOMEMAIN/config/config.toml
```

Troubleshooting:
* if you get an error `post failed: Post \"http://217.76.51.233:26657\": EOF`, reset the state and restart the node:
```shell=

systemctl stop mythos
mythosd tendermint unsafe-reset-all --home=./testnet/node0/mythosd
systemctl start mythos && journalctl -u mythos.service -f -o cat
```

## 8. Create your validator

Start your node and let it sync. After your node is synced, send the create validator transaction.

* create a `validator.json` file

get your validator's public key

```
mythosd tendermint show-validator --home ./testnet/node0/mythosd
```

and replace the information in the template below:

```json
{
	"pubkey": {"type_url":"/cosmos.crypto.ed25519.PubKey","value":"eyJrZXkiOiJlRWJ5OTBPdnl5ZkMwYU5NaXI0MGZZWVVyQUxiKzhTcDNQY1ZBTDJTZ2tVPSJ9"},
	"amount": "10000000000000000000amyt",
	"moniker": "lore",
	"identity": "optional identity signature (ex. UPort or Keybase)",
	"website": "validator's (optional) website",
	"security": "validator's (optional) security contact email",
	"details": "validator's (optional) details",
	"commission-rate": "0.05",
	"commission-max-rate": "0.2",
	"commission-max-change-rate": "0.05",
	"min-self-delegation": "1000000000000"
}
```


```shell=
touch ./validator.json
vi ./validator.json
# and paste the json configuration.
```

```shell=

mythosd tx cosmosmod staking create-validator ./validator.json --from node0 --chain-id=mythos_7000-25 --keyring-backend=test --home=./testnet/node0/mythosd --fees 200000000000000amyt --gas auto --gas-adjustment 1.4 --node tcp://127.0.0.1:26657 --yes

```

## 8. Reset Data

If you encounter issues and need to reset the chain data and resync from scratch:
```
mythosd tendermint unsafe-reset-all --home=./testnet/node0/mythosd
```


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
