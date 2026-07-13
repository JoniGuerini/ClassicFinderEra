-- Módulo: persistência (SavedVariables) do addon.
-- Mantém exatamente a mesma estrutura do saved-variable.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.DB = CEF.DB or {}

-- Era / SoD / Hardcore / Fresh compartilham o cliente _classic_era_ e o mesmo
-- ClassicEraFinderDB. Oficial é ao vivo (OK); listagens do Chat precisam de
-- escopo por temporada + realm.
local function normalizeRealmKey()
  if GetNormalizedRealmName then
    local n = GetNormalizedRealmName()
    if type(n) == "string" and n ~= "" then
      return strlower(n)
    end
  end
  local r = (GetRealmName and GetRealmName()) or "unknown"
  r = tostring(r):gsub("%s+", "")
  return strlower(r)
end

local function activeSeasonId()
  if C_Seasons and C_Seasons.GetActiveSeason then
    local s = C_Seasons.GetActiveSeason()
    if s ~= nil then
      return tonumber(s) or 0
    end
  end
  return 0
end

--- Chave de escopo das listagens Chat (não mistura HC ↔ SoD ↔ Era).
function CEF.DB.getListingScopeKey()
  return "s" .. tostring(activeSeasonId()) .. ":r:" .. normalizeRealmKey()
end

local function migrateFlatEntries(db)
  if type(db.listingByScope) ~= "table" then
    db.listingByScope = {}
  end
  -- Formato antigo: db.entries = { ... }. Não dá pra saber de qual modo veio;
  -- descarta pra não contaminar SoD/HC/Era. Mensagens BNet (db.chat) ficam.
  if type(db.entries) == "table" then
    db.entries = nil
  end
end

function CEF.DB.init()
  _G.ClassicEraFinderDB = _G.ClassicEraFinderDB or {}
  local db = _G.ClassicEraFinderDB
  migrateFlatEntries(db)
  if type(db.chat) ~= "table" then
    db.chat = {}
  end
  if type(db.chat.conversations) ~= "table" then
    db.chat.conversations = {}
  end
  if type(db.minimap) ~= "table" then
    db.minimap = {}
  end
  if db.minimap.angle == nil then
    db.minimap.angle = 218
  end
  -- nil = automático (idioma do cliente); "enUS" / "ptBR" / … = override manual.
  if db.localeOverride == false or db.localeOverride == "" then
    db.localeOverride = nil
  end
  -- nil / true = imprimir novas listagens do Chat no chat do jogo; false = off.
  if db.chatListingAlerts == nil then
    db.chatListingAlerts = true
  end
  db.version = db.version or 1
  if (tonumber(db.version) or 1) < 2 then
    db.version = 2
  end
end

function CEF.DB.getListingEntries()
  CEF.DB.init()
  local db = _G.ClassicEraFinderDB
  local key = CEF.DB.getListingScopeKey()
  local bucket = db.listingByScope[key]
  if type(bucket) ~= "table" then
    bucket = {}
    db.listingByScope[key] = bucket
  end
  return bucket, key
end

function CEF.DB.persistChat(conversations)
  CEF.DB.init()
  local db = _G.ClassicEraFinderDB
  local out = {}
  if type(conversations) == "table" then
    for id, conv in pairs(conversations) do
      if type(conv) == "table" and type(id) == "string" then
        local msgs = {}
        if type(conv.messages) == "table" then
          for i, m in ipairs(conv.messages) do
            if type(m) == "table" and type(m.text) == "string" and m.text ~= "" then
              local row = {
                id = m.id and tostring(m.id) or nil,
                t = tonumber(m.t) or 0,
                dir = (m.dir == "out" and "out") or (m.dir == "sys" and "sys") or "in",
                text = tostring(m.text),
              }
              if type(m.reply) == "table" and type(m.reply.text) == "string" and m.reply.text ~= "" then
                row.reply = {
                  id = m.reply.id and tostring(m.reply.id) or nil,
                  name = tostring(m.reply.name or ""),
                  text = tostring(m.reply.text),
                }
              end
              msgs[#msgs + 1] = row
            end
          end
        end
        out[id] = {
          id = tostring(conv.id or id),
          kind = (conv.kind == "bnet") and "bnet" or "whisper",
          name = tostring(conv.name or ""),
          bnetAccountID = tonumber(conv.bnetAccountID),
          lastActivity = tonumber(conv.lastActivity) or 0,
          unread = tonumber(conv.unread) or 0,
          messages = msgs,
        }
      end
    end
  end
  db.chat = db.chat or {}
  db.chat.conversations = out
end

function CEF.DB.persistEntries(entries)
  entries = entries or {}
  CEF.DB.init()

  local db = _G.ClassicEraFinderDB
  local key = CEF.DB.getListingScopeKey()
  local out = {}
  for i, e in ipairs(entries) do
    local instList = {}
    if type(e.instances) == "table" then
      for j, k in ipairs(e.instances) do
        instList[j] = tostring(k)
      end
    elseif e.instance and e.instance ~= "" and e.instance ~= "—" then
      instList[1] = tostring(e.instance)
    end

    out[i] = {
      sender = tostring(e.sender or ""),
      guid = tostring(e.guid or ""),
      text = tostring(e.text or ""),
      time = tonumber(e.time) or 0,
      instance = instList[1] or tostring(e.instance or ""),
      instances = instList,
      channel = tostring(e.channel or ""),
    }
  end
  db.listingByScope[key] = out
end
