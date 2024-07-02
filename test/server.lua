RegisterRPC("test:math", function(source, a, b)
    local x,y,z = CallClientRPC("test:playerPos", source, "math")
    print(x,y,z)

    return a + b, a - b, a * b, a / b
end)

Wait(100) -- Wait for the RPC to be registered

CallClientRPCAsync("test:playerPos", function(x, y, z)
    print(x, y, z)
end, 1, "Baller")
