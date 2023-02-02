# How to run the Mythos Testnet

Tutorial: https://hackmd.io/@aHg__0sdStO0UN9Z14Zlug/B18Md1Noi

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
