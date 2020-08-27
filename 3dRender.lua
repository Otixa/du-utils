local mat4 = require('cpml/mat4')
var = var+0.01
--Left/Right, Up/Down, Forward/Backward
--[[local mesh = {
    Vertices = {
        vec3(-0.5, 0, 0), 
        vec3(0.5, 0, 0), 
        vec3(0, 0.0, 0.4),
    },
    Triangles = { {1,2,3} }
}]]
local mesh = {
    Vertices = {
        vec3(0, 0, 0),
        vec3(5, 0, 0),
        vec3(5, 0, 5),
        vec3(0, 0, 5),
        vec3(0, 5, 0),
        vec3(5, 5, 0),
        vec3(5, 5, 5),
        vec3(0, 5, 5),
    },
    Triangles = { 
        {3,2,6},
        {3,6,7},
        {2,1,5},
        {2,5,6},
        {1,0,4},
        {1,4,5},
        {0,3,7},
        {0,7,4},
        {7,6,5},
        {7,5,4},
        {2,3,0},
        {2,0,1}
        
    }
}

--  -,+
--Right,Left Up,Down Front,Back
local cameraPosition = vec3(9,8,10)
local cameraTarget = vec3(2.5,2.5,2.5)
local cameraTransformationMatrix = mat4():look_at(cameraPosition, cameraTarget, vec3(0,1,0))

local viewMatrix = cameraTransformationMatrix:invert()
local projectionMatrix = mat4:perspective(90, 1, 0.1, 100)

local svg = [[<svg height="1000" width="1000">
<   defs>
        <pattern id="terrainTexture" patternUnits="userSpaceOnUse" width="1920" height="800">
            <image xlink:href="https://cdna.artstation.com/p/assets/images/images/009/647/842/large/joshua-lynch-roofing-tiles-02-layout-comp-wide.jpg" x="0" y="0" width="1920" height="800" />
        </pattern>
    </defs>
]]

for i,v in pairs(mesh.Triangles) do
    local v1 = mat4.project(mesh.Vertices[v[1]], viewMatrix, projectionMatrix, {0,0,1000,1000})
    local v2 = mat4.project(mesh.Vertices[v[2]], viewMatrix, projectionMatrix, {0,0,1000,1000})
    local v3 = mat4.project(mesh.Vertices[v[3]], viewMatrix, projectionMatrix, {0,0,1000,1000})
    svg = svg .. [[<g id="terrain" fill="url(#terrainTexture)"><polygon points="]]..v1.x..","..v1.y.." "..v2.x..","..v2.y.." "..v3.x..","..v3.y.." "..[[" style="fill:lime;stroke:purple;stroke-width:5" /></g>]]
end

local svg = svg..[[</svg>]]

screen.clear()
screen.setHTML(svg)