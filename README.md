$ bin/stem launch prototype/config.json prototype/userdata.sh
# wait an appropriate amount of time for the instance to go to "stopped"
$ bin/stem capture postgres-server <instance-id>
# wait a bit for amazon to create the snapshots
$ bin/stem launch server/config.json server/userdata.sh

