local game = {}

local enum = hw.getInfo()

local function hw2strings(enum, hwstrings, depth)
	enum = enum or hw.getInfo()
	hwstrings = hwstrings or {}
	depth = depth or 0
	if depth >= 5 then error('gone too deep') end
	local t = (' '):rep(depth)
	local s
	for k0, v0 in pairs(enum) do
		s = t .. tostring(k0)
		if type(v0) == 'table' then
			hwstrings[#hwstrings + 1] = s
			hw2strings(v0, hwstrings, depth + 1)
		else
			hwstrings[#hwstrings + 1] = s .. ' > ' .. tostring(v0)
		end
	end
	return hwstrings
end

print('===== enumerate hardware ====')

local hwstrings = hw2strings()

for i, v in ipairs(hwstrings) do
	print(v)
end

--[[
for k0, v0 in pairs(enum) do
	print(k0, v0)
	if type(v0) == 'table' then
		for k1, v1 in pairs(v0) do
			print('', k1, v1)
			if type(v1) == 'table' then
				for k2, v2 in pairs(v1) do
					print('', '', k2, v2)
					if type(v2) == 'table' then
						for k3, v3 in pairs(v2) do
							print('', '', '', k3, v3)
						end
					end
				end
			end
		end
	end
end
--]]

print('===== END OF enumerate hardware ====')

local offset = 0

local t = os.time()

function game.draw()
	draw.cls()
	for i, v in ipairs(hwstrings) do
		draw.text(v, 1, (i - 1) * 8 + math.floor(offset) * 8)
	end
end

function game:update(dt)
	if vpet.btn('down') then
		offset = offset - dt * 15
	end
	if vpet.btn('up') then
		offset = offset + dt * 15
	end
end

return game
