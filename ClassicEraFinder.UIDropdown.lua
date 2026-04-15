-- Módulo: fábrica genérica de dropdown (botão + menu com pool de linhas).
--
-- Unifica a implementação dos 3 dropdowns (instância, intenção, função) que
-- antes duplicavam ~450 linhas em ClassicEraFinder.UI.lua.
--
-- Uso:
--
--   local dd = CEF.UIDropdown.build({
--     parent         = mainFrame,            -- frame pai do menu flutuante
--     anchorParent   = filterBar,            -- onde o botão é ancorado
--     anchorTo       = searchBorder,         -- Region a que o botão se ancora (opcional, usa anchorParent se nil)
--     anchorPoint    = "TOPRIGHT",           -- ponto do anchorTo (default "TOPRIGHT")
--     anchorOffset   = 10,                   -- x offset
--     width          = 196,
--     height         = 26,
--     rowHeight      = 22,
--     frameLevel     = 500,
--     maxRowPool     = 72,
--     maxVisibleRows = 11,
--     supportsHeaders = true,                -- se true, entries com kind == "hdr" viram cabeçalhos
--     getOptions     = function() return CEF.INSTANCE_FILTER_MENU_OPTS end,
--     renderRow      = function(opt) return CEF.instanceFilterOptionRichText(opt.key) end,
--     renderSummary  = function() return CEF.instanceFilterOptionRichText(CEF.state.filterInstanceKey) end,
--     onSelect       = function(opt, ctx) ... end,
--     onOpen         = function(ctx) ... esconde siblings ... end,
--   })
--
--   dd.button, dd.menu, dd.summaryFS  -- regions
--   dd.refresh()                      -- repopula o menu
--   dd.close()                        -- fecha

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UIDropdown = CEF.UIDropdown or {}
local UID = CEF.UIDropdown

local function applyTex(tex, rgba)
  if tex and rgba then
    tex:SetColorTexture(rgba[1], rgba[2], rgba[3], rgba[4] or 1)
  end
end

function UID.build(config)
  local T = CEF.Theme
  local RGBA = (T and T.RGBA) or {}
  local RGB  = (T and T.RGB) or {}

  local parent        = assert(config.parent, "UIDropdown.build: parent required")
  local anchorParent  = config.anchorParent or parent
  local anchorTo      = config.anchorTo or anchorParent
  local anchorPoint   = config.anchorPoint or "TOPRIGHT"
  local anchorOffset  = config.anchorOffset or 0
  local width         = config.width or 196
  local height        = config.height or 26
  local rowHeight     = config.rowHeight or 22
  local frameLevel    = config.frameLevel or 500
  local maxRowPool    = config.maxRowPool or 12
  local maxVisibleRows = config.maxVisibleRows or 8
  local supportsHeaders = config.supportsHeaders == true
  local getOptions    = assert(config.getOptions, "UIDropdown.build: getOptions required")
  local renderRow     = assert(config.renderRow,  "UIDropdown.build: renderRow required")
  local renderSummary = assert(config.renderSummary, "UIDropdown.build: renderSummary required")
  local onSelect      = assert(config.onSelect,   "UIDropdown.build: onSelect required")
  local onOpen        = config.onOpen

  -- ==========================================================================
  -- Botão (summary + seta)
  -- ==========================================================================
  local button = CreateFrame("Button", nil, anchorParent)
  button:SetSize(width, height)
  button:SetPoint("TOPLEFT", anchorTo, anchorPoint, anchorOffset, 0)

  local btnBg = button:CreateTexture(nil, "BACKGROUND")
  btnBg:SetAllPoints()
  applyTex(btnBg, RGBA.dropdownBtnBg or { 0.11, 0.09, 0.07, 1 })

  local summaryFS = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  summaryFS:SetPoint("LEFT", 8, 0)
  summaryFS:SetPoint("RIGHT", button, "RIGHT", -22, 0)
  summaryFS:SetJustifyH("LEFT")
  summaryFS:SetText(renderSummary())

  local arrow = button:CreateTexture(nil, "OVERLAY")
  arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-Arrow-Down-Up")
  arrow:SetSize(16, 16)
  arrow:SetPoint("RIGHT", button, "RIGHT", -5, -1)
  do
    local rgb = RGB.arrowTint or { 0.95, 0.82, 0.45 }
    arrow:SetVertexColor(rgb[1], rgb[2], rgb[3])
  end

  -- ==========================================================================
  -- Menu flutuante + borda + scroll
  -- ==========================================================================
  local menu = CreateFrame("Frame", nil, parent)
  menu:SetWidth(width)
  menu:SetFrameStrata("TOOLTIP")
  menu:SetFrameLevel(frameLevel)
  menu:EnableMouse(true)
  menu:Hide()
  menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)

  local menuBg = menu:CreateTexture(nil, "BACKGROUND")
  menuBg:SetAllPoints()
  applyTex(menuBg, RGBA.dropdownMenuBg or { 0.05, 0.048, 0.06, 0.99 })

  local border = RGBA.dropdownMenuBorder or { 0.55, 0.45, 0.18, 0.85 }
  local ez = 1
  local function addEdge(anchorPts)
    local t = menu:CreateTexture(nil, "BORDER")
    if anchorPts.horiz then
      t:SetHeight(ez)
    else
      t:SetWidth(ez)
    end
    applyTex(t, border)
    for _, p in ipairs(anchorPts) do
      t:SetPoint(p[1], menu, p[2], 0, 0)
    end
    return t
  end
  addEdge({ { "TOPLEFT", "TOPLEFT" }, { "TOPRIGHT", "TOPRIGHT" }, horiz = true })
  addEdge({ { "BOTTOMLEFT", "BOTTOMLEFT" }, { "BOTTOMRIGHT", "BOTTOMRIGHT" }, horiz = true })
  addEdge({ { "TOPLEFT", "TOPLEFT" }, { "BOTTOMLEFT", "BOTTOMLEFT" } })
  addEdge({ { "TOPRIGHT", "TOPRIGHT" }, { "BOTTOMRIGHT", "BOTTOMRIGHT" } })

  local scroll = CreateFrame("ScrollFrame", nil, menu)
  scroll:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, -4)
  scroll:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -4, 4)
  scroll:EnableMouse(true)
  local child = CreateFrame("Frame", nil, scroll)
  scroll:SetScrollChild(child)
  child:EnableMouse(true)
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, child:GetHeight() - self:GetHeight())
    local v = self:GetVerticalScroll() - delta * rowHeight * 2
    if v < 0 then v = 0 end
    if v > maxO then v = maxO end
    self:SetVerticalScroll(v)
  end)

  -- ==========================================================================
  -- Pool de linhas
  -- ==========================================================================
  local rows = {}
  local ctx  -- preenchido no final (menu/button/summaryFS/refresh/close)

  local rowBg        = RGBA.dropdownRowBg or { 0.13, 0.11, 0.09, 0.96 }
  local rowBgHover   = RGBA.dropdownRowBgHover or { 0.26, 0.2, 0.14, 1 }
  local headerBg     = RGBA.dropdownHeaderBg or { 0.08, 0.07, 0.06, 1 }
  local headerTextRGB = RGB.dropdownHeaderText or { 1, 0.82, 0.18 }
  local rowTextRGB    = RGB.dropdownRowText or { 1, 1, 1 }

  for i = 1, maxRowPool do
    local row = CreateFrame("Button", nil, child)
    row:SetHeight(rowHeight)
    row.isHeader = false

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    applyTex(bg, rowBg)
    row.bg = bg

    row:SetScript("OnEnter", function()
      if row.isHeader then
        return
      end
      applyTex(bg, rowBgHover)
    end)
    row:SetScript("OnLeave", function()
      if row.isHeader then
        applyTex(bg, headerBg)
        return
      end
      applyTex(bg, rowBg)
    end)

    local lab = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lab:SetPoint("LEFT", 8, 0)
    lab:SetJustifyH("LEFT")
    lab:SetWidth(width - 24)
    row.label = lab

    row:SetScript("OnClick", function(self)
      if self.isHeader then
        return
      end
      if self.option then
        onSelect(self.option, ctx)
      end
    end)

    rows[i] = row
    row:Hide()
  end

  -- ==========================================================================
  -- Refresh: popula rows a partir de getOptions()
  -- ==========================================================================
  local function refresh()
    menu:SetWidth(button:GetWidth())
    local mw = menu:GetWidth()
    local labelW = math.max(40, mw - 24)
    local opts = getOptions() or {}
    local y = 0
    for i = 1, maxRowPool do
      local row = rows[i]
      if i <= #opts then
        local entry = opts[i]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
        row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -y)
        row:SetHeight(rowHeight)
        row.label:SetWidth(labelW)

        if supportsHeaders and entry.kind == "hdr" then
          row.isHeader = true
          row.option = nil
          row:EnableMouse(false)
          applyTex(row.bg, headerBg)
          row.label:SetTextColor(headerTextRGB[1], headerTextRGB[2], headerTextRGB[3])
          row.label:SetText(entry.text or "")
        else
          row.isHeader = false
          row:EnableMouse(true)
          row.option = entry
          applyTex(row.bg, rowBg)
          row.label:SetTextColor(rowTextRGB[1], rowTextRGB[2], rowTextRGB[3])
          row.label:SetText(renderRow(entry) or "")
        end

        row:Show()
        y = y + rowHeight
      else
        row:Hide()
      end
    end
    local n = #opts
    child:SetWidth(math.max(1, mw - 8))
    child:SetHeight(math.max(rowHeight, n * rowHeight))
    local vis = math.min(maxVisibleRows, math.max(1, n))
    menu:SetHeight(8 + vis * rowHeight)
    scroll:SetVerticalScroll(0)
  end

  local function close()
    menu:Hide()
  end

  ctx = {
    button    = button,
    menu      = menu,
    summaryFS = summaryFS,
    refresh   = refresh,
    close     = close,
    updateSummary = function()
      summaryFS:SetText(renderSummary())
    end,
  }

  button:SetScript("OnClick", function()
    if menu:IsShown() then
      menu:Hide()
      if onOpen then
        -- nada; só fechamos
      end
      if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
        CEF.UIFilters.syncFilterDropBlocker(parent)
      end
    else
      if onOpen then
        onOpen(ctx)
      end
      refresh()
      menu:Show()
      menu:Raise()
      if CEF.UIFilters and CEF.UIFilters.syncFilterDropBlocker then
        CEF.UIFilters.syncFilterDropBlocker(parent)
      end
    end
  end)

  return ctx
end
