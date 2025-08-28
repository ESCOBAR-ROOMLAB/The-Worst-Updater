#!/usr/bin/bash



## Define some useful functions

# Center text in the terminal

print_center(){
    local x
    local y
    text="$*"
    x=$(( ($(tput cols) - ${#text}) / 2))
    echo -ne "\E[6n";read -sdR y; y=$(echo -ne "${y#*}" | cut -d';' -f1)
    echo -ne "\033[${y};${x}f$*"
}

# main()

# clear the screen, put the cursor at line 10, and set the text color
# to light blue.
echo -ne "\\033[2J\033[10;1f\e[94m"



# Welcome message
clear
print_center "Welcome to The Worst Updater!! Let's get you started..."
sleep 3
clear



# Setup the SSH public key
echo "

This is your public key formatted for Cisco devices. You should now configure your devices and use this format of the public key. You can find a copy of it in ~/.ssh/Cisco_formatted_publickey.txt

"

cat ~/.ssh/id_rsa.pub | cut -c 9- | sed 's/ [^ ]*$//' | fold -w 72 | tee ~/.ssh/Cisco_formatted_publickey.txt


read -p "Are you done configuring your devices? (press Enter whenever you are ready): " iamdone
clear



# Setup the SSH Agent. First we kill all SSH Agent processes that are currently running, so we start fresh. Then, we setup a new agent

for p in $(ps | grep ssh-agent | awk '{ print $1 }'); do 
	kill $p; 
done

eval $(ssh-agent)

echo "

Now you will be prompted for the passphrase of your private key, so that it can be added to the SSH Agent

"
ssh-add
clear



# Set the subnet variable
read -p "

Enter the SUBNET PORTION (ex. 10.211.200 for 10.211.200.0/24) of the hosts IP address (if you have any doubts, look at the subnet mask of the hosts IP addresses and try to figure it out yourself. Otherways, call a competent networker and you can go away and study a little more) 


For more complex subnets, like a /23, enter JUST THE UNVARIABLE BYTES of the IP address (ex 137.232 for 137.232.2.0/23, or 137.232.200 for 137.232.200.128/25)


NOTE: do NOT include the final dot when writing it, we take care of that!!: " subnet

while [ -z $subnet ]; do
	echo "ERROR: the value cannot be blank. Enter a valid value!"
	read -p "Enter the subnet value: " subnet
done
clear



# Add your devices here
echo "

READ THIS EXPLANATION!! Enter the host portion of the Host IP address for every device you want to update, using one line per host. Here is an example...


EXAMPLE 1
------------------------------------------------------------------------

If your devices IPs are 10.211.200.2, 10.211.200.3 and 10.211.200.4 on the 10.211.200.0/24 network, the file will look like:

2
3
4

ENTER ONE HOST IP PER LINE!! DO NOT USE COMMAS, SPACES, ....
ONLY ENTER A NUMBER. DO NOT ENTER A DOT (.) BEFORE THE NUMBERS. Just keep adding more lines for each host...

------------------------------------------------------------------------



FOR MORE COMPLEX SUBNETS, JUST ENTER THE VARIABLE BYTES!!!



EXAMPLE 2
------------------------------------------------------------------------

If your devices IPs are 137.232.200.2, 137.232.200.27 and 137.232.201.120 on the 137.232.200.0/23 the file will look like:

200.2
200.27
201.120

-------------------------------------------------------------------------


Once you are done, press Ctl+o and then Ctl+x

"

read -p "Are you ready to do it? (enter 1 whenever you are ready): " timeforexplanation
> hostlist.txt
nano hostlist.txt
clear



# SSH user (make sure it's the same on all devices)
read -p "

All the PUSH actions are done via SSH. Enter the username for the SSH connection: " username

while [ -z $username ]; do
        echo "ERROR: the value cannot be blank. Enter a valid value!"
        read -p "All the PUSH actions are done via SSH. Enter the username for the SSH connection: " username
done
clear



# Interactive Menu
select mainoption in "Update many devices at once" "Push any commands to all hosts" "Monitor Configuration Drift" "Edit the hosts file again" "Get me out of here, this sucks"; do

	case $mainoption in 

		
		# Update many devices at once
		"Update many devices at once")
		
		read -p "Enter the name of the IOS image file that we will be working on, including the .bin extension: " imagename
		imagenamelocated="$(find ~/ -name $imagename 2>trash.txt)"

		rm -f trash.txt

		select suboption in "Check the current IOS version of the devices" "Copy the IOS image file to the devices memory" "Verify the digital signature of an IOS image" "Reload all the devices" "Delete an old IOS image" "Edit the hosts file again" "Go to the Main Menu"; do

			case $suboption in

				
				# Check the current IOS version of the devices
				"Check the current IOS version of the devices")

				cat << EOF > commandsforcheckversion.txt
sho ver | s IOS | head -n 3
EOF

				for i in $(cat hostlist.txt); do
					cat commandsforcheckversion.txt | xargs -0 echo | ssh $username@$subnet.$i
					echo "

					====> for $subnet.$i

					"
				wait
				done
				;;


				# Copy the IOS image file to the devices memory
				"Copy the IOS image file to the devices memory")
			
				# Loop to copy the file to each device
				for i in $(cat hostlist.txt); do
					echo "

					====> Copying image file to $subnet.$i

					"
					scp -O $imagenamelocated $username@$subnet.$i:$imagename &
	
					pid=$!
					echo $pid >> pid.txt

				done

				for a in $(cat pid.txt); do
       				wait $a
				done

       				echo "

       				The image has been copied to the Cisco device successfully

       				"

				> pid.txt
				;;
		


				# Verify the digital signature of an IOS image
				"Verify the digital signature of an IOS image")
        			echo "

        			Verifying that the image is not corrupted for $subnet.$i

        			"
				for i in $(cat hostlist.txt); do
        				ssh $username@$subnet.$i << EOF > image_verify_$subnet.$i.txt &
verify flash:$imagename
EOF
				echo "

				====> for $subnet.$i

				"

				pid=$!
				echo $pid >> pid.txt

				done

				for a in $(cat pid.txt); do
				wait $a
				done

				> pid.txt

			
				for i in $(cat hostlist.txt); do
					tail -7 image_verify_$subnet.$i.txt | head -n 8;
				done
				;;


		
				# Reload all the devices
				"Reload all the devices")
				echo "

				Proceeding with the reload

				"
				cat << EOF > commandsforsetbootvar.txt
config t
no boot system
boot system flash:$imagename
do wr
do reload


!
EOF

				for i in $(cat hostlist.txt); do
					cat commandsforsetbootvar.txt | xargs -0 echo | ssh $username@$subnet.$i 
					echo "

					=====> Reloading $subnet.$i

					"
				done
		
		
				echo "

				Wait 8 minutes you impatient fuck!!

				"
				;;



				# Delete an old IOS image
				"Delete an old IOS image")
				read -p "Enter the name of the old IOS image you want to delete (include the .bin extension): " oldimage

				cat <<EOF > commandsfordeleteoldimg.txt
delete /force flash:$oldimage
EOF

				for i in $(cat hostlist.txt); do
					cat commandsfordeleteoldimg.txt | xargs -0 echo | ssh $username@$subnet.$i
					echo "

					====> for $subnet.$i
					
					"
				done
				;;


		
				# Edit the hosts file again
				"Edit the hosts file again")
				nano hostlist.txt
				;;



				# Go to the Main Menu
				"Go to the Main Menu")
				break
				;;


			esac
		done
		;;


		# Push any commands to all hosts
		"Push any commands to all hosts")
		echo " 

		Enter ONE command PER LINE

		"

		nano commands_for_all_hosts.txt

		for i in $(cat hostlist.txt); do
			cat commands_for_all_hosts.txt | xargs -0 echo | ssh $username@$subnet.$i
			echo "

			====> Pushing to $subnet.$i
			
			"
		done

		;;

	

		# Monitor Configuration Drift
		"Monitor Configuration Drift")
		echo "

		Coming soon...

		"

		sleep 1

		;;



		# Edit the hosts file again
		"Edit the hosts file again")
		nano hostlist.txt

		;;	


		
		# Get me out of here, this sucks
		"Get me out of here, this sucks")
		
		MIN=1
		MAX=2
		RANDOM_NUMBER=$(( $RANDOM % (MAX - MIN + 1) + MIN ))
		if [ $RANDOM_NUMBER -eq 1 ]; then
			echo "

			See you later alligator...

			"
			sleep 1

			exit
		else
			echo "

			See you in a while crocodile...

			"

			sleep 1

			exit

		fi


	esac


done
