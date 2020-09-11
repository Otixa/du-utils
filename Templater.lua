Templater = (function()
    local this = {}

    debug = {traceback = traceback}
    plutils.load = function(code, name, mode, env)
        local err, fn = pcall(load(code, nil, "t", env))
        return function() return fn end, err
    end

    this.Templater = require('pl/template')

    function this.Fill(content, scope)
        local subs, err = this.Templater.substitute(content, scope)
        if err then error(err) end
        return subs
    end

    return this
end)()