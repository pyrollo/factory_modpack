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

network_lib={}
network_lib.path = minetest.get_modpath(minetest.get_current_modname())

-- Helpers

function network_lib.message(string) 
    print ("[network_api] "..string)
end

function network_lib.get_or_load_node(pos)
	local node = minetest.get_node_or_nil(pos)
	if node then return node end
	local vm = VoxelManip()
	local MinEdge, MaxEdge = vm:read_from_map(pos, pos)
	return minetest.get_node(pos)
end

-- Subfiles

dofile(network_lib.path.."/network_types.lua")
dofile(network_lib.path.."/network.lua")
dofile(network_lib.path.."/network_run.lua")

