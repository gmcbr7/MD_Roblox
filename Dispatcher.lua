--!strict
local types = require(script.Parent.Types)
local matcher = require(script.Parent.Matcher)
local utils = require(script.Parent.Utils)

type matchSpec = types.matchSpec

local dispatcher = {}

local hierarchy = require(script.Parent.Hierarchy)

--// Object responsible for dispatching the functions based on type, its the main handler of evezrything
--// Tried not to use indexing to avoid the overhead

-- TODO for v2: make it work by passing argument, followed by type, if no type is passed, argument is "any". i.e: {{arg1 = 3}, {arg2}} -> "number", "any"
function dispatcher.new()
	local self = {}
	self.hashes= {}
	self.patterns = {}
	self.hierarchy = hierarchy.new()
	
	function self:setHierarchy(childType: string, parentType: string)
		self.hierarchy:setParent(childType, parentType)
	end
	
	function self:register(specs: {any}, func: (any) -> any)
		local normalizedSpecs = {}
		local hasTypeMatch = false
		
		for _, spec in specs do
			local normalized = matcher.normalizeSpec(spec)
			table.insert(normalizedSpecs, normalized)
			if normalized.mode == "type" then
				hasTypeMatch = true
			end
		end
		
		if hasTypeMatch then
			table.insert(self.patterns, {
				specs = normalizedSpecs,
				func = func
				
			})
		else
			local hashKey = matcher.createHashKey(normalizedSpecs)
			if hashKey then
				self.hashes[hashKey] = {
					specs = normalizedSpecs,
					func = func
					
				}
			else
				table.insert(self.patterns, {
					specs = normalizedSpecs,
					func = func
					
				})
			end
		end
		
	end

	local newMeta = {
		
		__call = function(_, ...) 
			local funcArg = {...}
			local runtimeKey = matcher.createRuntimeKey(funcArg)
			local hashMatch = self.hashes[runtimeKey]
			
			if hashMatch then
				return hashMatch.func(...)
			end
			
			local valueMatch = nil
			local typeMatch = nil
			local anyMatch = nil
			
			for _, pattern in self.patterns do
				if #pattern.specs ~= #funcArg then
					continue
				end
				local allMatch = true
				local hasValue = false
				local hasAny = false
				for num, spec in pattern.specs do
					if not matcher.matches(funcArg[num], spec, self.hierarchy) then
						allMatch = false
						break
					end
					
					if spec.mode == "value" then
						hasValue = true
					elseif spec.mode == "any" then
						hasAny = true
					end
					
				end
				if allMatch then
					if hasValue and not valueMatch then
						valueMatch = pattern
						
					elseif not hasValue and not hasAny and not typeMatch then
						typeMatch = pattern
					elseif hasAny and not anyMatch then
						anyMatch = pattern
					end
				end
			end
			
			if valueMatch then
				return valueMatch.func(...)
			elseif typeMatch then
				return typeMatch.func(...)
			elseif anyMatch then
				return anyMatch.func(...)
			end
			
			local typeKey = {}
			
			for _, arg in funcArg do
				table.insert(typeKey, utils.getArgType(arg))
			end
			warn("no dispatch found")
		end
		
	}

	return setmetatable(self, newMeta)
end

return dispatcher
