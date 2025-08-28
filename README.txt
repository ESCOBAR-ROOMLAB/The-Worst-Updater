Good morning ladies and gentleman. I just wanted to share a little script that I use to update many devices running Cisco IOS XE at the same time, as well as to push configurations to all devices at once, so maybe someone can find it useful. My peers used it to update 12 switches in less than 10 minutes, so we didn't have to waste the whole morning with updates. Is a free tool that can be used in situations where is not possible to deploy a network controller.

The script is written in Bash since I made it when I was studying for the Linux+ exam, and it runs on any MCEN asset that has Git installed in it (Git can be found at Software Center, and it takes 1 minute to download). Just open a Git Bash, clone the remote repository, and then navigate to the script directory and make the script file executable. Lastly, have fun!


INSTRUCTIONS and NOTES
----------------------

1. Download Git from Software Center:
- Type "Software Center" on the "Search" bar on the bottom of the screen and press "Enter"
- Type "Git" on the search bar and press "Enter"
- Click on the icon that says "Git ..." (is a square with colors red,yellow,green and blue) and then click "Install"
- Give it 1 minute at least


2. Open a Git Bash shell
- Type "Git Bash" on the bottom search bar of your screen and press "Enter"


3. Clone the remote repository that contains the script and other needed files
- Type the following commands (or just copy and paste them)

git clone https://github.com/ESCOBAR-ROOMLAB/The-Worst-Updater
chmod +x The_Worst_Updater.sh




***BEFORE RUNNING THE SCRIPT***


4. All the devices you wish to work on should be reachable from your MCEN laptop. The script uses SSH to push configurations and SCP for file transfers.


5. Configure SSH with public key authentication on all your network devices. Make sure you have generated an SSH RSA keypair with the following parameters:

ssh-keygen -t rsa -b 2048

The reason why the script does not do this for you is because you may already have your keypair created and you wish to use it for the script actions.

The repository contains a file named "Device_configs", with configurations that you can use for all your devices (just make sure you define the variables properly, specially your username and your public key formatted for Cisco Devices). If you already have your MGMT VLAN setup on your devices, you can ignore the SVI configuration. The script will format your public key so that all lines are 72 characters long and it will display it on your terminal as well as copying it to ~/.ssh/Public_key_formatted_for_Cisco.txt, but IT IS ON YOU to copy it and paste it after entering the command "key string" on all your devices:

example (from Device_configs.txt)

...
user juan.gonzalezescobar
key-string
AAAAB3NzaC1yc2EAAAADAQABAAABAQC/mR6aH6YHPzx7C/J2lrvuH/vkdzuUXV5kwmfTupk8
eTzfc/7h1Q7BCTlJkNnoIwjh92sen0KsFWLTU3y+X9TI9gXvrCbqAuXDfJu2jiBn6oxK4kow
zpueDk6o+bpub97Mzc40wLpm+tLYwOncWm+8mWK4cCW5XglHaiJgkvsjXrUgw4LilEtAg7pi
I9kllDw9LSHM2BXjT6nyIhm+ZUBwFCCcRhLE564qIfjV5hMP5ow/DabgF1uCNbtN17oq/Mdj
NoUKlChbbEV0ZQnPXXFuMzkcFuZCFGYhsO9+Wrq2gcP0jpXSdwjhETQ6kXqecELPZ0KB/thw
P3IVCS+LRl3F
exit
...


Try to SSH into one of your devices. You should be able to run "ssh yourusername@X.X.X.X" and access your device after entering the passphrase for the private key. Note that the script will configure the SSH agent so that no passphrase prompts will occur when running it.




***WHEN RUNNING THE SCRIPT***


6. Once the SSH portion is complete, you can run the script. For updating devices, just download the desired image from Cisco's website and copy the entire name (including the .bin extension too). The script will ask you for this name if you select the "Update many devices at once" by pressing "1". 

./The_Worst_Updater.sh ---> this is the command to run the script


----> Avoid being impatient and pressing "Enter" repeteadly

----> Make sure that you copy the name of the Cisco IOS images completely, including the ".bin" extension, and without any blank space

----> Ensure that on the Hosts list you do NOT ADD ANY BLANK SPACE: just enter the host value and press "Enter" to enter the next host value on the next line. DO NOT ADD BLANK SPACES, DO NOT LIST THE VALUES WITH COMMAS... take some time to read the explanation that the script gives, and if is unclear please let me know so we can work it to make this tool more user-friendly.


If you want to correct any mistakes you find, send me the pull request via Github and I will be more than happy to resolve any possible conflicts and implement the changes.

PD: the script will not work depending on the current IOS version of your Cisco devices, so always consider that when troubleshooting
