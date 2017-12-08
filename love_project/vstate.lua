local vstate = {}

vstate.__index = vstate

function vstate:new(o)
	o = o or {}
	self:setproxy(o)
	return o
end

return vstate
