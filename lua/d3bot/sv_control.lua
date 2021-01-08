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

local D3bot = D3bot

local function ControlDistributor(bot, cUserCmd)
	local mem = bot.D3bot

	-- BUG: This is not called for dead bots for some reason. So there is need for gamemode specific code to bring back players.

	-- Don't take control if there is no D3bot structure
	if not mem then
		return
	end

	-- Assign brain to bot, if needed
	if not mem.Brain then
		-- "Insane in the membrane"
		-- "Crazy insane, got no brain"
		if D3bot.AssignBrain then
			D3bot.AssignBrain(bot, mem)
		end
	end
	-- Run brain "think" callback. Ideally this will resume one or more coroutines, depending on how complex the brain is.
	if mem.Brain then
		if mem.Brain.Callback then
			mem.Brain:Callback(bot, mem)
		end
	end

	-- Check if there is a locomotion control callback
	if mem.Locomotion == nil or mem.Locomotion.Callback == nil then
		cUserCmd:ClearButtons()
		cUserCmd:ClearMovement()
		return
	end

	-- "Don't you know I'm loco?"
	mem.Locomotion.Callback(bot, mem, cUserCmd)
end
hook.Add("StartCommand", D3bot.HookPrefix .. "ControlDistributor", ControlDistributor)