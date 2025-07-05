-- Hexa API Patch.lua

local ProtectedClosures = {}
local ProtectedGuis = {}
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

getgenv().printidentity = newcclosure(function()
    print("Current identity is", CurrentLevel or ExecutorLevel)
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

-- Instances: 7 | Scripts: 1 | Modules: 0 | Tags: 0
local G2L = {};

-- StarterGui.You are a fucking skid.
G2L["1"] = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"));
G2L["1"]["Name"] = [[You are a fucking skid.]];
G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;


-- StarterGui.You are a fucking skid..LocalScript
G2L["2"] = Instance.new("LocalScript", G2L["1"]);



-- StarterGui.You are a fucking skid..NotificationFrame
G2L["3"] = Instance.new("Frame", G2L["1"]);
G2L["3"]["BorderSizePixel"] = 0;
G2L["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["3"]["Size"] = UDim2.new(0, 341, 0, 583);
G2L["3"]["Position"] = UDim2.new(0.73373, 0, 0, 0);
G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["3"]["Name"] = [[NotificationFrame]];
G2L["3"]["BackgroundTransparency"] = 1;


-- StarterGui.You are a fucking skid..NotificationFrame.UIListLayout
G2L["4"] = Instance.new("UIListLayout", G2L["3"]);
G2L["4"]["Padding"] = UDim.new(0, 5);
G2L["4"]["VerticalAlignment"] = Enum.VerticalAlignment.Bottom;
G2L["4"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


-- StarterGui.You are a fucking skid..NotificationFrame.Template
G2L["5"] = Instance.new("Frame", G2L["3"]);
G2L["5"]["Visible"] = false;
G2L["5"]["BorderSizePixel"] = 0;
G2L["5"]["BackgroundColor3"] = Color3.fromRGB(16, 16, 16);
G2L["5"]["Size"] = UDim2.new(0, 348, 0, 34);
G2L["5"]["Position"] = UDim2.new(0, 0, 0.94168, 0);
G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["5"]["Name"] = [[Template]];
G2L["5"]["Rotation"] = -21;


-- StarterGui.You are a fucking skid..NotificationFrame.Template.UICorner
G2L["6"] = Instance.new("UICorner", G2L["5"]);



-- StarterGui.You are a fucking skid..NotificationFrame.Template.NotificationText
G2L["7"] = Instance.new("TextLabel", G2L["5"]);
G2L["7"]["TextWrapped"] = true;
G2L["7"]["BorderSizePixel"] = 0;
G2L["7"]["TextSize"] = 30;
G2L["7"]["TextXAlignment"] = Enum.TextXAlignment.Left;
G2L["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
G2L["7"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
G2L["7"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
G2L["7"]["BackgroundTransparency"] = 1;
G2L["7"]["RichText"] = true;
G2L["7"]["Size"] = UDim2.new(0, 332, 0, 34);
G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
G2L["7"]["Text"] = [[Test]];
G2L["7"]["Name"] = [[NotificationText]];
G2L["7"]["Position"] = UDim2.new(0.02232, 0, 0, 0);


-- StarterGui.You are a fucking skid..LocalScript
local function C_2()
local script = G2L["2"];
	local hui = gethui()
	local NotificationFrame = script.Parent:WaitForChild("NotificationFrame")
	local CurrentNotificationGui = 0
	
	if not syn or hui.Name ~= "HexaAPI_PROTECTED" then
		return
	end
	
	script.Parent.Name = tostring(syn.crypt.random())
	script.Parent.Parent = hui
	
	local TweenService = game:GetService("TweenService")
	
	local CoreRemote = Instance.new("BindableEvent")
	CoreRemote.Name = "HexaAPI_CoreBindableEvent"
	CoreRemote.Parent = hui
	
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
end;
task.spawn(C_2);

--return G2L["1"], require; -- I think without this the gui will runs fine.

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

for _, v in ipairs(ProtectedGuiFolder:GetChildren()) do
    if v:IsA("ScreenGui") and not ProtectedGuis[v] then
        table.insert(ProtectedGuis, v)
    end
end
