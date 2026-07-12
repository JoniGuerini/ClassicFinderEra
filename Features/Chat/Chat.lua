-- Módulo: hub de mensagens (whisper + Battle.net) — store, eventos e envio.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Chat = CEF.Chat or {}
local Chat = CEF.Chat

local conversations = {}
local activeConversationId = nil
local listeners = {}
local searchText = ""
local msgIdSeq = 0
local pendingReply = nil
local nextOutgoingReply = nil
local pendingOutgoingBody = nil
local lastWhisperAttempt = nil

local REPLY_SNIPPET_LEN = 80
local WHISPER_FAIL_WINDOW = 5

local function notify()
  for _, fn in ipairs(listeners) do
    pcall(fn)
  end
end

local function nextMsgId()
  msgIdSeq = msgIdSeq + 1
  return "m" .. tostring(msgIdSeq)
end

local function snippetText(text, maxLen)
  text = tostring(text or "")
  maxLen = maxLen or REPLY_SNIPPET_LEN
  if #text <= maxLen then
    return text
  end
  return strsub(text, 1, maxLen - 1) .. "…"
end

local function copyReply(reply)
  if type(reply) ~= "table" then
    return nil
  end
  local id = reply.id
  local name = tostring(reply.name or "")
  local text = tostring(reply.text or "")
  if text == "" then
    return nil
  end
  return {
    id = id and tostring(id) or nil,
    name = name,
    text = snippetText(text, REPLY_SNIPPET_LEN),
  }
end

local function buildReplyPrefix(reply)
  reply = copyReply(reply)
  if not reply then
    return nil
  end
  if reply.name ~= "" then
    return "> " .. reply.name .. ": " .. reply.text
  end
  return "> " .. reply.text
end

local function parseWiredReply(text)
  if type(text) ~= "string" then
    return nil, text
  end
  local name, snip, body = text:match("^> ([^\n:]+): ([^\n]*)\n(.+)$")
  if body and body ~= "" then
    return copyReply({ name = strtrim(name or ""), text = snip or "" }), body
  end
  local snip2, body2 = text:match("^> ([^\n]+)\n(.+)$")
  if body2 and body2 ~= "" then
    return copyReply({ name = "", text = snip2 or "" }), body2
  end
  return nil, text
end

local function normalizeDir(dir)
  if dir == "out" then
    return "out"
  end
  if dir == "sys" then
    return "sys"
  end
  return "in"
end

local function stripName(name)
  if CEF.stripRealm then
    return CEF.stripRealm(name or "") or ""
  end
  name = name or ""
  local short = name:match("^([^%-]+)")
  return short or name
end

local function escapePattern(s)
  return (tostring(s or ""):gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

-- Extrai o nome de ERR_CHAT_PLAYER_NOT_FOUND_S ("… '%s' …").
local function extractNotFoundName(systemText)
  if type(systemText) ~= "string" or systemText == "" then
    return nil
  end
  local fmt = ERR_CHAT_PLAYER_NOT_FOUND_S
  if type(fmt) == "string" and fmt ~= "" then
    local idx = fmt:find("%%s", 1, true)
    if idx then
      local prec = fmt:sub(1, idx - 1)
      local post = fmt:sub(idx + 2)
      local name = systemText:match("^" .. escapePattern(prec) .. "(.+)" .. escapePattern(post) .. "$")
      if name then
        name = strtrim(name)
        name = name:gsub("^['\"]+", ""):gsub("['\"]+$", "")
        if name ~= "" then
          return name
        end
      end
    end
  end
  return nil
end

local function namesMatch(a, b)
  a = strlower(stripName(a or ""))
  b = strlower(stripName(b or ""))
  return a ~= "" and a == b
end

function Chat.onChanged(fn)
  if type(fn) == "function" then
    listeners[#listeners + 1] = fn
  end
end

local function now()
  return time and time() or 0
end

function Chat.whisperId(name)
  local n = stripName(name)
  if n == "" then
    return nil
  end
  return "w:" .. strlower(n), n
end

-- Declarado adiante; forward para uso em canonicalBnetAccountId.
local friendAccountInfo

-- Resolve um bnetAccountID varrendo a lista de amigos, onde nome, BattleTag
-- e ID vêm da MESMA entrada. (GetAccountInfoByID retorna dados trocados no
-- Classic Era e não pode ser usado.)
local function canonicalBnetAccountId(accountId)
  accountId = tonumber(accountId)
  if not accountId then
    return nil, nil, nil
  end
  local n = (BNGetNumFriends and BNGetNumFriends()) or 0
  for i = 1, n do
    local id, accountName, _, _, battleTag = friendAccountInfo(i)
    if tonumber(id) == accountId then
      if accountName == "" then
        accountName = nil
      end
      if battleTag == "" then
        battleTag = nil
      end
      return accountId, accountName, battleTag
    end
  end
  return accountId, nil, nil
end

function Chat.bnetId(accountId, displayName)
  local canon, resolvedName, battleTag = canonicalBnetAccountId(accountId)
  if not canon then
    return nil
  end
  local display = resolvedName or displayName or ("BN#" .. tostring(canon))
  -- BattleTag é único e estável; IDs numéricos podem colidir entre a lista
  -- de amigos e os eventos de chat, o que misturava históricos.
  local key
  if battleTag then
    key = "bn:tag:" .. strlower(battleTag)
  else
    key = "bn:" .. tostring(canon)
  end
  return key, display, canon
end

local function ensureConv(id, kind, name, bnetAccountID)
  if not id then
    return nil
  end
  local c = conversations[id]
  if not c then
    c = {
      id = id,
      kind = kind or "whisper",
      name = name or "",
      bnetAccountID = bnetAccountID,
      lastActivity = 0,
      unread = 0,
      messages = {},
    }
    conversations[id] = c
  else
    if name and name ~= "" then
      c.name = name
    end
    if bnetAccountID then
      c.bnetAccountID = bnetAccountID
    end
    if kind then
      c.kind = kind
    end
  end
  return c
end

local function appendMessage(conv, dir, text, ts, reply)
  if not conv or type(text) ~= "string" or text == "" then
    return
  end
  dir = normalizeDir(dir)
  local attached = nil
  if dir ~= "sys" then
    attached = copyReply(reply)
    if dir == "out" and nextOutgoingReply then
      attached = copyReply(nextOutgoingReply) or attached
      if pendingOutgoingBody and pendingOutgoingBody ~= "" then
        text = pendingOutgoingBody
      else
        local parsed, body = parseWiredReply(text)
        if parsed then
          attached = attached or parsed
          text = body
        end
      end
      nextOutgoingReply = nil
      pendingOutgoingBody = nil
    else
      local parsed, body = parseWiredReply(text)
      if parsed then
        attached = attached or parsed
        text = body
      end
    end
  end
  if type(text) ~= "string" or text == "" then
    return
  end
  local msg = {
    id = nextMsgId(),
    t = ts or now(),
    dir = dir,
    text = text,
  }
  if attached then
    msg.reply = attached
  end
  conv.messages[#conv.messages + 1] = msg
  conv.lastActivity = ts or now()
  return msg
end

function Chat.persist()
  if CEF.DB and CEF.DB.persistChat then
    CEF.DB.persistChat(conversations)
  end
end

function Chat.loadFromDB()
  wipe(conversations)
  CEF.DB.init()
  local db = _G.ClassicEraFinderDB
  local src = db.chat and db.chat.conversations
  if type(src) ~= "table" then
    return
  end
  for id, conv in pairs(src) do
    if type(conv) == "table" then
      local c = {
        id = tostring(conv.id or id),
        kind = (conv.kind == "bnet") and "bnet" or "whisper",
        name = tostring(conv.name or ""),
        bnetAccountID = tonumber(conv.bnetAccountID),
        lastActivity = tonumber(conv.lastActivity) or 0,
        unread = tonumber(conv.unread) or 0,
        messages = {},
      }
      if type(conv.messages) == "table" then
        for _, m in ipairs(conv.messages) do
          if type(m) == "table" and type(m.text) == "string" and m.text ~= "" then
            local msg = {
              id = m.id and tostring(m.id) or nextMsgId(),
              t = tonumber(m.t) or 0,
              dir = normalizeDir(m.dir),
              text = tostring(m.text),
            }
            local r = copyReply(m.reply)
            if r then
              msg.reply = r
            end
            c.messages[#c.messages + 1] = msg
          end
        end
      end
      conversations[c.id] = c
    end
  end
  Chat.migrateBnetKeys()
end

local function mergeConvInto(target, src)
  for _, m in ipairs(src.messages or {}) do
    target.messages[#target.messages + 1] = m
  end
  table.sort(target.messages, function(a, b)
    return (a.t or 0) < (b.t or 0)
  end)
  if (src.lastActivity or 0) > (target.lastActivity or 0) then
    target.lastActivity = src.lastActivity
  end
  target.unread = (target.unread or 0) + (src.unread or 0)
end

-- Normaliza chaves de convs BNet (chave numérica antiga ou tag errada gerada
-- por bug de API) e descarta convs BNet vazias. Roda no load e quando a BNet
-- conecta (dados podem não estar prontos no login).
function Chat.migrateBnetKeys()
  local dirty = false
  local moves = nil
  for id, c in pairs(conversations) do
    if c.kind == "bnet" then
      if #(c.messages or {}) == 0 and activeConversationId ~= id then
        -- Convs vazias são recriadas sob demanda; remover limpa chaves ruins.
        moves = moves or {}
        moves[id] = { drop = true }
      elseif c.bnetAccountID then
        local newId, _, canon = Chat.bnetId(c.bnetAccountID, c.name)
        -- Só re-chaveia quando a lista de amigos resolveu um BattleTag de
        -- verdade; senão mantém a chave atual.
        if newId and newId:find("^bn:tag:") and newId ~= id then
          moves = moves or {}
          moves[id] = { newId = newId, canon = canon }
        end
      end
    end
  end
  if not moves then
    return
  end
  for oldId, mv in pairs(moves) do
    local c = conversations[oldId]
    conversations[oldId] = nil
    dirty = true
    if not mv.drop then
      c.id = mv.newId
      c.bnetAccountID = mv.canon or c.bnetAccountID
      local existing = conversations[mv.newId]
      if existing then
        mergeConvInto(existing, c)
      else
        conversations[mv.newId] = c
      end
      if activeConversationId == oldId then
        activeConversationId = mv.newId
      end
    end
  end
  if dirty then
    Chat.persist()
    notify()
  end
end

function Chat.getPendingReply()
  return pendingReply
end

function Chat.getPendingReplyOverhead()
  local prefix = buildReplyPrefix(pendingReply)
  if not prefix then
    return 0
  end
  return #prefix + 1
end

function Chat.clearPendingReply()
  pendingReply = nil
  notify()
end

function Chat.setPendingReplyFromMessage(msg, authorName)
  if type(msg) ~= "table" or type(msg.text) ~= "string" or msg.text == "" then
    return
  end
  pendingReply = {
    id = msg.id and tostring(msg.id) or nil,
    name = tostring(authorName or msg.replyName or ""),
    text = snippetText(msg.text, REPLY_SNIPPET_LEN),
  }
  notify()
end

function Chat.getActiveId()
  return activeConversationId
end

function Chat.setActiveId(id)
  local prev = activeConversationId
  if activeConversationId ~= id then
    pendingReply = nil
  end
  activeConversationId = id
  -- Rascunho sem mensagens (ex.: whisper da Guilda sem enviar) não deve ficar.
  if prev and prev ~= id then
    Chat.pruneEmptyConversation(prev)
  end
  if id and conversations[id] then
    conversations[id].unread = 0
    Chat.persist()
  end
  notify()
end

--- Remove conversa sem mensagens. Se for a ativa, limpa a seleção.
function Chat.pruneEmptyConversation(id)
  if not id then
    return false
  end
  local c = conversations[id]
  if not c or #(c.messages or {}) > 0 then
    return false
  end
  conversations[id] = nil
  if activeConversationId == id then
    activeConversationId = nil
    pendingReply = nil
    nextOutgoingReply = nil
    pendingOutgoingBody = nil
  end
  Chat.persist()
  notify()
  return true
end

--- Descarta a conversa ativa se ainda não tiver nenhuma mensagem.
function Chat.discardEmptyActive()
  return Chat.pruneEmptyConversation(activeConversationId)
end

function Chat.getConversation(id)
  return id and conversations[id] or nil
end

function Chat.getMessages(id)
  local c = conversations[id]
  return (c and c.messages) or {}
end

function Chat.setSearchText(q)
  searchText = strlower(q or "")
  notify()
end

function Chat.getSearchText()
  return searchText
end

-- Nomes BNet podem ser kstrings protegidas (não comparáveis). Preferir
-- BattleTag e nome do personagem, que são texto legível. Em whispers,
-- também compara sem o sufixo de realm (Nome-Reino).
local function textMatchesQuery(q, ...)
  if not q or q == "" then
    return true
  end
  for i = 1, select("#", ...) do
    local s = select(i, ...)
    if type(s) == "string" and s ~= "" then
      local hay = strlower(s)
      if hay:find(q, 1, true) then
        return true
      end
      -- BattleTag: "nome#1234" → "nome"
      local tagBase = hay:match("^([^#]+)")
      if tagBase and tagBase ~= hay and tagBase:find(q, 1, true) then
        return true
      end
      -- Realm: "nome-reino" → "nome"
      local realmBase = hay:match("^([^%-]+)")
      if realmBase and realmBase ~= hay and realmBase:find(q, 1, true) then
        return true
      end
    end
  end
  return false
end

function Chat.getWhisperList()
  local list = {}
  local q = searchText
  for _, c in pairs(conversations) do
    if c.kind == "whisper" and #(c.messages or {}) > 0 then
      local id = strlower(c.id or "")
      local idName = id:match("^w:(.+)$")
      local shortName = stripName(c.name or "")
      if textMatchesQuery(q, c.name, shortName, idName, id) then
        list[#list + 1] = c
      end
    end
  end
  table.sort(list, function(a, b)
    return strlower(a.name or "") < strlower(b.name or "")
  end)
  return list
end

--- Contagens para o painel vazio da aba Mensagens (ignora filtro de busca).
function Chat.getDashboardStats()
  local bnetTotal, bnetOnline = 0, 0
  local n = (BNGetNumFriends and BNGetNumFriends()) or 0
  for i = 1, n do
    local accountID, _, isOnline = friendAccountInfo(i)
    if accountID then
      bnetTotal = bnetTotal + 1
      if isOnline then
        bnetOnline = bnetOnline + 1
      end
    end
  end
  local whispers, unread, unanswered = 0, 0, 0
  for _, c in pairs(conversations) do
    local msgs = c.messages or {}
    if #msgs > 0 then
      if c.kind == "whisper" then
        whispers = whispers + 1
      end
      unread = unread + (tonumber(c.unread) or 0)
      local last = msgs[#msgs]
      if last and last.dir == "in" then
        unanswered = unanswered + 1
      end
    end
  end
  return {
    bnetTotal = bnetTotal,
    bnetOnline = bnetOnline,
    whispers = whispers,
    unread = unread,
    unanswered = unanswered,
  }
end

-- Mantido por compatibilidade; preferir getWhisperList / getBnetFriends.
function Chat.getConversationList()
  return Chat.getWhisperList()
end

function friendAccountInfo(i)
  if C_BattleNet and C_BattleNet.GetFriendAccountInfo then
    local info = C_BattleNet.GetFriendAccountInfo(i)
    if info then
      local accountName = info.accountName or info.battleTag or ""
      local accountID = info.bnetAccountID or info.ID
      local battleTag = info.battleTag
      local isOnline = false
      if info.isOnline ~= nil then
        isOnline = info.isOnline and true or false
      elseif info.gameAccountInfo and info.gameAccountInfo.isOnline ~= nil then
        isOnline = info.gameAccountInfo.isOnline and true or false
      end
      local toonName = nil
      if info.gameAccountInfo then
        toonName = info.gameAccountInfo.characterName
      end
      return accountID, accountName, isOnline, toonName, battleTag
    end
  end
  if BNGetFriendInfo then
    local presenceID, givenName, surname, toonName, toonID, client, isOnline = BNGetFriendInfo(i)
    local accountID = presenceID
    if BNGetFriendInfoByID and presenceID then
      -- presenceID is usable with BNSendWhisper on many classic builds
    end
    local accountName = (givenName or "") .. ((surname and surname ~= "") and (" " .. surname) or "")
    if accountName == "" then
      accountName = toonName or ("Friend " .. tostring(i))
    end
    return accountID, accountName, isOnline and true or false, toonName, nil
  end
  return nil
end

function Chat.getBnetFriends()
  local list = {}
  local n = (BNGetNumFriends and BNGetNumFriends()) or 0
  local q = searchText
  for i = 1, n do
    local accountID, accountName, isOnline, toonName, battleTag = friendAccountInfo(i)
    if accountID then
      local display = accountName
      if toonName and toonName ~= "" then
        display = accountName .. " (" .. toonName .. ")"
      end
      -- accountName pode ser kstring; battleTag/toonName são pesquisáveis.
      if textMatchesQuery(q, battleTag, toonName, accountName, display) then
        local id = Chat.bnetId(accountID, accountName)
        local conv = id and conversations[id]
        list[#list + 1] = {
          id = id,
          kind = "bnet",
          name = accountName,
          display = display,
          bnetAccountID = accountID,
          online = isOnline,
          toonName = toonName,
          unread = (conv and tonumber(conv.unread)) or 0,
          lastActivity = (conv and tonumber(conv.lastActivity)) or 0,
          hasHistory = conv and #(conv.messages or {}) > 0,
        }
      end
    end
  end
  table.sort(list, function(a, b)
    if a.online ~= b.online then
      return a.online
    end
    return strlower(a.name or "") < strlower(b.name or "")
  end)
  return list
end

-- Nomes BNet podem vir como "Nome#1234" ou com realm; compara de forma leniente.
local function nameMatches(candidate, wanted)
  candidate = strlower(tostring(candidate or ""))
  if candidate == "" then
    return false
  end
  if candidate == wanted then
    return true
  end
  local base = candidate:match("^([^#%-]+)")
  return base == wanted
end

-- Lista as conversas salvas (para diagnóstico via /cef listchat).
function Chat.debugListConversations()
  local lines = {}
  for id, c in pairs(conversations) do
    lines[#lines + 1] = string.format("%s | kind=%s | name=%s | msgs=%d",
      tostring(id), tostring(c.kind), tostring(c.name), #(c.messages or {}))
  end
  table.sort(lines)
  return lines
end

-- Move manualmente todo o histórico de uma conversa para outro amigo BNet.
-- Uso: /cef movechat <NomeOrigem> <NomeDestino>
function Chat.moveConversationByNames(fromName, toName)
  fromName = strlower(tostring(fromName or ""))
  toName = strlower(tostring(toName or ""))
  if fromName == "" or toName == "" then
    return false, "usage"
  end

  -- Pode haver mais de uma conv com o mesmo nome (restos de chaves ruins);
  -- escolhe a que tem mais mensagens. O nome pode ser uma kstring protegida,
  -- então compara também com o BattleTag embutido na chave.
  local src = nil
  for id, c in pairs(conversations) do
    local idl = strlower(id)
    local tagBase = idl:match("^bn:tag:([^#]+)")
    if nameMatches(c.name, fromName) or idl == fromName or tagBase == fromName then
      if not src or #(c.messages or {}) > #(src.messages or {}) then
        src = c
      end
    end
  end
  if not src or #(src.messages or {}) == 0 then
    return false, "source_not_found"
  end

  local targetAccountID, targetAccountName
  local n = (BNGetNumFriends and BNGetNumFriends()) or 0
  for i = 1, n do
    local accountID, accountName, _, _, battleTag = friendAccountInfo(i)
    if accountID and (nameMatches(accountName, toName) or nameMatches(battleTag, toName)) then
      targetAccountID = accountID
      targetAccountName = accountName
      break
    end
  end
  if not targetAccountID then
    return false, "target_not_found"
  end

  local id, display, canon = Chat.bnetId(targetAccountID, targetAccountName)
  if not id then
    return false, "target_not_found"
  end
  local target = ensureConv(id, "bnet", display, canon or tonumber(targetAccountID))
  if target == src then
    return false, "same_conversation"
  end

  mergeConvInto(target, src)
  conversations[src.id] = nil
  if activeConversationId == src.id then
    activeConversationId = target.id
  end
  Chat.persist()
  notify()
  return true, target.name
end

function Chat.openWhisper(name)
  local id, display = Chat.whisperId(name)
  if not id then
    return nil
  end
  ensureConv(id, "whisper", display)
  Chat.setActiveId(id)
  return id
end

function Chat.openBnet(accountID, displayName)
  local id, display, canon = Chat.bnetId(accountID, displayName)
  if not id then
    return nil
  end
  ensureConv(id, "bnet", display, canon or tonumber(accountID))
  Chat.setActiveId(id)
  return id
end

function Chat.focusWhisperAndShow(name)
  local id = Chat.openWhisper(name)
  local f = CEF.UI and CEF.UI.mainFrame
  if f then
    if not f:IsShown() then
      f:Show()
      if CEF.UI.uiTicker then
        CEF.UI.uiTicker:Show()
      end
    end
    if f.cefApplyNavTab then
      f.cefApplyNavTab("messages")
    end
    if f.cefScheduleChatLayoutSync then
      f.cefScheduleChatLayoutSync()
    elseif CEF.ChatUI and CEF.ChatUI.refresh then
      CEF.ChatUI.refresh()
    end
    -- Abrir conversa começa sempre com o campo limpo.
    if f.chatEditBox then
      f.chatEditBox:SetText("")
      if f.chatUpdateCharCount then
        f.chatUpdateCharCount()
      end
    end
    -- Foco com retry: espera o composer ficar visível (layout pode demorar frames).
    if not f.cefChatFocusBoot then
      f.cefChatFocusBoot = CreateFrame("Frame", nil, f)
      f.cefChatFocusBoot:Hide()
    end
    local boot = f.cefChatFocusBoot
    boot.cefTries = 0
    boot:Show()
    boot:SetScript("OnUpdate", function(self)
      self.cefTries = (self.cefTries or 0) + 1
      local edit = f.chatEditBox
      local ready = edit and f.chatComposer and f.chatComposer:IsShown()
      if ready or self.cefTries >= 20 then
        self:SetScript("OnUpdate", nil)
        self:Hide()
        if ready then
          edit:Enable()
          edit:EnableMouse(true)
          edit:SetFocus()
          if edit.HighlightText then
            edit:HighlightText(0, 0)
          end
        end
      end
    end)
  end
  return id
end

function Chat.addIncomingWhisper(name, text)
  local id, display = Chat.whisperId(name)
  local conv = ensureConv(id, "whisper", display)
  if not conv then
    return
  end
  appendMessage(conv, "in", text)
  if activeConversationId ~= id then
    conv.unread = (conv.unread or 0) + 1
  end
  Chat.persist()
  notify()
end

function Chat.addOutgoingWhisper(name, text)
  local id, display = Chat.whisperId(name)
  local conv = ensureConv(id, "whisper", display)
  if not conv then
    return
  end
  appendMessage(conv, "out", text)
  Chat.persist()
  notify()
end

function Chat.addIncomingBnet(accountID, displayName, text)
  local id, display, canon = Chat.bnetId(accountID, displayName)
  local conv = ensureConv(id, "bnet", display, canon or tonumber(accountID))
  if not conv then
    return
  end
  appendMessage(conv, "in", text)
  if activeConversationId ~= id then
    conv.unread = (conv.unread or 0) + 1
  end
  Chat.persist()
  notify()
end

function Chat.addOutgoingBnet(accountID, displayName, text)
  local id, display, canon = Chat.bnetId(accountID, displayName)
  local conv = ensureConv(id, "bnet", display, canon or tonumber(accountID))
  if not conv then
    return
  end
  appendMessage(conv, "out", text)
  Chat.persist()
  notify()
end

function Chat.sendActive(text)
  text = strtrim(text or "")
  if text == "" then
    return false
  end
  local conv = conversations[activeConversationId]
  if not conv then
    return false
  end
  nextOutgoingReply = copyReply(pendingReply)
  pendingOutgoingBody = text
  local savedPending = pendingReply
  pendingReply = nil
  notify()

  local wire = text
  local prefix = buildReplyPrefix(nextOutgoingReply)
  if prefix then
    wire = prefix .. "\n" .. text
  end

  local function failSend()
    nextOutgoingReply = nil
    pendingOutgoingBody = nil
    pendingReply = savedPending
    notify()
    return false
  end

  if conv.kind == "bnet" then
    local aid = tonumber(conv.bnetAccountID)
    if not aid or not BNSendWhisper then
      return failSend()
    end
    if #wire > 4096 then
      return failSend()
    end
    BNSendWhisper(aid, wire)
    return true
  end
  local target = conv.name
  if not target or target == "" or not SendChatMessage then
    return failSend()
  end
  if #wire > 255 then
    return failSend()
  end
  lastWhisperAttempt = {
    id = activeConversationId,
    name = target,
    t = now(),
  }
  SendChatMessage(wire, "WHISPER", nil, target)
  return true
end

function Chat.addSystemNotice(convId, text)
  text = tostring(text or "")
  if text == "" then
    return
  end
  local conv = conversations[convId]
  if not conv then
    return
  end
  appendMessage(conv, "sys", text)
  Chat.persist()
  notify()
end

local function handlePlayerNotFound(systemText)
  local foundName = extractNotFoundName(systemText)
  local attempt = lastWhisperAttempt
  local convId = nil

  if attempt and attempt.id and conversations[attempt.id] and (now() - (attempt.t or 0)) <= WHISPER_FAIL_WINDOW then
    local attemptConv = conversations[attempt.id]
    if foundName then
      if namesMatch(foundName, attempt.name) or namesMatch(foundName, attemptConv.name) then
        convId = attempt.id
      end
    else
      -- Fallback se o locale não casar o padrão: nome do último whisper no texto.
      local n = stripName(attempt.name)
      if n ~= "" and strlower(systemText):find(strlower(n), 1, true) then
        convId = attempt.id
      end
    end
  end

  if not convId and foundName then
    local id = select(1, Chat.whisperId(foundName))
    if id and conversations[id] then
      convId = id
    elseif activeConversationId and conversations[activeConversationId] then
      local ac = conversations[activeConversationId]
      if ac.kind == "whisper" and namesMatch(foundName, ac.name) then
        convId = activeConversationId
      end
    end
  end

  if not convId then
    return
  end

  nextOutgoingReply = nil
  pendingOutgoingBody = nil
  if attempt and attempt.id == convId then
    lastWhisperAttempt = nil
  end

  Chat.addSystemNotice(convId, systemText)
end

function Chat.deleteConversation(id)
  if not id or not conversations[id] then
    return
  end
  conversations[id] = nil
  if activeConversationId == id then
    activeConversationId = nil
    pendingReply = nil
    nextOutgoingReply = nil
    pendingOutgoingBody = nil
  end
  Chat.persist()
  notify()
end

function Chat.handleEvent(event, ...)
  if event == "CHAT_MSG_WHISPER" then
    local text, playerName = ...
    Chat.addIncomingWhisper(playerName, text)
  elseif event == "CHAT_MSG_WHISPER_INFORM" then
    local text, playerName = ...
    lastWhisperAttempt = nil
    Chat.addOutgoingWhisper(playerName, text)
  elseif event == "CHAT_MSG_BN_WHISPER" then
    local text, senderName = ...
    local bnetIDAccount = select(13, ...)
    if not bnetIDAccount then
      bnetIDAccount = select(14, ...)
    end
    Chat.addIncomingBnet(bnetIDAccount, senderName, text)
  elseif event == "CHAT_MSG_BN_WHISPER_INFORM" then
    local text, senderName = ...
    local bnetIDAccount = select(13, ...)
    if not bnetIDAccount then
      bnetIDAccount = select(14, ...)
    end
    Chat.addOutgoingBnet(bnetIDAccount, senderName, text)
  elseif event == "CHAT_MSG_SYSTEM" then
    local text = ...
    if type(text) == "string" and text ~= "" then
      handlePlayerNotFound(text)
    end
  elseif event == "BN_FRIEND_LIST_SIZE_CHANGED" or event == "BN_FRIEND_INFO_CHANGED" or event == "BN_CONNECTED" or event == "BN_DISCONNECTED" then
    if Chat.migrateBnetKeys then
      Chat.migrateBnetKeys()
    end
    notify()
  end
end

function Chat.totalUnread()
  local n = 0
  for _, c in pairs(conversations) do
    n = n + (tonumber(c.unread) or 0)
  end
  return n
end
