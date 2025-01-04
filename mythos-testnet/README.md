# Mythos Testnet 26

## Public Endpoints

  * rpc (26657): https://mythos-testnet-rpc.provable.dev
  * rest (1317): https://mythos-testnet.provable.dev/rest

## Explorers

  * https://testnet.explorer.provable.dev/mythos

## 1. Download binaries & genesis.json

* for ubuntu, you need >= 22.04


Stop and remove previous mythos testnet (if installed)
```shell==
sudo -S systemctl stop mythos

rm -rf /root/mythos
```

* install latest binary published at https://github.com/loredanacirstea/tempreleases/releases

```shell=
mkdir mythos && cd mythos && curl -OL "https://github.com/loredanacirstea/tempreleases/releases/download/v0.1.2/mythos-wz-v0.1.2-linux-amd64.tar.gz" && tar -xzvf mythos-wz-v0.1.2-linux-amd64.tar.gz && mv mythos-wz-v0.1.2-linux-amd64/mythosd ./bin && cd bin && chmod +x ./mythosd && cd ..
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
mythosd version

# v0.1.2
```

Initialize the chain:

```shell=
rm -rf ./testnet && mythosd testnet init-files --network.initial-chains=mythos,level0 --output-dir=$(pwd)/testnet --v=1 --keyring-backend=test --minimum-gas-prices="1000amyt" --same-machine=true --libp2p --min-level-validators=2 --enable-eid=false --chain-id=mythos_7000-26

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
rm ./testnet/node0/mythosd/config/genesis.json && rm ./testnet/node0/mythosd/config/genesis_mythos_7000-26.json && wget -P ./testnet/node0/mythosd/config https://raw.githubusercontent.com/loredanacirstea/tempreleases/main/mythos-testnet/genesis.json && cp ./testnet/node0/mythosd/config/genesis.json ./testnet/node0/mythosd/config/genesis_mythos_7000-26.json
```

Check genesis checksum!

```
sha256sum ./testnet/node0/mythosd/config/genesis.json
sha256sum ./testnet/node0/mythosd/config/genesis_mythos_7000-26.json
# fdb0c02c9052fc9f98e2a7b9f41f7b90a814cb20482e68fe12a2accdfbeabaa7
```

* for macOS `shasum -a 256 ./testnet/node0/mythosd/config/genesis.json`

## 3. Setup account

An account has been created for you with the name `node0`. Get the public address (starts with `mythos1`) and paste it in the Mythos Discord and ask for tokens. https://discord.gg/f5rbU2bkPz

```shell=
mythosd keys list --keyring-backend test --home ./testnet/node0/mythosd

```

* the address needs to be converted from `cosmos` to `mythos` prefixes https://www.bech32converter.com/. Or you can take it from `ips` in `./testnet/node0/mythosd/config/app.toml` (usually first address in the mapping)

## 4. Node IDS (important!)

* go to app.toml, under `Network Configuration` (bottom page) and update `ips` with your EXTERNAL IP (replace localhost) and the URI of a trusted peer node.
* your node should be first (default index for your node is 0 in the `id` mapping)

```shell=
vi ./testnet/node0/mythosd/config/app.toml
```
```
# Comma separated list of node ips
ips = "mythos_7000-14:YOUR_mythos1_ADDRESS@/ip4/YOUR_EXTERNAL_IP/tcp/5001/p2p/generated_libp2p_id,mythos1t4mccmwzs3zp7cslwryfzf64qwwnc9qavuewh2@/ip4/84.232.220.167/tcp/5001/p2p/12D3KooWErv9aiTwgVWuEiPccHvwjErwFbSDobuTQLnJ9fcGFe9G;level0_1000-1:YOUR_mythos1_ADDRESS@/ip4/YOUR_EXTERNAL_IP/tcp/5001/p2p/generated_libp2p_id"
```

* allow others to state sync, by keeping data snapshots

```
sed -i.bak -E "s|^(snapshot-interval[[:space:]]+=[[:space:]]+).*$|\1300|" ./testnet/node0/mythosd/config/app.toml
```

## 5. External ports

* 8090, 5001, 9900, 1317, 26657, 8545

```
sudo ufw allow 5001
sudo ufw allow 26657
sudo ufw allow 1317
```

# 6. Set up node sync before starting the node

```shell=

RPC="http://84.232.220.167:26657"
HOMEMAIN=/root/mythos/testnet/node0/mythosd

RECENT_HEIGHT=$(curl -s $RPC/block | jq -r .result.block.header.height)
TRUST_HEIGHT=$((RECENT_HEIGHT - 1))
TRUST_HASH=$(curl -s "$RPC/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)
echo $TRUST_HEIGHT && echo $TRUST_HASH
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
* if you get an error `post failed: Post \"http://localhost:26657\": EOF`, reset the state and restart the node:
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

* replace `--memo=""` value with your node ID - it is the first id for the mythos chain id from `ids=` in `./testnet/node0/mythosd/config/app.toml`

```shell=

mythosd tx cosmosmod staking create-validator ./validator.json --from node0 --chain-id=mythos_7000-26 --keyring-backend=test --home=./testnet/node0/mythosd --fees 200000000000000amyt --gas=20000000 --memo="YOUR_mythos1_ADDRESS@/ip4/YOUR_EXTERNAL_IP/tcp/5001/p2p/GENERATED_libp2p_id" --node tcp://127.0.0.1:26657 --yes

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

[Install]
WantedBy=multi-user.target
```
**NOTE:** Please notice that in service file example I use dedicated user account `t-mythos`. In case you running service under different account, please adjust it accordingly.
