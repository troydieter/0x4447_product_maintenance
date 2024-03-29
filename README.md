# 🧢 Maintenance

This stack will deploy a t3.nano EC2 instance running Amazon Linux 2 with auto shutdown - useful for maintenance work in AWS.

On a regular basis we have to do maintenance work for AWS clients accounts, for example:

- Do DB migrations.
- Move objects form one S3 Bucket to another.
- Check different volumes types.
- Access private networks.
- Ping resources to see if they are reachable.
- etc.

We got tired of creating an instance, waiting for it to boot, installing some default tools, and then remember to either shut it down, or terminate it.

This stack solves this problem by making a EC2 Instance, installing all the tools that we need at boot time, and then automatically shut down after 30 minutes by detecting if the SSH session is inactive. This way we don't have worry that our clients will be charged for an unused resource.

The auto shout down works thanks to a custom Bash script which checks the ec2-user session every 15 sec, and when it detects inactivity it will set a `shutdown` of 30 min in the future. Depending on the terminal app that you are using, you should get a Ring Bell letting you know you have 30 min left before the instance will be stoped. Giving you a chance to hit enter in the terminal to silently remove the `shutdown`. You can check the `/var/log/messages` to see what is exactly happening.

# Additional Software

The EC2 Instance will get the following extra software:

- Postgres
- MariaDB
- Nmap
- MC
- Nano
- Git
- Vim

# Make it your own

This stack is straight forward to clone and edit the CloudFormation file to modify to your needs. The EC2 configuration can be found [here](https://github.com/0x4447/0x4447_product_maintenance/tree/bash_script). You can edit either the `UserData` or `Cloud-Init` to install extra things that you need for your work.

# DISCLAIMER!

This stack is available to anyone at no cost, but on an as-is basis. 0x4447, LLC is not responsible for damages or costs of any kind that may occur when you use the stack. You take full responsibility when you use it.

# Deploy

### CloudFormation

<a target="_blank" href="https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=zer0x4447-Maintenance&templateURL=https://s3.amazonaws.com/0x4447-drive-cloudformation/maintenance.json">
<img align="left" style="float: left; margin: 0 10px 0 0;" src="https://s3.amazonaws.com/cloudformation-examples/cloudformation-launch-stack.png"></a>

To deploy this stack, all you need to do is click the button to the left and follow the instructions that CloudFormation provides in your AWS Dashboard. Alternatively, you can download the CF file from [here](https://s3.amazonaws.com/0x4447-drive-cloudformation/maintenance.json).

#### What Will Deploy?

![Maintenance Diagram](https://raw.githubusercontent.com/0x4447/0x4447_product_maintenance/assets/diagram.png)

The stack takes advantage of just EC2, and other minor services.

- 1x EC2 Instance with auto shut down.
- 1x Security group.
- 1x Instance Profile.
- 1x Role.
- 1x Policy.

# Pricing

Standard t3.nano On-Demand pricing applies when the instance is ON.

# How to work with this project

When you want to deploy the stack, the only file you should be interested in is the `CloudFormation.json` file. If you'd like to modify the stack, we recommend that you use the [Grapes framework](https://github.com/0x4447/0x4447-cli-node-grapes), which was designed to make it easier to work with the CloudFormation file. If you'd like to keep your sanity, never edit the main CF file 🤪.

# The End

If you enjoyed this project, please consider giving it a 🌟. And check out our [0x4447 GitHub account](https://github.com/0x4447), where you'll find additional resources you might find useful or interesting.

## Sponsor 🎊

This project is brought to you by 0x4447 LLC, a software company specializing in building custom solutions on top of AWS. Follow this link to learn more: https://0x4447.com. Alternatively, send an email to [hello@0x4447.email](mailto:hello@0x4447.email?Subject=Hello%20From%20Repo&Body=Hi%2C%0A%0AMy%20name%20is%20NAME%2C%20and%20I%27d%20like%20to%20get%20in%20touch%20with%20someone%20at%200x4447.%0A%0AI%27d%20like%20to%20discuss%20the%20following%20topics%3A%0A%0A-%20LIST_OF_TOPICS_TO_DISCUSS%0A%0ASome%20useful%20information%3A%0A%0A-%20My%20full%20name%20is%3A%20FIRST_NAME%20LAST_NAME%0A-%20My%20time%20zone%20is%3A%20TIME_ZONE%0A-%20My%20working%20hours%20are%20from%3A%20TIME%20till%20TIME%0A-%20My%20company%20name%20is%3A%20COMPANY%20NAME%0A-%20My%20company%20website%20is%3A%20https%3A%2F%2F%0A%0ABest%20regards.).

