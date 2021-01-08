-- Copyright (C) 2020 David Vogel
-- 
-- This file is part of D3bot.
-- 
-- D3bot is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- D3bot is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with D3bot.  If not, see <http://www.gnu.org/licenses/>.

-- Container for the main navmesh instance.
-- On the server realm this will be used for navigation, and on the client realm this will be used for displaying/editing.

local D3bot = D3bot
local NAV_MAIN = D3bot.NavMain
local NAV_MESH = D3bot.NAV_MESH
local NAV_PUBSUB = D3bot.NavPubSub

-- Get the current navmesh, or nil if there is none.
function NAV_MAIN:GetNavmesh()
	return self.Navmesh
end

-- Get the current navmesh, or create a new one.
function NAV_MAIN:ForceNavmesh()
	if self.Navmesh then return self.Navmesh end

	-- Create new navmesh and link PubSub
	self.Navmesh = NAV_MESH:New()
	if SERVER then self.Navmesh:SetPubSub(NAV_PUBSUB) end

	return self.Navmesh
end

-- Will overwrite the current main navmesh with the given one.
function NAV_MAIN:SetNavmesh(navmesh)
	if self.Navmesh then self.Navmesh:SetPubSub(nil) end

	self.Navmesh = navmesh
	if SERVER and self.Navmesh then self.Navmesh:SetPubSub(NAV_PUBSUB) end
end