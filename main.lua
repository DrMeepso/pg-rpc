--[[
Copyright (c) 2024 Z.Ireland

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

---@type boolean
local isServer = IsDuplicityVersion()

---@class RPC
---@field name string
---@field func function
---@field callback table -- the callback function

---@type table<string, RPC>
local registeredRPCs = {}

---@param name string
---@param func function
function RegisterRPC(name, func)
    if registeredRPCs[name] then
        error("RPC with name " .. name .. " already exists")
    end

    -- We are on the server
    RegisterNetEvent(name) -- Register the event
    local handel = AddEventHandler(name, function(prams, cbID) -- Add the event handler
        local args = prams
        local source = source
    
        if isServer then
            local result = {func(source, table.unpack(args))} -- Call the function
            TriggerClientEvent(name .. ":response", source, result, cbID)
        else
            local result = {func(table.unpack(args))} -- Call the function
            TriggerServerEvent(name .. ":response", result, cbID)
        end
    end)

    registeredRPCs[name] = {
        name = name,
        func = func,
        callback = handel
    }
end

---@param name string
function RemoveRPC(name)
    if not registeredRPCs[name] then
        error("RPC with name " .. name .. " does not exist")
    end
    
    RemoveEventHandler(registeredRPCs[name].callback) -- Remove the event handler
    registeredRPCs[name] = nil -- Remove the RPC
end

---@type table<string, number>
Timeouts = {}
---@type table<string, number>
TempTimeouts = {}

--- Set the timeout for the RPCs
---@param time number
function SetRPCTimeout(time)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    Timeouts[resource] = time
end

--- Set the timeout for the next RPC
---@param time number
function SetNextTimeout(time)
    local resource = GetInvokingResource() or GetCurrentResourceName()
    TempTimeouts[resource] = time
end

--- Disable the timeout for the next RPC
function DisableNextTimeout()
    local resource = GetInvokingResource() or GetCurrentResourceName()
    TempTimeouts[resource] = -1
end

--- Call a Client-Side RPC
---@param name string
---@param player number
---@param ... any
---@return any -- the result of the RPC
function CallClientRPC(name, player, ...)
    local args = {...}

    if not isServer and player ~= -1 then
        error("Client can only call RPCs to the server!")
    end

    -- variables for the response
    callbackID = math.random(1000000, 9999999) + GetGameTimer() -- Generate a random callback ID
    isFinished = false
    rpcResult = {}

    RegisterNetEvent(name .. ":response") -- Register the event
    local cb = AddEventHandler(name .. ":response", function(result, cbID) -- Add the event handler
        if cbID ~= callbackID then return end -- Check if the callback ID is the same
        isFinished = true
        rpcResult = result
    end)

    -- Trigger the event
    if isServer then
        TriggerClientEvent(name, player, args, callbackID)
    else
        TriggerServerEvent(name, args, callbackID)
    end

    -- Wait for the response
    local callBegin = GetGameTimer()
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local timeOut = TempTimeouts[resource] or Timeouts[resource] or (30 * 1000)
    local doTimeout = TempTimeouts[resource] ~= -1
    TempTimeouts[resource] = nil -- Reset the temp timeout
    while not isFinished do
        Wait(0)
        if GetGameTimer() - callBegin > timeOut and doTimeout then
            warn("RPC " .. name .. " timed out!")
            isFinished = true -- Break the loop!
        end
    end

    -- Remove the event handler
    RemoveEventHandler(cb)

    return table.unpack(rpcResult)
end

--- Call a Server-Side RPC
---@param name string
---@param ... any
---@return any -- the result of the RPC
function CallRPC(name, ...)
    local args = {...}
    return CallClientRPC(name, -1, table.unpack(args))
end

--- Call a Client-Side RPC Asynchronously
---@param name string
---@param cb function
---@param ... any
function CallClientRPCAsync(name, cb, player, ...)
    local args = {...}
    
    if not isServer and player ~= -1 then
        error("Client can only call RPCs to the server!")
    end

    callbackId = math.random(1000000, 9999999) + GetGameTimer() -- Generate a random callback ID
    isFinished = false

    RegisterNetEvent(name .. ":response") -- Register the event
    ecb = AddEventHandler(name .. ":response", function(result, cbID) -- Add the event handler
        if cbID ~= callbackId then return end -- Check if the callback ID is the same
        RemoveEventHandler(ecb)
        isFinished = true
        cb(table.unpack(result))
    end)

    -- Trigger the event
    if isServer then
        TriggerClientEvent(name, player, args, callbackId)
    else
        TriggerServerEvent(name, args, callbackId)
    end

    -- For the timeout (if there is one)
    local callBegin = GetGameTimer()
    local resource = GetInvokingResource() or GetCurrentResourceName()
    local timeOut = TempTimeouts[resource] or Timeouts[resource] or (30 * 1000)
    local doTimeout = TempTimeouts[resource] ~= -1
    TempTimeouts[resource] = nil -- Reset the temp timeout
    while not isFinished do
        Wait(0)
        if GetGameTimer() - callBegin > timeOut and doTimeout then
            warn("RPC " .. name .. " timed out!")
            RemoveEventHandler(ecb)
            isFinished = true -- Break the loop!
            cb(table.unpack({}))
        end
    end

end

--- Call a Server-Side RPC Asynchronously
---@param name string
---@param cb function
---@param ... any
function CallRPCAsync(name, cb, ...)
    CallClientRPCAsync(name, cb, -1, ...)
end

-- create the exports for the resource, but make sure we are in the correct resource!
if GetCurrentResourceName() == "pg-rpc" then
    exports("RegisterRPC", RegisterRPC)
    exports("RemoveRPC", RemoveRPC)
    exports("SetRPCTimeout", SetRPCTimeout)
    exports("SetNextTimeout", SetNextTimeout)
    exports("DisableNextTimeout", DisableNextTimeout)
    exports("CallClientRPC", CallClientRPC)
    exports("CallRPC", CallRPC)
    exports("CallClientRPCAsync", CallClientRPCAsync)
    exports("CallRPCAsync", CallRPCAsync)
end