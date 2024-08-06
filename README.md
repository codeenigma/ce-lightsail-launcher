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
* For now this is only tested on Debian Linux
* You will need your own AWS account
* Make sure you have [added a key pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html)

### Steps
1. Login to your AWS account
2. [Open Lightsail](https://lightsail.aws.amazon.com/ls/webapp/home/instances)
3. Click 'Create Instance'
4. Select 'Linux/Unix'
5. Select 'OS Only'
6. Select one of the 'Debian' images (any should work)
7. Click 'Add Launch Script'
8. Open [`launcher.sh`](https://github.com/codeenigma/ce-lightsail-launcher/blob/main/launcher.sh) in a new window
9. Copy it to your clipboard using the 'copy raw contents' button in the top right
10. Close it so you go back to Lightsail and paste into the 'Add Launch Script' text box
11. Make sure the correct SSH key is selected (you can create one inline if needed, but make sure you download the private part)
12. Choose an instance plan (you can use the $12 free for 3 months plan but the installation will be a little slow)
13. Click the 'Create instance' button

Now you will need to be patient, especially if you selected the $12 plan, because the demo content generation takes about an hour to complete on smaller plans. Once the demo content generation is completed you will find LocalGov Drupal runs just fine. Set up is obviously quicker with a $24 instance plan or higher, but is no longer free tier.

### Troubleshooting
If the launch script does not work correctly, you should be able to go to your [Lightsail instances page](https://lightsail.aws.amazon.com/ls/webapp/home/instances) and click the little Terminal icon against the server you want to use. This will open an SSH terminal as the admin user. Run these commands to execute the same launcher script as root on the server:

```sh
# Switch to the root user
sudo su
# Download the launcher script
wget -O /root/launcher.sh https://github.com/codeenigma/ce-lightsail-launcher/blob/main/launcher.sh
# Make the launcher script executable
chmod +x /root/launcher.sh
# Execute the launcher script
/root/launcher.sh
```

This typically takes around 10 minutes to run.

#### `gawkpath_default` error
Due to an issue with the way Debian is provided in Lightsail (as far as we can tell) sometimes the `/etc/profile.d/gawk.csh` script causes `ce-deploy` to fail to run. If you see the `alias: gawkpath_default not found` error then you can move that file out of the way and try again with this command:

```sh
mv /etc/profile.d/gawk.csh /root/
```

### Launching LocalGov Drupal
Once you have waited a while you can go to your Lightsail Instances page and click on your instance. Under 'Metrics' you should be able to see if your instance is running hot or not. If the metrics show CPU has settled down to a low number, you can be sure the installer is done. To launch LocalGov Drupal:

1. Go to 'Networking'
2. Copy the 'Public IP'
3. Go to the HTTP address with that IP, e.g. if the 'Public IP' is 3.2.3.2 then visit http://3.2.3.2 in your browser

You should be presented with LocalGov Drupal.

For HTTPS you will need to go to your server in Lightsail and select the 'Networking' tab. Under 'IPv4 Firewall' you will need to click 'Add rule' and under 'Application' pick 'HTTPS' then click 'Create'.

### Logging in
You will not initially know your LGD root password. To set it to a value you know connect to your instance by clicking the 'Connect using SSH' button. This will open in a new window. Run these commands:

```bash
cd /home/ce-dev/deploy/live.local/web/sites/default/
../../../vendor/drush/drush/drush uli
```

It will give you a URL that looks something like this:
* http://default/user/reset/1/1663176889/e2t6sE2VaougAwPwOl_h7N1OK-lyN8J9QtNU8ZDFoIc/login

Replace `default` with your 'Public IP' and you will be logged in so you can set the password and create other users/manage the site.

If you create other users and need to send them password reset links, the command would look like this for the username `greg`:

```bash
cd /home/ce-dev/deploy/live.local/web/sites/default/
../../../vendor/drush/drush/drush uli --name greg
```

## Roadmap
This is an initial release which fires up LGD on a single instance. Lightsail and the tools being used allow for more flexibility, so we would like to add some of the following features in the coming months:

* Optionally make proper of Lightsail databases
* Ensure Ubuntu support
* Allow for different Drupal distributions
* Trigger the launcher from the Lightsail API
* Provide a web UI for launching different distributions
