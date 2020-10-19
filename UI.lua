UIObject = function(x, y, width, height, content)
    local this = {}
    local vec2 = require("cpml/vec2")
    local typeof = require("pl/types").type
    setmetatable(this, {_name = "UIObject"})
    this.Enabled = false
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
    this.Anchoring = {
        TopLeft = false,
        TopRight = false,
        BottomLeft = false,
        BottomRight = false
    }
    this.IsClickable = true

    this.UI = nil
    this.Horizon = Horizon

    this.GUID =
        (function()
        math.randomseed(system.getTime() * 1000000)
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

    function this.GetAbsolutePos()
        local pos = this.Position + this.Offset
        if this.Parent then
            pos = pos + this.Parent.GetAbsolutePos()
            local pad = this.UI.TransformSize(this.Parent.Padding)
            pos = pos + pad
        end
        return pos
    end

    function this._update()
        if this.Parent ~= nil then
        -- Recalc pos,size based on anchoring, set IsDirty if changed
        end
        
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
                error(v.GUID .. " is already a child of" .. this.GUID)
                return
            end
        end
        child.Parent = this
        child.UI = this.UI
        this.Children[#this.Children + 1] = child
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
        error(v.GUID .. " is not a child of" .. this.GUID)
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
        local anyDirty = scope.IsDirty
        for k, v in ipairs(scope.Children) do
            if v.AlwaysDirty or v.IsDirty then
                anyDirty = true
                break
            end
        end
        if scope.AlwaysDirty or anyDirty then
            buffer = template.substitute(scope._wrapStart .. scope.Content .. scope._wrapEnd, scope)
            for k, v in ipairs(scope.Children) do
                buffer = buffer .. v.Render(v)
            end
            scope.IsDirty = false
        end
        return buffer
    end

    return this
end

UIPanel = function(x, y, width, height, content)
    local this = UIObject(x, y, width, height, content)
    this._wrapStart =
        [[<panel style="position:absolute;left:$(GetAbsolutePos().x)vw;top:$(GetAbsolutePos().y)vh;width:$(Width)vw;height:$(Height)vh;z-index:$(Zindex);$(Style)" class="$(Class)">]]
    this._wrapEnd = [[</panel>]]
    return this
end

UIExpandable = function(x, y, content)
    local this = UIPanel(x, y, width, height, content)
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

UICore = function(adapter, CSS)
    local template = require("pl/template")
    local this = {}
    setmetatable(this, {__call = function(ref, ...) ref.Update(...) end, _name = "UICore" })
    local vec2 = require("cpml/vec2")
    local typeof = require("pl/types").type
    this.Tags = "hud,core"
    this.Config = adapter.Config
    this.Widgets = {}
    this.CSS = CSS or ""
    this.Adapter = adapter

    local header = ""
    if this.CSS then
        header = "<style>" .. this.CSS .. "</style>"
    end

    this.MousePos = vec2(this.Config.ScreenSize.x * 0.5, this.Config.ScreenSize.y * 0.5)

    system.showScreen(1)
    system.freeze(1)
    Horizon.Controller.hide()

    function contains(obj, pos)
        if pos.x > obj.x and pos.x < obj.x + obj.Width and pos.y > obj.y and pos.y < obj.y + obj.Height then
            return true
        end
        return false
    end

    function this.TransformSize(size)
        return vec2(size, size + ((size / this.Config.ScreenSize.y) * 1000))
    end

    function this.Update(eventType, deltaTime)
        this.MousePos = this.Adapter.GetMouse()
        local buffer = header .. [[<div id="horizon">]]
        for k, v in ipairs(this.Widgets) do
            v._update()
            buffer = buffer .. v.Render(v)
        end
        this.Adapter.Set(buffer .. "</div>")
    end

    local function getContained(objArray, targetArr)
        if not targetArr then
            targetArr = {}
        end
        for _, v in ipairs(objArray) do
            if v.Contains(this.MousePos) and v.IsClickable then
                table.insert(targetArr, v)
            end
            if #v.Children > 0 then
                getContained(v.Children, targetArr)
            end
        end
        return targetArr
    end

    function this.Click()
        local contained = getContained(this.Widgets)
        local top = nil
        for _, v in ipairs(contained) do
            if not top or top.Zindex < v.Zindex then
                top = v
            end
        end
        if top then
            top.OnClick(top)
        end
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
    end

    function this.RemoveWidget(widget)
        if typeof(widget) ~= "UIObject" then
            return
        end
        for k, v in ipairs(this.Widgets) do
            if v.GUID == widget.GUID then
                v.UI = nil
                table.remove(this.Widgets, k)
                return
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
    local vec2 = require("cpml/vec2")
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
    local vec2 = require("cpml/vec2")
    this.Config = {
        EnableMouse = true,
        MouseSensitivity = 1.2,
        ScreenSize = vec2(2560, 1440)
    }
    this.Config.MousePos = vec2(this.Config.ScreenSize.x * 0.5, this.Config.ScreenSize.y * 0.5)
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
    local vec2 = require("cpml/vec2")
    this.Config = {
        EnableMouse = true,
        MouseSensitivity = 1,
        ScreenSize = vec2(1920, 1080)
    }
    local mousePos = vec2(50,50)
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
