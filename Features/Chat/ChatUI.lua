-- Módulo: UI da aba Mensagens (lista + thread estilo chat).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.ChatUI = CEF.ChatUI or {}
local GUI = CEF.ChatUI

local LEFT_W = 260
local ROW_H = 28
local MSG_PAD = 8
local COMPOSER_H = 32
local COMPOSER_GAP = 8
local REPLY_BAR_H = 34
local POOL = 48
local MSG_POOL = 80
local WHISPER_MAX_LETTERS = 255
local BNET_MAX_LETTERS = 4096
local CHAR_COUNT_INSET = 58
local REPLY_QUOTE_MAX = 72

local function fmtTime(ts)
  ts = tonumber(ts) or 0
  if ts <= 0 or not date then
    return ""
  end
  return date("%H:%M", ts)
end

local function relativeOrClock(ts)
  if CEF.UIUtils and CEF.UIUtils.formatRelativeTime and ts then
    local age = (time and time() or 0) - ts
    if age < 86400 then
      return fmtTime(ts)
    end
  end
  return fmtTime(ts)
end

local function truncateReply(text, maxLen)
  text = tostring(text or "")
  maxLen = maxLen or REPLY_QUOTE_MAX
  if #text <= maxLen then
    return text
  end
  return strsub(text, 1, maxLen - 1) .. "…"
end

local function syncComposerLayout(f)
  local composer = f.chatComposer
  local replyBar = f.chatReplyBar
  local msgScroll = f.chatMsgScroll
  if not composer or not msgScroll then
    return
  end
  local pending = CEF.Chat.getPendingReply and CEF.Chat.getPendingReply()
  if replyBar then
    if pending then
      replyBar:Show()
      if f.chatReplyLabel then
        f.chatReplyLabel:SetText(CEF.L.CHAT_REPLYING_TO or "Replying to")
      end
      if f.chatReplyNameFs then
        f.chatReplyNameFs:SetText(pending.name ~= "" and pending.name or (CEF.L.CHAT_REPLY or "Reply"))
      end
      if f.chatReplyTextFs then
        f.chatReplyTextFs:SetText(truncateReply(pending.text, 90))
      end
      msgScroll:ClearAllPoints()
      msgScroll:SetPoint("TOPLEFT", f.chatThreadHeader, "BOTTOMLEFT", 0, -4)
      msgScroll:SetPoint("BOTTOMRIGHT", replyBar, "TOPRIGHT", 0, 6)
    else
      replyBar:Hide()
      msgScroll:ClearAllPoints()
      msgScroll:SetPoint("TOPLEFT", f.chatThreadHeader, "BOTTOMLEFT", 0, -4)
      msgScroll:SetPoint("BOTTOMRIGHT", composer, "TOPRIGHT", 0, 6)
    end
  end
end

function GUI.refresh()
  local f = CEF.UI and CEF.UI.mainFrame
  if not f or not f.chatRoot or not f.chatRoot:IsShown() then
    return
  end
  GUI.refreshList(f)
  GUI.refreshThread(f)
end

function GUI.refreshList(f)
  local listScroll = f.chatListScroll
  local listChild = f.chatListChild
  local rows = f.chatListRows
  if not listScroll or not listChild or not rows then
    return
  end

  local viewH = listScroll:GetHeight() or 0
  local childW = listChild:GetWidth() or 0
  if viewH < 8 or childW < 32 then
    if f.cefScheduleChatLayoutSync then
      f.cefScheduleChatLayoutSync()
    end
    return
  end

  local whispers = (CEF.Chat.getWhisperList and CEF.Chat.getWhisperList()) or CEF.Chat.getConversationList()
  local friends = CEF.Chat.getBnetFriends()
  local active = CEF.Chat.getActiveId()

  local items = {}
  items[#items + 1] = { kind = "header", label = CEF.L.CHAT_SECTION_BNET }
  if #friends == 0 then
    items[#items + 1] = { kind = "empty", label = CEF.L.CHAT_NO_FRIENDS }
  else
    for _, fr in ipairs(friends) do
      items[#items + 1] = { kind = "friend", friend = fr }
    end
  end
  items[#items + 1] = { kind = "header", label = CEF.L.CHAT_SECTION_WHISPERS or CEF.L.CHAT_KIND_WHISPER }
  if #whispers == 0 then
    items[#items + 1] = { kind = "empty", label = CEF.L.CHAT_NO_WHISPERS or CEF.L.CHAT_NO_CONVERSATIONS }
  else
    for _, c in ipairs(whispers) do
      items[#items + 1] = { kind = "whisper", conv = c }
    end
  end

  local totalH = #items * ROW_H
  listChild:SetHeight(math.max(totalH, 1))
  local viewH2 = listScroll:GetHeight() or 1
  local vs = listScroll:GetVerticalScroll() or 0
  local maxScroll = math.max(0, totalH - viewH2)

  -- Mantém a conversa ativa visível na lista.
  if active then
    for idx, it in ipairs(items) do
      local rowId = (it.kind == "whisper" and it.conv and it.conv.id)
        or (it.kind == "friend" and it.friend and it.friend.id)
      if rowId and rowId == active then
        local rowTop = (idx - 1) * ROW_H
        local rowBot = rowTop + ROW_H
        if rowTop < vs then
          vs = rowTop
        elseif rowBot > vs + viewH2 then
          vs = rowBot - viewH2
        end
        break
      end
    end
  end
  if vs < 0 then
    vs = 0
  end
  if vs > maxScroll then
    vs = maxScroll
  end
  listScroll:SetVerticalScroll(vs)

  local first = 1
  if totalH > 0 then
    first = math.floor(vs / ROW_H) + 1
  end
  local visible = math.ceil(viewH2 / ROW_H) + 2
  local last = math.min(#items, first + visible - 1)

  for _, rf in ipairs(rows) do
    rf:Hide()
  end

  for i = first, last do
    local rowIndex = i - first + 1
    if rowIndex > POOL then
      break
    end
    local rf = rows[rowIndex]
    if not rf then
      rf = CreateFrame("Button", nil, listChild)
      rf:SetHeight(ROW_H)
      local bg = rf:CreateTexture(nil, "BACKGROUND")
      bg:SetAllPoints()
      rf.bg = bg
      local bnetIcon = rf:CreateTexture(nil, "ARTWORK")
      bnetIcon:SetSize(12, 12)
      bnetIcon:SetPoint("LEFT", rf, "LEFT", 8, 0)
      bnetIcon:Hide()
      rf.bnetIcon = bnetIcon
      local statusDot = rf:CreateTexture(nil, "ARTWORK")
      statusDot:SetSize(8, 8)
      statusDot:SetPoint("LEFT", rf, "LEFT", 8, 0)
      statusDot:Hide()
      rf.statusDot = statusDot
      local fs = rf:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("LEFT", rf, "LEFT", 8, 0)
      fs:SetPoint("RIGHT", rf, "RIGHT", -28, 0)
      fs:SetJustifyH("LEFT")
      fs:SetWordWrap(false)
      rf.label = fs
      local badge = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      badge:SetPoint("RIGHT", rf, "RIGHT", -8, 0)
      badge:SetTextColor(1, 0.82, 0.2)
      rf.badge = badge
      rows[rowIndex] = rf
      f.chatListRows = rows
    end

    local item = items[i]
    rf:ClearAllPoints()
    rf:SetPoint("TOPLEFT", listChild, "TOPLEFT", 0, -((i - 1) * ROW_H))
    rf:SetPoint("TOPRIGHT", listChild, "TOPRIGHT", 0, -((i - 1) * ROW_H))
    rf.badge:SetText("")
    if rf.bnetIcon then
      rf.bnetIcon:Hide()
    end
    if rf.statusDot then
      rf.statusDot:Hide()
    end
    rf.label:ClearAllPoints()
    rf.label:SetPoint("LEFT", rf, "LEFT", 8, 0)
    rf.label:SetPoint("RIGHT", rf, "RIGHT", -28, 0)
    rf:SetScript("OnClick", nil)

    if item.kind == "header" then
      rf.bg:SetColorTexture(0.1, 0.09, 0.08, 1)
      rf.label:SetText("|cffffcc66" .. item.label .. "|r")
      rf:EnableMouse(false)
    elseif item.kind == "empty" then
      rf.bg:SetColorTexture(0.07, 0.07, 0.08, 0.6)
      rf.label:SetText("|cff888888" .. item.label .. "|r")
      rf:EnableMouse(false)
    elseif item.kind == "whisper" then
      local c = item.conv
      local selected = active == c.id
      if selected then
        rf.bg:SetColorTexture(0.32, 0.24, 0.12, 1)
      elseif (i % 2) == 0 then
        rf.bg:SetColorTexture(0.1, 0.1, 0.12, 0.85)
      else
        rf.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
      end
      local unread = tonumber(c.unread) or 0
      if selected then
        rf.label:SetText("|cffffe09a" .. (c.name or "") .. "|r")
      else
        rf.label:SetText(c.name or "")
      end
      if unread > 0 then
        rf.badge:SetText(tostring(unread))
      end
      rf:EnableMouse(true)
      rf:SetScript("OnClick", function()
        CEF.Chat.setActiveId(c.id)
      end)
    elseif item.kind == "friend" then
      local fr = item.friend
      -- Amigo BNet só fica selecionado se a conversa ativa for exatamente essa.
      local selected = active and fr.id and active == fr.id
      if selected then
        rf.bg:SetColorTexture(0.32, 0.24, 0.12, 1)
      else
        rf.bg:SetColorTexture(0.08, 0.08, 0.1, 0.85)
      end
      if rf.bnetIcon then
        -- Logo BNet em Media (branco+alpha); cor via vertex (Classic Era).
        rf.bnetIcon:SetTexture("Interface\\AddOns\\ClassicEraFinder\\Media\\battlenet")
        rf.bnetIcon:SetVertexColor(0.0, 0.68, 1.0)
        rf.bnetIcon:SetSize(14, 14)
        rf.bnetIcon:ClearAllPoints()
        rf.bnetIcon:SetPoint("LEFT", rf, "LEFT", 8, 0)
        rf.bnetIcon:Show()
      end
      if rf.statusDot then
        local tex = fr.online
          and ((FRIENDS_TEXTURE_ONLINE) or "Interface\\FriendsFrame\\StatusIcon-Online")
          or ((FRIENDS_TEXTURE_OFFLINE) or "Interface\\FriendsFrame\\StatusIcon-Offline")
        rf.statusDot:SetTexture(tex)
        rf.statusDot:SetVertexColor(1, 1, 1, 1)
        rf.statusDot:SetSize(10, 10)
        rf.statusDot:ClearAllPoints()
        if rf.bnetIcon and rf.bnetIcon:IsShown() then
          rf.statusDot:SetPoint("LEFT", rf.bnetIcon, "RIGHT", 4, 0)
        else
          rf.statusDot:SetPoint("LEFT", rf, "LEFT", 8, 0)
        end
        rf.statusDot:Show()
        rf.label:ClearAllPoints()
        rf.label:SetPoint("LEFT", rf.statusDot, "RIGHT", 6, 0)
        rf.label:SetPoint("RIGHT", rf, "RIGHT", -28, 0)
      end
      local unread = tonumber(fr.unread) or 0
      if selected then
        rf.label:SetText("|cffffe09a" .. (fr.display or fr.name or "") .. "|r")
      else
        rf.label:SetText(fr.display or fr.name or "")
      end
      if unread > 0 then
        rf.badge:SetText(tostring(unread))
      end
      rf:EnableMouse(true)
      rf:SetScript("OnClick", function()
        CEF.Chat.openBnet(fr.bnetAccountID, fr.name)
      end)
    end
    rf:Show()
  end
end

function GUI.refreshThread(f)
  local headerFs = f.chatThreadTitle
  local typeFs = f.chatThreadType
  local emptyFs = f.chatThreadEmpty
  local emptyNoteFs = f.chatThreadEmptyNote
  local msgScroll = f.chatMsgScroll
  local msgChild = f.chatMsgChild
  local msgRows = f.chatMsgRows
  local composer = f.chatComposer
  if not headerFs or not msgScroll or not msgChild or not msgRows then
    return
  end

  local id = CEF.Chat.getActiveId()
  local conv = CEF.Chat.getConversation(id)
  local dash = f.chatDash
  if not conv then
    headerFs:SetText(CEF.L.CHAT_SELECT_CONVERSATION)
    if typeFs then
      typeFs:SetText("")
    end
    if f.chatDeleteConvBtn then
      f.chatDeleteConvBtn:Hide()
    end
    if emptyFs then
      emptyFs:Show()
      emptyFs:SetText(CEF.L.CHAT_EMPTY_THREAD)
    end
    if emptyNoteFs then
      emptyNoteFs:Show()
      emptyNoteFs:SetText(CEF.L.CHAT_EMPTY_THREAD_NOTE or "")
    end
    if dash and dash.refresh then
      dash:refresh()
      dash:Show()
    end
    if composer then
      composer:Hide()
    end
    if f.chatReplyBar then
      f.chatReplyBar:Hide()
    end
    for _, rf in ipairs(msgRows) do
      rf:Hide()
    end
    msgChild:SetHeight(1)
    return
  end

  if emptyFs then
    emptyFs:Hide()
  end
  if emptyNoteFs then
    emptyNoteFs:Hide()
  end
  if dash then
    dash:Hide()
  end
  if composer then
    composer:Show()
  end
  syncComposerLayout(f)
  if f.chatDeleteConvBtn then
    f.chatDeleteConvBtn:Show()
  end
  headerFs:SetText(conv.name or "")
  if typeFs then
    typeFs:SetText(conv.kind == "bnet" and CEF.L.CHAT_KIND_BNET or CEF.L.CHAT_KIND_WHISPER)
  end
  if f.chatEditBox then
    local maxLen = (conv.kind == "bnet") and BNET_MAX_LETTERS or WHISPER_MAX_LETTERS
    local overhead = (CEF.Chat.getPendingReplyOverhead and CEF.Chat.getPendingReplyOverhead()) or 0
    maxLen = math.max(1, maxLen - overhead)
    f.chatEditBox:SetMaxLetters(maxLen)
    f.chatEditMaxLetters = maxLen
    if f.chatUpdateCharCount then
      f.chatUpdateCharCount()
    end
  end

  local msgs = conv.messages or {}
  local widths = msgScroll:GetWidth() or 400
  local bubbleMax = math.max(140, widths * 0.70)
  local y = -MSG_PAD
  local totalH = MSG_PAD
  local selfName = (UnitName and UnitName("player")) or CEF.L.CHAT_YOU

  for _, rf in ipairs(msgRows) do
    rf:Hide()
  end

  local startIdx = 1
  if #msgs > MSG_POOL then
    startIdx = #msgs - MSG_POOL + 1
  end

  local function ensureMsgRow(parent)
    local rf = CreateFrame("Frame", nil, parent)
    local nameFs = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameFs:SetJustifyH("LEFT")
    rf.nameFs = nameFs
    local timeFs = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeFs:SetTextColor(0.55, 0.52, 0.48)
    rf.timeFs = timeFs

    local bubble = CreateFrame("Frame", nil, rf)
    local bg = bubble:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bubble.bg = bg

    local quote = CreateFrame("Frame", nil, bubble)
    quote:SetPoint("TOPLEFT", bubble, "TOPLEFT", 8, -6)
    quote:SetPoint("TOPRIGHT", bubble, "TOPRIGHT", -8, -6)
    local qAccent = quote:CreateTexture(nil, "ARTWORK")
    qAccent:SetWidth(3)
    qAccent:SetPoint("TOPLEFT", quote, "TOPLEFT", 0, 0)
    qAccent:SetPoint("BOTTOMLEFT", quote, "BOTTOMLEFT", 0, 0)
    quote.accent = qAccent
    local qBg = quote:CreateTexture(nil, "BACKGROUND")
    qBg:SetPoint("TOPLEFT", quote, "TOPLEFT", 0, 0)
    qBg:SetPoint("BOTTOMRIGHT", quote, "BOTTOMRIGHT", 0, 0)
    qBg:SetColorTexture(0, 0, 0, 0.22)
    quote.bg = qBg
    local qName = quote:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    qName:SetPoint("TOPLEFT", quote, "TOPLEFT", 8, -4)
    qName:SetPoint("TOPRIGHT", quote, "TOPRIGHT", -6, -4)
    qName:SetJustifyH("LEFT")
    quote.nameFs = qName
    local qText = quote:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    qText:SetPoint("TOPLEFT", qName, "BOTTOMLEFT", 0, -1)
    qText:SetPoint("TOPRIGHT", quote, "TOPRIGHT", -6, -1)
    qText:SetJustifyH("LEFT")
    qText:SetWordWrap(false)
    quote.textFs = qText
    bubble.quote = quote

    local fs = bubble:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("TOP")
    fs:SetWordWrap(true)
    bubble.text = fs
    rf.bubble = bubble

    local replyBtn = CreateFrame("Button", nil, rf)
    replyBtn:SetHeight(14)
    local replyFs = replyBtn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    replyFs:SetPoint("LEFT", replyBtn, "LEFT", 0, 0)
    replyFs:SetJustifyH("LEFT")
    replyFs:SetText(CEF.L.CHAT_REPLY or "Reply")
    replyBtn.fs = replyFs
    replyBtn:SetWidth(math.max(48, (replyFs:GetStringWidth() or 48) + 4))
    replyBtn:SetScript("OnEnter", function(self)
      self.fs:SetTextColor(1, 0.92, 0.55)
    end)
    replyBtn:SetScript("OnLeave", function(self)
      self.fs:SetTextColor(0.55, 0.52, 0.48)
    end)
    replyFs:SetTextColor(0.55, 0.52, 0.48)
    rf.replyBtn = replyBtn

    local sysFs = rf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sysFs:SetJustifyH("CENTER")
    sysFs:SetJustifyV("MIDDLE")
    sysFs:SetWordWrap(true)
    sysFs:SetTextColor(1.0, 0.82, 0.2)
    sysFs:Hide()
    rf.sysFs = sysFs
    return rf
  end

  local rowIndex = 0
  local scrollW = msgScroll:GetWidth() or 400
  for i = startIdx, #msgs do
    rowIndex = rowIndex + 1
    local m = msgs[i]
    local rf = msgRows[rowIndex]
    if not rf or not rf.bubble or not rf.bubble.quote or not rf.replyBtn or not rf.sysFs then
      if rf then
        rf:Hide()
      end
      rf = ensureMsgRow(msgChild)
      msgRows[rowIndex] = rf
      f.chatMsgRows = msgRows
    end

    if m.dir == "sys" then
      rf.nameFs:Hide()
      rf.timeFs:Hide()
      rf.bubble:Hide()
      rf.replyBtn:Hide()
      rf.sysFs:Show()
      local sysW = math.max(120, scrollW - MSG_PAD * 2)
      rf.sysFs:ClearAllPoints()
      rf.sysFs:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, 0)
      rf.sysFs:SetWidth(sysW)
      rf.sysFs:SetText(m.text or "")
      local sysH = math.max(18, (rf.sysFs:GetStringHeight() or 14) + 4)
      rf:SetHeight(sysH)
      rf:SetWidth(sysW)
      rf:ClearAllPoints()
      rf:SetPoint("TOPLEFT", msgChild, "TOPLEFT", MSG_PAD, y)
      rf:Show()
      y = y - sysH - 8
      totalH = totalH + sysH + 8
    else
      rf.sysFs:Hide()
      rf.nameFs:Show()
      rf.timeFs:Show()
      rf.bubble:Show()
      rf.replyBtn:Show()

    local outgoing = m.dir == "out"
    local displayName = outgoing and (CEF.L.CHAT_YOU or selfName) or (conv.name or "")
    rf.nameFs:SetText(displayName)
    if outgoing then
      rf.nameFs:SetTextColor(1.0, 0.82, 0.35)
    else
      rf.nameFs:SetTextColor(0.55, 0.78, 1.0)
    end
    rf.timeFs:SetText(relativeOrClock(m.t))

    local maxTextW = bubbleMax - 20
    local quote = rf.bubble.quote
    local quoteH = 0
    local hasReply = type(m.reply) == "table" and type(m.reply.text) == "string" and m.reply.text ~= ""
    if hasReply then
      local qName = (m.reply.name and m.reply.name ~= "") and m.reply.name or (CEF.L.CHAT_REPLY or "Reply")
      quote.nameFs:SetText(qName)
      quote.textFs:SetText(truncateReply(m.reply.text, REPLY_QUOTE_MAX))
      quote.nameFs:SetWidth(maxTextW - 14)
      quote.textFs:SetWidth(maxTextW - 14)
      local qnH = quote.nameFs:GetStringHeight() or 12
      local qtH = quote.textFs:GetStringHeight() or 10
      quoteH = qnH + qtH + 10
      quote:SetHeight(quoteH)
      quote:Show()
      if outgoing then
        quote.accent:SetColorTexture(1.0, 0.82, 0.35, 0.95)
        quote.nameFs:SetTextColor(1.0, 0.82, 0.35)
      else
        quote.accent:SetColorTexture(0.45, 0.72, 1.0, 0.95)
        quote.nameFs:SetTextColor(0.55, 0.78, 1.0)
      end
      quote.textFs:SetTextColor(0.7, 0.68, 0.62)
      rf.bubble.text:ClearAllPoints()
      rf.bubble.text:SetPoint("TOPLEFT", quote, "BOTTOMLEFT", 2, -5)
    else
      quote:Hide()
      rf.bubble.text:ClearAllPoints()
      rf.bubble.text:SetPoint("TOPLEFT", rf.bubble, "TOPLEFT", 10, -7)
    end

    rf.bubble.text:SetWidth(maxTextW)
    rf.bubble.text:SetText(m.text or "")
    local rawW = rf.bubble.text:GetStringWidth() or 40
    local quoteNameW = 0
    local quoteTextW = 0
    if hasReply then
      quoteNameW = quote.nameFs:GetStringWidth() or 0
      quoteTextW = quote.textFs:GetStringWidth() or 0
    end
    local textW = math.max(36, math.min(maxTextW, math.max(rawW, quoteNameW, quoteTextW) + 2))
    rf.bubble.text:SetWidth(textW)
    if hasReply then
      quote.nameFs:SetWidth(textW - 4)
      quote.textFs:SetWidth(textW - 4)
      local qnH = quote.nameFs:GetStringHeight() or 12
      local qtH = quote.textFs:GetStringHeight() or 10
      quoteH = qnH + qtH + 10
      quote:SetHeight(quoteH)
      quote:ClearAllPoints()
      quote:SetPoint("TOPLEFT", rf.bubble, "TOPLEFT", 8, -6)
      quote:SetWidth(textW + 4)
    end
    local textH = rf.bubble.text:GetStringHeight() or 12
    local bubbleH = math.max(26, textH + 14 + (hasReply and (quoteH + 5) or 0))
    local bubbleW = textW + 20
    local headerH = 16
    local replyRowH = 14
    local h = headerH + 4 + bubbleH + replyRowH
    local nameW = rf.nameFs:GetStringWidth() or 40
    local timeW = rf.timeFs:GetStringWidth() or 20
    rf.replyBtn.fs:SetText(CEF.L.CHAT_REPLY or "Reply")
    local replyW = math.max(48, (rf.replyBtn.fs:GetStringWidth() or 48) + 4)
    local blockW = math.max(bubbleW, nameW + timeW + 10, replyW)

    rf:SetHeight(h)
    rf:SetWidth(blockW)
    rf:ClearAllPoints()

    rf.nameFs:ClearAllPoints()
    rf.timeFs:ClearAllPoints()
    rf.bubble:ClearAllPoints()
    rf.bubble:SetHeight(bubbleH)
    rf.bubble:SetWidth(bubbleW)
    rf.replyBtn:ClearAllPoints()
    rf.replyBtn.fs:ClearAllPoints()
    if outgoing then
      rf.replyBtn.fs:SetPoint("RIGHT", rf.replyBtn, "RIGHT", 0, 0)
      rf.replyBtn.fs:SetJustifyH("RIGHT")
    else
      rf.replyBtn.fs:SetPoint("LEFT", rf.replyBtn, "LEFT", 0, 0)
      rf.replyBtn.fs:SetJustifyH("LEFT")
    end
    rf.replyBtn:SetWidth(replyW)
    rf.replyBtn:SetScript("OnClick", function()
      CEF.Chat.setPendingReplyFromMessage(m, displayName)
      if f.chatEditBox then
        f.chatEditBox:SetFocus()
      end
    end)

    if outgoing then
      rf:SetPoint("TOPRIGHT", msgChild, "TOPRIGHT", -MSG_PAD, y)
      rf.nameFs:SetPoint("TOPRIGHT", rf, "TOPRIGHT", 0, 0)
      rf.timeFs:SetPoint("RIGHT", rf.nameFs, "LEFT", -6, 0)
      rf.bubble:SetPoint("TOPRIGHT", rf, "TOPRIGHT", 0, -headerH - 2)
      rf.bubble.bg:SetColorTexture(0.28, 0.2, 0.12, 0.95)
      rf.bubble.text:SetTextColor(1, 0.95, 0.85)
      rf.nameFs:SetJustifyH("RIGHT")
      rf.replyBtn:SetPoint("TOPRIGHT", rf.bubble, "BOTTOMRIGHT", 0, -1)
    else
      rf:SetPoint("TOPLEFT", msgChild, "TOPLEFT", MSG_PAD, y)
      rf.nameFs:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, 0)
      rf.timeFs:SetPoint("LEFT", rf.nameFs, "RIGHT", 6, 0)
      rf.bubble:SetPoint("TOPLEFT", rf, "TOPLEFT", 0, -headerH - 2)
      rf.bubble.bg:SetColorTexture(0.12, 0.16, 0.22, 0.95)
      rf.bubble.text:SetTextColor(0.92, 0.94, 0.98)
      rf.nameFs:SetJustifyH("LEFT")
      rf.replyBtn:SetPoint("TOPLEFT", rf.bubble, "BOTTOMLEFT", 0, -1)
    end

    rf:Show()
    y = y - h - 6
    totalH = totalH + h + 6
    end
  end

  msgChild:SetHeight(math.max(totalH, 1))
  local viewH = msgScroll:GetHeight() or 1
  local maxScroll = math.max(0, totalH - viewH)
  msgScroll:SetVerticalScroll(maxScroll)
end

function GUI.createPanels(f, navBar)
  local CC = CEF.CONST
  local RIGHT_SCROLL_OUTSET = 14

  local root = CreateFrame("Frame", nil, f)
  root:SetPoint("TOPLEFT", navBar, "BOTTOMLEFT", 0, -6)
  root:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -RIGHT_SCROLL_OUTSET, 8)
  root:Hide()
  f.chatRoot = root

  -- Left pane
  local left = CreateFrame("Frame", nil, root)
  left:SetPoint("TOPLEFT", root, "TOPLEFT", 0, 0)
  left:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT", 0, 0)
  left:SetWidth(LEFT_W)
  local leftBg = left:CreateTexture(nil, "BACKGROUND")
  leftBg:SetAllPoints()
  leftBg:SetColorTexture(0.07, 0.065, 0.07, 0.97)

  local searchBox = CreateFrame("EditBox", nil, left)
  searchBox:SetHeight(22)
  searchBox:SetPoint("TOPLEFT", left, "TOPLEFT", 8, -8)
  searchBox:SetPoint("TOPRIGHT", left, "TOPRIGHT", -8, -8)
  searchBox:SetAutoFocus(false)
  searchBox:SetFontObject(GameFontHighlightSmall)
  searchBox:SetTextInsets(6, 6, 0, 0)
  local searchBg = searchBox:CreateTexture(nil, "BACKGROUND")
  searchBg:SetAllPoints()
  searchBg:SetColorTexture(0.12, 0.11, 0.1, 1)
  local searchPh = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  searchPh:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
  searchPh:SetText(CEF.L.CHAT_SEARCH_PLACEHOLDER)
  f.chatSearchPlaceholder = searchPh
  searchBox:SetScript("OnTextChanged", function(self)
    local t = self:GetText() or ""
    searchPh:SetShown(t == "")
    CEF.Chat.setSearchText(t)
  end)
  searchBox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  f.chatSearchBox = searchBox

  local listScroll = CreateFrame("ScrollFrame", nil, left)
  listScroll:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, -6)
  listScroll:SetPoint("BOTTOMRIGHT", left, "BOTTOMRIGHT", -2, 4)
  listScroll:EnableMouseWheel(true)
  local listChild = CreateFrame("Frame", nil, listScroll)
  listChild:SetWidth(LEFT_W - 10)
  listChild:SetHeight(100)
  listScroll:SetScrollChild(listChild)
  listScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, listChild:GetHeight() - self:GetHeight())
    local v = self:GetVerticalScroll() - delta * ROW_H * 3
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    self:SetVerticalScroll(v)
    GUI.refreshList(f)
  end)
  listScroll:SetScript("OnVerticalScroll", function()
    GUI.refreshList(f)
  end)
  f.chatListScroll = listScroll
  f.chatListChild = listChild
  f.chatListRows = {}

  -- Right pane
  local right = CreateFrame("Frame", nil, root)
  right:SetPoint("TOPLEFT", left, "TOPRIGHT", 4, 0)
  right:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", 0, 0)
  local rightBg = right:CreateTexture(nil, "BACKGROUND")
  rightBg:SetAllPoints()
  rightBg:SetColorTexture(0.06, 0.055, 0.06, 0.97)

  local threadHeader = CreateFrame("Frame", nil, right)
  threadHeader:SetHeight(36)
  threadHeader:SetPoint("TOPLEFT", right, "TOPLEFT", 0, 0)
  threadHeader:SetPoint("TOPRIGHT", right, "TOPRIGHT", 0, 0)
  f.chatThreadHeader = threadHeader
  local thBg = threadHeader:CreateTexture(nil, "BACKGROUND")
  thBg:SetAllPoints()
  thBg:SetColorTexture(0.1, 0.09, 0.08, 1)
  local title = threadHeader:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", threadHeader, "TOPLEFT", 12, -4)
  title:SetTextColor(1, 0.9, 0.55)
  title:SetJustifyH("LEFT")
  title:SetText(CEF.L.CHAT_SELECT_CONVERSATION)
  f.chatThreadTitle = title

  local deleteConvBtn = CreateFrame("Button", nil, threadHeader)
  deleteConvBtn:SetSize(18, 18)
  deleteConvBtn:SetPoint("RIGHT", threadHeader, "RIGHT", -10, 0)
  deleteConvBtn:Hide()
  local deleteConvFs = deleteConvBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  deleteConvFs:SetAllPoints()
  deleteConvFs:SetText("×")
  deleteConvFs:SetTextColor(0.7, 0.55, 0.45)
  deleteConvBtn:SetScript("OnEnter", function()
    deleteConvFs:SetTextColor(1, 0.4, 0.3)
  end)
  deleteConvBtn:SetScript("OnLeave", function()
    deleteConvFs:SetTextColor(0.7, 0.55, 0.45)
  end)
  deleteConvBtn:SetScript("OnClick", function()
    local cid = CEF.Chat.getActiveId()
    if cid and f.chatShowDeleteConfirm then
      f.chatShowDeleteConfirm(cid)
    end
  end)
  f.chatDeleteConvBtn = deleteConvBtn
  f.chatDeleteConvFs = deleteConvFs

  title:SetPoint("RIGHT", deleteConvBtn, "LEFT", -8, 0)

  local typeFs = threadHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  typeFs:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
  typeFs:SetTextColor(0.65, 0.62, 0.55)
  typeFs:SetJustifyH("LEFT")
  f.chatThreadType = typeFs

  local composer = CreateFrame("Frame", nil, right)
  composer:SetHeight(COMPOSER_H)
  composer:SetPoint("BOTTOMLEFT", right, "BOTTOMLEFT", COMPOSER_GAP, COMPOSER_GAP)
  composer:SetPoint("BOTTOMRIGHT", right, "BOTTOMRIGHT", -COMPOSER_GAP, COMPOSER_GAP)
  composer:Hide()
  f.chatComposer = composer

  local replyBar = CreateFrame("Frame", nil, right)
  replyBar:SetHeight(REPLY_BAR_H)
  replyBar:SetPoint("BOTTOMLEFT", composer, "TOPLEFT", 0, 4)
  replyBar:SetPoint("BOTTOMRIGHT", composer, "TOPRIGHT", 0, 4)
  replyBar:Hide()
  local replyBarBg = replyBar:CreateTexture(nil, "BACKGROUND")
  replyBarBg:SetAllPoints()
  replyBarBg:SetColorTexture(0.14, 0.12, 0.1, 1)
  local replyAccent = replyBar:CreateTexture(nil, "ARTWORK")
  replyAccent:SetWidth(3)
  replyAccent:SetPoint("TOPLEFT", replyBar, "TOPLEFT", 0, 0)
  replyAccent:SetPoint("BOTTOMLEFT", replyBar, "BOTTOMLEFT", 0, 0)
  replyAccent:SetColorTexture(1.0, 0.82, 0.35, 0.95)
  local replyCancel = CreateFrame("Button", nil, replyBar)
  replyCancel:SetSize(18, 18)
  replyCancel:SetPoint("RIGHT", replyBar, "RIGHT", -6, 0)
  local replyCancelFs = replyCancel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  replyCancelFs:SetAllPoints()
  replyCancelFs:SetText("×")
  replyCancelFs:SetTextColor(0.75, 0.55, 0.45)
  replyCancel:SetScript("OnEnter", function()
    replyCancelFs:SetTextColor(1, 0.75, 0.55)
  end)
  replyCancel:SetScript("OnLeave", function()
    replyCancelFs:SetTextColor(0.75, 0.55, 0.45)
  end)
  replyCancel:SetScript("OnClick", function()
    CEF.Chat.clearPendingReply()
  end)
  local replyLabel = replyBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  replyLabel:SetPoint("TOPLEFT", replyBar, "TOPLEFT", 10, -3)
  replyLabel:SetText(CEF.L.CHAT_REPLYING_TO or "Replying to")
  f.chatReplyLabel = replyLabel
  local replyNameFs = replyBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  replyNameFs:SetPoint("LEFT", replyLabel, "RIGHT", 4, 0)
  replyNameFs:SetPoint("RIGHT", replyCancel, "LEFT", -8, 0)
  replyNameFs:SetJustifyH("LEFT")
  replyNameFs:SetTextColor(1.0, 0.82, 0.35)
  local replyTextFs = replyBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  replyTextFs:SetPoint("TOPLEFT", replyBar, "TOPLEFT", 10, -16)
  replyTextFs:SetPoint("RIGHT", replyCancel, "LEFT", -8, 0)
  replyTextFs:SetJustifyH("LEFT")
  f.chatReplyBar = replyBar
  f.chatReplyNameFs = replyNameFs
  f.chatReplyTextFs = replyTextFs

  local sendBtn = CreateFrame("Button", nil, composer)
  sendBtn:SetSize(72, COMPOSER_H)
  sendBtn:SetPoint("TOPRIGHT", composer, "TOPRIGHT", 0, 0)
  sendBtn:SetPoint("BOTTOMRIGHT", composer, "BOTTOMRIGHT", 0, 0)
  local sendBg = sendBtn:CreateTexture(nil, "BACKGROUND")
  sendBg:SetAllPoints()
  sendBg:SetColorTexture(0.35, 0.26, 0.12, 1)
  local sendFs = sendBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  sendFs:SetAllPoints()
  sendFs:SetText(CEF.L.CHAT_SEND)
  sendFs:SetTextColor(1, 0.92, 0.55)
  f.chatSendFs = sendFs

  local edit = CreateFrame("EditBox", nil, composer)
  edit:SetPoint("TOPLEFT", composer, "TOPLEFT", 0, 0)
  edit:SetPoint("BOTTOMLEFT", composer, "BOTTOMLEFT", 0, 0)
  edit:SetPoint("RIGHT", sendBtn, "LEFT", -COMPOSER_GAP, 0)
  edit:SetMultiLine(false)
  edit:SetAutoFocus(false)
  edit:SetFontObject(GameFontHighlightSmall)
  edit:SetTextInsets(8, CHAR_COUNT_INSET, 0, 0)
  edit:SetMaxLetters(WHISPER_MAX_LETTERS)
  local editBg = edit:CreateTexture(nil, "BACKGROUND")
  editBg:SetAllPoints()
  editBg:SetColorTexture(0.12, 0.11, 0.1, 1)
  f.chatEditBox = edit
  f.chatEditMaxLetters = WHISPER_MAX_LETTERS

  local charCountFs = edit:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  charCountFs:SetPoint("RIGHT", edit, "RIGHT", -8, 0)
  charCountFs:SetJustifyH("RIGHT")
  charCountFs:SetText("0/" .. WHISPER_MAX_LETTERS)
  f.chatCharCountFs = charCountFs

  local function updateCharCount()
    local maxLen = f.chatEditMaxLetters or WHISPER_MAX_LETTERS
    local n = edit:GetNumLetters() or 0
    charCountFs:SetText(n .. "/" .. maxLen)
    if n >= maxLen then
      charCountFs:SetTextColor(0.95, 0.35, 0.3)
    elseif n >= math.floor(maxLen * 0.9) then
      charCountFs:SetTextColor(0.95, 0.75, 0.35)
    else
      charCountFs:SetTextColor(0.55, 0.52, 0.48)
    end
  end
  f.chatUpdateCharCount = updateCharCount

  local function doSend()
    local text = edit:GetText() or ""
    if CEF.Chat.sendActive(text) then
      edit:SetText("")
      updateCharCount()
    end
  end
  sendBtn:SetScript("OnClick", doSend)
  edit:SetScript("OnEnterPressed", function()
    doSend()
  end)
  edit:SetScript("OnEscapePressed", function(self)
    if CEF.Chat.getPendingReply and CEF.Chat.getPendingReply() then
      CEF.Chat.clearPendingReply()
      return
    end
    self:ClearFocus()
  end)
  edit:SetScript("OnTextChanged", function()
    updateCharCount()
  end)
  updateCharCount()

  local msgScroll = CreateFrame("ScrollFrame", nil, right)
  msgScroll:SetPoint("TOPLEFT", threadHeader, "BOTTOMLEFT", 0, -4)
  msgScroll:SetPoint("BOTTOMRIGHT", composer, "TOPRIGHT", 0, 6)
  msgScroll:EnableMouseWheel(true)
  local msgChild = CreateFrame("Frame", nil, msgScroll)
  msgChild:SetWidth(400)
  msgChild:SetHeight(100)
  msgScroll:SetScrollChild(msgChild)
  msgScroll:SetScript("OnMouseWheel", function(self, delta)
    local maxO = math.max(0, msgChild:GetHeight() - self:GetHeight())
    local v = self:GetVerticalScroll() - delta * 40
    if v < 0 then
      v = 0
    end
    if v > maxO then
      v = maxO
    end
    self:SetVerticalScroll(v)
  end)
  f.chatMsgScroll = msgScroll
  f.chatMsgChild = msgChild
  f.chatMsgRows = {}

  -- Mini-dashboard no estado vazio (BNet + sussurros + não respondidas).
  local dash = CreateFrame("Frame", nil, right)
  dash:SetSize(400, 78)
  dash:SetPoint("BOTTOM", msgScroll, "CENTER", 0, 52)
  dash:Hide()
  f.chatDash = dash

  local DASH_CARD_W = 124
  local DASH_CARD_GAP = 14
  local function makeDashStat(parent, x)
    local card = CreateFrame("Frame", nil, parent)
    card:SetSize(DASH_CARD_W, 72)
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", x, 0)
    local bg = card:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.09, 0.08, 0.95)
    local label = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -10)
    label:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, -10)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.75, 0.7, 0.58)
    local value = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    value:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    value:SetPoint("TOPRIGHT", label, "BOTTOMRIGHT", 0, -6)
    value:SetJustifyH("LEFT")
    value:SetTextColor(1, 0.9, 0.45)
    local sub = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    sub:SetPoint("TOPLEFT", value, "BOTTOMLEFT", 0, -4)
    sub:SetPoint("TOPRIGHT", value, "BOTTOMRIGHT", 0, -4)
    sub:SetJustifyH("LEFT")
    sub:SetTextColor(0.55, 0.52, 0.48)
    card.label = label
    card.value = value
    card.sub = sub
    return card
  end

  dash.bnet = makeDashStat(dash, 0)
  dash.whisper = makeDashStat(dash, DASH_CARD_W + DASH_CARD_GAP)
  dash.unanswered = makeDashStat(dash, (DASH_CARD_W + DASH_CARD_GAP) * 2)

  function dash:refreshLocale()
    if self.bnet and self.bnet.label then
      self.bnet.label:SetText(CEF.L.CHAT_DASH_BNET)
    end
    if self.whisper and self.whisper.label then
      self.whisper.label:SetText(CEF.L.CHAT_DASH_WHISPERS)
    end
    if self.unanswered and self.unanswered.label then
      self.unanswered.label:SetText(CEF.L.CHAT_DASH_UNANSWERED)
    end
  end

  function dash:refresh()
    self:refreshLocale()
    local stats = (CEF.Chat.getDashboardStats and CEF.Chat.getDashboardStats()) or {}
    local online = tonumber(stats.bnetOnline) or 0
    local total = tonumber(stats.bnetTotal) or 0
    local whispers = tonumber(stats.whispers) or 0
    local unanswered = tonumber(stats.unanswered) or 0
    if self.bnet then
      self.bnet.value:SetText(tostring(online) .. " / " .. tostring(total))
      self.bnet.sub:SetText(CEF.L.CHAT_DASH_BNET_SUB or "")
    end
    if self.whisper then
      self.whisper.value:SetText(tostring(whispers))
      self.whisper.sub:SetText(CEF.L.CHAT_DASH_WHISPERS_SUB or "")
    end
    if self.unanswered then
      self.unanswered.value:SetText(tostring(unanswered))
      self.unanswered.sub:SetText(CEF.L.CHAT_DASH_UNANSWERED_SUB or "")
      if unanswered > 0 then
        self.unanswered.value:SetTextColor(1, 0.72, 0.42)
      else
        self.unanswered.value:SetTextColor(1, 0.9, 0.45)
      end
    end
  end
  dash:refreshLocale()

  local emptyFs = right:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  emptyFs:SetPoint("TOP", dash, "BOTTOM", 0, -18)
  emptyFs:SetWidth(400)
  emptyFs:SetJustifyH("CENTER")
  emptyFs:SetJustifyV("TOP")
  emptyFs:SetWordWrap(true)
  emptyFs:SetText(CEF.L.CHAT_EMPTY_THREAD)
  f.chatThreadEmpty = emptyFs

  local emptyNoteFs = right:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  emptyNoteFs:SetPoint("TOP", emptyFs, "BOTTOM", 0, -14)
  emptyNoteFs:SetWidth(400)
  emptyNoteFs:SetJustifyH("CENTER")
  emptyNoteFs:SetJustifyV("TOP")
  emptyNoteFs:SetWordWrap(true)
  emptyNoteFs:SetTextColor(0.55, 0.52, 0.48)
  emptyNoteFs:SetText(CEF.L.CHAT_EMPTY_THREAD_NOTE or "")
  f.chatThreadEmptyNote = emptyNoteFs

  msgScroll:SetScript("OnSizeChanged", function(self)
    if f.cefNavTab == "messages" and f.cefScheduleChatLayoutSync then
      f.cefScheduleChatLayoutSync()
    end
  end)

  local chatLayoutBoot = CreateFrame("Frame", nil, f)
  chatLayoutBoot:Hide()
  local function scheduleChatLayoutSync()
    chatLayoutBoot:Show()
    chatLayoutBoot:SetScript("OnUpdate", function(s)
      s:SetScript("OnUpdate", nil)
      s:Hide()
      if f.cefNavTab == "messages" and f.cefSyncChatLayout then
        f.cefSyncChatLayout()
      end
    end)
  end
  f.cefScheduleChatLayoutSync = scheduleChatLayoutSync

  f.cefSyncChatLayout = function()
    if not root or not root:IsShown() then
      return
    end
    local lw = left:GetWidth() or 0
    local lh = listScroll:GetHeight() or 0
    local mw = msgScroll:GetWidth() or 0
    if lw < 32 or lh < 8 or mw < 32 then
      scheduleChatLayoutSync()
      return
    end
    listChild:SetWidth(math.max(40, lw - 10))
    msgChild:SetWidth(math.max(100, mw))
    -- Rebind evita ScrollFrame Classic “perder” o conteúdo após fullscreen.
    listScroll:SetScrollChild(listChild)
    msgScroll:SetScrollChild(msgChild)
    GUI.refresh()
  end

  root:SetScript("OnShow", function()
    scheduleChatLayoutSync()
  end)
  root:SetScript("OnSizeChanged", function()
    if root:IsShown() then
      scheduleChatLayoutSync()
    end
  end)
  listScroll:SetScript("OnSizeChanged", function()
    if f.cefNavTab == "messages" then
      scheduleChatLayoutSync()
    end
  end)

  f.cefApplyChatLocale = function()
    if searchPh then
      searchPh:SetText(CEF.L.CHAT_SEARCH_PLACEHOLDER)
    end
    if sendFs then
      sendFs:SetText(CEF.L.CHAT_SEND)
    end
    if f.chatDeleteConvFs then
      f.chatDeleteConvFs:SetText("×")
    end
    if f.chatDeleteConfirmTitle then
      f.chatDeleteConfirmTitle:SetText(CEF.L.CHAT_DELETE_CONFIRM_TITLE)
    end
    if f.chatDeleteConfirmCancelFs then
      f.chatDeleteConfirmCancelFs:SetText(CEF.L.CHAT_DELETE_CONFIRM_CANCEL)
    end
    if f.chatDeleteConfirmOkFs then
      f.chatDeleteConfirmOkFs:SetText(CEF.L.CHAT_DELETE_CONFIRM_OK)
    end
    if f.chatThreadEmpty then
      f.chatThreadEmpty:SetText(CEF.L.CHAT_EMPTY_THREAD)
    end
    if f.chatThreadEmptyNote then
      f.chatThreadEmptyNote:SetText(CEF.L.CHAT_EMPTY_THREAD_NOTE or "")
    end
    if f.chatDash and f.chatDash.refreshLocale then
      f.chatDash:refreshLocale()
    end
    GUI.refresh()
  end

  -- Modal de confirmação para apagar conversa (centro da janela).
  local pendingDeleteId = nil
  local confirmOverlay = CreateFrame("Button", nil, f)
  confirmOverlay:SetAllPoints(f)
  confirmOverlay:SetFrameStrata("DIALOG")
  confirmOverlay:EnableMouse(true)
  confirmOverlay:Hide()
  local overlayBg = confirmOverlay:CreateTexture(nil, "BACKGROUND")
  overlayBg:SetAllPoints()
  overlayBg:SetColorTexture(0, 0, 0, 0.65)

  local confirmBox = CreateFrame("Frame", nil, confirmOverlay)
  confirmBox:SetSize(360, 152)
  confirmBox:SetPoint("CENTER", confirmOverlay, "CENTER", 0, 8)
  confirmBox:EnableMouse(true)

  local boxBg = confirmBox:CreateTexture(nil, "BACKGROUND")
  boxBg:SetAllPoints()
  boxBg:SetColorTexture(0.05, 0.048, 0.06, 0.99)

  local brM, bgM, bbM, baM = 0.55, 0.45, 0.18, 0.9
  local ez = 1
  local edgeTop = confirmBox:CreateTexture(nil, "BORDER")
  edgeTop:SetHeight(ez)
  edgeTop:SetColorTexture(brM, bgM, bbM, baM)
  edgeTop:SetPoint("TOPLEFT", confirmBox, "TOPLEFT", 0, 0)
  edgeTop:SetPoint("TOPRIGHT", confirmBox, "TOPRIGHT", 0, 0)
  local edgeBot = confirmBox:CreateTexture(nil, "BORDER")
  edgeBot:SetHeight(ez)
  edgeBot:SetColorTexture(brM, bgM, bbM, baM)
  edgeBot:SetPoint("BOTTOMLEFT", confirmBox, "BOTTOMLEFT", 0, 0)
  edgeBot:SetPoint("BOTTOMRIGHT", confirmBox, "BOTTOMRIGHT", 0, 0)
  local edgeL = confirmBox:CreateTexture(nil, "BORDER")
  edgeL:SetWidth(ez)
  edgeL:SetColorTexture(brM, bgM, bbM, baM)
  edgeL:SetPoint("TOPLEFT", confirmBox, "TOPLEFT", 0, 0)
  edgeL:SetPoint("BOTTOMLEFT", confirmBox, "BOTTOMLEFT", 0, 0)
  local edgeR = confirmBox:CreateTexture(nil, "BORDER")
  edgeR:SetWidth(ez)
  edgeR:SetColorTexture(brM, bgM, bbM, baM)
  edgeR:SetPoint("TOPRIGHT", confirmBox, "TOPRIGHT", 0, 0)
  edgeR:SetPoint("BOTTOMRIGHT", confirmBox, "BOTTOMRIGHT", 0, 0)

  local headerBar = confirmBox:CreateTexture(nil, "ARTWORK")
  headerBar:SetHeight(36)
  headerBar:SetPoint("TOPLEFT", confirmBox, "TOPLEFT", 1, -1)
  headerBar:SetPoint("TOPRIGHT", confirmBox, "TOPRIGHT", -1, -1)
  headerBar:SetColorTexture(0.15, 0.12, 0.08, 1)

  local headerLine = confirmBox:CreateTexture(nil, "ARTWORK")
  headerLine:SetHeight(1)
  headerLine:SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, 0)
  headerLine:SetPoint("TOPRIGHT", headerBar, "BOTTOMRIGHT", 0, 0)
  headerLine:SetColorTexture(0.45, 0.35, 0.18, 0.55)

  local confirmTitle = confirmBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  confirmTitle:SetPoint("LEFT", headerBar, "LEFT", 16, 0)
  confirmTitle:SetPoint("RIGHT", headerBar, "RIGHT", -16, 0)
  confirmTitle:SetJustifyH("CENTER")
  confirmTitle:SetTextColor(1, 0.9, 0.55)
  confirmTitle:SetText(CEF.L.CHAT_DELETE_CONFIRM_TITLE or "Delete conversation?")
  f.chatDeleteConfirmTitle = confirmTitle

  local confirmBody = confirmBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  confirmBody:SetPoint("TOPLEFT", confirmBox, "TOPLEFT", 20, -50)
  confirmBody:SetPoint("TOPRIGHT", confirmBox, "TOPRIGHT", -20, -50)
  confirmBody:SetJustifyH("CENTER")
  confirmBody:SetTextColor(0.78, 0.75, 0.68)
  f.chatDeleteConfirmBody = confirmBody

  local function styleModalBtn(btn, r, g, b, hr, hg, hb)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(r, g, b, 1)
    btn.bg = bg
    local edgeT = btn:CreateTexture(nil, "BORDER")
    edgeT:SetHeight(1)
    edgeT:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    edgeT:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    edgeT:SetColorTexture(0.55, 0.45, 0.18, 0.55)
    local edgeB = btn:CreateTexture(nil, "BORDER")
    edgeB:SetHeight(1)
    edgeB:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    edgeB:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    edgeB:SetColorTexture(0.55, 0.45, 0.18, 0.55)
    local edgeLeft = btn:CreateTexture(nil, "BORDER")
    edgeLeft:SetWidth(1)
    edgeLeft:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    edgeLeft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    edgeLeft:SetColorTexture(0.55, 0.45, 0.18, 0.55)
    local edgeRight = btn:CreateTexture(nil, "BORDER")
    edgeRight:SetWidth(1)
    edgeRight:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    edgeRight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    edgeRight:SetColorTexture(0.55, 0.45, 0.18, 0.55)
    btn:SetScript("OnEnter", function()
      bg:SetColorTexture(hr, hg, hb, 1)
    end)
    btn:SetScript("OnLeave", function()
      bg:SetColorTexture(r, g, b, 1)
    end)
  end

  local cancelBtn = CreateFrame("Button", nil, confirmBox)
  cancelBtn:SetSize(118, 28)
  cancelBtn:SetPoint("BOTTOMLEFT", confirmBox, "BOTTOMLEFT", 24, 16)
  styleModalBtn(cancelBtn, 0.13, 0.11, 0.09, 0.2, 0.17, 0.13)
  local cancelFs = cancelBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  cancelFs:SetAllPoints()
  cancelFs:SetText(CEF.L.CHAT_DELETE_CONFIRM_CANCEL or "Cancel")
  cancelFs:SetTextColor(0.9, 0.86, 0.75)
  f.chatDeleteConfirmCancelFs = cancelFs

  local okBtn = CreateFrame("Button", nil, confirmBox)
  okBtn:SetSize(118, 28)
  okBtn:SetPoint("BOTTOMRIGHT", confirmBox, "BOTTOMRIGHT", -24, 16)
  styleModalBtn(okBtn, 0.42, 0.16, 0.12, 0.55, 0.22, 0.16)
  local okFs = okBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  okFs:SetAllPoints()
  okFs:SetText(CEF.L.CHAT_DELETE_CONFIRM_OK or "Delete")
  okFs:SetTextColor(1, 0.88, 0.78)
  f.chatDeleteConfirmOkFs = okFs

  local function hideDeleteConfirm()
    pendingDeleteId = nil
    confirmOverlay:Hide()
  end

  f.chatShowDeleteConfirm = function(cid)
    pendingDeleteId = cid
    local conv = CEF.Chat.getConversation and CEF.Chat.getConversation(cid)
    local name = (conv and conv.name) or ""
    local bodyFmt = CEF.L.CHAT_DELETE_CONFIRM_BODY or "Delete the conversation with %s? This cannot be undone."
    confirmTitle:SetText(CEF.L.CHAT_DELETE_CONFIRM_TITLE or "Delete conversation?")
    cancelFs:SetText(CEF.L.CHAT_DELETE_CONFIRM_CANCEL or "Cancel")
    okFs:SetText(CEF.L.CHAT_DELETE_CONFIRM_OK or "Delete")
    if name ~= "" then
      confirmBody:SetText(bodyFmt:format(name))
    else
      confirmBody:SetText(CEF.L.CHAT_DELETE_CONFIRM_BODY_GENERIC or "Delete this conversation? This cannot be undone.")
    end
    confirmOverlay:Show()
  end

  confirmOverlay:SetScript("OnClick", hideDeleteConfirm)
  cancelBtn:SetScript("OnClick", hideDeleteConfirm)
  okBtn:SetScript("OnClick", function()
    local cid = pendingDeleteId
    hideDeleteConfirm()
    if cid then
      CEF.Chat.deleteConversation(cid)
    end
  end)
  confirmOverlay:SetScript("OnHide", function()
    pendingDeleteId = nil
  end)
  confirmBox:SetScript("OnMouseUp", function() end)

  CEF.Chat.onChanged(function()
    if root:IsShown() then
      GUI.refresh()
    end
  end)

  CEF.UI.chatRoot = root
end
