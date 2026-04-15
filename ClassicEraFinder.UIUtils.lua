-- Módulo: utilitários de UI compartilhados (tooltip, formatação, cores, etc.)
-- Exposto em ClassicEraFinder.UIUtils.*

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.UIUtils = CEF.UIUtils or {}
local UI = CEF.UIUtils

local CHAT_ICON_H, CHAT_ICON_W = 14, 14

-- {skull}, {rt8}, {star}, etc. → sequência |T...|t (o cliente pinta como no chat).
local BRACE_TO_RAIDINDEX = {
  rt1 = 1, rt2 = 2, rt3 = 3, rt4 = 4, rt5 = 5, rt6 = 6, rt7 = 7, rt8 = 8,
  star = 1, circle = 2, diamond = 3, triangle = 4, moon = 5, square = 6, cross = 7, skull = 8,
}

local function raidTargetInlineTex(index)
  return ("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d:%d|t"):format(index, CHAT_ICON_H, CHAT_ICON_W)
end

local function trimS(s)
  if not s then
    return ""
  end
  return (s:match("^%s*(.-)%s*$") or s)
end

function UI.expandChatIcons(text)
  if not text or text == "" then
    return text
  end
  return (text:gsub("%b{}", function(block)
    local rawInner = block:sub(2, -2):lower()
    -- {{square}}{{circle}} → bloco "{{square}}"; interior após 1 strip = "{square}" → desembrulhar mais um nível.
    local inner = rawInner
    if #rawInner >= 2 and rawInner:sub(1, 1) == "{" and rawInner:sub(-1) == "}" then
      inner = trimS(rawInner:sub(2, -2))
    else
      inner = trimS(rawInner)
    end
    local idx = BRACE_TO_RAIDINDEX[inner]
    if idx then
      return raidTargetInlineTex(idx)
    end
    return block
  end))
end

local cefTooltipFrame

function UI.cefTooltipHide()
  if cefTooltipFrame then
    cefTooltipFrame:Hide()
  end
end

function UI.cefTooltipEnsure()
  if cefTooltipFrame then
    return cefTooltipFrame
  end
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetWidth(380)
  f:SetHeight(48)
  f:SetFrameStrata("TOOLTIP")
  f:SetFrameLevel((f:GetFrameLevel() or 0) + 80)

  f.padX = 14
  f.padY = 12
  f.gapBodyMeta = 14
  f.heightSlack = 8

  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
  bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
  bg:SetColorTexture(0.02, 0.02, 0.03, 0.97)
  f.bg = bg

  local br, bgg, bb, ba = 0.55, 0.45, 0.18, 0.85
  local ez = 1
  local bTop = f:CreateTexture(nil, "BORDER")
  bTop:SetHeight(ez)
  bTop:SetColorTexture(br, bgg, bb, ba)
  bTop:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  bTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
  local bBot = f:CreateTexture(nil, "BORDER")
  bBot:SetHeight(ez)
  bBot:SetColorTexture(br, bgg, bb, ba)
  bBot:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
  bBot:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
  local bLeft = f:CreateTexture(nil, "BORDER")
  bLeft:SetWidth(ez)
  bLeft:SetColorTexture(br, bgg, bb, ba)
  bLeft:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
  bLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
  local bRight = f:CreateTexture(nil, "BORDER")
  bRight:SetWidth(ez)
  bRight:SetColorTexture(br, bgg, bb, ba)
  bRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
  bRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

  f.title = f:CreateFontString(nil, "OVERLAY")
  f.title:Hide()

  f.body = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.body:SetTextColor(0.98, 0.98, 0.96)
  f.body:SetJustifyH("LEFT")
  f.body:SetJustifyV("TOP")
  f.body:SetWordWrap(true)
  f.body:SetWidth(352)
  f.body:SetPoint("TOPLEFT", f, "TOPLEFT", f.padX, -f.padY)

  f.meta = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.meta:SetTextColor(0.92, 0.92, 0.9)
  f.meta:SetJustifyH("LEFT")
  f.meta:SetJustifyV("TOP")
  f.meta:SetWidth(352)
  f.meta:SetWordWrap(true)
  f.meta:SetPoint("TOPLEFT", f.body, "BOTTOMLEFT", 0, -f.gapBodyMeta)

  cefTooltipFrame = f
  return f
end

function UI.cefTooltipShow(anchorFrame, entry)
  if not entry or not entry.text then
    return
  end
  local tip = UI.cefTooltipEnsure()

  local boxW = 380
  tip:SetWidth(boxW)
  local inner = boxW - tip.padX * 2
  tip.body:SetWidth(inner)
  tip.meta:SetWidth(inner)

  tip.body:SetText(UI.expandChatIcons(entry.text))

  local L = CEF.L or {}
  local grey = "|cffaaaaaa"
  local white = "|cffffffff"
  local instBlock = CEF.entryInstancesComboRichText(entry)
  local meta = grey .. (L["tooltipInstance"] or "Instance:") .. "|r\n" .. instBlock
  local nameColor = UI.classColorRichPrefix(entry.guid)
  meta = meta .. "\n\n" .. grey .. (L["tooltipCharacter"] or "Character:") .. "|r " .. nameColor .. CEF.stripRealm(entry.sender or "") .. "|r"
  if entry.channel and entry.channel ~= "" then
    meta = meta .. "\n" .. grey .. (L["tooltipChannel"] or "Channel:") .. "|r " .. white .. entry.channel .. "|r"
  end
  tip.meta:SetText(meta)

  local bodyH = tip.body:GetStringHeight()
  local metaH = tip.meta:GetStringHeight()
  local h = tip.padY + bodyH + tip.gapBodyMeta + metaH + tip.padY + tip.heightSlack
  tip:SetHeight(math.max(48, math.ceil(h)))

  local scale = UIParent:GetEffectiveScale()
  local x, y = GetCursorPosition()
  x, y = x / scale, y / scale
  tip:ClearAllPoints()
  tip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x + 18, y + 18)
  tip:Show()
end

local MSG_DISPLAY_MAX_CHARS = 50

function UI.formatMessageCell(raw, lineBudget)
  if not raw then
    return "", false
  end
  lineBudget = lineBudget or 1
  if lineBudget < 1 then
    lineBudget = 1
  end
  local maxChars = math.min(260, MSG_DISPLAY_MAX_CHARS * lineBudget)
  if #raw <= maxChars then
    return UI.expandChatIcons(raw), false
  end
  local cut = maxChars - 3
  local prefix = raw:sub(1, cut)
  prefix = prefix:gsub("%{[^}]*$", "")
  return UI.expandChatIcons(prefix) .. "|cFFFFFFFF...|r", true
end

function UI.classColorRGB(guid)
  if not guid or guid == "" then
    return 1, 1, 1
  end
  local _, classFile = GetPlayerInfoByGUID(guid)
  if not classFile then
    return 1, 1, 1
  end
  local token = strupper(classFile)
  local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[token]
  if c then
    return c.r, c.g, c.b
  end
  return 1, 1, 1
end

function UI.classColorRichPrefix(guid)
  local r, g, b = UI.classColorRGB(guid)
  return string.format(
    "|cff%02x%02x%02x",
    math.floor(r * 255 + 0.5),
    math.floor(g * 255 + 0.5),
    math.floor(b * 255 + 0.5)
  )
end

function UI.formatRelativeAge(ts)
  if not ts then return "" end
  local now = time()
  local d = now - ts
  if d < 0 then
    d = 0
  end
  if d < 8 then
    return "agora"
  end
  if d < 60 then
    return ("%ds"):format(d)
  end
  if d < 3600 then
    return ("%d min"):format(math.floor(d / 60))
  end
  if d < 86400 then
    return ("%d h"):format(math.floor(d / 3600))
  end
  return ("%d d"):format(math.floor(d / 86400))
end

function UI.entryIsSelf(e)
  if not e or not e.sender then
    return false
  end
  local me = UnitName("player")
  if not me then
    return false
  end
  local s = CEF.stripRealm(e.sender)
  return strlower(s) == strlower(me)
end

