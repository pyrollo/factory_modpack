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

-- Networks information cache
network_lib.networks_cache={}

local message = network_lib.message
local get_or_load_node = network_lib.get_or_load_node

local function renumber_list(list)
    local result = {}
    for _, value in pairs(list) do  
        result[#result+1] = value
    end
    return result
end

local function pos_in_list(pos, list)
    for i = 1, #list do
        if pos.x == list[i].x and
           pos.y == list[i].y and
           pos.z == list[i].z 
        then
            return true
        end
    end
    return false
end

local function get_neighboors(pos)
    return {
        {x=pos.x+1, y=pos.y,   z=pos.z},
        {x=pos.x-1, y=pos.y,   z=pos.z},
        {x=pos.x,   y=pos.y+1, z=pos.z},
        {x=pos.x,   y=pos.y-1, z=pos.z},
        {x=pos.x,   y=pos.y,   z=pos.z+1},
        {x=pos.x,   y=pos.y,   z=pos.z-1}}
end

-- Networks

local function callback_devices(network, callback)
    local nodedef
    for i = 1,#network.devices do
        nodedef = minetest.registered_nodes[get_or_load_node(network.devices[i]).name]
        if nodedef[callback] and
           type(nodedef[callback]) == "function" then
            nodedef[callback](network.devices[i], network)
        end
    end
end

local function rebuild_network(pos)
    -- Rebuild network from scratch
    local network = {}
    network.cables = {}
    network.devices = {}
    network.last_run = minetest.get_gametime()
    
    -- Explore network
    local current_nodes = {pos}
    local node = get_or_load_node(pos)
    local network_type = network_lib.get_network_type(node)
    if network_type then
        repeat
            local next_nodes = {}
            for _, pos in pairs(current_nodes) do
                network.cables[#network.cables+1] = pos
                local neighboors = get_neighboors(pos)
                for i = 1, #neighboors do
                    node = get_or_load_node(neighboors[i])
                    if minetest.get_item_group(node.name, network_type.device_group) > 0 then
                        if not pos_in_list(neighboors[i], network.devices) then
                           network.devices[#network.devices+1] = neighboors[i]
                        end
                    end
                    if minetest.get_item_group(node.name, network_type.cable_group) > 0 then
                        if not pos_in_list(neighboors[i], network.cables) and
                           not pos_in_list(neighboors[i], next_nodes)
                        then
                            next_nodes[#next_nodes+1] = neighboors[i]
                        end
                    end
                end
            end
            current_nodes = next_nodes
        until #current_nodes == 0
        
        -- Determine network id and store network
        local pos = network.cables[1] -- ID is the hash of position that have highest x, y, z coordinates
        for i=2,#network.cables do
            if network.cables[i].x > pos.x or
               network.cables[i].y > pos.y or
               network.cables[i].z > pos.z then
                pos = network.cables[i]
            end
        end
        network.id = string.format('%i',minetest.hash_node_position(pos))

        network.type = network_type
        network.name = network_type.name.." network #"..network.id
        network_lib.networks_cache[network.id] = network; -- Store network in cache

        -- Affect network id to cable nodes
        local meta
        for i = 1,#network.cables do
            get_or_load_node(network.cables[i])
            meta = minetest.get_meta(network.cables[i])
            meta:set_string("network_id", network.id)
            meta:set_string("infotext", network.name.." ("..#network.cables..")");
        end

        -- Inform devices that network might have changed
        callback_devices(network, "on_network_changed")

        return network.id
    end
    return nil
end

local function refresh_network_devices(network)
    if network ~= nil then
        network.devices = {}
        network.last_run = minetest.get_gametime()
        for i = 1, #network.cables do
            for _, pos in pairs(get_neighboors(network.cables[i])) do
                local node = get_or_load_node(pos)
                if minetest.get_item_group(node.name, network.type.device_group) > 0 then
                    if not pos_in_list(pos, network.devices) then
                       network.devices[#network.devices+1] = pos
                    end
                end
            end
        end

        -- Inform devices that network might have changed
        callback_devices(network, "on_network_changed")
    end
end

local function get_network(pos)
    local node = get_or_load_node(pos)

    if network_lib.get_network_type(node) then
        local meta = minetest.get_meta(pos)
        local id = meta:get_string("network_id")
        if network_lib.networks_cache[id] == nil then
            id = rebuild_network(pos)
        end
        return network_lib.networks_cache[id]
    end
    return nil
end

function network_lib.get_connected_networks(pos)
    local node = get_or_load_node(pos)
    local networks = {}

    for _, pos in pairs(get_neighboors(pos)) do
        local network = get_network(pos)
        if network ~= nil and 
           minetest.get_item_group(node.name, network.type.device_group) > 0 then
           networks[network.id] = network
        end
    end
    return renumber_list(networks)
end

local function rebuild_neighboors_networks(pos)
    local network_ids = {}
    
    for _, pos in pairs(get_neighboors(pos)) do
        local done = false
        for _, id in pairs(network_ids) do
            if pos_in_list(pos, network_lib.networks_cache[id].cables) then
                done = true
                break
            end        
        end
        if not done then
            network_ids[#network_ids+1] = rebuild_network(pos)
        end
    end     
end

function network_lib.refresh_neighboors_networks_devices(pos)
    local networks = {}
    local network
    local nodedef
    for _, pos in pairs(get_neighboors(pos)) do
        network = get_network(pos)
        if network ~= nil then
            networks[network.id] = network
        end
    end     

    for id, network in pairs(networks) do
        refresh_network_devices(network)
    end
end

function network_lib.register_cable(nodename, network_type_name, nodedef)
    local network_type = network_lib.registered_types[network_type_name]

    if network_type == nil then
        network_lib.message("Warning : registering '"..nodename.."' with unknown network type '"..network_type_name.."'.")
    else
        -- Add network api stuff to node definition

        nodedef.groups[network_type.cable_group] = 1
        nodedef.connects_to = {"group:"..network_type.cable_group, "group:"..network_type.device_group}

        -- TODO : Keep calling on_... functions if any
        nodedef.on_construct = function(pos)
                rebuild_network(pos)
            end

        nodedef.on_destruct = function(pos)
                local meta = minetest.get_meta(pos)
                local id = meta:get_string("network_id")
                if network_lib.networks_cache[id] == nil then
                    network_lib.message("Warning : removing cable without network ID at "..minetest.pos_to_string(pos)..".")
                else
                    local network = network_lib.networks_cache[id]
                    network_lib.networks_cache[id] = nil
                    -- Yet set node to air to avoid it from being put back in network
                    minetest.swap_node(pos, {name="air"})
                    rebuild_neighboors_networks(pos)
                    callback_devices(network, "on_network_changed") -- This can be done only in on_destruct not in after_destruct (we dont know the network anymore)
                end
            end
    end

    minetest.register_node(nodename, nodedef)
end


