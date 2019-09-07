# idle_shutdown_aws

## Overview

This will do the following:

1. Detect idle SSH sessions.
2. If Idle session detected, then it's set a system shutdown of 30 min.
3. If a ssh session is not idle anymore, remove the system shutdown.
4. Keep checking for idle sessions every 15 sec.

## Encode script to base64

This command will convert the content of the Bash script in to base64 with no column formating. To be used in the CloudFormation file.

```
] cat idle_shutdown_aws.sh | base64 -w 0
```

## Requirements

The script must have access to /etc/sudoers the first time it runs, to do the correct changes.

## Running this script

1. It can be run via interactive session like so:

```
] bash /path/to/idle_shutdown_aws.sh >> /home/ec2-user/idle_shutdown.log &
```

2. It can be configured as a crontab job:

```
* * * * * /path/to/idle_shutdown_aws.sh >> /home/ec2-user/idle_shutdown.log
```

3. Or it can be configured as a systemd service:

```
] touch /etc/systemd/system/idle_shutdown_aws.service
```

Then paste the following in the `idle_shutdown_aws.service` file:

```
[Unit]
Description=Idle Instance Detection
Documentation=https://0x4447.com
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/home/ec2-user/idle_shutdown_aws.sh
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=idle_shutdown_aws
Restart=on-failure
RestartSec=3
KillMode=process
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
```


