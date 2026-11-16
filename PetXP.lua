local _, ns = ...

------------------------------------------------------------------------
-- Pet XP bar: a thin bar under your pet's frame (or wherever you drag
-- it), shown while your hunter pet is out. Options live in a small
-- window: right-click the bar, the Customize button in Settings, or
-- /bttk petxp.
------------------------------------------------------------------------
local DEFAULT_COLOR = { r = 0.67, g = 0.83, b = 0.45 } -- hunter green

local bar = CreateFrame("StatusBar", "BeastTrainingTrackerKuroPetXP", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
bar:SetHeight(7)
bar:SetFrameStrata("MEDIUM")
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar:SetMinMaxValues(0, 1)
bar:SetValue(0)
bar:SetMovable(true)
bar:EnableMouse(true)
bar:SetClampedToScreen(true)
bar:RegisterForDrag("LeftButton")
bar:Hide()
if bar.SetBackdrop then
  bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
  bar:SetBackdropColor(0, 0, 0, 0.6)
  bar:SetBackdropBorderColor(0, 0, 0, 0.9)
end

local text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
text:SetPoint("CENTER", 0, 1)
text:Hide()

local function Opts() return ns.db.opts end

local function Color()
  local c = Opts().petXpColor or DEFAULT_COLOR
  return c.r, c.g, c.b
end

-- Width of the pet portrait + health/mana bars, in the pet frame's scale
local function PetFrameWidth()
  local pf = _G.PetFrame
  if not pf then return end
  local left = _G.PetPortrait or pf
  local right = _G.PetFrameManaBar or _G.PetFrameHealthBar
  local l, r = left:GetLeft(), right and right:GetRight()
  if l and r and r > l then return r - l end
end

-- Default spot: under the pet frame, from the left of the pet's portrait
-- to the right end of its bars. Parented to the pet frame so it scales
-- and hides with it. Once dragged, it lives on UIParent where you put it.
local function Place()
  local o = Opts()
  bar:ClearAllPoints()
  bar:SetHeight(o.petXpHeight or 7)
  local p = ns.db.petXpPos
  if p then
    if bar:GetParent() ~= UIParent then bar:SetParent(UIParent) end
    bar:SetWidth(o.petXpAutoWidth and (p[5] or 120) or o.petXpWidth)
    bar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  else
    local pf = _G.PetFrame
    if pf then
      if bar:GetParent() ~= pf then bar:SetParent(pf) end
      bar:SetWidth(o.petXpAutoWidth and (PetFrameWidth() or 120) or o.petXpWidth)
      bar:SetPoint("TOPLEFT", _G.PetPortrait or pf, "BOTTOMLEFT", 0, -3)
    else
      if bar:GetParent() ~= UIParent then bar:SetParent(UIParent) end
      bar:SetWidth(o.petXpAutoWidth and 120 or o.petXpWidth)
      bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 100, -120)
    end
  end
  bar:SetFrameLevel((bar:GetParent():GetFrameLevel() or 0) + 5)
end

local function PetXP()
  if not (UnitExists("pet") and GetPetExperience) then return end
  if HasPetUI then
    local hasUI, isHunterPet = HasPetUI()
    if not (hasUI and isHunterPet) then return end
  end
  local cur, max = GetPetExperience()
  if not cur or not max or max <= 0 then return end
  return cur, max
end

local function Label()
  local cur, max = PetXP()
  if not cur then return "" end
  local o = Opts()
  -- "Fang  Lvl 31:  1234 / 5678  (22%)", minus whatever parts are turned off
  local who = {}
  if o.petXpShowName then who[#who + 1] = UnitName("pet") or "Pet" end
  if o.petXpShowLevel then who[#who + 1] = ("Lvl %d"):format(UnitLevel("pet") or 0) end
  local nums = {}
  if o.petXpShowXP then nums[#nums + 1] = ("%d / %d"):format(cur, max) end
  if o.petXpShowPct then
    local pct = ("%d%%"):format(math.floor(cur / max * 100))
    nums[#nums + 1] = o.petXpShowXP and ("(" .. pct .. ")") or pct
  end
  local a, b = table.concat(who, "  "), table.concat(nums, "  ")
  if a ~= "" and b ~= "" then return a .. ":  " .. b end
  return a .. b
end

local hovering
local function Update()
  if not ns.db or not Opts().petXpBar or not ns.Active() then bar:Hide() return end
  local cur, max = PetXP()
  if not cur then bar:Hide() return end
  if not bar.moving then Place() end
  bar:SetStatusBarColor(Color())
  bar:SetMinMaxValues(0, max)
  bar:SetValue(cur)
  if hovering or Opts().petXpTextAlways then
    text:SetText(Label())
    text:Show()
  else
    text:Hide()
  end
  bar:Show()
end
ns.UpdatePetXP = Update

------------------------------------------------------------------------
-- Mouse: tooltip, drag to move, right-click for options
------------------------------------------------------------------------
bar:SetScript("OnEnter", function(self)
  hovering = true
  text:SetText(Label())
  text:Show()
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:AddLine("Pet experience", 1, 0.82, 0)
  local cur, max = PetXP()
  if cur then
    GameTooltip:AddLine(("%d / %d  (%d to level %d)"):format(cur, max, max - cur, (UnitLevel("pet") or 0) + 1), 1, 1, 1)
    if (UnitLevel("pet") or 0) >= (UnitLevel("player") or 0) then
      GameTooltip:AddLine("Your pet can't level past you.", 1, 0.5, 0.25, true)
    end
  end
  GameTooltip:AddLine(" ")
  if not Opts().petXpLock then GameTooltip:AddLine("Drag: move", 0.5, 0.5, 0.5) end
  GameTooltip:AddLine("Right-click: options  ·  Shift-right-click: snap back under the pet frame", 0.5, 0.5, 0.5, true)
  GameTooltip:Show()
end)
bar:SetScript("OnLeave", function()
  hovering = nil
  if not Opts().petXpTextAlways then text:Hide() end
  GameTooltip_Hide()
end)

bar:SetScript("OnDragStart", function(self)
  if Opts().petXpLock then return end
  -- detach from the pet frame, keeping its on-screen size and spot
  local s = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
  local w = self:GetWidth() * s
  local x, y = self:GetCenter()
  self:SetParent(UIParent)
  self:SetFrameStrata("MEDIUM")
  self:ClearAllPoints()
  self:SetWidth(w)
  if x then self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x * s, y * s) end
  self:StartMoving()
  self.moving = true
end)
bar:SetScript("OnDragStop", function(self)
  if not self.moving then return end
  self.moving = nil
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint()
  ns.db.petXpPos = { p, rp, x, y, self:GetWidth() }
end)

local function ResetPosition()
  ns.db.petXpPos = nil
  Update()
  ns.Say("pet XP bar moved back under your pet frame.")
end

------------------------------------------------------------------------
-- Options window
------------------------------------------------------------------------
local win
local function Slider(name, label, lo, hi, step, x, y, key)
  local s = CreateFrame("Slider", name, win, "OptionsSliderTemplate")
  s:SetWidth(200)
  s:SetPoint("TOPLEFT", x, y)
  s:SetMinMaxValues(lo, hi)
  s:SetValueStep(step)
  if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
  local low, high = s.Low or _G[name .. "Low"], s.High or _G[name .. "High"]
  s.label = s.Text or _G[name .. "Text"]
  if low then low:SetText(lo) end
  if high then high:SetText(hi) end
  s:SetScript("OnValueChanged", function(self, v)
    v = math.floor(v / step + 0.5) * step
    if s.label then s.label:SetText(("%s: %d"):format(label, v)) end
    if win.filling then return end
    Opts()[key] = v
    Update()
  end)
  return s
end

local function CheckBox(label, x, y, key)
  local cb = CreateFrame("CheckButton", nil, win, "UICheckButtonTemplate")
  cb:SetSize(22, 22)
  cb:SetPoint("TOPLEFT", x, y)
  local fs = cb.text or cb.Text
  if not fs then
    fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
  end
  fs:SetFontObject("GameFontHighlightSmall")
  fs:SetText(label)
  cb:SetScript("OnClick", function(self)
    Opts()[key] = self:GetChecked() and true or false
    if win.Fill then win.Fill() end
    Update()
  end)
  return cb
end

local function Button(label, w, onClick)
  local b = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
  b:SetSize(w, 22)
  b:SetText(label)
  b:SetScript("OnClick", onClick)
  return b
end

local function BuildWindow()
  win = CreateFrame("Frame", "BeastTrainingTrackerKuroPetXPOptions", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  win:SetSize(280, 360)
  win:SetPoint("CENTER")
  win:SetFrameStrata("DIALOG")
  win:SetMovable(true)
  win:EnableMouse(true)
  win:SetClampedToScreen(true)
  win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", win.StopMovingOrSizing)
  if win.SetBackdrop then
    win:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24,
      insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
  end
  tinsert(UISpecialFrames, win:GetName()) -- Escape closes it

  local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -14)
  title:SetText("Pet XP Bar")
  local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)

  -- color
  local colorLabel = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  colorLabel:SetPoint("TOPLEFT", 20, -44)
  colorLabel:SetText("Bar color")
  local swatch = CreateFrame("Button", nil, win, BackdropTemplateMixin and "BackdropTemplate" or nil)
  swatch:SetSize(36, 18)
  swatch:SetPoint("LEFT", colorLabel, "RIGHT", 10, 0)
  if swatch.SetBackdrop then
    swatch:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8 })
    swatch:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)
  end
  swatch.color = swatch:CreateTexture(nil, "ARTWORK")
  swatch.color:SetPoint("TOPLEFT", 3, -3)
  swatch.color:SetPoint("BOTTOMRIGHT", -3, 3)
  local function SetColor(r, g, b)
    Opts().petXpColor = { r = r, g = g, b = b }
    swatch.color:SetColorTexture(r, g, b, 1)
    Update()
  end
  swatch:SetScript("OnClick", function()
    local r, g, b = Color()
    local function apply() SetColor(ColorPickerFrame:GetColorRGB()) end
    local function cancel() SetColor(r, g, b) end
    if ColorPickerFrame.SetupColorPickerAndShow then
      ColorPickerFrame:SetupColorPickerAndShow({ r = r, g = g, b = b, hasOpacity = false, swatchFunc = apply, cancelFunc = cancel })
    else
      ColorPickerFrame.hasOpacity = false
      ColorPickerFrame.opacityFunc = nil
      ColorPickerFrame.previousValues = { r, g, b }
      ColorPickerFrame.func = apply
      ColorPickerFrame.cancelFunc = cancel
      ColorPickerFrame:SetColorRGB(r, g, b)
      ColorPickerFrame:Hide()
      ColorPickerFrame:Show()
    end
  end)
  local resetColor = Button("Default", 70, function()
    Opts().petXpColor = nil
    swatch.color:SetColorTexture(Color())
    Update()
  end)
  resetColor:SetPoint("LEFT", swatch, "RIGHT", 10, 0)

  -- size
  local height = Slider("BeastTrainingTrackerKuroPetXPHeight", "Height", 3, 24, 1, 40, -88, "petXpHeight")
  local autoW = CheckBox("Match the pet frame's width", 16, -120, "petXpAutoWidth")
  local width = Slider("BeastTrainingTrackerKuroPetXPWidth", "Width", 60, 400, 5, 40, -164, "petXpWidth")

  -- behaviour
  local always = CheckBox("Always show the numbers", 16, -194, "petXpTextAlways")
  local lock = CheckBox("Lock position", 16, -218, "petXpLock")

  -- which parts of the text to show
  local textLabel = win:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  textLabel:SetPoint("TOPLEFT", 20, -250)
  textLabel:SetText("Text on the bar")
  local showName = CheckBox("Pet name", 16, -266, "petXpShowName")
  local showLevel = CheckBox("Level", 140, -266, "petXpShowLevel")
  local showXP = CheckBox("XP numbers", 16, -290, "petXpShowXP")
  local showPct = CheckBox("Percent", 140, -290, "petXpShowPct")

  local resetPos = Button("Move back under pet frame", 180, ResetPosition)
  resetPos:SetPoint("BOTTOM", 0, 18)

  function win.Fill()
    local o = Opts()
    win.filling = true
    swatch.color:SetColorTexture(Color())
    height:SetValue(o.petXpHeight or 7)
    width:SetValue(o.petXpWidth or 160)
    win.filling = nil
    autoW:SetChecked(o.petXpAutoWidth)
    always:SetChecked(o.petXpTextAlways)
    lock:SetChecked(o.petXpLock)
    showName:SetChecked(o.petXpShowName)
    showLevel:SetChecked(o.petXpShowLevel)
    showXP:SetChecked(o.petXpShowXP)
    showPct:SetChecked(o.petXpShowPct)
    -- the width slider only matters when not matching the pet frame
    width:SetAlpha(o.petXpAutoWidth and 0.4 or 1)
    width:EnableMouse(not o.petXpAutoWidth)
  end
  win:SetScript("OnShow", win.Fill)
end

function ns.TogglePetXPOptions()
  if not ns.db then return end
  if not win then BuildWindow() end
  if win:IsShown() then win:Hide() else win:Show() end
end

bar:SetScript("OnMouseUp", function(self, button)
  if button ~= "RightButton" then return end
  if IsShiftKeyDown() then ResetPosition() else ns.TogglePetXPOptions() end
end)

------------------------------------------------------------------------
local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "UNIT_PET", "UNIT_PET_EXPERIENCE", "PET_UI_UPDATE", "UNIT_LEVEL",
  "PLAYER_LEVEL_UP" }) do
  pcall(ev.RegisterEvent, ev, e)
end
-- after Blizzard has shown/hidden the pet frame for this event
ev:SetScript("OnEvent", function() if C_Timer then C_Timer.After(0, Update) else Update() end end)

ns.OnRefresh(function() Update() end)
ns.OnDeactivate(function() bar:Hide() end)
