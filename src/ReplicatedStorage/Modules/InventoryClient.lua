local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Use bounded waits with assertions for required dependencies
local GuiUtil = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GuiUtil"))

local modulesFolder = GuiUtil.BoundWait(ReplicatedStorage, "Modules")
local uiControllerModule = GuiUtil.BoundWait(modulesFolder, "UIController")
local ok, UIController = pcall(require, uiControllerModule)
assert(ok, "Failed to load UIController module: " .. tostring(UIController))

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
