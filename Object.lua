--!strict
local object = {}

object.new = function(md: any)
	return setmetatable({}, {
		__index = function(_, methodName: string)
			return function(...)
				return md:dispatch(methodName, ...)
			end
		end
	})
end

return object