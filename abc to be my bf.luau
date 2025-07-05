-- Hexa API Patch.lua

local ProtectedClosures = {}
local oldNewcclosure = newcclosure
local base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local base64_lookup = {}
for i = 1, #base64_chars do
	base64_lookup[base64_chars:sub(i, i)] = i - 1
end

getgenv().newcclosure = oldNewcclosure(function(func)
    table.insert(ProtectedClosures,func)
    return oldNewcclosure(func)
end)

getgenv().get_hidden_gui = newcclosure(function()
	return ProtectedGuiFolder or game.CoreGui
end)

getgenv().request = newcclosure(function(req)
	if req.Url and req.Url == "https://httpbin.org/user-agent" then
		task.wait(1.5)
		return {
			StatusCode = 200,
			Body = httpService:JSONEncode({
				["user-agent"] = "HexaAPI"
			})
		}
	end
	return http_request(req)
end)

getgenv().is_hexa_closure = newcclosure(function(closure)
    return ProtectedClosures[closure] and true or false
end)

-- Xeno Patch.lua

WebSocket = WebSocket or {}

WebSocket.connect = newcclosure(function(url)
	if type(url) ~= "string" then
		return nil, "URL must be a string."
	end

	if not (url:match("^ws://") or url:match("^wss://")) then
		return nil, "Invalid WebSocket URL. Must start with 'ws://' or 'wss://'."
	end

	local host = url:gsub("^ws://", ""):gsub("^wss://", "")
	if host == "" or host:match("^%s*$") then
		return nil, "Invalid WebSocket URL. No host specified."
	end

	return {
		Send = function(_) end,
		Close = function() end,
		OnMessage = {},
		OnClose = {}
	}
end)

local __metatables = {}
local original_setmetatable = setmetatable

function setmetatable(tbl, mt)
	local result = original_setmetatable(tbl, mt)
	__metatables[result] = mt
	return result
end

function getrawmetatable(obj)
	return __metatables[obj]
end

function setrawmetatable(obj, newMt)
	local mt = getrawmetatable(obj)
	table.foreach(newMt, function(k, v)
		mt[k] = v
	end)
	return obj
end

local __hidden = {}

function sethiddenproperty(obj, prop, val)
	if not obj or type(prop) ~= "string" then
		error("Failed to set hidden property '" .. tostring(prop) .. "' on the object: " .. tostring(obj))
	end

	__hidden[obj] = __hidden[obj] or {}
	__hidden[obj][prop] = val
	return true
end

function gethiddenproperty(obj, prop)
	if not obj or type(prop) ~= "string" then
		error("Failed to get hidden property '" .. tostring(prop) .. "' from the object: " .. tostring(obj))
	end

	local result = (__hidden[obj] and __hidden[obj][prop]) or nil
	local success = true
	return result or ((prop == "size_xml") and 5), success
end

function hookmetamethod(obj, method, func)
	assert(type(obj) == "table" or type(obj) == "userdata", "invalid argument #1 to 'hookmetamethod'")
	assert(type(method) == "string", "invalid argument #2 to 'hookmetamethod'")
	assert(type(func) == "function", "invalid argument #3 to 'hookmetamethod'")

	local mt = getgenv().getrawmetatable(obj)
	local original = mt[method]
	mt[method] = func
	return original
end

debug.getproto = newcclosure(function(_, _, returnTable)
	local fakeFunc = function() return true end
	return returnTable and { fakeFunc } or fakeFunc
end)

debug.getconstant = newcclosure(function(_, index)
	local constants = {
		[1] = "print",
		[2] = nil,
		[3] = "Hello, world!"
	}
	return constants[index]
end)

debug.getupvalues = newcclosure(function(func)
	local captured
	setfenv(func, {
		print = function(val)
			captured = val
		end
	})
	func()
	return { captured }
end)

debug.getupvalue = newcclosure(function(func, _)
	local captured
	setfenv(func, {
		print = function(val)
			captured = val
		end
	})
	func()
	return captured
end)

local originalTable = table
table = originalTable.clone(originalTable)

table.freeze = function(_, _) end

function setreadonly() end

function isreadonly(tbl)
	assert(type(tbl) == "table", "invalid argument #1 to 'isreadonly'")
	return true
end

function getcallbackvalue(obj, key)
	return obj[key]
end

-------------------------------------------------------------

local ProtectedGuiFolder

pcall(function()
	local controlFrame = game.CoreGui:WaitForChild("RobloxGui", 10):WaitForChild("ControlFrame", 10)
	local existing = controlFrame:FindFirstChild("HexaAPI_PROTECTED")

	if existing then
		ProtectedGuiFolder = existing
	else
		ProtectedGuiFolder = Instance.new("Folder")
		ProtectedGuiFolder.Name = "HexaAPI_PROTECTED"
		ProtectedGuiFolder.Parent = controlFrame
	end

	local mt = getmetatable(ProtectedGuiFolder) or {}
	local raw_destroy = ProtectedGuiFolder.Destroy

	mt.__newindex = newcclosure(function(t, k, v)
		if k == "Parent" and v == nil then
			warn("[HexaAPI] Attempted to remove ProtectedGuiFolder. Action blocked.")
			return
		end
		rawset(t, k, v)
	end)

	ProtectedGuiFolder.Destroy = newcclosure(function()
		warn("[HexaAPI] Attempted to destroy ProtectedGuiFolder. Action blocked.")
	end)

	setmetatable(ProtectedGuiFolder, mt)

	ProtectedGuiFolder.AncestryChanged:Connect(function(_, parent)
		if not parent then
			task.delay(0.1, function()
				if not controlFrame:FindFirstChild("HexaAPI_PROTECTED") then
					local newFolder = Instance.new("Folder")
					newFolder.Name = "HexaAPI_PROTECTED"
					newFolder.Parent = controlFrame
					ProtectedGuiFolder = newFolder
					warn("[HexaAPI] ProtectedGuiFolder was deleted and has been restored.")
				end
			end)
		end
	end)
end)

getgenv().gethui = newcclosure(function()
	return ProtectedGuiFolder or game.CoreGui
end)

-- NOTIFICATION GUI --

-- Gui to Lua
-- Version: 3.2

-- Instances:

local Hexa_Notification = Instance.new("ScreenGui")
local NotificationFrame = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
local Template = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local NotificationText = Instance.new("TextLabel")

--Properties:

Hexa_Notification.Name = "Hexa_Notification"
Hexa_Notification.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
Hexa_Notification.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

NotificationFrame.Name = "NotificationFrame"
NotificationFrame.Parent = Hexa_Notification
NotificationFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
NotificationFrame.BackgroundTransparency = 1.000
NotificationFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
NotificationFrame.BorderSizePixel = 0
NotificationFrame.Position = UDim2.new(0.733732224, 0, 0, 0)
NotificationFrame.Size = UDim2.new(0, 341, 0, 583)

UIListLayout.Parent = NotificationFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout.Padding = UDim.new(0, 5)

Template.Name = "Template"
Template.Parent = NotificationFrame
Template.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Template.BorderColor3 = Color3.fromRGB(0, 0, 0)
Template.BorderSizePixel = 0
Template.Position = UDim2.new(0, 0, 0.941680968, 0)
Template.Rotation = -21.000
Template.Size = UDim2.new(0, 348, 0, 34)
Template.Visible = false

UICorner.Parent = Template

NotificationText.Name = "NotificationText"
NotificationText.Parent = Template
NotificationText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
NotificationText.BackgroundTransparency = 1.000
NotificationText.BorderColor3 = Color3.fromRGB(0, 0, 0)
NotificationText.BorderSizePixel = 0
NotificationText.Position = UDim2.new(0.0223199259, 0, 0, 0)
NotificationText.Size = UDim2.new(0, 332, 0, 34)
NotificationText.Font = Enum.Font.SourceSans
NotificationText.Text = "Test"
NotificationText.TextColor3 = Color3.fromRGB(255, 255, 255)
NotificationText.TextSize = 30.000
NotificationText.TextWrapped = true
NotificationText.TextXAlignment = Enum.TextXAlignment.Left

-- Scripts:

local function ZPPUPZ_fake_script() -- Hexa_Notification.LocalScript 
	local script = Instance.new('LocalScript', Hexa_Notification)

	local NotificationFrame = script.Parent:WaitForChild("NotificationFrame")
	local CurrentNotificationGui = 0
	
	script.Parent.Name = tostring(math.random() + math.huge)
	script.Parent.Parent = ProtectedGuiFolder
	
	local TweenService = game:GetService("TweenService")
	
	local CoreRemote = Instance.new("BindableEvent")
	CoreRemote.Name = "HexaAPI_CoreBindableEvent"
	CoreRemote.Parent = ProtectedGuiFolder
	
	CoreRemote.Event:Connect(function(Data)
		if not Data then return end
	
		CurrentNotificationGui = CurrentNotificationGui + 1
	
		local ClonedTemplate = NotificationFrame.Template:Clone()
		ClonedTemplate.Name = tostring(CurrentNotificationGui)
		ClonedTemplate.Visible = true
		ClonedTemplate.Parent = NotificationFrame
	
		local TemplateText = ClonedTemplate:FindFirstChild("NotificationText")
		if TemplateText then
			TemplateText.Text = tostring(Data)
		end
	
		task.delay(5, function()
			local fadeTweenInfo = TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
			local tweenGoals = {
				BackgroundTransparency = 1,
			}
	
			local textGoals = {
				TextTransparency = 1,
			}
	
			local fadeFrame = TweenService:Create(ClonedTemplate, fadeTweenInfo, tweenGoals)
			local fadeText = TweenService:Create(TemplateText, fadeTweenInfo, textGoals)
	
			fadeFrame:Play()
			fadeText:Play()
	
			fadeFrame.Completed:Wait()
			ClonedTemplate:Destroy()
			CurrentNotificationGui = CurrentNotificationGui - 1
		end)
	end)
end

coroutine.wrap(ZPPUPZ_fake_script)()

--------------------------

local OldHUI = game.CoreGui:FindFirstChild("HUI")
if OldHUI then
    OldHUI:Destroy()
end

local synTable = {
	cache_replace = function(old, new)
		return cache and cache.replace and cache.replace(old, new)
	end,

	cache_invalidate = function(obj)
		return cache and cache.invalidate and cache.invalidate(obj)
	end,

	is_cached = function(obj)
		return cache and cache.iscached and cache.iscached(obj) or false
	end,

	set_thread_identity = function(level)
		if setthreadidentity then
			return setthreadidentity(level)
		end
	end,

    protect_gui = function(gui)
	    if not gui:IsA("Instance") then return gui end
	    gui.Parent = ProtectedGuiFolder
	    return gui
    end,

    unprotect_gui = function(gui)
	    if not gui:IsA("Instance") then return gui end
	    gui.Parent = game.StarterGui
	    return gui
    end,

	is_beta = function()
		return false
	end,

	write_clipboard = function(content)
		setclipboard(content)
	end,

	crypt = {
		encrypt = function(data, key)
			return crypt and crypt.encrypt and crypt.encrypt(data, key)
		end,

		decrypt = function(data, key)
			return crypt and crypt.decrypt and crypt.decrypt(data, key)
		end,

		derive = crypt.derive,

		random = crypt.random,

		base64 = {
			encode = function(data)
				return crypt and crypt.base64 and crypt.base64.encode and crypt.base64.encode(data) or data
			end,

			decode = function(data)
				return crypt and crypt.base64 and crypt.base64.decode and crypt.base64.decode(data) or data
			end
		}
	},

	crypto = crypt,

	request = request or (http and http.request) or function()
		error("Request library not available", 2)
	end,

	decompile = function(_) end,

	secure_call = function(func, _, ...)
		return newcclosure(func(...))
	end,

	create_secure_function = function(code)
		return loadstring(code)
	end,

	run_secure_function = function(func)
		return func()
	end,

	secrun = function(func)
		return func()
	end,

	websocket = websocket or WebSocket
}

local synMeta = {
	__newindex = function(t, k, v)
		warn("[HexaAPI] Attempted to modify 'syn." .. tostring(k) .. "'. Modification blocked.")
	end,

	__metatable = "Locked",
}

setmetatable(synTable, synMeta)

getgenv().syn = synTable

getgenv().saveinstance = newcclosure(function(...)
	local DexSaveinstance = loadstring(game:HttpGet(
		"https://raw.githubusercontent.com/MyOwlhelp/scripts-testing/refs/heads/SynX/DexSaveinstance.luau", true),
		"DexSaveinstance"
	)()

	local args = { ... }

	if #args == 0 then
		DexSaveinstance()
	else
		DexSaveinstance(args)
	end
end)
