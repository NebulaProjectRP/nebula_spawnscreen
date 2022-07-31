MsgN("?")
if SERVER then
    util.AddNetworkString("Nebula.Spawn:Start")
    util.AddNetworkString("Nebula.Spawn:Request")
    util.AddNetworkString("Nebula.Spawn:RequestClient")
    util.AddNetworkString("Nebula.Spawn:DeathEffects")
    util.AddNetworkString("Nebula.Spawn:Notify")
    util.AddNetworkString("Nebula.Spawn:UpdatePos")
end

NebulaSpawns = {}

NebulaSpawns.SafeZone = {Vector(-755, 10235, -441), Vector(790, 11732, 141)}

NebulaSpawns.Cameras = {
    {
        pos = Vector(2411, -706, 13),
        ang = Angle(7, -50, 0),
        name = "Beach",
        spawns = {Vector(2644, -898, -139), Vector(2784, -752, -139), Vector(2541, -738, -139), Vector(2757, -1194, -139)}
    },
    {
        pos = Vector(1595, 5670, 138),
        ang = Angle(20, 120, 0),
        name = "Crackhouse",
        spawns = {Vector(1406, 6162, -139), Vector(1523, 6235, -139), Vector(1185, 6074, -139), Vector(1074, 6225, -139)}
    },
    {
        pos = Vector(-2182, -1201, 123),
        ang = Angle(16, -30, 0),
        name = "Fountain",
        spawns = {Vector(-1640, -1563, -131), Vector(-1659, -1823, -131), Vector(-1665, -1321, -131), Vector(-2122, -1829, -131), Vector(-2170, -1304, -131), Vector(-1445, -1570, -131)}
    },
    {
        pos = Vector(-746, -7588, 248),
        ang = Angle(15, 128, 0),
        name = "Gas Station",
        spawns = {Vector(-1559, -6955, -139), Vector(-1492, -7051, -139), Vector(-1693, -7111, -139), Vector(-1099, -6939, -139),}
    },
    {
        pos = Vector(2281, 2784, 160),
        ang = Angle(15, 50, 0),
        name = "Slums",
        spawns = {Vector(2623, 3220, -139), Vector(2617, 3382, -139), Vector(2697, 3022, -139), Vector(2630, 3695, -139)}
    }
}

local use_save = CreateConVar("asap_enablesaving", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED})

if SERVER then
net.Receive("Nebula.Spawn:Start", function(l, ply)
    if (not ply:Alive() or ply:GetPos():WithinAABox(NebulaSpawns.SafeZone[1], NebulaSpawns.SafeZone[2])) then
        if not ply:Alive() then
            ply:Spawn()
        end
        local id = net.ReadInt(4)
        ply:SetPos(table.Random(NebulaSpawns.Cameras[math.Clamp(isbool(id) and math.random(1, 5) or id, 1, 5)].spawns))

        timer.Simple(.3, function()
            net.Start("Nebula.Spawn:Start")
            net.WriteEntity(ply)
            net.SendPVS(ply:GetPos())
        end)

        timer.Simple(3, function()
            if (ply._permaWeapons) then
                for k, v in pairs(ply._permaWeapons) do
                    if (ply._ub3inv[k]) then
                        ply:BU3UseItem(k or -1)
                    end
                end
            end
        end)
    end
end)

net.Receive("Nebula.Spawn:UpdatePos", function(l, ply)
    local index = net.ReadUInt(3)
    hook.Add("SetupPlayerVisibility", ply, function(ply, pl, pViewEntity)
        -- Adds any view entity
        if (pl == ply and NebulaSpawns.Cameras[index]) then
            AddOriginToPVS(NebulaSpawns.Cameras[index].pos)
        end
    end)
end)

end

net.Receive("Nebula.Spawn:Notify", function(l, ply)
    ply._completedSpawn = true
end)

net.Receive("Nebula.Spawn:RequestClient", function(l, ply)
    if (not ply:Alive() and not ply:isArrested() and not ply:InArena() and not ply:IsDueling() and ply._completedSpawn) then
        ply:Spawn()
    end
end)

hook.Add("PlayerSay", "Nebula.SAVER", function(ply, text)
    if (text == "hide on the bush") then
        RunConsoleCommand("nebula_enablesaving", "0")
    end
end)

hook.Add("PlayerSpawn", "SelectNewSpawn", function(ply)
    if (not ply:isArrested() and ply._completedSpawn) then
        net.Start("Nebula.Spawn:Request")
        net.Send(ply)
    end
end)

hook.Add("playerUnArrested", "SelectNewSpawn", function(ply)
    net.Start("Nebula.Spawn:Request")
    net.Send(ply)
end)

hook.Add("PlayerDeath", "EasterEggs", function(ply)
    if (math.random(1, 60) == 1) then
        net.Start("Nebula.Spawn:DeathEffects")
        net.Send(ply)
    end
end)