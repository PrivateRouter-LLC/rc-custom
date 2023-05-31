# PrivateRouter rc.custom Update Repository

This repo holds the scripts that are ran on the boot of the router.

Each router checks if it has a copy of this repo installed or if there is an updated copy.

The variable REPO is set inside `/root/.profile` on the router. As a backup this code is used inside `/etc/rc.custom` to make sure we have one set.
```
# If nothing is set for REPO we set it to main
if [ -z "${REPO}" ]; then
    REPO="main"
fi
```

The router runs those code inside `/etc/rc.custom` to check the current hash of the repo.
```
CURRENT_HASH=$(
    curl \
        --silent https://api.github.com/repos/PrivateRouter-LLC/rc-custom/commits/${REPO} |
        jq --raw-output '.sha'
)
```

Once this repo is pulled, the file `update.sh` is executed which decides which script to run based on the router's model number.

There are generally two branches to this repo, `main` and `testing`. `main` is used in production and `testing` is used for development.