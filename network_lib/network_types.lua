--[[
    network_lib mod for Minetest - Networking framework library
    (c) Pierre-Yves Rollo

    This file is part of network_lib.

    network_lib is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    network_lib is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with network_lib.  If not, see <http://www.gnu.org/licenses/>.
--]]

network_lib.registered_types={}
local registered_abm={}

function network_lib.get_network_type(node) 
    for _, network_type in pairs(network_lib.registered_types) do
        if minetest.get_item_group(node.name, network_type.cable_group) > 0 then
            return network_type
        end
    end
    return nil
end

--[[
 typedef fields:
    label : Display name of the network type
    cable_group : group of cables belonging to the network type
    device_group : group of devices connecting to this network type
    on_run : Run callback for networks of this type. Will be called each second.
--]] 
function network_lib.register_network_type(name, typedef)
    typedef['name'] = name
    assert(network_lib.registered_types[name] == nil, "[network_lib] Can't register \""..name.."\" network twice !")

    network_lib.registered_types[name] = typedef

    -- Register an ABM for this network devices only if there is a on_run function in network typedef
    if type(typedef.on_run) == "function" and
       typedef.device_group ~= nil and
       registered_abm[typedef.device_group] == nil -- Avoid registering several ABMs for the same group
    then
        print ("Registering devices ABM for "..typedef.device_group)
        registered_abm[typedef.device_group] = 1
        minetest.register_abm({
            nodenames = "group:"..typedef.device_group,
            interval = 1,
            chance = 1,
            action = function(pos)
                network_lib.trigger_connected_network_step_run(pos)    
            end
        })
    end

end


