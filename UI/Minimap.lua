-- Módulo: Minimap button (lado do addon).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Minimap = CEF.Minimap or {}
local state = CEF.Minimap

local function mmFrame()
  return _G.Minimap
end

function state.place()
  if not state.button or not mmFrame() then
    return
  end

  CEF.DB.init()

  local angle = math.rad(tonumber(ClassicEraFinderDB.minimap.angle) or 218)
  local x, y = math.cos(angle), math.sin(angle)
  local mm = mmFrame()
  local radius = (mm:GetWidth() / 2) + 5
  state.button:ClearAllPoints()
  state.button:SetPoint("CENTER", mm, "CENTER", x * radius, y * radius)
end

function state.saveAngleFromCursor()
  if not mmFrame() then
    return
  end
  CEF.DB.init()
  local mm = mmFrame()
  local mx, my = mm:GetCenter()
  local px, py = GetCursorPosition()
  local scale = mm:GetEffectiveScale()
  px, py = px / scale, py / scale
  local dx, dy = px - mx, py - my
  ClassicEraFinderDB.minimap.angle = math.deg(math.atan2(dy, dx))
  state.place()
end

function state.create(onClickToggle)
  if state.button or not mmFrame() then
    return state.button
  end
  if type(onClickToggle) ~= "function" then
    return state.button
  end

  CEF.DB.init()

  local b = CreateFrame("Button", "ClassicEraFinderMinimapButton", mmFrame())
  b:SetSize(32, 32)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(mmFrame():GetFrameLevel() + 6)

  -- O Button cria Normal/Pushed por defeito; isso costuma desalinhar ou mostrar ícone “estranho”.
  b:SetNormalTexture("")
  b:SetPushedTexture("")
  b:SetDisabledTexture("")
  local nt = b:GetNormalTexture()
  if nt then
    nt:Hide()
  end
  local pt = b:GetPushedTexture()
  if pt then
    pt:Hide()
  end

  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local hi = b:GetHighlightTexture()
  if hi and hi.SetBlendMode then
    hi:SetBlendMode("ADD")
  end
  if hi and hi.SetAllPoints then
    hi:SetAllPoints(b)
  end

  -- Template anchors igual ao MinimapTrackingButton da Blizzard.
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetSize(20, 20)
  icon:SetPoint("TOPLEFT", b, "TOPLEFT", 6, -6)
  icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")

  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53)
  border:SetPoint("TOPLEFT", b, "TOPLEFT", -1, 1)

  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Classic Era Finder", 1, 0.9, 0.3)
    GameTooltip:AddLine(CEF.L.MINIMAP_TIP_LEFT, 1, 1, 1, true)
    GameTooltip:AddLine(CEF.L.MINIMAP_TIP_RIGHT, 0.75, 0.75, 0.75, true)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", GameTooltip_Hide)

  b:RegisterForClicks("LeftButtonUp")
  b:RegisterForDrag("RightButton")

  b:SetScript("OnClick", function()
    onClickToggle()
  end)
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      state.saveAngleFromCursor()
    end)
  end)
  b:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
    state.saveAngleFromCursor()
  end)

  state.button = b
  state.place()
  return b
end

--- Fecha o tray do MinimapButtonButton se estiver aberto (sem API pública).
function state.collapseExternalCollectors()
  local main = _G.MinimapButtonButtonButton
  if not main or type(main.GetChildren) ~= "function" then
    return
  end
  local open = false
  local children = { main:GetChildren() }
  for i = 1, #children do
    local child = children[i]
    if child and child.IsShown and child:IsShown() then
      open = true
      break
    end
  end
  if not open then
    return
  end
  -- Usa o OnMouseDown do MBB (LeftButton = toggle) para manter o estado interno certo.
  local onMouseDown = main.GetScript and main:GetScript("OnMouseDown")
  if type(onMouseDown) == "function" then
    pcall(onMouseDown, main, "LeftButton")
  end
end

