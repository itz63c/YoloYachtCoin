YYCcoin Core integration/staging tree
=====================================

Developer chat can be found on Discord at [https://discord.me/yyc](https://discord.me/yyc).

What is YYCcoin?
----------------

YYCcoin is an experimental digital currency that enables instant payments to
anyone, anywhere in the world. YYCcoin uses peer-to-peer technology to operate
with no central authority: managing transactions and issuing money are carried
out collectively by the network. YYCcoin Core is the name of open source
software which enables the use of this currency.

For more information, as well as an immediately useable, binary version of
the YYCcoin Core software, see [https://www.yoloyachtclub.com](https://www.yoloyachtclub.com).

Implementation
-------
Implementing the yyccoind application is trivial and assumes Ubuntu Server 18.04 LTS

```bash
sudo apt install redis build-essential libgmp3-dev \
    libsodium-dev libboost-dev libboost-system1.65 \
    libboost-filesystem1.65 libboost-program-options1.65 \
    libboost-thread1.65 libdb5.3++ libminiupnpc10 \
    libevent-pthreads-2.1-6 libzmq5 -y
    
mkdir wsbcoin .wsbcoin
echo "daemon=1" > .wsbcoin/wsbcoin.conf
curl -o .wsbcoin/wsbcoin.conf https://raw.githubusercontent.com/wsbcoin-project/mining-pool-setup/master/wsbcoin.conf
curl -o wsbcoin/wsbcoind https://raw.githubusercontent.com/wsbcoin-project/mining-pool-setup/master/wsbcoind
curl -o wsbcoin/wsbcoin-cli https://raw.githubusercontent.com/wsbcoin-project/mining-pool-setup/master/wsbcoin-cli
chmod 755 wsbcoin/*
./wsbcoind
```


License
-------

YYCcoin Core is released under the terms of the MIT license. See [COPYING](COPYING) for more
information or see https://opensource.org/licenses/MIT.

Development Process
-------------------

The `master` branch is regularly built and tested, but is not guaranteed to be
completely stable. [Tags](https://github.com/yoloyachtclub/YoloYachtCoin/tags) are created
regularly to indicate new official, stable release versions of YYCcoin Core.

The contribution workflow is described in [CONTRIBUTING.md](CONTRIBUTING.md).

Testing
-------

Testing and code review is the bottleneck for development; we get more pull
requests than we can review and test on short notice. Please be patient and help out by testing
other people's pull requests, and remember this is a security-critical project where any mistake might cost people
lots of money.
