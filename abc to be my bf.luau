-- Hexa API Patch.lua

local ProtectedClosures = {}
local ProtectedGuis = {}
local oldNewcclosure = newcclosure

getgenv().newcclosure = oldNewcclosure(function(func)
    table.insert(ProtectedClosures,func)
    return oldNewcclosure(func)
end)

if UseHexaDecompiler == true then
    loadstring(game:HttpGet("https://gist.githubusercontent.com/MyOwlhelp/b103f397cd59fda36bb8b7767dc9cd8d/raw/110b035145e1c5860b9243857abf8cb9ec7c695c/HexaLuaDecompiler.luau", true))()
else
    getgenv().decompile = function(_)
        return "-- Built-in decompiler is disabled. Put your own decompiler here."
    end
end

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

    printidentity = function()
        printidentity()
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

		derive = function(value, length)
			length = length or 32
			local derived = table.create(length)
			local valueLength = #value

			for i = 1, length do
				local char = value:byte(((i - 1) % valueLength) + 1)
				derived[i] = string.char((char + i * 13) % 256)
			end

			return table.concat(derived)
		end,

		random = function(size)
			size = size or 16
			local bytes = table.create(size)

			for i = 1, size do
				bytes[i] = string.char(math.random(0, 255))
			end

			return table.concat(bytes)
		end,

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
    if not ProtectedGuis[v] then
        table.insert(ProtectedGuis, v)
    end
end
