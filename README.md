# linux-automatic-hibernation

requires:
- pm-hibernate
- smartmontools

use cronjob to execute this execute periodically

# execute sleep script every 30 minutes
30 * * * *	root /root/scripts/sleep.sh

skip if:
- snapraid is running
- unrar is running
- ssh connection is established
- any harddrive is running a smart check
