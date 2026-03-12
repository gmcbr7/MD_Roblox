--!strict
local dispatcher = require('./Dispatcher')
local object = require('./Object')

local scopeHandler = {}
local scopes: {[string]: any} = {}
local defaultGlobal = "GLOBAL"

scopeHandler.scope = function(scopeName: string?)
	local name = scopeName or defaultGlobal
	if not scopes[name] then
		scopes[name] = dispatcher.new()
	end
	return scopes[name]
end

scopeHandler.object = function(scopeNameOrDispatcher: any)
	local md
	if typeof(scopeNameOrDispatcher) == "string" or scopeNameOrDispatcher == nil then
		md = scopeHandler.scope(scopeNameOrDispatcher)
	else
		md = scopeNameOrDispatcher
	end
	return object.new(md)
end

return scopeHandler