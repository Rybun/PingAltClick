-- PingAltClick: modificador + clic (Alt + clic izquierdo por defecto) = sistema de
-- pings normal de Blizzard. El modificador (Alt, Ctrl, Shift o combinaciones) y el
-- botón (izquierdo o derecho) se eligen en /pingac o en Opciones -> AddOns.
--
-- Mundo: la tecla de ping (TOGGLEPINGLISTENER) llama a C_Ping.TogglePingListener,
-- que está restringida, así que se asigna esa misma acción a la combinación elegida
-- (p. ej. ALT-BUTTON1) con un override binding y el modo de ping "Mantener tecla"
-- (pingMode = 0):
--   * clic rápido        -> ping contextual (unidad, objeto o punto del mundo)
--   * mantener clic      -> rueda radial; mover el ratón y soltar para elegir
--
-- Interfaz: los clics sobre marcos no llegan a las asignaciones de teclas. En los
-- botones de acción y marcos de unidad se envuelve el OnClick con un fragmento
-- seguro que, con la combinación elegida, redirige el clic a un botón virtual
-- "pingalt" que ejecuta /ping. Así no se pisa lo que configuran Bartender o Clique,
-- y modificador + tecla de atajo sigue funcionando como siempre.
--
-- Marcos de unidad fuera de combate: mientras el modificador está pulsado se
-- desactivan sus clics (el movimiento del ratón no), así que el clic cae al mundo,
-- salta la asignación y el juego detecta el marco bajo el cursor igual que con la
-- tecla de ping, rueda radial incluida.
--
-- En combate SetMouseClickEnabled y SetPassThroughButtons están bloqueados, así que
-- un controlador de estado seguro ([mod:...]) desactiva el ratón de esos marcos con
-- EnableMouse, que sí está permitido en código seguro, y el resultado es el mismo:
-- el ping funciona igual dentro y fuera de combate.
local ACTION = "TOGGLEPINGLISTENER"
local PING_MODE_KEY_DOWN = Enum.PingMode and Enum.PingMode.KeyDown or 0
local PING_CMD = SLASH_PING1 or "/ping"
-- Sin objetivo: el juego busca el receptor de ping bajo el cursor, igual que con la
-- tecla de ping (hechizo/objeto del botón, unidad del marco, "Salud 100%" en la barra de vida...)
local MACRO_ACTION = PING_CMD
local MACRO_UNIT = PING_CMD

local DEFAULTS = {
    modifier = "ALT",
    button = "LeftButton",
}

-- Orden canónico de los modificadores en las asignaciones de WoW: ALT-CTRL-SHIFT.
-- "NONE" (sin modificador) solo se permite con los botones 3-5.
local MODIFIERS = { "ALT", "CTRL", "SHIFT", "ALT-CTRL", "ALT-SHIFT", "CTRL-SHIFT", "NONE" }
local BUTTONS = { "LeftButton", "RightButton", "MiddleButton", "Button4", "Button5" }
local BUTTON_KEYS = {
    LeftButton = "BUTTON1", RightButton = "BUTTON2", MiddleButton = "BUTTON3",
    Button4 = "BUTTON4", Button5 = "BUTTON5",
}
-- Botones que no pueden ir sin modificador (romperían el clic normal)
local NEEDS_MODIFIER = { LeftButton = true, RightButton = true }

local L = {
    ALT = "Alt", CTRL = "Ctrl", SHIFT = "Shift", NONE = "None (buttons 3-5 only)",
    LeftButton = "Left Click", RightButton = "Right Click", MiddleButton = "Middle Button",
    Button4 = "Mouse Button 4", Button5 = "Mouse Button 5",
    MODIFIER = "Modifier",
    MODIFIER_TOOLTIP = "Key to hold while clicking to ping. It must match exactly: with Alt selected, Ctrl + Alt + click is left alone for other addons.\n\n\"None\" is only available with the middle button and buttons 4 and 5.",
    BUTTON = "Mouse button",
    BUTTON_TOOLTIP = "Mouse button used to ping while holding the modifier.",
    NONE_ADJUSTED = "No modifier only works with the middle button or buttons 4 and 5. Adjusted to: %s",
    CURRENT = "Ping with: |cffffd100%s|r",
    CONFLICT = "|cffff8040%s|r was bound to \"%s\". PingAltClick takes priority over it.",
    RESET = "Reset",
    APPLY_AFTER_COMBAT = "The change will be applied when combat ends.",
    USAGE = "Usage: /pingac (window), /pingac <alt|ctrl|shift|ctrl+alt...|none> <left|right|middle|4|5>, /pingac reset",
}
if GetLocale() == "esES" or GetLocale() == "esMX" then
    L.SHIFT = "Mayús"
    L.NONE = "Ninguno (solo botones 3-5)"
    L.LeftButton = "Clic izquierdo"
    L.RightButton = "Clic derecho"
    L.MiddleButton = "Botón central"
    L.Button4 = "Botón 4 del ratón"
    L.Button5 = "Botón 5 del ratón"
    L.MODIFIER = "Modificador"
    L.MODIFIER_TOOLTIP = "Tecla que hay que mantener al hacer clic para hacer ping. Tiene que coincidir exactamente: con Alt elegido, Ctrl + Alt + clic queda libre para otros addons.\n\n\"Ninguno\" solo está disponible con el botón central y los botones 4 y 5."
    L.BUTTON = "Botón del ratón"
    L.BUTTON_TOOLTIP = "Botón del ratón con el que se hace ping mientras mantienes el modificador."
    L.NONE_ADJUSTED = "Sin modificador solo funciona con el botón central o los botones 4 y 5. Ajustado a: %s"
    L.CURRENT = "Ping con: |cffffd100%s|r"
    L.CONFLICT = "|cffff8040%s|r estaba asignado a \"%s\". PingAltClick tiene prioridad."
    L.RESET = "Restablecer"
    L.APPLY_AFTER_COMBAT = "El cambio se aplicará al salir de combate."
    L.USAGE = "Uso: /pingac (ventana), /pingac <alt|ctrl|shift|ctrl+alt...|ninguno> <izq|der|central|4|5>, /pingac reset"
end

local db

local function cfg()
    return db or DEFAULTS
end

local function hasMod(part)
    return ("-" .. cfg().modifier .. "-"):find("-" .. part .. "-", 1, true) ~= nil
end

local function noModifier()
    return cfg().modifier == "NONE"
end

local function bindingKey()
    if noModifier() then return BUTTON_KEYS[cfg().button] end
    return cfg().modifier .. "-" .. BUTTON_KEYS[cfg().button]
end

local function modifierText(m)
    if m == "NONE" then return L.NONE end
    local parts = {}
    for part in m:gmatch("[^-]+") do
        parts[#parts + 1] = L[part] or part
    end
    return table.concat(parts, " + ")
end

local function comboText()
    if noModifier() then return L[cfg().button] end
    return modifierText(cfg().modifier) .. " + " .. L[cfg().button]:lower()
end

-- Condición del controlador de estado: el modificador exacto, sin los demás.
-- Sin modificador no hace falta: los marcos dejan pasar ese botón todo el rato.
local function stateCondition()
    if noModifier() then return "0" end
    local c = {}
    for _, part in ipairs({ "ALT", "CTRL", "SHIFT" }) do
        c[#c + 1] = (hasMod(part) and "mod:" or "nomod:") .. part:lower()
    end
    return "[" .. table.concat(c, ",") .. "] 1; 0"
end

local function modifiersMatch()
    return (not IsAltKeyDown()) == (not hasMod("ALT"))
        and (not IsControlKeyDown()) == (not hasMod("CTRL"))
        and (not IsShiftKeyDown()) == (not hasMod("SHIFT"))
end

local f = CreateFrame("Frame")
local header = CreateFrame("Frame", "PingAltClickHeader", UIParent, "SecureHandlerStateTemplate")
header:SetAttribute("nunits", 0)
-- Modificador pulsado en combate: el clic de los marcos de unidad pasa al mundo
header:SetAttribute("_onstate-pingalt", [[
    local total = self:GetAttribute("nunits") or 0
    local count, missing = 0, 0
    local enable = tostring(newstate) ~= "1"
    if not enable and not PlayerInCombat() then
        total = 0
    end
    for i = 1, total do
        local frame = self:GetFrameRef("unit" .. i)
        if frame then
            if enable then
                if self:GetAttribute("disabled" .. i) then
                    frame:EnableMouse(true)
                    self:SetAttribute("disabled" .. i, nil)
                    count = count + 1
                end
            elseif not self:GetAttribute("disabled" .. i) then
                -- Los marcos de unidad siempre tienen el ratón activo
                frame:EnableMouse(false)
                self:SetAttribute("disabled" .. i, true)
                count = count + 1
            end
        else
            missing = missing + 1
        end
    end
    if self:GetAttribute("debug") then
        self:CallMethod("DebugState", newstate, PlayerInCombat(), total, count, missing)
    end
]])
function header:DebugState(state, inCombat, total, count, missing)
    print(("|cff33ff99PingAltClick|r estado=%s combate=%s marcos=%s cambiados=%s sin-ref=%s"):format(
        tostring(state), tostring(inCombat), tostring(total), tostring(count), tostring(missing)))
end
RegisterStateDriver(header, "pingalt", stateCondition())
local wrapped = {}
local pending = {}
local unitFrames = {}
local clickDisabled = {}

-- La combinación se lee de atributos del propio botón (los pone setFrameConfig).
-- Las pulsaciones de atajos (p. ej. Alt+1 en una barra paginada) también llegan
-- como LeftButton: solo es ping si el cursor está realmente sobre el botón.
local PRE_CLICK = [[
    if button == self:GetAttribute("pingalt-button")
        and (not IsAltKeyDown()) == (not self:GetAttribute("pingalt-alt"))
        and (not IsControlKeyDown()) == (not self:GetAttribute("pingalt-ctrl"))
        and (not IsShiftKeyDown()) == (not self:GetAttribute("pingalt-shift"))
        and self:IsUnderMouse(true) then
        return "pingalt"
    end
]]

local function setFrameConfig(frame)
    frame:SetAttribute("pingalt-button", cfg().button)
    frame:SetAttribute("pingalt-alt", hasMod("ALT") or nil)
    frame:SetAttribute("pingalt-ctrl", hasMod("CTRL") or nil)
    frame:SetAttribute("pingalt-shift", hasMod("SHIFT") or nil)
end

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
    setFrameConfig(frame)
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

local secureUnits = {}

local function hookUnit(frame)
    if not frame then return end
    unitFrames[frame] = true
    hook(frame, MACRO_UNIT)
    if not secureUnits[frame] and wrapped[frame] and not InCombatLockdown() then
        local n = header:GetAttribute("nunits") + 1
        secureUnits[frame] = n
        header:SetFrameRef("unit" .. n, frame)
        header:SetAttribute("nunits", n)
    end
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

-- Barras y marcos de otros addons (EllesmereUI, etc.) tienen nombres propios: se
-- reconocen por sus atributos seguros en lugar de por el nombre.
local function isActionButton(frame)
    return frame:GetAttribute("action") ~= nil or frame:GetAttribute("type") == "action"
end

local function isUnitButton(frame)
    return frame:GetAttribute("*type1") == "target" or frame:GetAttribute("type1") == "target"
        or (frame:GetAttribute("unit") ~= nil and frame:IsMouseEnabled())
end

local lastScan = 0

local function scanFrames()
    if InCombatLockdown() then return end
    lastScan = GetTime()
    local frame = EnumerateFrames()
    while frame do
        if not frame:IsForbidden() and not wrapped[frame] and frame:IsObjectType("Button") and frame:IsProtected() then
            if isActionButton(frame) then
                hook(frame, MACRO_ACTION)
            elseif isUnitButton(frame) then
                hookUnit(frame)
            end
        end
        frame = EnumerateFrames(frame)
    end
end

local scanQueued

local updateUnitClicks

local function queueScan()
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(1, function()
        scanQueued = false
        scanFrames()
        -- Sin modificador, los marcos nuevos también dejan pasar el botón
        if updateUnitClicks then updateUnitClicks() end
    end)
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
    SetOverrideBinding(f, true, bindingKey(), ACTION)
end

-- Modificador pulsado fuera de combate: el botón de ping de los marcos de unidad
-- pasa al mundo. Con SetPassThroughButtons solo pasa ese botón, así que el resto
-- (p. ej. Alt + clic derecho de Clique) sigue llegando al marco. Si no se puede,
-- se recurre a desactivar todos los clics del marco.
local PASS_BUTTONS = { "LeftButton", "RightButton", "MiddleButton", "Button4", "Button5" }

local function setPassThrough(frame, button)
    if not (frame.SetPassThroughButtons and frame.ShouldButtonPassThrough) then return end
    local prev, list = {}, {}
    for _, b in ipairs(PASS_BUTTONS) do
        if frame:ShouldButtonPassThrough(b) then
            prev[#prev + 1] = b
            list[#list + 1] = b
        end
    end
    if frame:ShouldButtonPassThrough(button) then return prev end
    list[#list + 1] = button
    if pcall(frame.SetPassThroughButtons, frame, unpack(list)) and frame:ShouldButtonPassThrough(button) then
        return prev
    end
end

local function restoreUnitClicks(keepPermanent)
    for frame, state in pairs(clickDisabled) do
        if not (keepPermanent and state ~= true) then
            clickDisabled[frame] = nil
            if state == true then
                frame:SetMouseClickEnabled(true)
            else
                pcall(frame.SetPassThroughButtons, frame, unpack(state))
            end
        end
    end
end

function updateUnitClicks()
    if InCombatLockdown() then return end
    -- Sin modificador (botones 3-5) el botón pasa al mundo siempre
    if not (noModifier() or modifiersMatch()) then
        restoreUnitClicks()
        return
    end
    -- Recoge los marcos creados más tarde (cambios de perfil, opciones...)
    if GetTime() - lastScan > 5 then
        scanFrames()
    end
    for frame in pairs(unitFrames) do
        if not clickDisabled[frame] then
            local prev = setPassThrough(frame, cfg().button)
            if prev then
                clickDisabled[frame] = prev
            elseif not noModifier() and frame:IsMouseClickEnabled() then
                clickDisabled[frame] = true
                frame:SetMouseClickEnabled(false)
            end
        end
    end
end

local mod = CreateFrame("Frame")
mod:RegisterEvent("MODIFIER_STATE_CHANGED")
mod:RegisterEvent("PLAYER_REGEN_DISABLED")
mod:RegisterEvent("PLAYER_REGEN_ENABLED")
mod:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        -- Última ocasión antes del bloqueo de combate. Si el modificador sigue
        -- pulsado, se fuerza al controlador seguro a reevaluar para que tome el relevo.
        -- Sin modificador, el paso del botón al mundo se queda puesto en combate.
        restoreUnitClicks(noModifier())
        header:SetAttribute("state-pingalt", "0")
    else
        updateUnitClicks()
    end
end)

-- Aplica modificador, botón y opción de combate (fuera de combate)
local function applyConfig()
    if InCombatLockdown() then
        f:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    RegisterStateDriver(header, "pingalt", stateCondition())
    for frame in pairs(wrapped) do
        setFrameConfig(frame)
    end
    applyBinding()
    restoreUnitClicks()
    updateUnitClicks()
end

local listeners = {}

local function notifyListeners()
    for _, fn in ipairs(listeners) do fn() end
end

-- Sin modificador solo con los botones 3-5: si no, se ajusta el otro campo
local function normalizeConfig(changedKey)
    if db and db.modifier == "NONE" and NEEDS_MODIFIER[db.button] then
        if changedKey == "button" then
            db.modifier = DEFAULTS.modifier
        else
            db.button = "Button5"
        end
        print("|cff33ff99PingAltClick|r " .. L.NONE_ADJUSTED:format(comboText()))
    end
end

local warnedCombat
local function onConfigChanged(changedKey)
    normalizeConfig(changedKey)
    if InCombatLockdown() then
        if not warnedCombat then
            warnedCombat = true
            print("|cff33ff99PingAltClick|r: " .. L.APPLY_AFTER_COMBAT)
        end
    end
    applyConfig()
    notifyListeners()
end

local settings = {}

local function setOption(key, value)
    if not db or db[key] == value then return end
    local setting = settings[key]
    if setting and setting.SetValue then
        -- Escribe en db y dispara onConfigChanged a través del panel
        setting:SetValue(value)
    end
    if db[key] ~= value then
        db[key] = value
    end
    onConfigChanged(key)
end

local function isValid(list, value)
    for _, v in ipairs(list) do
        if v == value then return true end
    end
end

-- Asignación normal (sin override) que la combinación elegida pisa, si la hay
local function bindingConflict()
    local key = bindingKey()
    local action = GetBindingAction(key)
    if action and action ~= "" and action ~= ACTION then
        local name = _G["BINDING_NAME_" .. action] or action
        return L.CONFLICT:format(comboText(), name)
    end
end

local function setupOptions()
    if not (Settings and Settings.RegisterVerticalLayoutCategory) then return end
    local VarType = Settings.VarType or {}
    local category = Settings.RegisterVerticalLayoutCategory("PingAltClick")

    local function onChanged(key)
        return function()
            onConfigChanged(key)
        end
    end
    local function watch(setting, variable, key)
        if setting.SetValueChangedCallback then
            setting:SetValueChangedCallback(onChanged(key))
        else
            Settings.SetOnValueChangedCallback(variable, onChanged(key))
        end
    end

    local CreateDropdown = Settings.CreateDropdown or Settings.CreateDropDown
    local function dropdown(variable, key, values, label, tooltip, textFn, varType)
        if not (CreateDropdown and Settings.CreateControlTextContainer) then return end
        local setting = Settings.RegisterAddOnSetting(category, variable, key, db,
            varType or VarType.String or "string", label, DEFAULTS[key])
        CreateDropdown(category, setting, function()
            local container = Settings.CreateControlTextContainer()
            for _, v in ipairs(values) do
                container:Add(v, textFn(v))
            end
            return container:GetData()
        end, tooltip)
        watch(setting, variable, key)
        settings[key] = setting
    end
    dropdown("PingAltClick_Modifier", "modifier", MODIFIERS, L.MODIFIER, L.MODIFIER_TOOLTIP, modifierText)
    dropdown("PingAltClick_Button", "button", BUTTONS, L.BUTTON, L.BUTTON_TOOLTIP, function(v) return L[v] end)


    Settings.RegisterAddOnCategory(category)
end

-- Ventana de /pingac --------------------------------------------------------------

local function createDropdown(parent, name, values, textFn, key)
    local ok, dd = pcall(CreateFrame, "DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    if ok and dd and dd.SetupMenu then
        dd:SetWidth(180)
        dd:SetupMenu(function(_, root)
            for _, v in ipairs(values) do
                root:CreateRadio(textFn(v), function() return cfg()[key] == v end,
                    function() setOption(key, v) end, v)
            end
        end)
        dd.Refresh = function() if dd.GenerateMenu then dd:GenerateMenu() end end
        return dd, 0
    end
    -- Cliente sin el menú nuevo: UIDropDownMenu clásico
    dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(dd, 160)
    UIDropDownMenu_Initialize(dd, function()
        for _, v in ipairs(values) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = textFn(v)
            info.checked = cfg()[key] == v
            info.func = function() setOption(key, v) end
            UIDropDownMenu_AddButton(info)
        end
    end)
    dd.Refresh = function() UIDropDownMenu_SetText(dd, textFn(cfg()[key])) end
    return dd, -16
end

local window

local function createWindow()
    local ok, w = pcall(CreateFrame, "Frame", "PingAltClickConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    if not ok then
        w = CreateFrame("Frame", "PingAltClickConfigFrame", UIParent, "BackdropTemplate")
        w:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
        local close = CreateFrame("Button", nil, w, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
    end
    w:SetSize(380, 210)
    w:SetPoint("CENTER")
    w:SetFrameStrata("DIALOG")
    w:SetClampedToScreen(true)
    w:SetMovable(true)
    w:EnableMouse(true)
    w:RegisterForDrag("LeftButton")
    w:SetScript("OnDragStart", w.StartMoving)
    w:SetScript("OnDragStop", w.StopMovingOrSizing)
    tinsert(UISpecialFrames, "PingAltClickConfigFrame")

    local title = w.TitleText or w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    if not w.TitleText then title:SetPoint("TOP", 0, -14) end
    title:SetText("PingAltClick")

    local y = -40
    local function row(label, name, values, textFn, key)
        local text = w:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("TOPLEFT", 20, y - 6)
        text:SetText(label)
        local dd, xOffset = createDropdown(w, name, values, textFn, key)
        dd:SetPoint("TOPRIGHT", -20 - (xOffset ~= 0 and -16 or 0), y)
        y = y - 36
        return dd
    end
    w.modifier = row(L.MODIFIER, "PingAltClickModifierDropdown", MODIFIERS, modifierText, "modifier")
    w.button = row(L.BUTTON, "PingAltClickButtonDropdown", BUTTONS, function(v) return L[v] end, "button")


    local current = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    current:SetPoint("TOPLEFT", 20, y)
    current:SetPoint("RIGHT", -20, 0)
    current:SetJustifyH("LEFT")
    w.current = current

    local warning = w:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    warning:SetPoint("TOPLEFT", current, "BOTTOMLEFT", 0, -6)
    warning:SetPoint("RIGHT", -20, 0)
    warning:SetJustifyH("LEFT")
    w.warning = warning

    local reset = CreateFrame("Button", nil, w, "UIPanelButtonTemplate")
    reset:SetSize(110, 22)
    reset:SetPoint("BOTTOMRIGHT", -16, 14)
    reset:SetText(L.RESET)
    reset:SetScript("OnClick", function()
        for k, v in pairs(DEFAULTS) do setOption(k, v) end
    end)

    function w:Refresh()
        self.modifier.Refresh()
        self.button.Refresh()
        self.current:SetText(L.CURRENT:format(comboText()))
        self.warning:SetText(bindingConflict() or "")
    end
    w:SetScript("OnShow", w.Refresh)
    listeners[#listeners + 1] = function()
        if w:IsShown() then w:Refresh() end
    end
    return w
end

local function toggleWindow()
    window = window or createWindow()
    window:SetShown(not window:IsShown())
end

-- /pingac ctrl left, /pingac alt+shift der, /pingac reset
local BUTTON_ALIASES = {
    middle = "MiddleButton", mid = "MiddleButton", central = "MiddleButton", ["3"] = "MiddleButton", m3 = "MiddleButton", button3 = "MiddleButton", mouse3 = "MiddleButton",
    ["4"] = "Button4", m4 = "Button4", button4 = "Button4", mouse4 = "Button4",
    ["5"] = "Button5", m5 = "Button5", button5 = "Button5", mouse5 = "Button5",
    left = "LeftButton", l = "LeftButton", lmb = "LeftButton", izq = "LeftButton", izquierdo = "LeftButton", i = "LeftButton",
    right = "RightButton", r = "RightButton", rmb = "RightButton", der = "RightButton", derecho = "RightButton", d = "RightButton",
}
local MOD_ALIASES = { alt = "ALT", ctrl = "CTRL", control = "CTRL", shift = "SHIFT", mayus = "SHIFT", ["mayús"] = "SHIFT" }

local function parseModifier(token)
    if token == "none" or token == "ninguno" or token == "no" then return "NONE" end
    local have = {}
    for part in token:gmatch("[^%+%-]+") do
        local m = MOD_ALIASES[part]
        if not m then return end
        have[m] = true
    end
    local parts = {}
    for _, m in ipairs({ "ALT", "CTRL", "SHIFT" }) do
        if have[m] then parts[#parts + 1] = m end
    end
    local result = table.concat(parts, "-")
    return isValid(MODIFIERS, result) and result or nil
end

SLASH_PINGALTCLICKCONFIG1 = "/pingac"
SlashCmdList.PINGALTCLICKCONFIG = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
        toggleWindow()
        return
    end
    if msg == "reset" then
        for k, v in pairs(DEFAULTS) do setOption(k, v) end
    else
        local button, modifier
        for token in msg:gmatch("%S+") do
            if BUTTON_ALIASES[token] then
                button = BUTTON_ALIASES[token]
            elseif parseModifier(token) then
                modifier = parseModifier(token)
            else
                button, modifier = nil, nil
                break
            end
        end
        if not (button or modifier) then
            print("|cff33ff99PingAltClick|r " .. L.USAGE)
            return
        end
        if modifier then setOption("modifier", modifier) end
        if button then setOption("button", button) end
    end
    print("|cff33ff99PingAltClick|r " .. L.CURRENT:format(comboText()))
    local conflict = bindingConflict()
    if conflict then print("|cff33ff99PingAltClick|r " .. conflict) end
end

-- Arranque --------------------------------------------------------------------------

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
        warnedCombat = nil
        for frame, macro in pairs(pending) do
            pending[frame] = nil
            if unitFrames[frame] then
                hookUnit(frame)
            else
                hook(frame, macro)
            end
        end
        applyConfig()
        queueScan()
    elseif event == "PLAYER_LOGIN" then
        PingAltClickDB = PingAltClickDB or {}
        db = PingAltClickDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then db[k] = v end
        end
        if not isValid(MODIFIERS, db.modifier) then db.modifier = DEFAULTS.modifier end
        if not isValid(BUTTONS, db.button) then db.button = DEFAULTS.button end
        -- opciones retiradas en 2.6
        db.combatWheel = nil
        db.markOnAttack = nil
        if db.modifier == "NONE" and NEEDS_MODIFIER[db.button] then db.modifier = DEFAULTS.modifier end
        setupOptions()
        applyAll()
        applyConfig()
        local LAB = LibStub and LibStub("LibActionButton-1.0", true)
        if LAB and LAB.RegisterCallback then
            LAB.RegisterCallback(self, "OnButtonCreated", function(_, button)
                hook(button, MACRO_ACTION)
            end)
        end
    else
        applyAll()
        queueScan()
    end
end)

-- /pingalt: diagnóstico. Pon el ratón sobre un botón o marco y escribe /pingalt
SLASH_PINGALTCLICK1 = "/pingalt"
SlashCmdList.PINGALTCLICK = function(msg)
    if msg and msg:lower():match("^%s*debug") then
        if InCombatLockdown() then
            print("|cff33ff99PingAltClick|r: " .. L.APPLY_AFTER_COMBAT)
            return
        end
        local on = not header:GetAttribute("debug")
        header:SetAttribute("debug", on or nil)
        print("|cff33ff99PingAltClick|r debug: " .. (on and "ON" or "OFF"))
        return
    end
    local key = bindingKey()
    print("|cff33ff99PingAltClick|r")
    print("  " .. key .. " -> " .. tostring(GetBindingAction(key, true)) .. " (" .. stateCondition() .. ")")
    print("  pingMode = " .. tostring(GetCVar("pingMode")) .. ", enablePings = " .. tostring(GetCVar("enablePings")))
    print("  Tecla de ping actual: " .. tostring(GetBindingKey(ACTION)))
    print("  En combate: " .. tostring(InCombatLockdown()))
    local count = 0
    for _ in pairs(wrapped) do count = count + 1 end
    print("  Marcos enganchados: " .. count .. ", marcos de unidad (combate): " .. tostring(header:GetAttribute("nunits")))

    local foci = GetMouseFoci and GetMouseFoci() or { GetMouseFocus and GetMouseFocus() }
    local frame = foci and foci[1]
    local depth = 0
    while frame and depth < 8 do
        local name = frame.GetDebugName and frame:GetDebugName() or tostring(frame:GetName())
        local line = ("  [%d] %s mouse=%s protegido=%s"):format(depth, name,
            tostring(frame.IsMouseClickEnabled and frame:IsMouseClickEnabled()),
            tostring(frame.IsProtected and frame:IsProtected()))
        if frame.GetAttribute then
            line = line .. (" enganchado=%s pasa-botón=%s ping-receiver=%s type=%s *type1=%s"):format(
                tostring(wrapped[frame] ~= nil),
                tostring(frame.ShouldButtonPassThrough and frame:ShouldButtonPassThrough(cfg().button)),
                tostring(frame:GetAttribute("ping-receiver")),
                tostring(frame:GetAttribute("type")),
                tostring(frame:GetAttribute("*type1")))
        end
        print(line)
        frame = frame:GetParent()
        depth = depth + 1
    end
end
