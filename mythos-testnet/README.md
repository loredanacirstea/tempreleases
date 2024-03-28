# Mythos Testnet 23

## Changes!

- chain id changed to `mythos_7000-23`

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
mkdir mythos && cd mythos && wget "https://github.com/loredanacirstea/tempreleases/raw/main/mythos-testnet/linux_x86_64.zip?commit=faa91e36ea896a5f15d54cea2641818964ab6011" -O linux_x86_64.zip && unzip linux_x86_64.zip && mv linux_x86_64 ./bin && cd bin && chmod +x ./mythosd && cd ..
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

# commit `46794933f75aa69077d0a725272e0272594b8b68`
```

Initialize the chain:

```shell=
rm -rf ./testnet && mythosd testnet init-files --chain-id=mythos_7000-23 --output-dir=$(pwd)/testnet --v=1 --keyring-backend=test --minimum-gas-prices="1000amyt" --same-machine=true --libp2p

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
rm ./testnet/node0/mythosd/config/genesis.json
wget -P ./testnet/node0/mythosd/config https://raw.githubusercontent.com/loredanacirstea/tempreleases/main/mythos-testnet/genesis.json
```

Check genesis checksum!

```
sha256sum ./testnet/node0/mythosd/config/genesis.json
# 4a1cf3bda46e37e6f680cd361d947a89344abf6e921134a0a4c0277c370224e6
```

## 3. Setup account

Create your own account and ask for tokens in Mythos Discord with your public address. https://discord.gg/f5rbU2bkPz

```shell=
mythosd keys add mykey --home=testnet/node0/mythosd --keyring-backend=test
```

## 4. Node IDS (important!)

* go to app.toml, under `Network Configuration` (bottom page) and update `ips` with your EXTERNAL IP and a bootstrap address and p2p id of a trusted peer node

```shell=
vi testnet/node0/mythosd/config/app.toml
```
```
# Comma separated list of node ips
ips = "<your_mythos_address>@<your_libp2p_EXTERNAL_IP_address>,mythos1drz0zullqalfvgsgu8dmx0w6vdq9mkq63wdepp@/ip4/74.208.105.20/tcp/5001/p2p/12D3KooWFzX5hTTtB842DfY6qXfAMD7dzixhpsksjNn6TSXnu7Eq"
```

## 5. Allow 5001 as an external port

```
sudo ufw allow 5001
```

## 6. Start

```shell=
mythosd start --home=testnet/node0/mythosd

# or start your service
systemctl start mythos && journalctl -u mythos.service -f -o cat
```

## 7. Sync Node

Start your node and let it sync. After your node is synced, send the create validator transaction.

* create a `validator.json` file

get your validator's public key

```
mythosd tendermint show-validator --home ./testnet/node0/mythosd
```

and replace the information in the template below:

```json
{
	"pubkey": {"@type":"/cosmos.crypto.ed25519.PubKey","key":"ScSHzXINHzfOGMI6XN/7CzfpfAwKlIAOwCHNHEFCw1g="},
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

mythosd tx cosmosmod staking create-validator ./validator.json --from node0 --chain-id=mythos_7000-23 --keyring-backend=test --home=testnet/node0/mythosd --fees 200000000000000amyt --gas auto --gas-adjustment 1.4 --node tcp://127.0.0.1:26657 --yes

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
