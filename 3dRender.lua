local mat4 = require('cpml/mat4')
local icoSphere = {Verticies={{0.0,-1.0,0.0},{0.723607,-0.44722,0.525725},{-0.276388,-0.44722,0.850649},{-0.894426,-0.447216,0.0},{-0.276388,-0.44722,-0.850649},{0.723607,-0.44722,-0.525725},{0.276388,0.44722,0.850649},{-0.723607,0.44722,0.525725},{-0.723607,0.44722,-0.525725},{0.276388,0.44722,-0.850649},{0.894426,0.447216,0.0},{0.0,1.0,0.0},{-0.162456,-0.850654,0.499995},{0.425323,-0.850654,0.309011},{0.262869,-0.525738,0.809012},{0.850648,-0.525736,0.0},{0.425323,-0.850654,-0.309011},{-0.52573,-0.850652,0.0},{-0.688189,-0.525736,0.499997},{-0.162456,-0.850654,-0.499995},{-0.688189,-0.525736,-0.499997},{0.262869,-0.525738,-0.809012},{0.951058,0.0,0.309013},{0.951058,0.0,-0.309013},{0.0,0.0,1.0},{0.587786,0.0,0.809017},{-0.951058,0.0,0.309013},{-0.587786,0.0,0.809017},{-0.587786,0.0,-0.809017},{-0.951058,0.0,-0.309013},{0.587786,0.0,-0.809017},{0.0,0.0,-1.0},{0.688189,0.525736,0.499997},{-0.262869,0.525738,0.809012},{-0.850648,0.525736,0.0},{-0.262869,0.525738,-0.809012},{0.688189,0.525736,-0.499997},{0.162456,0.850654,0.499995},{0.52573,0.850652,0.0},{-0.425323,0.850654,0.309011},{-0.425323,0.850654,-0.309011},{0.162456,0.850654,-0.499995}},Triangles={{1,14,13},{2,14,16},{1,13,18},{1,18,20},{1,20,17},{2,16,23},{3,15,25},{4,19,27},{5,21,29},{6,22,31},{2,23,26},{3,25,28},{4,27,30},{5,29,32},{6,31,24},{7,33,38},{8,34,40},{9,35,41},{10,36,42},{11,37,39},{39,42,12},{39,37,42},{37,10,42},{42,41,12},{42,36,41},{36,9,41},{41,40,12},{41,35,40},{35,8,40},{40,38,12},{40,34,38},{34,7,38},{38,39,12},{38,33,39},{33,11,39},{24,37,11},{24,31,37},{31,10,37},{32,36,10},{32,29,36},{29,9,36},{30,35,9},{30,27,35},{27,8,35},{28,34,8},{28,25,34},{25,7,34},{26,33,7},{26,23,33},{23,11,33},{31,32,10},{31,22,32},{22,5,32},{29,30,9},{29,21,30},{21,4,30},{27,28,8},{27,19,28},{19,3,28},{25,26,7},{25,15,26},{15,2,26},{23,24,11},{23,16,24},{16,6,24},{17,22,6},{17,20,22},{20,5,22},{20,21,5},{20,18,21},{18,4,21},{18,19,4},{18,13,19},{13,3,19},{16,17,6},{16,14,17},{14,1,17},{13,15,3},{13,14,15},{14,2,15}}}

function Model(name, position, scale, modelTable)
    local self = {}
    self.Name = name
    self.Position = position
    self.Scale = scale
    self.Verticies = modelTable.Verticies
    self.Triangles = modelTable.Triangles

    self.ComputedVerticies = {}

    local function computeVerticies(position, scale)
        self.ComputedVerticies = {}
        for i=1,#self.Verticies,1 do
            local vertex = vec3((self.Verticies[i][1]*scale)+position.x,(self.Verticies[i][2]*scale)+position.y,(self.Verticies[i][3]*scale)+position.z)
            table.insert(self.ComputedVerticies, vertex)
        end
    end

    computeVerticies(position, scale)

    return self
end

Renderer = (function()

    local internals = {}
    local self = {}

    internals.FarClip = 500000
    internals.CameraPosition = vec3(0,0,0)
    internals.CameraTarget = vec3(0,0,0)
    internals.WorldUp = vec3(0,1,0)
    internals.RenderTarget = nil
    internals.ScreenWidth = 1920
    internals.ScreenHeight = 1080
    internals.SVG = ""

    self.Models = {}

    internals.PerspectiveMatrix = mat4():perspective(80, 1920/1080, 100, internals.FarClip)
    
    local function updateCameraMatrix()
        internals.ViewMatrix = mat4():look_at(internals.CameraPosition, internals.CameraTarget, internals.WorldUp)
    end
    local function projectVertex(pos)
        local pos = internals.ViewMatrix * internals.PerspectiveMatrix * { pos.x, pos.y, pos.z, 1 }

        pos[1] = pos[1] / pos[4] * 0.5 + 0.5
        pos[2] = pos[2] / pos[4] * 0.5 + 0.5

        pos[1] = pos[1] * (internals.ScreenWidth/2)
        pos[2] = pos[2] * (internals.ScreenHeight /2)

        return vec3(pos[1], pos[2], pos[3])
    end
    
    function self.Update()

        local outputSVG = ""
        local yieldCounter = 0
        for k,v in pairs(self.Models) do
            local modelSVG = [[<svg height="]]..internals.ScreenHeight..[[" width="]]..internals.ScreenWidth..[[" style="fill:#949494;stroke:#949494;stroke-width:1;opacity:0.2">]]

            local modelRelativePosition = vec3(v.Position.x-internals.CameraPosition.x, v.Position.y-internals.CameraPosition.y, v.Position.z-internals.CameraPosition.z)
            if modelRelativePosition:len() < internals.FarClip then

                for i,triangle in pairs(v.Triangles) do
                    local screenCoords1 = projectVertex(v.ComputedVerticies[triangle[1]])
                    local screenCoords2 = projectVertex(v.ComputedVerticies[triangle[2]])
                    local screenCoords3 = projectVertex(v.ComputedVerticies[triangle[3]])

                    modelSVG = modelSVG..[[<g><polygon points="]]..screenCoords1.x..","..screenCoords1.y.." "..screenCoords2.x..","..screenCoords2.y.." "..screenCoords3.x..","..screenCoords3.y.." "..[["/></g>]]
                    
                    yieldCounter = yieldCounter + 1
                    if yieldCounter > 50 then
                        coroutine.yield(false)
                        yieldCounter = 0
                    end

                end

            end

            modelSVG = modelSVG.."</svg>"
            outputSVG = outputSVG..modelSVG
        end

        coroutine.yield(true, outputSVG)
    end

    function self.Render(cameraPosition, cameraTarget, worldUp)
        if internals.RenderThread == nil then
            internals.CameraPosition = cameraPosition
            internals.CameraTarget = cameraTarget
            internals.WorldUp = worldUp
    
            updateCameraMatrix()

            internals.RenderThread = coroutine.create(self.Update)
            coroutine.resume(internals.RenderThread)
        else
            local renderThreadStatus = coroutine.status(internals.RenderThread)
            if renderThreadStatus == "suspended" then
                local ignore, status, svg = coroutine.resume(internals.RenderThread)
                if status == true then
                    internals.RenderThread = nil
                    internals.SVG = svg
                end
            end
        end

        --internals.RenderTarget.clear()
        if internals.RenderTarget == nil then 
            screen.print("Render target is null")
        else
            internals.RenderTarget.setHTML(internals.SVG)
        end
        
    end

    function self.SetRenderTarget(screen)
        if screen.getElementClass() ~= "ScreenUnit" then 
            error("Render Target must be a screen") 
            return
        end
        internals.RenderTarget = screen
    end

    function self.AddModel(model)
        self.Models[model.Name] = model
    end


    return self
end)()


--local planetModel = Model("Alioth", vec3(-8,-8,-126303), 126456, icoSphere)
local planetModelSmall = Model("Alioth", core.getConstructWorldPos()+vec3(0,10,0), 10, icoSphere)
Renderer.AddModel(planetModelSmall)
Renderer.SetRenderTarget(screen)

--[[ Update method :

local camPos = vec3(core.getConstructWorldPos())

local camTarget = vec3(core.getConstructWorldOrientationForward())
camTarget.x = camTarget.x*10 + camPos.x
camTarget.y = camTarget.y*10 + camPos.y
camTarget.z = camTarget.z*10 + camPos.z

local camUp = vec3(core.getConstructWorldOrientationUp())
Renderer.Render(camPos, camTarget, camUp)

]]