-- PingAltClick: Alt + clic izquierdo = sistema de pings normal de Blizzard
--
-- Mundo: la tecla de ping (TOGGLEPINGLISTENER) llama a C_Ping.TogglePingListener,
-- que está restringida, así que se asigna esa misma acción a ALT-BUTTON1 con un
-- override binding y el modo de ping "Mantener tecla" (pingMode = 0):
--   * Alt + clic rápido        -> ping contextual (unidad, objeto o punto del mundo)
--   * Alt + mantener clic      -> rueda radial; mover el ratón y soltar para elegir
--
-- Interfaz: los clics sobre marcos no llegan a las asignaciones de teclas. En los
-- botones de acción y marcos de unidad se envuelve el OnClick con un fragmento
-- seguro que, con Alt + clic izquierdo, redirige el clic a un botón virtual
-- "pingalt" que ejecuta /ping. Así no se pisa lo que configuran Bartender o Clique,
-- y Alt + tecla de atajo sigue funcionando como siempre.
--
-- Marcos de unidad fuera de combate: mientras Alt está pulsado se desactivan sus
-- clics (el movimiento del ratón no), así que el clic cae al mundo, salta la
-- asignación ALT-BUTTON1 y el juego detecta el marco bajo el cursor igual que con la
-- tecla de ping, rueda radial incluida. En combate eso está bloqueado, así que se
-- usa el /ping del fragmento seguro (solo ping contextual).
local KEY = "ALT-BUTTON1"
local ACTION = "TOGGLEPINGLISTENER"
local PING_MODE_KEY_DOWN = Enum.PingMode and Enum.PingMode.KeyDown or 0
local PING_CMD = SLASH_PING1 or "/ping"
-- Sin objetivo: el juego busca el receptor de ping bajo el cursor, igual que con la
-- tecla de ping (hechizo/objeto del botón, unidad del marco, "Salud 100%" en la barra de vida...)
local MACRO_ACTION = PING_CMD
local MACRO_UNIT = PING_CMD

local f = CreateFrame("Frame")
local header = CreateFrame("Frame", "PingAltClickHeader", UIParent, "SecureHandlerBaseTemplate")
local wrapped = {}
local pending = {}
local unitFrames = {}
local clickDisabled = {}

local PRE_CLICK = [[
    if button == "LeftButton" and IsAltKeyDown() then
        return "pingalt"
    end
]]

local function hook(frame, macro)
    if not frame or wrapped[frame] then return end
    if not frame.IsProtected or not frame:IsProtected() then return end
    if InCombatLockdown() then
        pending[frame] = macro
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    frame:SetAttribute("*type-pingalt", "macro")
    frame:SetAttribute("*macrotext-pingalt", macro)
    header:WrapScript(frame, "OnClick", PRE_CLICK)
    wrapped[frame] = macro
end

local ACTION_BARS = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button",
    "MultiBar6Button", "MultiBar7Button",
}

local function hookActionButtons()
    for _, prefix in ipairs(ACTION_BARS) do
        for i = 1, 12 do
            hook(_G[prefix .. i], MACRO_ACTION)
        end
    end
    local LAB = LibStub and LibStub("LibActionButton-1.0", true)
    if LAB then
        for button in pairs(LAB:GetAllButtons()) do
            hook(button, MACRO_ACTION)
        end
    end
end

local function hookUnit(frame)
    if not frame then return end
    unitFrames[frame] = true
    hook(frame, MACRO_UNIT)
end

local function hookUnitFrames()
    for _, name in ipairs({ "PlayerFrame", "TargetFrame", "FocusFrame", "PetFrame", "TargetFrameToT", "FocusFrameToT" }) do
        hookUnit(_G[name])
    end
    for i = 1, 4 do
        hookUnit(_G["PartyMemberFrame" .. i])
        if PartyFrame and PartyFrame["MemberFrame" .. i] then
            hookUnit(PartyFrame["MemberFrame" .. i])
        end
    end
    for i = 1, 5 do
        hookUnit(_G["CompactPartyFrameMember" .. i])
    end
    for i = 1, 40 do
        hookUnit(_G["CompactRaidFrame" .. i])
    end
end

if CompactUnitFrame_SetUpFrame then
    hooksecurefunc("CompactUnitFrame_SetUpFrame", hookUnit)
end

local function applyBinding()
    if InCombatLockdown() then
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    if GetCVar("pingMode") ~= tostring(PING_MODE_KEY_DOWN) then
        SetCVar("pingMode", PING_MODE_KEY_DOWN)
    end
    ClearOverrideBindings(f)
    SetOverrideBinding(f, true, KEY, ACTION)
end

-- Alt pulsado fuera de combate: los clics de los marcos de unidad pasan al mundo
local function restoreUnitClicks()
    for frame in pairs(clickDisabled) do
        clickDisabled[frame] = nil
        frame:SetMouseClickEnabled(true)
    end
end

local function updateUnitClicks()
    if InCombatLockdown() then return end
    if not IsAltKeyDown() then
        restoreUnitClicks()
        return
    end
    for frame in pairs(unitFrames) do
        if not clickDisabled[frame] and frame:IsMouseClickEnabled() then
            clickDisabled[frame] = true
            frame:SetMouseClickEnabled(false)
        end
    end
end

local mod = CreateFrame("Frame")
mod:RegisterEvent("MODIFIER_STATE_CHANGED")
mod:RegisterEvent("PLAYER_REGEN_DISABLED")
mod:RegisterEvent("PLAYER_REGEN_ENABLED")
mod:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Última ocasión antes del bloqueo de combate
        restoreUnitClicks()
    else
        updateUnitClicks()
    end
end)

local function applyAll()
    hookActionButtons()
    hookUnitFrames()
end

f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        applyBinding()
        for frame, macro in pairs(pending) do
            pending[frame] = nil
            hook(frame, macro)
        end
    elseif event == "PLAYER_LOGIN" then
        applyBinding()
        applyAll()
        local LAB = LibStub and LibStub("LibActionButton-1.0", true)
        if LAB and LAB.RegisterCallback then
            LAB.RegisterCallback(self, "OnButtonCreated", function(_, button)
                hook(button, MACRO_ACTION)
            end)
        end
    else
        applyAll()
    end
end)

-- /pingalt: diagnóstico. Pon el ratón sobre un botón o marco y escribe /pingalt
SLASH_PINGALTCLICK1 = "/pingalt"
SlashCmdList.PINGALTCLICK = function()
    print("|cff33ff99PingAltClick|r")
    print("  " .. KEY .. " -> " .. tostring(GetBindingAction(KEY, true)))
    print("  pingMode = " .. tostring(GetCVar("pingMode")) .. ", enablePings = " .. tostring(GetCVar("enablePings")))
    print("  Tecla de ping actual: " .. tostring(GetBindingKey(ACTION)))
    local count = 0
    for _ in pairs(wrapped) do count = count + 1 end
    print("  Marcos enganchados: " .. count)

    local foci = GetMouseFoci and GetMouseFoci() or { GetMouseFocus and GetMouseFocus() }
    local frame = foci and foci[1]
    local depth = 0
    while frame and depth < 8 do
        local name = frame.GetDebugName and frame:GetDebugName() or tostring(frame:GetName())
        local line = ("  [%d] %s mouse=%s protegido=%s"):format(depth, name,
            tostring(frame.IsMouseClickEnabled and frame:IsMouseClickEnabled()),
            tostring(frame.IsProtected and frame:IsProtected()))
        if frame.GetAttribute then
            line = line .. (" enganchado=%s ping-receiver=%s type=%s *type1=%s"):format(
                tostring(wrapped[frame] ~= nil),
                tostring(frame:GetAttribute("ping-receiver")),
                tostring(frame:GetAttribute("type")),
                tostring(frame:GetAttribute("*type1")))
        end
        print(line)
        frame = frame:GetParent()
        depth = depth + 1
    end
end
