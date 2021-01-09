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

AddCSLuaFile()

local D3bot = D3bot
local UTIL = D3bot.Util

-- Get a map with all currently used usernames (ply:Nick() of all players).
function UTIL.GetUsernamesMap()
	local usernames = {}
	for _, ply in pairs(player.GetAll()) do
		usernames[ply:Nick()] = ply
	end
	return usernames
end

-- Floors the coordinates of a vector
function UTIL.FloorVector(vec)
	return Vector(math.floor(vec[1]), math.floor(vec[2]), math.floor(vec[3]))
end

-- Round the coordinates of a vector
function UTIL.RoundVector(vec)
	return Vector(math.floor(vec[1] + 0.5), math.floor(vec[2] + 0.5), math.floor(vec[3] + 0.5))
end

-- Realm bitmasks
UTIL.REALM_SERVER = 1 -- 0b01
UTIL.REALM_CLIENT = 2 -- 0b10
UTIL.REALM_SHARED = 3 -- 0b11

-- Include a lua file into the given realm.
-- The usage of any AddCSLuaFile() is not necessary.
-- This helper must be run in the "shared" realm to work properly.
-- - UTIL.REALM_SERVER: The file will only be included on the server side.
-- - UTIL.REALM_CLIENT: The file will only be included on the client side. Additionally the file will be marked with AddCSLuaFile.
-- - UTIL.REALM_SHARED: The file will only be included on both sides. Additionally the file will be marked with AddCSLuaFile.
function UTIL.IncludeRealm(path, realm) -- TODO: Add function that determines realm by filename/path
	if realm == UTIL.REALM_SERVER then
		if SERVER then include(path) end
	elseif realm == UTIL.REALM_CLIENT then
		if SERVER then AddCSLuaFile(path) end
		if CLIENT then include(path) end
	elseif realm == UTIL.REALM_SHARED then
		if SERVER then AddCSLuaFile(path) end
		include(path)
	else
		error("Invalid realm")
	end
end

-- Includes all (lua) files in the given directory path + filename into a specific realm.
-- The path must be absolute (relative to the lua directory), and the filename can contain * wildcards.
-- Example: UTIL.IncludeDirectory("foo/bar/", "sv_*.lua", UTIL.REALM_SERVER)
function UTIL.IncludeDirectory(path, name, realm)
	local filenames, _ = file.Find(path .. name, "LUA")
	for _, filename in ipairs(filenames) do
		UTIL.IncludeRealm(path .. filename, realm)
	end
end

-- Sorted version of pairs: This will iterate in ascending key order over any map/sparse array.
function UTIL.kpairs(m)
	-- Get keys of m
	local keys = {}
	for k in pairs(m) do
		table.insert(keys, k)
	end

	-- Sort keys
	table.sort(keys)

	-- Return iterator
	local i = 0
	return function()
		i = i + 1
		local key = keys[i]
		if key then
			return key, m[key]
		end
	end
end

-- Returns the closest point from the list points to a given point p with a radius r.
-- If no point is found, nil will be returned.
function UTIL.GetNearestPoint(points, p, r)
	-- Stupid linear search for the closest point
	local minDistSqr = (r and r * r) or math.huge
	local resultPoint
	for _, point in pairs(points) do -- Needs to be pairs, as it needs to support sparse arrays/maps
		local distSqr = p:DistToSqr(point)
		if minDistSqr > distSqr then
			minDistSqr = distSqr
			resultPoint = point
		end
	end

	return resultPoint
end

-- Returns the barycentric coordinates of point p of the triangle defined by p1, p2 and p3.
-- Point p will be projected onto the triangle plane automatically.
function UTIL.GetBarycentric3D(p1, p2, p3, p)
	-- See: https://gamedev.stackexchange.com/a/23745

	local v1, v2, v3 = p2 - p1, p3 - p1, p - p1
	local d11, d12, d22, d31, d32 = v1:Dot(v1), v1:Dot(v2), v2:Dot(v2), v3:Dot(v1), v3:Dot(v2)
	local denom = d11 * d22 - d12 * d12
	local v = (d22 * d31 - d12 * d32) / denom
	local w = (d11 * d32 - d12 * d31) / denom
	local u = 1 - v - w

	return u, v, w
end

-- Returns the barycentric coordinates of point p of the triangle defined by p1, p2 and p3.
-- This will clamp the coordinates in a way that the resulting u, v and w represent a point inside the triangle with the shortest distance to p.
-- Point p will be projected onto the triangle plane automatically.
function UTIL.GetBarycentric3DClamped(p1, p2, p3, p)
	-- See: https://stackoverflow.com/a/37923949/14967192

	local u, v, w = UTIL.GetBarycentric3D(p1, p2, p3, p)

	-- The point is outside of the triangle at the edge between p2 and p3
	if u < 0 and u <= v and u <= w then
		local t = (p - p2):Dot(p3 - p2) / (p3 - p2):Dot(p3 - p2)
		t = math.Clamp(t, 0, 1)
		return 0, 1 - t, t
	end
	-- The point is outside of the triangle at the edge between p1 and p3
	if v < 0 and v <= u and v <= w then
		local t = (p - p3):Dot(p1 - p3) / (p1 - p3):Dot(p1 - p3)
		t = math.Clamp(t, 0, 1)
		return t, 0, 1 - t
	end
	-- The point is outside of the triangle at the edge between p1 and p2
	if w < 0 and w <= u and w <= v then
		local t = (p - p1):Dot(p2 - p1) / (p2 - p1):Dot(p2 - p1)
		t = math.Clamp(t, 0, 1)
		return 1 - t, t, 0
	end

	-- Point is inside of the triangle
	return u, v, w
end

-- Returns the closest entity from lists of entities that intersects with a ray from the given origin in the given direction dir.
-- The entities in the supplied lists have to implement the IntersectsRay method.
-- The result is either nil or the intersecting entity, and its distance from the origin as a fraction of dir length.
-- This will not return anything behind the origin, or beyond the length of dir.
function UTIL:GetClosestIntersectingWithRay(origin, dir, ...)
	local lists = {...}
	local minDist = 1
	local minEntity = nil

	for _, list in ipairs(lists) do
		for _, entity in pairs(list) do
			local dist = entity:IntersectsRay(origin, dir)
			if dist and minDist > dist then
				minDist = dist
				minEntity = entity
			end
		end
	end

	return minEntity, minDist
end

-- Returns pos snapped to the closest (in proximity range) snapping point of a given navmesh or map geometry.
-- This will always return a point, even if it is pos itself.
function UTIL:GetSnappedPosition(navmesh, mapgeometry, pos, proximity)
	local posGeometry = mapgeometry and mapgeometry:GetNearestPoint(pos, proximity)
	local posNavmesh = navmesh and navmesh:GetNearestPoint(pos, proximity)
	local pos = UTIL.GetNearestPoint({posGeometry, posNavmesh}, pos) or pos
	return UTIL.RoundVector(pos)
end