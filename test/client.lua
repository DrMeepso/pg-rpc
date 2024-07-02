RegisterRPC("test:playerPos", function(random)
    print(random)
    local player = GetPlayerPed(-1)
    local pos = GetEntityCoords(player)
    return pos.x, pos.y, pos.z
end)

Wait(100) -- Wait for the RPC to be registered

SetNextTimeout(200)
CallRPCAsync("test:math", function(add, sub, mul, div)
    print("Async", add, sub, mul, div)
end, 20, 10)

local add, sub, mul, div = CallRPC("test:math", 10, 5)
print("Sync", add, sub, mul, div)