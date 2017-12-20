local game = {}

local enum = hw.getInfo()

print('===== enumerate hardware ====')

for k0, v0 in pairs(enum) do
	print(k0, v0)
	if type(v0) == 'table' then
		for k1, v1 in pairs(v0) do
			print(' ', k1, v1)
			if type(v1) == 'table' then
				for k2, v2 in pairs(v1) do
					print(' ', ' ', k2, v2)
					if type(v2) == 'table' then
						for k3, v3 in pairs(v2) do
							print(' ', ' ', ' ', k3, v3)
						end
					end
				end
			end
		end
	end
end

print('===== END OF enumerate hardware ====')

vpet.quit()

return game
