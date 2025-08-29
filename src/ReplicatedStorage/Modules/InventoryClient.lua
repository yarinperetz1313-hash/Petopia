local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIController = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIController"))

local InventoryClient = {}
local items = {}
local listeners = {}

local function fireChanged()
    for _, fn in ipairs(listeners) do
        fn(items)
    end
end

function InventoryClient.GetItems()
    return items
end

function InventoryClient.OnChanged(fn)
    table.insert(listeners, fn)
end

UIController.On("AddToInventory", function(item)
    table.insert(items, item)
    fireChanged()
end)

function InventoryClient.Set(itemsTable)
    items = itemsTable or {}
    fireChanged()
end

return InventoryClient