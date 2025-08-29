local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Use explicit waits and error handling to locate dependencies
local modulesFolder = ReplicatedStorage:WaitForChild("Modules", 5)
assert(modulesFolder, "Missing Modules folder in ReplicatedStorage")

local GuiUtil = require(modulesFolder:WaitForChild("GuiUtil", 5))
assert(GuiUtil, "GuiUtil module is missing")

local uiControllerModule = GuiUtil.BoundWait(modulesFolder, "UIController")
local ok, UIController = pcall(require, uiControllerModule)
if not ok then
    error("Failed to load UIController module: " .. tostring(UIController))
end

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