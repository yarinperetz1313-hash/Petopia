diff --git a//dev/null b/src/ReplicatedStorage/Modules/UIController.lua
index 0000000000000000000000000000000000000000..ca52afd5304b30a9cdef11d58885a6ca0fd38add 100644
--- a//dev/null
+++ b/src/ReplicatedStorage/Modules/UIController.lua
@@ -0,0 +1,18 @@
+--[[
+    UIController.lua
+    Centralised collection of BindableEvents used for client <-> client
+    communication between user interface systems.  Each event is wrapped
+    in a table for organised access.
+--]]
+
+local UIController = {}
+
+UIController.Events = {
+    ToggleInventory = Instance.new("BindableEvent"),
+    ToggleShop = Instance.new("BindableEvent"),
+    ToggleSettings = Instance.new("BindableEvent"),
+    ToggleMenu = Instance.new("BindableEvent"),
+}
+
+return UIController
+
