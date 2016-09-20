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

function network_lib.trigger_connected_network_step_run(pos)
    local time = minetest.get_gametime()
    local networks = network_lib.get_connected_networks(pos)
    for id, network in pairs(networks) do
        if network.type.on_run ~= nil and
           type(network.type.on_run) == 'function' and
           network.last_run < time -- 1 second for now, may be improved... or not 
        then 
            network.last_run = minetest.get_gametime()
            network.type.on_run(network)
        end
    end
end




