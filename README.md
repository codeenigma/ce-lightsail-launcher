# ce-lightsail-launcher
Experimental project to launch Drupal in an AWS Lightsail VM using cloud-init.

## Background
[Code Enigma](https://www.codeenigma.com) have been working with [LocalGov Drupal](https://localgovdrupal.org/) and [AWS](https://aws.amazon.com/) to try and create the easiest and cheapest route possible for someone with no real experience of Drupal and no spare servers to set up and test LocalGov Drupal in an environment they can share with others. [AWS Lightsail](https://aws.amazon.com/lightsail/) was identified as a good entrypoint because it offers 3 months free on the smaller instances, has a simple interface and is specifically designed to allow for application testing.

## How it works
One of the advantages of Lightsail is the ability to provide a launch script. Being a [Drupal](https://www.drupal.org/) specialist support company, we already have extensive tooling for deploying Drupal and it's dependencies to Debian-based servers, written predominantly in Ansible. See:
* https://github.com/codeenigma/ce-dev (local developer tools)
* https://github.com/codeenigma/ce-deploy (code deployment scripts)
* https://github.com/codeenigma/ce-provision (server software management)

This project uses these existing tools within a [cloud-init](https://cloudinit.readthedocs.io/) launch script, which you can copy and paste into the Lightsail control panel, to launch LocalGov Drupal on it's own Lightsail server.

## Quickstart

### Prerequisites
* It's going to be helpful to know a little bit about Linux terminal and bash
* For now this is only tested on Debian and, in this early stage, we recommend you use Debian 10
* You will need your own AWS account
* Make sure you have [added a key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)

### Steps
1. Login to your AWS account
2. Make sure you have an SSH key set up in AWS EC2
2. [Open Lightsail](https://lightsail.aws.amazon.com/ls/webapp/home/instances)
3. Click 'Create Instance'
4. Select 'Linux/Unix'
5. Select 'OS Only'
6. (recommended) Select 'Debian 10.8'
7. Click 'Add Launch Script'
8. Open [launch.sh](https://github.com/codeenigma/ce-lightsail-launcher/blob/main/launcher.sh) in a new window
9. Copy it to your clipboard using the 'copy raw contents' button in the top right
10. Close it so you go back to Lightsail and paste into the 'Add Launch Script' text box
11. Make sure the correct SSH key is selected
12. Choose an instance plan (you can use the $10 free for 3 months plan but it is a bit slow)
13. Click the 'Create instance' button

Now you will need to be patient, especially if you selected the $10 plan, because the installer can be quite slow (over an hour for smaller plans, more like 10 minutes for larger plans). It's obviously quicker with a $20 instance plan or higher, but is no longer free tier.

Once you have waited a while you can go to your Lightsail Instances page and click on your instance. Under 'Metrics' you should be able to see if your instance is running hot or not. If the metrics show CPU has settled down to a low number, you can be sure the installer is done. To launch LocalGov Drupal:

1. Go to 'Networking'
2. Copy the 'Public IP'
3. Go to the HTTP address with that IP, e.g. if the 'Public IP' is 3.2.3.2 then visit http://3.2.3.2 in your browser

You should be presented with LocalGov Drupal.

### Logging in
You will not initially know your LGD root password. To set it to a value you know connect to your instance by clicking the 'Connect using SSH' button. This will open in a new window. Run these commands:

```bash
cd /home/ce-dev/deploy/live.local/web/sites/default/
../../../vendor/drush/drush/drush uli
```

It will give you a URL that looks something like this:
* http://default/user/reset/1/1663176889/e2t6sE2VaougAwPwOl_h7N1OK-lyN8J9QtNU8ZDFoIc/login

Replace `default` with your 'Public IP' and you will be logged in so you can set the password and create other users/manage the site.

## Roadmap
This is an initial release which fires up LGD on a single instance. Lightsail and the tools being used allow for more flexibility, so we would like to add some of the following features in the coming months:

* Optionally make proper of Lightsail databases
* Ensure Debian 11 and Ubuntu support
* Allow for different Drupal distributions
* Trigger the launcher from the Lightsail API
* Provide a web UI for launching different distributions
