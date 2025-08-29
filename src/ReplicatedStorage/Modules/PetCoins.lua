local PetCoins = {}

local DataStoreService = game:GetService("DataStoreService")
local coinStore = DataStoreService:GetDataStore("PetCoinsStore")

function PetCoins.Get(player)
	local success, coins = pcall(function()
		return coinStore:GetAsync(player.UserId) or 0
	end)
	if success then
		return coins
	else
		return 0
	end
end

function PetCoins.Set(player, amount)
	pcall(function()
		coinStore:SetAsync(player.UserId, amount)
	end)
end

function PetCoins.Add(player, amount)
	local current = PetCoins.Get(player)
	PetCoins.Set(player, current + amount)
end

return PetCoins
