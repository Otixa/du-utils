math.randomseed(system.getTime())
local Vertices = {
    {0.25,0.5},
    {0.75,0.5},
    {0.5,0.45}
}

local telemeterOffsets = {3.5, 3.5, 2}

local screenWidth = 500
local screenHeight = 500

local svg = [[<svg height="]]..screenHeight..[[" width="]]..screenWidth..[[">]]

local telemLDistance = telemL.getDistance()-telemeterOffsets[1]
local telemRDistance = telemR.getDistance()-telemeterOffsets[2]
local telemFDistance = telemF.getDistance()-telemeterOffsets[3]

local terrainDistances = vec3(telemLDistance, telemRDistance, telemFDistance)
local averageTerrainDistance = (terrainDistances.x+terrainDistances.y+terrainDistances.z)/3
local correctedTerrainDistances = vec3(terrainDistances.x-averageTerrainDistance, terrainDistances.y-averageTerrainDistance, terrainDistances.z-averageTerrainDistance)
local normalizedTerrainDistances = correctedTerrainDistances:normalize()*0.1

svg = svg .. [[<polygon points="]]
..Vertices[1][1]*screenWidth..","
..(Vertices[1][2]+normalizedTerrainDistances.x)*screenHeight.." "
..Vertices[2][1]*screenWidth..","
..(Vertices[2][2]+normalizedTerrainDistances.y)*screenHeight.." "
..Vertices[3][1]*screenWidth..","
..(Vertices[3][2]+normalizedTerrainDistances.z)*screenHeight..
" "..[[" style="fill:#A4A4A4;stroke:white;stroke-width:5" />]]

local svg = svg..[[</svg>]]

screen.clear()
screen.setHTML(svg)