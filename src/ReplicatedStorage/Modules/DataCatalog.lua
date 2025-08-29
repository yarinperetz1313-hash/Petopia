local DataCatalog = {}

local items = {
    puppy   = {id = "puppy",   name = "Puppy",         price = 100, type = "Pet",     rarity = "Common", available = true},
    kitten  = {id = "kitten",  name = "Kitten",        price = 150, type = "Pet",     rarity = "Common", available = true},
    hamster = {id = "hamster", name = "Hamster",       price = 75,  type = "Pet",     rarity = "Common", available = true},
    potion  = {id = "potion",  name = "Healing Potion",price = 50,  type = "Item",    available = true},
    treat   = {id = "treat",   name = "Pet Treat",     price = 25,  type = "Item",    available = true},
    slot    = {id = "slot",    name = "Extra Slot",    price = 500, type = "Upgrade", available = true},
    speed   = {id = "speed",   name = "Pet Speed",     price = 300, type = "Upgrade", available = true},
}

local function clone(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

function DataCatalog.GetItem(id)
    local item = items[id]
    if item and item.available ~= false then
        return clone(item)
    end
    return nil
end

return DataCatalog