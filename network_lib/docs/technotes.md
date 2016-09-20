#Network mod technical notes
##Network identification
Each network is identified by an integer number corresponding of position serialization of one of the network nodes. Let's call this node "network id node"
Network information is stored in the network id node metadata.
If no information is available, this means that the network has been modified or created recently.
In that case, infomation will be reconstructed in the next network step

##Network steps
How to trigger network wide step once at every network tic ?
Add an ABM to every network compatible nodes (on the network group).
The ABM will :
- Check if network has information in network id node. If not : create it
- Check if network information contains last run time. If not : set current time as last run time and do nothing (prevents artificial triggering of network when adding wires).
- Check if last run time is older than network tic duration. If not, do nothing.
- Trigger network step
##Network modification
__When adding a node__, in current version, the whole network is explored to, find if several networks are merged into new one, or change the network id node. This could be improved by simply add the node to the network if it connects to only one network.
The connected machine list have to be refreshed.
__When removing a node__, a network may be splitted into two separate network and machines may be left unconnected.
All 6 neighbours nodes are checked and corresponding networks are rebuilt.
# Network Lib
##Variables
###networks
A table of buffered networks indexed by their ID.
Each element has this structure :
__id__: Network ID
__type__: Network type
__name__: Network name (WIP)
__cables__: List of cable nodes position (maybe useless)
__devices__: List of connected devices (usefull!)
__last_run__: Time of last network run 
##Public Methods
###register_network_type
Registers a new network type.

	register_network_type(name, typedef)

__name__ : name of the network type.
__typedef__ fields are:
_label_ : Display name of the network type
_cable_group_ : group of cables belonging to the network type
_device_group_ : group of devices connecting to this network type
_on_run_ : Run callback for networks of this type. Will be called each network step.

Usecase: Create a new network type.

###register_cable

	register_cable(nodename, network_type_name, nodedef)


###get_connected_networks
Returns networks connected to a device node at _pos_ (does not work for cable nodes).

	get_connected_networks(pos)

Usecase: A device can know which network(s) it is connected to.
###refresh_neighboors_networks_devices

	refresh_neighboors_networks_devices(pos)
	
Usecase: ?
	
##Private methods
###get_network_type

	get_network_type(node) 

###network_abm

	network_abm(pos, node, active_object_count, active_object_count_wider)

###compute_network_id

	compute_network_id(network)

###callback_devices

	callback_devices(network, callback)

###rebuild_network
Explores or re-explore network

	rebuild_network(pos)

This function :
- Explores network, starting from _pos_
- Assigns an ID to the network;
- Stores network node lists;
- Stores network attached devices;
	
###refresh_network_devices
Refresh the devices list attached to a network.

	refresh_network_devices(network)
	
###get_network
Gives the network object corresponding to node at position _pos_.
Returns nil if node is not a part of a network.
Exploire the network if it has not been explored yet.

	get_network(pos)
	
###rebuild_neighboors_networks
Rebuilds networks around a node (used when cable has been dug).

	rebuild_neighboors_networks(pos)
	
