--!strict
local matcher = require('./Matcher')
local utils = require('./Utils')
local hierarchy = require('./Hierarchy')

--// Object responsible for dispatching the functions based on type, its the main handler of everything
-- TODO for v2: make it work by passing argument, followed by type, if no type is passed, argument is "any". i.e: {{arg1 = 3}, {arg2}} -> "number", "any"

local dispatcher = {}
dispatcher.__index = dispatcher

local function resolveBucket(bucket: any, funcArg: {any}, hier: any): ((any) -> any)?
	local runtimeKey = matcher.createRuntimeKey(funcArg)
	local hashMatch = bucket.hashes[runtimeKey]
	if hashMatch then
		return hashMatch.func
	end

	local bestMatch = nil
	local bestScore = -1

	for _, pattern: any in bucket.patterns do
		if #pattern.specs ~= #funcArg then
			continue
		end

		local allMatch = true
		local score = 0

		for num, spec in pattern.specs do
			if not matcher.matches(funcArg[num], spec, hier) then
				allMatch = false
				break
			end
			if spec.mode == "value" then
				score += 3
			elseif spec.mode == "type" then
				score += 2
			elseif spec.mode == "any" then
				score += 1
			end
		end

		if allMatch and score > bestScore then
			bestScore = score
			bestMatch = pattern
		end
	end

	if bestMatch then
		return bestMatch.func
	end

	return nil
end

local function registerToBucket(bucket: any, specs: {any}, func: (any) -> any)
	local normalizedSpecs = {}
	local allType = true

	for _, spec in specs do
		local normalized = matcher.normalizeSpec(spec)
		table.insert(normalizedSpecs, normalized)
		if normalized.mode ~= "type" then
			allType = false
		end
	end

	if allType then
		local hashKey = matcher.createHashKey(normalizedSpecs)
		if hashKey then
			bucket.hashes[hashKey] = {
				specs = normalizedSpecs,
				func = func
			}
			return
		end
	end

	table.insert(bucket.patterns, {
		specs = normalizedSpecs,
		func = func
	})
end

dispatcher.setHierarchy = function(self: any, childType: string, parentType: string)
	self.hierarchy:setParent(childType, parentType)
end

dispatcher.register = function(self: any, nameOrSpecs: any, specsOrFunc: any, func: any)
	local name : string?, specs: {any}, fn: (any) -> any

	if typeof(nameOrSpecs) == "string" then
		name = nameOrSpecs
		specs = specsOrFunc
		fn = func
	else
		name = nil
		specs = nameOrSpecs
		fn = specsOrFunc
	end

	if name then
		if not self.named[name] then
			self.named[name] = { hashes = {}, patterns = {} }
		end
		registerToBucket(self.named[name], specs, fn)
	else
		registerToBucket(self.unnamed, specs, fn)
	end
end

dispatcher.dispatch = function(self: any, name: string, ...)
	local bucket = self.named[name]
	if not bucket then
		error("no dispatch found for method: " .. name)
	end

	local funcArg = {...}
	local fn = resolveBucket(bucket, funcArg, self.hierarchy)

	if fn then
		return fn(...)
	end

	local typeNames = {}
	for _, arg in funcArg do
		table.insert(typeNames, utils.getArgType(arg))
	end
	error("no dispatch found for " .. name .. "(" .. table.concat(typeNames, ", ") .. ")")
end

dispatcher.new = function()
	local self = {
		named = {},
		unnamed = { hashes = {}, patterns = {} },
		hierarchy = hierarchy.new()
	}

	setmetatable(self, {
		__index = dispatcher,
		__call = function(_, ...)
			local funcArg = {...}
			local fn = resolveBucket(self.unnamed, funcArg, self.hierarchy)

			if fn then
				return fn(...)
			end

			local typeNames = {}
			for _, arg in funcArg do
				table.insert(typeNames, utils.getArgType(arg))
			end
			error("no dispatch found for (" .. table.concat(typeNames, ", ") .. ")")
		end
	})

	return self
end

return dispatcher