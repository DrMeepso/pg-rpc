# Pretty Good: RPC
### Proper RPCs for FiveM!

## Why
Pretty Good: RPC was created to provide a simple and easy to use RPC system for FiveM. Durring my short time as a FiveM developer I found that Callback/RPC systems built into other resources just didn't cut it. using a `cb()` function to end the RPC just felt clunky and hard to use. So I created Pretty Good: RPC to provide a simple and easy to use RPC system for FiveM.

## Features
- Simple and easy to use
- Sync and Async RPCs
    - You can call a RPC and get a response within the same line (Sync)
- Client to Server and Server to Client RPCs
- Timeouts for Async RPCs
    - RPCs will timeout after 30 seconds by default
- Local like return values for RPCs
    - No need to use `cb()` to end the RPC
- Single file import for easy use in your own resources

## What is a RPC?
A RPC is a Remote Procedure Call. Put simply it is a way to call a function on the server from the client or client to server and receive a response. A RPC is usful for sending data between the client and server for things like checks, events, and more!

## Installation
You install Pretty Good: RPC like any other FiveM resource.
1. Download the latest release from the releases page.
2. Extract the zip file.
3. Drag and drop the `pg-rpc` folder into your resources folder. (Rename the folder if needed)
4. Add `ensure pg-rpc` to your server.cfg.
5. Start your server!

### Use in your own resource
In order to use the pg-rpc you need to get the functions from the resource. You have a few options to do this.

#### Option 1: Fetch the exports
You can fetch the exports from the resource and use them in your own resource, while still having the pg-rpc resource be a dependency.

```lua
--- Fetch the exports from the pg-rpc resource
local RPC = exports['pg-rpc']

--- Now all RPC functions are available to use under the RPC table!
RPC.RegisterRPC("test:math", function(a, b)
    return a + b, a - b, a * b, a / b
end)
```
---
#### Option 2: Link the main.lua file
You can link the main.lua file from the pg-rpc resource to your own resource. This will allow you to use the functions directly without needing to fetch the exports.

```lua
-- fxmanifest.lua

shared_script {
    --- what ever other files you have
    '@pg-rpc/main.lua'
}
```

Now you can use the functions directly in your resource! No need to fetch the exports.
Just make sure you place the import above any files you would like to use it!

```lua
--- Now all RPC functions are available to use!
RegisterRPC("test:math", function(a, b)
    return a + b, a - b, a * b, a / b
end)
```
---
#### Option 3: Drag Main.lua into your resource
You can drag the main.lua file from the pg-rpc resource into your own resource. This will allow you to use the functions directly without needing to fetch the exports.

Just make sure you add the exports to the fxmanifest.lua file under the shared_script section!

```lua
--- All RPC functions are available to use!
RegisterRPC("test:math", function(a, b)
    return a + b, a - b, a * b, a / b
end)
```

## Usage

### Registering a RPC
To register a RPC you use the `RegisterRPC` function. This function takes two arguments, the name of the RPC and the function to call when the RPC is called.

```lua
function RegisterRPC(name: string, func: function)
    -> void

-- Client side
func(...any) 
    -> ...any

-- Server side
func(player: number, ...any) 
    -> ...any
```
    
```lua
-- client.lua
RegisterRPC("test:math", function(a, b)
    return a + b, a - b, a * b, a / b
end)
```

When registering a RPC from the server you get an additional argument, the player that called the RPC.

```lua
-- server.lua
RegisterRPC("test:math", function(player, a, b)
    return a + b, a - b, a * b, a / b
end)
```
---
### Removing a RPC
To remove a RPC you use the `RemoveRPC` function. This function takes one argument, the name of the RPC to remove.

```lua
function RemoveRPC(name: string)
    -> void
```

```lua
-- shared.lua
RemoveRPC("test:math")
```
---
### Calling a RPC
Calling a RPC is simple and easy. You can call a RPC from the client to the server or the server to the client. Sync and Async RPCs are supported.

#### Client to Server
To call a RPC from the client to the server you use the `CallRPC` function. This function takes one argument, the name of the RPC and the arguments to pass to the RPC.

```lua 
function CallRPC(name: string, ...any)
  -> ...any
```

```lua
-- client.lua
local add, sub, mul, div = CallRPC("test:math", 5, 3)
```
The `CallRPC` function will return the values returned from the RPC as if called localy

#### Server to Client
To call a RPC from the server to the client you use the `CallClientRPC` function. This function takes two arguments, the player to call the RPC on, the name of the RPC, and the arguments to pass to the RPC.

```lua
function CallClientRPC(name: string, player: number, ...any)
  -> ...any
```

```lua
-- server.lua
local player = 1
local add, sub, mul, div = CallClientRPC("test:math", player, 5, 3)
```
The `CallClientRPC` function will return the values returned from the RPC as if called localy

---
### Calling a Async RPC 
Async RPCs are much the same as normal RPCs, but they take a function as the last argument. This function will be called when the RPC is finished. this is useful when you dont want to block the main thread.

#### Client to Server
To call a RPC from the client to the server you use the `CallRPCAsync` function. This function takes two arguments, the name of the RPC, the arguments to pass to the RPC, and the function to call when the RPC is finished.

```lua
function CallRPCAsync(name: string, cb: function, ...any)
    -> void

-- cb will be a function with the ammount of arguments returned from the RPC
```

```lua
-- client.lua
CallRPCAsync("test:math", function(add, sub, mul, div)
    print(add, sub, mul, div)
end, 5, 3)
```

#### Server to Client
To call a RPC from the server to the client you use the `CallClientRPCAsync` function. This function takes three arguments, the player to call the RPC on, the name of the RPC, the arguments to pass to the RPC, and the function to call when the RPC is finished.

```lua
function CallClientRPCAsync(name: string, cb: function, player: number, ...any)
    -> void
```

```lua
-- server.lua
local player = 1
CallClientRPCAsync("test:math", function(add, sub, mul, div)
    print(add, sub, mul, div)
end, player, 5, 3)
```

---

## Timeouts
> All timeouts are in milliseconds `ms = s * 1000`

Async RPCs have a timeout of 30 seconds by default. This means that if the RPC is not finished within 30 seconds the function passed to the RPC will be called with nil values.
To change this timeout you can use the `SetRPCTimeout` function. This function takes one argument, the timeout in milliseconds.

```lua
function SetRPCTimeout(timeout: number)
    -> void
```

> Please keep in mind that the `SetRPCTimeout` function will set the timeout for all RPCs in the resource (Client and Server will stay seperate).
```lua
-- shared.lua
SetRPCTimeout(10000) -- 10 seconds
```

---

### Temporary Timeouts
You can set a temporary timeout for a single RPC by passing running the `SetNextTimeout` function before calling the RPC. This function takes one argument, the timeout in milliseconds.

```lua
function SetNextTimeout(timeout: number)
    -> void
```

> After being called the timeout will be reset to the default timeout for the resource, if no timeout is set the default timeout will be used. (30 seconds)

```lua
-- client.lua (Works on server too)
SetNextTimeout(10000) -- 10 seconds
local add, sub, mul, div = CallRPC("test:math", 5, 3)
```

---

### Disabling Timeouts
You can disable timeouts for a single RPC by calling the `DisableNextTimeout` function before calling the RPC. This is only recommended for Async RPCs you dont mind hanging!

```lua
function DisableNextTimeout()
    -> void
```

> :warning: Disabling timeouts when using synchronous calls will cause the RPC to never timeout. This can cause your resource to hang if the RPC is never finished!

```lua
-- client.lua (Works on server too)
DisableNextTimeout()
local add, sub, mul, div = CallRPC("test:math", 5, 3)
```
