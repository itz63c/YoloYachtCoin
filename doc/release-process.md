Release Process
====================

Before every release candidate:

* Update translations (ping wumpus on IRC) see [translation_process.md](https://github.com/bitcoin/bitcoin/blob/master/doc/translation_process.md#synchronising-translations).

* Update manpages, see [gen-manpages.sh](https://github.com/yyccoin-project/yyccoin/blob/master/contrib/devtools/README.md#gen-manpagessh).

Before every minor and major release:

* Update [bips.md](bips.md) to account for changes since the last release.
* Update version in `configure.ac` (don't forget to set `CLIENT_VERSION_IS_RELEASE` to `true`)
* Write release notes (see below)
* Update `src/chainparams.cpp` nMinimumChainWork with information from the getblockchaininfo rpc.
* Update `src/chainparams.cpp` defaultAssumeValid  with information from the getblockhash rpc.
  - The selected value must not be orphaned so it may be useful to set the value two blocks back from the tip.
  - Testnet should be set some tens of thousands back from the tip due to reorgs there.
  - This update should be reviewed with a reindex-chainstate with assumevalid=0 to catch any defect
     that causes rejection of blocks in the past history.

Before every major release:

* Update hardcoded [seeds](/contrib/seeds/README.md), see [this pull request](https://github.com/bitcoin/bitcoin/pull/7415) for an example.
* Update [`BLOCK_CHAIN_SIZE`](/src/qt/intro.cpp) to the current size plus some overhead.
* Update `src/chainparams.cpp` chainTxData with statistics about the transaction count and rate.
* Update version of `contrib/gitian-descriptors/*.yml`: usually one'd want to do this on master after branching off the release - but be sure to at least do it before a new major release

### First time / New builders

If you're using the automated script (found in [contrib/gitian-build.sh](/contrib/gitian-build.sh)), then at this point you should run it with the "--setup" command. Otherwise ignore this.

Check out the source code in the following directory hierarchy.

    cd /path/to/your/toplevel/build
    git clone https://github.com/yyccoin-project/gitian.sigs.ltc.git
    git clone https://github.com/yyccoin-project/yyccoin-detached-sigs.git
    git clone https://github.com/devrandom/gitian-builder.git
    git clone https://github.com/yyccoin-project/yyccoin.git

### YYCcoin maintainers/release engineers, suggestion for writing release notes

Write release notes. git shortlog helps a lot, for example:

    git shortlog --no-merges v(current version, e.g. 0.7.2)..v(new version, e.g. 0.8.0)

(or ping @wumpus on IRC, he has specific tooling to generate the list of merged pulls
and sort them into categories based on labels)

Generate list of authors:

    git log --format='%aN' "$*" | sort -ui | sed -e 's/^/- /'

Tag version (or release candidate) in git

    git tag -s v(new version, e.g. 0.8.0)

### Setup and perform Gitian builds

If you're using the automated script (found in [contrib/gitian-build.sh](/contrib/gitian-build.sh)), then at this point you should run it with the "--build" command. Otherwise ignore this.

Setup Gitian descriptors:

    pushd ./yyccoin
    export SIGNER=(your Gitian key, ie bluematt, sipa, etc)
    export VERSION=(new version, e.g. 0.8.0)
    git fetch
    git checkout v${VERSION}
    popd

Ensure your gitian.sigs.ltc are up-to-date if you wish to gverify your builds against other Gitian signatures.

    pushd ./gitian.sigs.ltc
    git pull
    popd

Ensure gitian-builder is up-to-date:

    pushd ./gitian-builder
    git pull
    popd

### Fetch and create inputs: (first time, or when dependency versions change)

    pushd ./gitian-builder
    mkdir -p inputs
    wget -P inputs https://bitcoincore.org/cfields/osslsigncode-Backports-to-1.7.1.patch
    wget -P inputs http://downloads.sourceforge.net/project/osslsigncode/osslsigncode/osslsigncode-1.7.1.tar.gz
    popd

Create the OS X SDK tarball, see the [OS X readme](README_osx.md) for details, and copy it into the inputs directory.

### Optional: Seed the Gitian sources cache and offline git repositories

By default, Gitian will fetch source files as needed. To cache them ahead of time:

    pushd ./gitian-builder
    make -C ../yyccoin/depends download SOURCES_PATH=`pwd`/cache/common
    popd

Only missing files will be fetched, so this is safe to re-run for each build.

NOTE: Offline builds must use the --url flag to ensure Gitian fetches only from local URLs. For example:

    pushd ./gitian-builder
    ./bin/gbuild --url yyccoin=/path/to/yyccoin,signature=/path/to/sigs {rest of arguments}
    popd

The gbuild invocations below <b>DO NOT DO THIS</b> by default.

### Build and sign YYCcoin Core for Linux, Windows, and OS X:

    pushd ./gitian-builder
    ./bin/gbuild --num-make 2 --memory 3000 --commit yyccoin=v${VERSION} ../yyccoin/contrib/gitian-descriptors/gitian-linux.yml
    ./bin/gsign --signer $SIGNER --release ${VERSION}-linux --destination ../gitian.sigs.ltc/ ../yyccoin/contrib/gitian-descriptors/gitian-linux.yml
    mv build/out/yyccoin-*.tar.gz build/out/src/yyccoin-*.tar.gz ../

    ./bin/gbuild --num-make 2 --memory 3000 --commit yyccoin=v${VERSION} ../yyccoin/contrib/gitian-descriptors/gitian-win.yml
    ./bin/gsign --signer $SIGNER --release ${VERSION}-win-unsigned --destination ../gitian.sigs.ltc/ ../yyccoin/contrib/gitian-descriptors/gitian-win.yml
    mv build/out/yyccoin-*-win-unsigned.tar.gz inputs/yyccoin-win-unsigned.tar.gz
    mv build/out/yyccoin-*.zip build/out/yyccoin-*.exe ../

    ./bin/gbuild --num-make 2 --memory 3000 --commit yyccoin=v${VERSION} ../yyccoin/contrib/gitian-descriptors/gitian-osx.yml
    ./bin/gsign --signer $SIGNER --release ${VERSION}-osx-unsigned --destination ../gitian.sigs.ltc/ ../yyccoin/contrib/gitian-descriptors/gitian-osx.yml
    mv build/out/yyccoin-*-osx-unsigned.tar.gz inputs/yyccoin-osx-unsigned.tar.gz
    mv build/out/yyccoin-*.tar.gz build/out/yyccoin-*.dmg ../
    popd

Build output expected:

  1. source tarball (`yyccoin-${VERSION}.tar.gz`)
  2. linux 32-bit and 64-bit dist tarballs (`yyccoin-${VERSION}-linux[32|64].tar.gz`)
  3. windows 32-bit and 64-bit unsigned installers and dist zips (`yyccoin-${VERSION}-win[32|64]-setup-unsigned.exe`, `yyccoin-${VERSION}-win[32|64].zip`)
  4. OS X unsigned installer and dist tarball (`yyccoin-${VERSION}-osx-unsigned.dmg`, `yyccoin-${VERSION}-osx64.tar.gz`)
  5. Gitian signatures (in `gitian.sigs.ltc/${VERSION}-<linux|{win,osx}-unsigned>/(your Gitian key)/`)

### Verify other gitian builders signatures to your own. (Optional)

Add other gitian builders keys to your gpg keyring, and/or refresh keys.

    gpg --import yyccoin/contrib/gitian-keys/*.pgp
    gpg --refresh-keys

Verify the signatures

    pushd ./gitian-builder
    ./bin/gverify -v -d ../gitian.sigs.ltc/ -r ${VERSION}-linux ../yyccoin/contrib/gitian-descriptors/gitian-linux.yml
    ./bin/gverify -v -d ../gitian.sigs.ltc/ -r ${VERSION}-win-unsigned ../yyccoin/contrib/gitian-descriptors/gitian-win.yml
    ./bin/gverify -v -d ../gitian.sigs.ltc/ -r ${VERSION}-osx-unsigned ../yyccoin/contrib/gitian-descriptors/gitian-osx.yml
    popd

### Next steps:

Commit your signature to gitian.sigs.ltc:

    pushd gitian.sigs.ltc
    git add ${VERSION}-linux/${SIGNER}
    git add ${VERSION}-win-unsigned/${SIGNER}
    git add ${VERSION}-osx-unsigned/${SIGNER}
    git commit -a
    git push  # Assuming you can push to the gitian.sigs.ltc tree
    popd

Codesigner only: Create Windows/OS X detached signatures:
- Only one person handles codesigning. Everyone else should skip to the next step.
- Only once the Windows/OS X builds each have 3 matching signatures may they be signed with their respective release keys.

Codesigner only: Sign the osx binary:

    transfer yyccoin-osx-unsigned.tar.gz to osx for signing
    tar xf yyccoin-osx-unsigned.tar.gz
    ./detached-sig-create.sh -s "Key ID"
    Enter the keychain password and authorize the signature
    Move signature-osx.tar.gz back to the gitian host

Codesigner only: Sign the windows binaries:

    tar xf yyccoin-win-unsigned.tar.gz
    ./detached-sig-create.sh -key /path/to/codesign.key
    Enter the passphrase for the key when prompted
    signature-win.tar.gz will be created

Codesigner only: Commit the detached codesign payloads:

    cd ~/yyccoin-detached-sigs
    checkout the appropriate branch for this release series
    rm -rf *
    tar xf signature-osx.tar.gz
    tar xf signature-win.tar.gz
    git add -a
    git commit -m "point to ${VERSION}"
    git tag -s v${VERSION} HEAD
    git push the current branch and new tag

Non-codesigners: wait for Windows/OS X detached signatures:

- Once the Windows/OS X builds each have 3 matching signatures, they will be signed with their respective release keys.
- Detached signatures will then be committed to the [yyccoin-detached-sigs](https://github.com/yyccoin-project/yyccoin-detached-sigs) repository, which can be combined with the unsigned apps to create signed binaries.

Create (and optionally verify) the signed OS X binary:

    pushd ./gitian-builder
    ./bin/gbuild -i --commit signature=v${VERSION} ../yyccoin/contrib/gitian-descriptors/gitian-osx-signer.yml
    ./bin/gsign --signer $SIGNER --release ${VERSION}-osx-signed --destination ../gitian.sigs.ltc/ ../yyccoin/contrib/gitian-descriptors/gitian-osx-signer.yml
    ./bin/gverify -v -d ../gitian.sigs.ltc/ -r ${VERSION}-osx-signed ../yyccoin/contrib/gitian-descriptors/gitian-osx-signer.yml
    mv build/out/yyccoin-osx-signed.dmg ../yyccoin-${VERSION}-osx.dmg
    popd

Create (and optionally verify) the signed Windows binaries:

    pushd ./gitian-builder
    ./bin/gbuild -i --commit signature=v${VERSION} ../yyccoin/contrib/gitian-descriptors/gitian-win-signer.yml
    ./bin/gsign --signer $SIGNER --release ${VERSION}-win-signed --destination ../gitian.sigs.ltc/ ../yyccoin/contrib/gitian-descriptors/gitian-win-signer.yml
    ./bin/gverify -v -d ../gitian.sigs.ltc/ -r ${VERSION}-win-signed ../yyccoin/contrib/gitian-descriptors/gitian-win-signer.yml
    mv build/out/yyccoin-*win64-setup.exe ../yyccoin-${VERSION}-win64-setup.exe
    mv build/out/yyccoin-*win32-setup.exe ../yyccoin-${VERSION}-win32-setup.exe
    popd

Commit your signature for the signed OS X/Windows binaries:

    pushd gitian.sigs.ltc
    git add ${VERSION}-osx-signed/${SIGNER}
    git add ${VERSION}-win-signed/${SIGNER}
    git commit -a
    git push  # Assuming you can push to the gitian.sigs.ltc tree
    popd

### After 3 or more people have gitian-built and their results match:

- Create `SHA256SUMS.asc` for the builds, and GPG-sign it:

```bash
sha256sum * > SHA256SUMS
```

The list of files should be:
```
yyccoin-${VERSION}-aarch64-linux-gnu.tar.gz
yyccoin-${VERSION}-arm-linux-gnueabihf.tar.gz
yyccoin-${VERSION}-i686-pc-linux-gnu.tar.gz
yyccoin-${VERSION}-x86_64-linux-gnu.tar.gz
yyccoin-${VERSION}-osx64.tar.gz
yyccoin-${VERSION}-osx.dmg
yyccoin-${VERSION}.tar.gz
yyccoin-${VERSION}-win32-setup.exe
yyccoin-${VERSION}-win32.zip
yyccoin-${VERSION}-win64-setup.exe
yyccoin-${VERSION}-win64.zip
```
The `*-debug*` files generated by the gitian build contain debug symbols
for troubleshooting by developers. It is assumed that anyone that is interested
in debugging can run gitian to generate the files for themselves. To avoid
end-user confusion about which file to pick, as well as save storage
space *do not upload these to the yyccoin.cloud server, nor put them in the torrent*.

- GPG-sign it, delete the unsigned file:
```
gpg --digest-algo sha256 --clearsign SHA256SUMS # outputs SHA256SUMS.asc
rm SHA256SUMS
```
(the digest algorithm is forced to sha256 to avoid confusion of the `Hash:` header that GPG adds with the SHA256 used for the files)
Note: check that SHA256SUMS itself doesn't end up in SHA256SUMS, which is a spurious/nonsensical entry.

- Upload zips and installers, as well as `SHA256SUMS.asc` from last step, to the yyccoin.cloud server.

```

- Update yyccoin.cloud version

- Announce the release:

  - yyccoin-dev and yyccoin-dev mailing list

  - blog.yyccoin.cloud blog post

  - Update title of #yyccoin and #yyccoin-dev on Freenode IRC

  - Optionally twitter, reddit /r/YYCcoin, ... but this will usually sort out itself

  - Archive release notes for the new version to `doc/release-notes/` (branch `master` and branch of the release)

  - Create a [new GitHub release](https://github.com/yyccoin-project/yyccoin/releases/new) with a link to the archived release notes.

  - Celebrate
