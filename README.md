# Hook Script for dehydrated with dns.he.net

This is a bash script to help generate certificates with Let's Encrypt using the dns_01 method. It is a hook script to be called from [dehydrated](https://github.com/dehydrated-io/dehydrated). It is specialized for the free DNS service offered by Hurricane Electric at [dns.he.net](dns.he.net) and not directly useful with any other DNS server. It has been created in an IPv6 context where the entire lan can have global addresses.

The script utilises the option to enable Dynamic DNS for TXT records in a zone served by dns.he.net. Any such dynamic record has it's very own key to authenticate updates. So you don't have to open your credentials (and thus complete control over your domains) to a script running as root just to enable the issue of certificates. 

### Preparation

In order to dynamically update txt records they have to be there in the first place. You need to do this manually, open the managment page at dns.he.net for your domain in the browser, click New TXT and fill out the fields. Assuming you would want to create certificates for octoprint.example.com then the TXT should be for 
``_acme-challenge.octoprint.example.com``. Select **300** for TTL and check the box at the bottom, **Enable entry for dynamic dns**. There is a circle-of-arrows icon at the right side of the row with the dynamic record, click on it to generate or enter your update keys. This is the password needed by the script.

If you like to update that record's content manually, 
```
curl -k https://dyn.dns.he.net/nic/update -d "hostname=_acme-challenge.octoprint.example.com" -d "password=superSecret16Bit" -d "txt=acme-challenge-here" 
``` 
does the trick. It responds with **good**, **nochg** or **badauth**. In the latter case, something with the password is not right. 
You can check the record's content with 
```
host -t txt _acme-challenge.octoprint.example.com
```
These two lines are the core of this script.

### Installation

It is assumed that you already installed [dehydrated](https://github.com/dehydrated-io/dehydrated), if not: it's easy, clone or download the script to a place like /usr/local/bin/dehydrated and make it executable, create /etc/dehydrated for the config and edit the config. Comprehensive docu is at their site. On debian you can just ``sudo apt-get install dehydrated`` and then maybe adapt some of the configured pathes. 

Clone or download **this script** to a place of your liking, next to dehydrated under /usr/local/bin or under /var/lib/dehydrated/hook if you chose to install the debian package. I suggest to copy the entire ``hook/`` directory which contains the hook.sh and another folder with tiny drop-in scripts. More about that below. Any ways, you have to tell dehydrated where it resides.

### Config

There are 2 settings in dehydrated/config that this script needs to run successfully:
```
CHALLENGETYPE="dns-01" 
HOOK=path/to/hook.sh
```
The hook.sh itself has few settings at the top of the file that need inspection and probably editing:
```
domain_passwords="/etc/dehydrated/domain_passwords.txt"
certs_path="/etc/dehydrated/certs"
scriptlets_dir="/path/to/hook/scriptlets"
 
```
Among these, the most important is ``domain_passwords``. This file needs to be created during setup, best next to dehydrateted's ``domain.txt`` as it corresponds to that's content and format. 
Each row describes one domain that will get a certificate, and there are 2 columns, domain name and the update key. 
Please note: if you have altnames in your cert, i.e. "example com www.example.com octoprint.example.com" in your domains.txt then you'll need to create a \_acme-challenge txt record for every single subdomain and domain_passwords.txt will need a row for each of them.


### hooks

dehydrated calls the hook.sh (with different parameters), on: 
- startup_hook
- deploy_challenge
- clean_challenge
- deploy_cert
- exit_hook

Of these, *deploy_challenge* and *clean_challenge* are actually handled by the hook.sh itself. On *deploy_challenge* a call like shown above is assembled and given, followed by a waiting loop until the change registers. On *clean_challenge* a similar call updates the record to something unspecific. 
For *startup, exit* and *deploy_cert* scripts in the scriptlet_dir are called. There is a naming convention that only scripts with a filename starting with startup will get called at the startup event and similar for deploy_cert and exit. That is not really necessary as those scripts can easily decide on their own if the parameters fit for getting active, but it helps for clarity. 
The idea is to have a drop-in activation for different consumers. A scriptlet for haproxy, another for the webserver or webmin or ...


### Failures
The most likely are problems with the update key aka password. Sometimes the dynamic update simply will not work with those keys autogenerated on the he.net page and only worked with keys pasted there. It is recommended to test the mechanics manually from the command line with calls analog the ones given above. If it does not do there the script has no chance.
Another thing is the minimum **TimeToLive** for a dns record, which is 300 seconds. In other words, there may be up to 5 minutes wait until the update to a challenge is visible. The script will be rather noisy about the wait, putting out a line every second.  This is not a failure but may look like it was one. 


### Scriptlets
This could become a collection of mini-slutions and I don't even have to delete the ones not needed or wanted on a particular box - just leave them on example.com and they are present but inactive. Right now there are only 2, octoprint/haproxy the one that actually got me started on this and openhab2 was fast to write once I had figured out how to avoid interactive password dialogs with openssl and keytool 
