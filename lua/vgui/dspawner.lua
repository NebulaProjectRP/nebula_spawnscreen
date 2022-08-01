local PANEL = {}
PANEL.RTs = {}
PANEL.Materials = {}
PANEL.Progress = {}

local rendered = false
local id = 1

function PANEL:Init()
    SPAWN = self
    self:SetSize(ScrW(), ScrH())
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:MakePopup()
    self.RTs = {}
    self.Materials = {}
    self.Progress = {}
    self:SetDraggable(false)
    hook.Run("OnSpawnOpen")
    if IsValid(_LOUNGE_CHAT) then
        _LOUNGE_CHAT:SetVisible(false)
    end
    if aMenu and IsValid(aMenu.Base) then
        aMenu.Base:SetVisible(false)
    end
    id = 1
    self:CreateRenderTargets()
    if (system.IsWindows() and not system.HasFocus()) then
        system.FlashWindow()
    end
end


function PANEL:CreateRenderTargets()
    hook.Add("HUDShouldDraw", self, function() return false end)
    hook.Add("GetMotionBlurValues", self, function() return 0, 0, 0, 0 end)
    rendered = false

    hook.Add("CalcView", self, function()
        local tbl = {}
        local camera = NebulaSpawns.Cameras[id]
        tbl.origin = camera.pos
        tbl.farz = 10000
        tbl.angles = camera.ang

        return tbl
    end)

end

function PANEL:OnMousePressed(ms)
    if (system.HasFocus() and not self.Triggered and ms == MOUSE_LEFT) then
        if (isbool(self.Hovered)) then
            self.Hovered = math.random(1, 5)
        end
        net.Start("Nebula.Spawn:Start")
        net.WriteInt(self.Hovered, 4)
        net.SendToServer()
        if (math.random(1, 50) == 25) then
            sound.PlayURL("https://www.myinstants.com/media/sounds/gta-san-andreas-ah-shit-here-we-go-again.mp3", "", function() end)
        else
            surface.PlaySound("ui/hint.wav")
        end
        self.Triggered = CurTime() + .3
        timer.Simple(.3, function()
            LocalPlayer():ScreenFade( SCREENFADE.IN, Color( 0, 0, 0, 255 ), 0.3, 0 )
            if (not alreadySpawned) then
                hook.Run("OnPlayerStart", LocalPlayer())
                //net.Start("Nebula.PlayerStart")
                //net.SendToServer()
                alreadySpawned = true
            end
            hook.Run("OnSelectSpawn", self.Hovered)
            if IsValid(self) then
                self:Remove()
            end
        end)
    end
end

PANEL.Hovered = -1
PANEL.Weight = {}
local gl = surface.GetTextureID("vgui/gradient-l")
local gr = surface.GetTextureID("vgui/gradient-r")
local icons = Material("nebularp/ui/spawnicons")
local icon_gwen = {}
for x = 1, 5 do
    icon_gwen[x] = {
        GWEN.CreateTextureNormal((x - 1) * 200, 0, 200, 256, icons),
        GWEN.CreateTextureNormal((x - 1) * 200, 256, 200, 256, icons)
    }
end
local logo = surface.GetTextureID("nebularp/ui/sb_text")

PANEL.ViewAlpha = 255
function PANEL:DrawView(k, v, wide, correctWide, h, uvGap)
    surface.SetDrawColor(255, 255, 255, self.ViewAlpha)
    surface.SetMaterial(v)
    surface.DrawTexturedRectUV(wide, 0, correctWide, h, .5 - uvGap / 2, 0, .5 + uvGap / 2, 1)

    render.RenderView({
        origin = NebulaSpawns.Cameras[k].pos,
        angles = NebulaSpawns.Cameras[k].ang,
        x = wide,
        y = 64,
        w = w,
        h = h - 64,
    })
    if (self.ViewAlpha > 0) then
        self.ViewAlpha = self.ViewAlpha - FrameTime() * 125
    end
end

local oldK
PANEL.OldAlphas = {200, 200, 200, 200, 200}

local deg = Material("vgui/gradient-d")
function PANEL:Paint(w, h)
    if (not rendered) then
        if (self.Materials[id]) then return end
        self.RTs[id] = GetRenderTarget(FrameNumber() .. "_camera" .. id, ScrW(), ScrH(), false)
        render.PushRenderTarget(self.RTs[id])
        render.PopRenderTarget()
        render.CopyTexture(render.GetRenderTarget(), self.RTs[id])

        self.Materials[id] = CreateMaterial("RT_Camera_" .. id .. FrameNumber(), "UnlitGeneric", {
            ["$basetexture"] = self.RTs[id]:GetName(),
            ["$vertexalpha"] = 1,
        })

        self.Weight[id] = .2
        id = id + 1
        if (id >= table.Count(NebulaSpawns.Cameras) + 1) then
            hook.Remove("CalcView", self)
            hook.Remove("HUDShouldDraw", self)
            hook.Remove("GetMotionBlurValues", self)
            rendered = true
            xpos = 0
            wide = w / 5
            if IsValid(_LOUNGE_CHAT) then
                _LOUNGE_CHAT:SetVisible(true)
            end
            if aMenu and IsValid(aMenu.Base) then
                aMenu.Base:SetVisible(true)
            end
        end
    else
        local mx, my = gui.MousePos()
        local wide = 0

        if (isnumber(self.Hovered) and self.Hovered != oldK) then
            oldK = self.Hovered
            self.ViewAlpha = 255
            net.Start("Nebula.Spawn:UpdatePos")
            net.WriteUInt(self.Hovered, 3)
            net.SendToServer()
        end

        for k, v in pairs(self.Materials) do
            surface.SetDrawColor(color_white)
            surface.SetMaterial(v)
            self.Weight[k] = Lerp(FrameTime() * 8, self.Weight[k], self.Hovered == k and .6 or (.5 / 5))
            if (k >= table.Count(self.Materials)) then
                local weighting = 0
                for r, v in pairs(self.Weight) do
                    if (r == k) then continue end
                    weighting = weighting + v
                end
                self.Weight[k] = 1 - weighting
            end
            local uvGap = self.Weight[k]
            local correctWide = self.Weight[k] * w
            if (self.Hovered == k) then
                self:DrawView(k, v, wide, correctWide, h, uvGap)
            else
                surface.DrawTexturedRectUV(wide, 0, correctWide, h, .5 - uvGap / 2, 0, .5 + uvGap / 2, 1)
                self.OldAlphas[k] = Lerp(FrameTime() * 8, self.OldAlphas[k], self.Hovered == k and 0 or 200)
                surface.SetDrawColor(0, 0, 0, self.OldAlphas[k])
                draw.NoTexture()
                surface.DrawTexturedRectUV(wide, 0, correctWide, h, .5 - uvGap / 2, 0, .5 + uvGap / 2, 1)
            end
            surface.SetDrawColor(0, 0, 0, 75)
            surface.SetTexture(gl)
            surface.DrawTexturedRect(wide, 0, 64, h)
            surface.SetTexture(gr)
            surface.DrawTexturedRect(wide + correctWide - 64, 0, 64, h)
            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(wide - 1, 0, 2, h)
            
            surface.SetMaterial(deg)
            surface.DrawTexturedRect(0, h - 64, w, 128)
            surface.DrawTexturedRectRotated(w / 2, 64, w, 128, 180)

            if (self.Hovered == k) then
                surface.DrawTexturedRect(wide, h - 128, correctWide, 128, .5 - uvGap / 2)
                draw.SimpleText(NebulaSpawns.Cameras[k].name, NebulaUI:Font(96), wide + correctWide / 2, h - h * .2 + 112, color_white, 1, 1)    
            end
            icon_gwen[k][self.Hovered == k and 2 or 1](wide + correctWide / 2 - 100, h - h * .2 - 128, 200, 256, color_white)

            if (mx > (k - 1) * (w / 5) and mx < k * w / 5) then
                if (self.Hovered != k) then
                    surface.PlaySound("ui/buttonrollover.wav")
                end
                self.Hovered = k
            end

            wide = correctWide + wide
        end

        surface.SetDrawColor(26, 26, 26, 255)
        surface.DrawRect(0, 0, w, 96)
        surface.SetDrawColor(color_white)
        surface.SetTexture(logo)
        surface.DrawTexturedRectRotated(w / 2, 48, 256, 64, 0)
        draw.SimpleText("Welcome to", NebulaUI:Font(20), w / 2, 24, color_white, 1, 1)
    end

    if (self.Triggered) then
        local amount = 1 - (self.Triggered - CurTime()) / .3
        surface.SetDrawColor(0, 0, 0, amount * 255)
        surface.DrawRect(0, 0, w, h)
    end
end

vgui.Register("nebula.spawner", PANEL, "DFrame")

net.Receive("Nebula.Spawn:Request", function()
    if IsValid(SPAWN) then
        SPAWN:Remove()
    end

    SPAWN = vgui.Create("nebula.spawner")
end)

local triggered = false
hook.Add("RenderScene", "PlaceHolder", function()
    if (not system.HasFocus()) then return end
    if (gui.IsConsoleVisible()) then return end
    if (gui.IsGameUIVisible()) then return end
    if (triggered) then return end
    triggered = true
    net.Start("Nebula.Spawn:Notify")
    net.SendToServer()
    if IsValid(SPAWN) then
        SPAWN:Remove()
    end

    SPAWN = vgui.Create("nebula.spawner")
    hook.Remove("RenderScene", "PlaceHolder")
end)
