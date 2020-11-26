--@class PlanetaryUtils
--@require Planets

PlanetaryUtils = (function ()
	local this = {}
	local deg2rad    = math.pi/180
	local rad2deg    = 180/math.pi
	
	function this.FromGamePos(pos)
		local pattern = "::pos{(%d+),(%d+),([+-]?%d+%.?%d*),([+-]?%d+%.?%d*),([+-]?%d+%.?%d*)}"
		local systemId,planetId,latitude,longitude,altitude = string.match(pos,pattern)
		
		posTable = {
			SystemId  = tonumber(systemId),
			PlanetId  = tonumber(planetId),
			Latitude  = tonumber(latitude),
			Longitude = tonumber(longitude),
			Altitude  = tonumber(altitude)
		}
		
		local xproj = math.cos(posTable.Latitude * deg2rad)
		posTable.Cartesian = vec3(Planets[posTable.PlanetId].Position) + (
			(Planets[posTable.PlanetId].WaterRadius + posTable.Altitude) * 
			vec3(xproj * math.cos(posTable.Longitude * deg2rad),
				xproj * math.sin(posTable.Longitude * deg2rad),
				math.sin(posTable.Latitude * deg2rad))
		)
		
		return setmetatable(posTable,{
			__tostring = function(pos)
				return string.format("::pos{%d,%d,%s,%s,%s}",
					pos.SystemId,
					pos.PlanetId,
					utils.round(pos.Latitude,0.0001),
					utils.round(pos.Longitude,0.0001),
					utils.round(pos.Altitude,0.0001))
			end
		})
	end
	
	function this.FromWorldPos(pos,planetId,systemId)
		local planetId = planetId or FindClosestBody(pos)
		local systemId = systemId or 0
		local posRelative = pos - Planets[planetId].Position
		local distance = posRelative:len()
		local altitude = distance - Planets[planetId].WaterRadius
		
		local phi = math.atan(posRelative.y,posRelative.x)
		local longitude = ((phi <= 0) and phi or (2 * math.pi + phi)) * rad2deg
		local latitude = ((math.pi / 2) - math.acos(posRelative.z / distance)) * rad2deg
		
		return setmetatable({
			SystemId  = systemId,
			PlanetId  = planetId,
			Latitude  = latitude,
			Longitude = longitude,
			Altitude  = altitude,
			Cartesian = pos
		},{
			__tostring = function(pos)
				return string.format("::pos{%d,%d,%s,%s,%s}",
					pos.SystemId,
					pos.PlanetId,
					utils.round(pos.Latitude,0.0001),
					utils.round(pos.Longitude,0.0001),
					utils.round(pos.Altitude,0.0001))
			end
		})
	end
	
	function FindClosestBody(pos)
		for i, v in ipairs(Planets) do
			if (pos - vec3(v.Position)):len() < v.WaterRadius + 40000 then
				return i
			end
		end
		return 0
	end
	
	return this
end)()