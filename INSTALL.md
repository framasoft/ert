# EthercalcRevisionTool installation

## Ethercalc prerequisites

Go to you Ethercalc directory, then:

```
cd misc
wget https://raw.githubusercontent.com/audreyt/ethercalc/master/misc/archive.ls -O archive.ls
```

(we need an up-to-date `archive.ls` file)

With this file, we can export revisions of all calcs in `static/history` directory of the Ethercalc directory.

**Hint**: for the rest of this section, we'll suppose that you are in the `misc` directory of your Ethercalc installation directory.

For this, we'll need `LiveScript` to be installed on your system:

```
npm install -g LiveScript
```

Then, we can export the calcs:

```
PUT_IN_HISTORY=1 ./archive.ls
```

If you don't use the default database in Redis (let's say you use the database `1` instead of the default `0`):

```
REDIS_DB=1 PUT_IN_HISTORY=1 ./archive.ls
```

Put this command in the crontab of your ethercalc's user:

```
crontab -e -u ethercalc
```

Add (this is an example, adjust to your installation and needs):

```
*/10 * * * * cd /opt/ethercalc/node_modules/ethercalc/misc && REDIS_DB=1 PUT_IN_HISTORY=1 ./archive.ls > /dev/null
```

This will dump calcs revisions every ten minutes (only if the calc has changed since the last dumped revision).

**Warning**: If you tested the export while being `root`, you'll need to change the permissions to allow the ethercalc's user to use that directory to export to it.

```
chown ethercalc: -R ../static/history
```

## Prerequisites

First, install some packages from your distribution, in order to be able to install dependencies:

```
apt-get install build-essential libssl-dev
```

Then, install `Carton`, which is a Perl application that will handle dependencies for you:

```
cpan Carton
```

## Get EthercalcRevisionTool

```
git clone https://git.framasoft.org/framasoft/ert.git
```

## Install dependencies

```
cd ert
carton install
```

## Configuration

```
cp ethercalc_revision_tool.conf.template ethercalc_revision_tool.conf
vim ethercalc_revision_tool.conf
```

The configuration template contains explanations about the options.

The only two mandatory settings are `rev_dir` and `ethercalc_url`. EthercalcRevisionTool won't start if you don't set it!

## Init files

### InitV

```
cp utilities/ethercalc_revision_tool.init /etc/init.d/ethercalc_revision_tool
cp utilities/ethercalc_revision_tool.default /etc/default/ethercalc_revision_tool
chown root:root /etc/init.d/ethercalc_revision_tool /etc/default/ethercalc_revision_tool
vim /etc/default/ethercalc_revision_tool
```

You need to change `EDIR` and USER in `/etc/default/ethercalc_revision_tool` to fit your installation. Then:

```
/etc/init.d/ethercalc_revision_tool start
```

### Systemd

```
cp utilities/ethercalc_revision_tool.service /etc/systemd/system/
vim /etc/systemd/system/ethercalc_revision_tool.service
```

You need to change `User`, `WorkingDirectory` and `PIDFile` in `/etc/systemd/system/ethercalc_revision_tool.service` to fit your installation. Then:

```
systemctl daemon-reload
systemctl start ethercalc_revision_tool.service
```

### Upstart

```
cp utilities/ethercalc_revision_tool_upstart.conf /etc/init/ethercalc_revision_tool.conf
cp utilities/ethercalc_revision_tool.default /etc/default/ethercalc_revision_tool
vim /etc/default/ethercalc_revision_tool
```

You need to change `EDIR` and `USER` in `/etc/default/ethercalc_revision_tool` to fit your installation. Then:

```
start ethercalc_revision_tool
```
