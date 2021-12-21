--@class UI

local template = require("pl/template")
local vec2 = require("cpml/vec2")
---@diagnostic disable-next-line: different-requires
local typeof = require("pl/types").type

---@class UIAnchor UI Anchoring type.
UIAnchor = (function()
    ---@class UIAnchor UI Anchoring type.
    local this = {}
    setmetatable(this, {_name = "UIAnchor"})

    ---Set origin to top left.
    this.TopLeft = function (pos, width, height)
        return pos
    end

    ---Set origin to top center.
    this.TopCenter = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.x = retn.x - (width * 0.5)
        return retn
    end

    ---Set origin to top right.
    this.TopRight = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.x = retn.x - width
        return retn
    end

    ---Set origin to middle left.
    this.MiddleLeft = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.y = retn.y - (height * 0.5)
        return retn
    end
    
    ---Set origin to middle center.
    this.Middle = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.x = retn.x - (width * 0.5)
        retn.y = retn.y - (height * 0.5)
        return retn
    end

    ---Set origin to middle right.
    this.MiddleRight = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.x = retn.x - width
        retn.y = retn.y - (height * 0.5)
        return retn
    end

    ---Set origin to bottom left.
    this.BottomLeft = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.y = retn.y - height
        return retn
    end

    ---Set origin to bottom center.
    this.BottomCenter = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.x = retn.x - (width * 0.5)
        retn.y = retn.y - height
        return retn
    end

    ---Set origin to bottom right.
    this.BottomRight = function (pos, width, height)
        local retn = vec2(pos.x, pos.y)
        retn.x = retn.x - width
        retn.y = retn.y - height
        return retn
    end
    return this
end)()

---@class UIObject Base UI object class.
---@param x number Screen X position.
---@param y number Screen Y position.
---@param width number Object width.
---@param height number Object height.
---@param content string Default content of the object.
UIObject = function(x, y, width, height, content)
    ---@class UIObject Base UI object class.
    local this = {}
    setmetatable(this, {_name = "UIObject"})
    this.Enabled = true
    this.Name = nil
    this.AlwaysDirty = false

    this.Position = vec2(x or 0, y or 0)
    this.Offset = vec2(0, 0)

    this.Width = width or 0
    this.Height = height or 0
    this.Zindex = 0
    this.Padding = 0
    this.Class = ""
    this.Style = ""

    this.Parent = nil
    this.Children = {}
    this.Content = content or ""
    this.IsDirty = true
    this.IsHovered = false
    this.IsPressed = false
    this.Anchor = UIAnchor.TopLeft
    this.IsClickable = true

    this.UI = nil
    this.Horizon = Horizon

    this.GUID =
        (function()
        local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        return string.gsub(
            template,
            "[xy]",
            function(c)
                local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
                return string.format("%x", v)
            end
        )
    end)()

    this._wrapStart = ""
    this._wrapEnd = ""

    local buffer = ""

    function this.Contains(pos)
        local selfPos = this.GetAbsolutePos()
        selfPos.x = selfPos.x + this.Padding
        selfPos.y = selfPos.y + this.Padding

        if pos.x >= selfPos.x and pos.x <= selfPos.x + this.Width and pos.y >= selfPos.y and
            pos.y <= selfPos.y + this.Height
        then
            return true
        end
        return false
    end

    function this.IsEnabled()
        if not this.UI then return false end
        if this.Parent then
            return this.Enabled and this.Parent.IsEnabled()
        end
        return this.Enabled
    end

    function this.GetAbsolutePos()
        local pos = this.Position + this.Offset
        if this.Parent then
            pos = pos + this.Parent.GetAbsolutePos()
            local pad = this.UI.TransformSize(this.Parent.Padding)
            pos = pos + pad
        end
        return this.Anchor(pos, this.Width, this.Height)
    end

    function this._update()
        if not this.Enabled then return end

        if this.Contains(this.UI.MousePos) then
            if not this.IsHovered then
                this.IsHovered = true
                this.IsDirty = true
                this.OnEnter(this)
            end
            this.IsDirty = true
        else
            if this.IsHovered then
                this.IsHovered = false
                this.IsDirty = true
                this.OnLeave(this)
            end
        end
        this.OnUpdate(this)

        for _, v in ipairs(this.Children) do
            if v.UI == nil then v.UI = this.UI or this.Parent.UI end
            v._update()
        end
    end

    function this.AddChild(child)
        if typeof(child) ~= "UIObject" then
            error("Trying to add a non-UIObject")
            return
        end
        for k, v in ipairs(this.Children) do
            if v.GUID == child.GUID then
                error(v.GUID .. " is already a child of " .. this.GUID)
                return
            end
        end
        child.Parent = this
        child.UI = this.UI
        child.Zindex = this.Zindex + 1
        table.insert(this.Children, child)
    end

    function this.RemoveChild(child)
        if typeof(child) ~= "UIObject" then
            error("Trying to remove a non-UIObject")
            return
        end
        for k, v in ipairs(this.Children) do
            if v.GUID == child.GUID then
                v.UI = nil
                v.Parent = nil
                table.remove(this.Children, k)
                v.Offset = {
                    X = v.Offset.x,
                    Y = v.Offset.y
                }
                return
            end
        end
        error(child.GUID .. " is not a child of " .. this.GUID)
    end

    function this.OnUpdate(scope)
    end
    function this.OnEnter(scope)
    end
    function this.OnLeave(scope)
    end
    function this.OnPress(scope)
    end
    function this.OnRelease(scope)
    end
    function this.OnClick(scope)
    end
    function this.OnScroll(scope, delta)
    end
    function this.Render(scope)
        if not this.Enabled then return "" end
        local anyDirty = scope.IsDirty
        for i=1, #scope.Children do
            local child = scope.Children[i]
            if child.AlwaysDirty or child.IsDirty then
                anyDirty = true
                break
            end
        end
        if scope.AlwaysDirty or anyDirty then
            buffer = {}
            buffer[1] = template.substitute(scope._wrapStart .. scope.Content .. scope._wrapEnd, scope)
            for i=1, #scope.Children do
                local child = scope.Children[i]
                buffer[i+1] = child.Render(child)
            end
            buffer = table.concat(buffer)
            scope.IsDirty = false
        end
        return buffer
    end

    return this
end

---@class UIPanel:UIObject A basic UI panel.
UIPanel = function(x, y, width, height, content)
    ---@class UIPanel:UIObject A basic UI panel.
    local this = UIObject(x, y, width, height, content)
    this._wrapStart =
        [[<panel style="position:absolute;left:$(GetAbsolutePos().x)vw;top:$(GetAbsolutePos().y)vh;width:$(Width)vw;height:$(Height)vh;z-index:$(Zindex);$(Style)" class="$(Class)">]]
    this._wrapEnd = [[</panel>]]
    return this
end

UIExpandable = function(x, y, content)
    local this = UIPanel(x, y, 0, 0, content)
    this.Width = 0
    this.Height = 0

    local baseUpdate = this._update

    function this._update()
        local maxHeight = 0
        local maxWidth = 0
        for k, v in ipairs(this.Children) do
            local w = v.Position.x + v.Width
            local h = v.Position.y + v.Height
            if w > maxWidth then
                maxWidth = w
                this.IsDirty = true
            end
            if h > maxHeight then
                maxHeight = h
                this.IsDirty = true
            end
        end
        if this.IsDirty then
            local pad = this.UI.TransformSize(this.Padding) * 2
            this.Width = maxWidth + pad.x
            this.Height = maxHeight + pad.y
        end
        baseUpdate()
    end

    return this
end

UIFillHorizontal = function(x, y, width, height, content)
    local this = UIPanel(x, y, width, height, content)

    local baseUpdate = this._update
    function this._update()
        if this.Parent then
            local desired = this.Parent.Width - (this.Parent.Padding * 2)
            if this.Width ~= desired then
                this.Width = this.Parent.Width - (this.Parent.Padding * 2)
                this.IsDirty = true
            end
        end
        baseUpdate()
    end

    return this
end

UIButton = function(x, y, width, height, content)
    local this = UIPanel(x, y, width, height, content)
    this.Class = "button"
    this.OnEnter = function (ref) ref.Class = ref.Class .. " hover" ref.IsDirty = true end
    this.OnLeave = function (ref) ref.Class = ref.Class:gsub(" hover", "") ref.IsDirty = true end
    return this
end

UILabel = function(x, y, width, height, content)
    local this = UIPanel(x, y, width, height, content)
    this._wrapStart = [[<uilabel style="position:absolute;left:$(GetAbsolutePos().x)vw;top:$(GetAbsolutePos().y)vh;width:$(Width)vw;height:$(Height)vh;z-index:$(Zindex);$(Style)" class="$(Class)">]]
    this._wrapEnd = [[</uilabel>]]
    return this
end

UIHeading = function(x, y, width, height, content)
    local this = UIPanel(x, y, width, height, content)
    this._wrapStart = [[<uiheading style="position:absolute;left:$(GetAbsolutePos().x)vw;top:$(GetAbsolutePos().y)vh;width:$(Width)vw;height:$(Height)vh;z-index:$(Zindex);$(Style)" class="$(Class)">]]
    this._wrapEnd = [[</uiheading>]]
    return this
end

UICheckbox = function(x, y, width, height)
    local this = UIPanel(x, y, width, height)
    this._wrapStart = [[<uicheckbox style="position:absolute;left:$(GetAbsolutePos().x)vw;top:$(GetAbsolutePos().y)vh;width:$(Width)vw;height:$(Height)vh;z-index:$(Zindex);$(Style)" class="$(Class)">]]
    this._wrapEnd = [[</uicheckbox>]]
    this.Style = "opacity: 0.75"
    this.Value = false
    this.AlwaysDirty = true
    function this.OnEnter()
        this.Style = "opacity: 0.95"
        this.IsDirty = true
    end
    function this.OnLeave()
        this.Style = "opacity: 0.75"
        this.IsDirty = true
    end
    function this.OnClick()
        this.Value = not this.Value
        this.IsDirty = true
    end
    local baseUpdate = this._update
    function this._update()
        baseUpdate()
        if this.Value then
            this.Class = "checked"
        else
            this.Class = ""
        end
    end
    return this
end

UIProgressVertical = function(x, y, width, height)
    local this = UIPanel(x, y, width, height)
    this.Value = 100
    this.Class = "prog-bar"
    this.BarStyle = ""
    this.BarColor = "var(--primary)"
    this._wrapStart = [[<uivprogress style="position:absolute;left:$(GetAbsolutePos().x)vw;top:$(GetAbsolutePos().y)vh;width:$(Width)vw;height:$(Height)vh;z-index:$(Zindex);$(Style)" class="$(Class)"><inner style="height:$(Value)%;background-color:$(BarColor);box-shadow:0 0 0.25vw 0.05vw $(BarColor);$(BarStyle)">]]
    this._wrapEnd = [[</inner></uivprogress>]]

    return this
end

UICore = function(adapter, CSS)
    local this = {}
    setmetatable(this, {__call = function(ref, ...) ref.Update(...) end, _name = "UICore" })
    this.Tags = "hud,core"
    this.Config = adapter.Config
    this.Widgets = {}
    this.CSS = CSS
    this.Adapter = adapter

    local header = ""
    if this.CSS then
        header = "<style>" .. this.CSS .. "</style>"
    end

    this.MousePos = vec2(this.Config.ScreenSize.x * 0.5, this.Config.ScreenSize.y * 0.5)

    system.showScreen(1)

    function this.TransformSize(size)
        return vec2(size, size + ((size / this.Config.ScreenSize.y) * 1000))
    end

    function this.Update(eventType, deltaTime)
        this.MousePos = this.Adapter.GetMouse()

        local buffer = header .. [[<div id="horizon">]]
        for i=1,#this.Widgets do
            local widget = this.Widgets[i]
            widget._update()
            buffer = buffer .. widget.Render(widget)
        end
        this.Adapter.Set(buffer .. "</div>")
    end

    local function getContained(objArray, targetArr, pos)
        if not targetArr then
            targetArr = {}
        end
        for _, v in ipairs(objArray) do
            if v.IsEnabled() and v.IsClickable and v.Contains(pos or this.MousePos) then
                table.insert(targetArr, v)
            end
            if #v.Children > 0 then
                getContained(v.Children, targetArr)
            end
        end
        return targetArr
    end

    function this.Click(pos)
        local contained = getContained(this.Widgets, nil, pos)
        local top = nil
        for _, v in ipairs(contained) do
            if not top or top.Zindex < v.Zindex and v.IsEnabled() then
                top = v
            end
        end
        if top then
            top.OnClick(top)
        end
        return top
    end

    function this.AddWidget(widget)
        if typeof(widget) ~= "UIObject" then
            return
        end
        for k, v in ipairs(this.Widgets) do
            if v.GUID == widget.GUID then
                return
            end
        end
        widget.UI = this
        table.insert(this.Widgets, widget)
        return widget
    end

    function this.RemoveWidget(widget)
        if typeof(widget) ~= "UIObject" then
            return
        end
        for k, v in ipairs(this.Widgets) do
            if v.GUID == widget.GUID then
                v.UI = nil
                table.remove(this.Widgets, k)
                return k
            end
        end
    end

    -- fixes for template builtin
    debug = {traceback = traceback}
    plutils.load = function(code, name, mode, env)
        local err, fn = pcall(load(code, nil, "t", env))
        return function()
            return fn
        end, err
    end

    return this
end

DisplayAdapter = function(slot)
    local this = {}
    setmetatable(this, { _name = "DisplayAdapter" })
    this.Slot = slot

    this.Config = {
        EnableMouse = true,
        MouseSensitivity = 1.2,
        ScreenSize = vec2(2560, 1440)
    }
    this.Enable = function() end
    this.Disable = function() end
    this.Set = function(content) end
    this.GetMouse = function() end
    return this
end

SystemDisplay = (function(system)
    local this = DisplayAdapter(system)
    this.Config = {
        EnableMouse = true,
        MouseSensitivity = 1.5,
        ScreenSize = vec2(system.getScreenWidth(), system.getScreenHeight())
    }
    this.Config.MousePos = vec2(this.Config.ScreenSize.x * 0.5, this.Config.ScreenSize.y * 0.5)
    this.Name = "System"
    this.Enable = function() system.showScreen(1) end
    this.Disable = function() system.showScreen(0) end
    this.Set = function(content) system.setScreen(content) end
    local mousePos = vec2(50,50)
    local function xform(pos)
        return vec2((pos.x / this.Config.ScreenSize.x) * 100, (pos.y / this.Config.ScreenSize.y) * 100)
    end

    local function processMouse(x, y)
        mousePos = mousePos + (vec2(x, y) * this.Config.MouseSensitivity)
        if mousePos.x < 0 then
            mousePos.x = 0
        end
        if mousePos.x > this.Config.ScreenSize.x then
            mousePos.x = this.Config.ScreenSize.x
        end
        if mousePos.y < 0 then
            mousePos.y = 0
        end
        if mousePos.y > this.Config.ScreenSize.y then
            mousePos.y = this.Config.ScreenSize.y
        end
        return xform(mousePos)
    end
    this.GetMouse = function()
        return processMouse(system.getMouseDeltaX(), system.getMouseDeltaY())
    end
    return this
end)(system)

ScreenDisplay = function(screen)
    local this = DisplayAdapter(screen)
    this.Config = {
        EnableMouse = true,
        MouseSensitivity = 1,
        ScreenSize = vec2(1920, 1080)
    }
    local mousePos = vec2(50,50)
    this.Name = "Screen"
    this.Enable = function() screen.enable() end
    this.Disable = function() screen.disable() end
    this.Set = function(content) screen.setHTML(content) end
    this.Click = function(x, y) end
    this.GetMouse = function()
        mousePos.x = screen.getMouseX() * 100
        mousePos.y = screen.getMouseY() * 100
        return mousePos
    end
    return this
end
