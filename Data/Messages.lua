-- Módulo: lógica de mensagens (LFG/LFM, intenção, filtros de role)
-- Exposto em ClassicEraFinder.* para o entrypoint chamar.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

local INTENT_FILTER_MENU_OPTS = {
  { key = false, labelKey = "FILTER_ALL_LISTINGS" },
  { key = "invite", labelKey = "FILTER_LOOKING_FOR_GROUP" },
  { key = "whisper", labelKey = "FILTER_LOOKING_FOR_MEMBERS" },
}
CEF.INTENT_FILTER_MENU_OPTS = INTENT_FILTER_MENU_OPTS

local function intentLabel(opt)
  return (opt and opt.labelKey and CEF.L[opt.labelKey]) or (opt and opt.label) or "—"
end

function CEF.refreshIntentLocaleLabels()
  for _, opt in ipairs(INTENT_FILTER_MENU_OPTS) do
    opt.label = intentLabel(opt)
  end
end

function CEF.intentFilterOptionRichText(intentKeyOrSet)
  if type(intentKeyOrSet) ~= "table" then
    if intentKeyOrSet == false or intentKeyOrSet == nil then
      return "|cffffffff" .. CEF.L.FILTER_ALL_LISTINGS .. "|r"
    end
    for _, opt in ipairs(INTENT_FILTER_MENU_OPTS) do
      if opt.key == intentKeyOrSet then
        return "|cffffffff" .. intentLabel(opt) .. "|r"
      end
    end
    return "|cffffffff—|r"
  end
  local keys = CEF.filterSetSortedKeys(intentKeyOrSet)
  if #keys == 0 then
    return "|cffffffff" .. CEF.L.FILTER_ALL_LISTINGS .. "|r"
  end
  if #keys == 1 then
    return CEF.intentFilterOptionRichText(keys[1])
  end
  local labels = {}
  for _, k in ipairs(keys) do
    for _, opt in ipairs(INTENT_FILTER_MENU_OPTS) do
      if opt.key == k then
        labels[#labels + 1] = intentLabel(opt)
        break
      end
    end
  end
  if #labels == 0 then
    return "|cffffffff" .. CEF.L("FILTER_N_TYPES", #keys) .. "|r"
  end
  return "|cffffffff" .. table.concat(labels, ", ") .. "|r"
end

local ROLE_FILTER_MENU_OPTS = {
  { key = false, labelKey = "FILTER_ANY_ROLE" },
  { key = "tank", labelKey = "FILTER_ROLE_TANK" },
  { key = "heal", labelKey = "FILTER_ROLE_HEAL" },
  { key = "dps", labelKey = "FILTER_ROLE_DPS" },
}
CEF.ROLE_FILTER_MENU_OPTS = ROLE_FILTER_MENU_OPTS

local function roleLabel(opt)
  return (opt and opt.labelKey and CEF.L[opt.labelKey]) or (opt and opt.label) or "—"
end

function CEF.refreshRoleLocaleLabels()
  for _, opt in ipairs(ROLE_FILTER_MENU_OPTS) do
    opt.label = roleLabel(opt)
  end
end

function CEF.roleFilterOptionRichText(roleKeyOrSet)
  if type(roleKeyOrSet) ~= "table" then
    if roleKeyOrSet == false or roleKeyOrSet == nil then
      return "|cffffffff" .. CEF.L.FILTER_ANY_ROLE .. "|r"
    end
    for _, opt in ipairs(ROLE_FILTER_MENU_OPTS) do
      if opt.key == roleKeyOrSet then
        return "|cffffffff" .. roleLabel(opt) .. "|r"
      end
    end
    return "|cffffffff—|r"
  end
  local keys = CEF.filterSetSortedKeys(roleKeyOrSet)
  if #keys == 0 then
    return "|cffffffff" .. CEF.L.FILTER_ANY_ROLE .. "|r"
  end
  if #keys == 1 then
    return CEF.roleFilterOptionRichText(keys[1])
  end
  local labels = {}
  for _, k in ipairs(keys) do
    for _, opt in ipairs(ROLE_FILTER_MENU_OPTS) do
      if opt.key == k then
        labels[#labels + 1] = roleLabel(opt)
        break
      end
    end
  end
  if #labels == 0 then
    return "|cffffffff" .. CEF.L("FILTER_N_ROLES", #keys) .. "|r"
  end
  return "|cffffffff" .. table.concat(labels, ", ") .. "|r"
end

-- Palavras que sugerem montagem de grupo / vaga
local LFG_PLAIN = {
  "lfg", "lfm", "lf ", "lf1", "lf1m", "lf2", "lf2m", "lf3", "lf3m", "looking for", "need ", "need a", "need 1", "need 2",
  "group for", "gtg", "forming", "wtb group", "boost", "carry",
  "procura", "preciso", "precisa", "grupo", "vaga", "tank", "heal", "healer", "dps",
  "warrior", "paladin", "druid", "rogue", "hunter", "mage", "priest", "lock", "shaman",
  "guerreiro", "mago", "sacer", "cacador", "ladino",
  -- Italiano
  "cerco", "cerchiamo", "gruppo", "manca", "servono",
  -- Alemão
  "suche", "suchen", "gesucht", "brauchen", "gruppe", "heiler",
  -- Francês
  "cherche", "recherche", "cherchons", "manque", "besoin", "groupe", "soigneur",
  -- Espanhol
  "busco", "buscamos", "se busca", "necesito", "necesitamos", "tanque", "sanador",
  -- Russo (normalizado por lowerCyrillic)
  "ищу", "ищем", "нужен", "нужны", "требу", "группу", "группа", "пати", "танк", "хил", "дд",
  -- Coreano
  "구함", "구직", "모집", "파티", "팟", "탱", "힐", "딜",
  -- Chinês (simpl./trad.); gate ainda exige detetar a instância na mensagem
  "求组", "求組", "求队", "求隊", "组队", "組隊", "开团", "開團", "缺", "招", "徵",
  "坦", "奶", "补", "補", "输出", "輸出", "治疗", "治療",
}

-- Recrutamento (LFM: líder busca gente) noutros idiomas → ação Sussurro.
local LFM_I18N_NEEDLES = {
  -- Português (reforço)
  "procuramos", "recrutando", "so falta", "só falta",
  -- Italiano
  "cerchiamo", "ci manca", "ci serve", "servono",
  "cerco tank", "cerco un tank", "cerco heal", "cerco healer", "cerco un heal", "cerco dps", "cerco un dps",
  "manca tank", "manca heal", "manca healer", "manca dps",
  "serve tank", "serve heal", "serve healer", "serve dps",
  -- Alemão
  "wir suchen", "suchen noch", "brauchen noch", "noch platz", "letzter platz",
  "suchen tank", "suchen heiler", "suchen heal", "suchen dd", "suchen dps",
  "brauchen tank", "brauchen heiler", "brauchen dd", "brauchen dps",
  "suche tank", "suche heiler", "suche dd", "suche dps",
  "tank gesucht", "heiler gesucht", "heal gesucht", "healer gesucht", "dd gesucht", "dps gesucht",
  -- Francês
  "cherchons", "on cherche", "recherchons", "on recherche",
  "cherche tank", "cherche heal", "cherche dps",
  "manque tank", "manque heal", "manque dps", "il manque", "il nous manque",
  "besoin d'un", "besoin d'une", "besoin d’un", "besoin d’une",
  "besoin tank", "besoin heal", "besoin dps",
  -- Espanhol
  "buscamos", "se busca", "necesitamos", "hace falta", "faltan",
  "necesito tank", "necesito tanque", "necesito heal", "necesito healer", "necesito dps",
  "busco tank", "busco tanque", "busco heal", "busco healer", "busco dps",
  "falta tank", "falta tanque", "falta heal", "falta healer", "falta dps",
  -- Russo
  "ищем", "нужен танк", "нужен хил", "нужен дд", "нужны", "требуется", "требуются",
  "набираем", "наберем", "наберём", "набор в",
  "ищу танка", "ищу хила", "ищу дд",
  -- Coreano
  "모집", "구인",
  "탱 구함", "탱구함", "탱커 구함", "탱커구함",
  "힐 구함", "힐구함", "힐러 구함", "힐러구함",
  "딜 구함", "딜구함", "딜러 구함", "딜러구함",
  "한자리", "한 자리",
  -- Chinês (simpl./trad.)
  "缺t", "缺坦", "缺奶", "缺补", "缺補", "缺治疗", "缺治療", "缺输出", "缺輸出", "缺dps",
  "缺人", "缺1", "缺2", "缺3", "缺几", "缺幾",
  "还差", "還差", "差1", "差2", "差一个", "差一個",
  "招人", "招t", "招坦", "招奶", "徵人", "徵坦", "徵補",
  "来个t", "来个奶", "來個坦", "來個補", "来t", "来奶",
}

-- Procura de grupo (LFG: jogador busca vaga) noutros idiomas → ação Convidar.
local LFG_I18N_NEEDLES = {
  -- Português (reforço)
  "procurando grupo", "procuro pt", "procuro vaga", "busco vaga",
  -- Italiano
  "cerco gruppo", "cerco un gruppo", "cerco party", "cerco pt", "cerco grp",
  -- Alemão
  "suche gruppe", "suche eine gruppe", "suche grp", "gruppe gesucht", "suche anschluss",
  -- Francês
  "cherche groupe", "cherche un groupe", "recherche groupe", "recherche un groupe", "cherche grp",
  -- Espanhol
  "busco grupo", "busco un grupo", "busco party", "busco pt", "busco grp",
  -- Russo
  "ищу группу", "ищу групу", "ищу пати", "ищу пт", "возьмите в группу", "возьмите в пати",
  -- Coreano
  "구직", "파티 구함", "파티구함", "팟 구함", "팟구함", "자리 구함", "자리구함", "파티 구해요", "팟 구해요",
  -- Chinês (simpl./trad.)
  "求组", "求組", "求队", "求隊", "求个组", "求個組", "求进组", "求進組", "求带", "求帶", "求拉", "有组吗", "有組嗎",
}

-- Termos de função noutros idiomas para o filtro de role (Chat).
local ROLE_I18N_NEEDLES = {
  tank = { "tanque", "танк", " мт ", "탱", "坦" },
  heal = { "heiler", "soigneur", "sanador", "хил", "힐", "奶", "补", "補", "治疗", "治療" },
  dps = { " dd ", " dds ", " дд", "дамаг", "딜", "输出", "輸出" },
}

-- Pedidos óbvios de serviço / craft (reforço; o filtro principal é reconhecer masmorra/raid).
-- Evitar termos genéricos tipo "engineering" — batem em "Gnomeregan" etc.
local PROFESSION_TRADE_EXCLUDE = {
  "enchanter",
  "enchantor",
  "lf enchant",
  "lfg enchant",
  "lfm enchant",
  "need enchant",
  "need an enchant",
  "want enchant",
  " chest enchant",
  " bracer enchant",
  " boot enchant",
  " cloak enchant",
  " weapon enchant",
  "+4 stats",
  "+3 stats",
  "+8 stats",
  "stats to chest",
  "stats on chest",
  " lockbox",
  "unlock my",
  " disenchant",
  " d/e ",
  "port to ",
  "portal to ",
  "summon to ",
}

-- Broadcasts de morte Hardcore / sistema (citam masmorra + classe do killer → falsos LFG).
local HARDCORE_DEATH_EXCLUDE = {
  "has been slain by",
  "was slain by",
  "has fallen to",
  "they were level",
  "foi morto por",
  "foi morta por",
  "foi derrotado por",
  "foi derrotada por",
  "a été tué par",
  "a été tuée par",
  "wurde getötet von",
  "ha sido asesinado por",
  "ha sido asesinada por",
}

-- lower() do cliente não converte cirílico (Ищу→ищу); faz à mão (UTF-8, 2 bytes).
local function lowerCyrillic(s)
  if not s:find("\208", 1, true) then
    return s
  end
  -- А-П (U+0410–041F) → а-п
  s = s:gsub("\208([\144-\159])", function(b)
    return "\208" .. string.char(b:byte() + 32)
  end)
  -- Р-Я (U+0420–042F) → р-я
  s = s:gsub("\208([\160-\175])", function(b)
    return "\209" .. string.char(b:byte() - 32)
  end)
  -- Ё → ё
  s = s:gsub("\208\129", "\209\145")
  return s
end

local function normalizeMessage(msg)
  if not msg then
    return ""
  end
  -- NBSP UTF-8 e códigos de cor do chat (evita «dm|r» ou espaço “invisível» sem match).
  msg = msg:gsub("\194\160", " ")
  msg = msg:gsub("|c[%x]+", ""):gsub("|r", ""):gsub("|T[^|]+|t", "")
  msg = lowerCyrillic(msg:lower()):gsub("%s+", " ")
  return (msg:match("^%s*(.-)%s*$") or msg)
end

-- Exporta o normalizador para outros módulos.
function CEF.normalizeMessage(msg)
  return normalizeMessage(msg)
end

function CEF.classifyMessageIntent(text)
  local t = normalizeMessage(text)
  if t == "" then
    return "whisper"
  end

  local function isLfmRecruiting()
    if t:find("^lfm[%s,.!%-]", 1) or t == "lfm" then
      return true
    end
    if t:find("%s+lfm[%s,.!%-]", 1) or t:find("%s+lfm$", 1) then
      return true
    end
    if t:find("looking for more", 1, true) then
      return true
    end
    if t:find("lf%d+m", 1) or t:find("lf %d+m", 1) or t:find("lf%d+ m", 1) then
      return true
    end
    -- "LF 1 tank", "LF 1-2 tanks", "LF1 heal" — pede N jogadores = recruta grupo.
    do
      local roleOrClass =
        "(tank|tanks|heal|heals|healer|healers|dps|dd|dds|"
        .. "mage|mages|lock|locks|warlock|warlocks|"
        .. "priest|priests|pala|paladin|paladins|"
        .. "druid|druids|rogue|rogues|hunter|hunters|"
        .. "sham|shaman|shamans|warrior|warriors|war)"
      if t:find("lf%s*%d+%s*%-?%s*%d*%s*" .. roleOrClass, 1) then
        return true
      end
    end
    -- "lf 2 more dps", "lf1 more tank" — recrutamento (mais vagas), não LFG solo só com "lf".
    if t:find("lf %d+ more", 1) or t:find("lf%d+ more", 1) or t:find("lf%d+more", 1) then
      return true
    end
    if t:find("lf one more", 1, true) or t:find("lf two more", 1, true) or t:find("lf three more", 1, true) then
      return true
    end
    if t:find("looking for %d+ more", 1) then
      return true
    end
    if t:find("need %d+", 1) or t:find("need a ", 1, true) or t:find("need an ", 1, true) then
      return true
    end
    if t:find("need 1 ", 1, true) or t:find("need 2 ", 1, true) or t:find("need 3 ", 1, true) then
      return true
    end
    if t:find("need tank", 1, true) or t:find("need heal", 1, true) or t:find("need dps", 1, true) then
      return true
    end
    if t:find("need mage", 1, true) or t:find("need lock", 1, true) or t:find("need priest", 1, true) then
      return true
    end
    if t:find("precisamos", 1, true) or t:find("preciso de", 1, true) or t:find("falta ", 1, true) or t:find("falta um", 1, true) then
      return true
    end
    if t:find("tem grupo", 1, true) and t:find("vaga", 1, true) then
      return true
    end
    if t:find("^lf%s+tank", 1) or t:find("^lf%s+heal", 1) or t:find("^lf%s+heals", 1) or t:find("^lf%s+dps", 1) then
      return true
    end
    if t:find("^lf%s+mage", 1) or t:find("^lf%s+lock", 1) or t:find("^lf%s+priest", 1) or t:find("^lf%s+pala", 1) then
      return true
    end
    if t:find("^lf%s+druid", 1) or t:find("^lf%s+rogue", 1) or t:find("^lf%s+hunter", 1) then
      return true
    end
    if t:find("^lf%s+sham", 1) or t:find("^lf%s+warrior", 1) or t:find("^lf%s+warlock", 1) then
      return true
    end
    for _, needle in ipairs(LFM_I18N_NEEDLES) do
      if t:find(needle, 1, true) then
        return true
      end
    end
    return false
  end

  local function isLfgSeekingGroup()
    if t:find("^lfg[%s,.!%-]", 1) or t == "lfg" then
      return true
    end
    if t:find("%s+lfg[%s,.!%-]", 1) or t:find("%s+lfg$", 1) then
      return true
    end
    if t:find("looking for group", 1, true) then
      return true
    end
    if t:find("procuro grupo", 1, true) or t:find("procura grupo", 1, true) or t:find("pf grupo", 1, true) then
      return true
    end
    -- "DPS LF SFK group", "26 rogue LF SFK or BFD", "Tank LF WC":
    -- (nível opcional +) função/classe + LF (não LFM) = procura vaga, não monta grupo.
    -- Nota: padrões Lua não têm '|'; checar cada prefixo em plain text.
    if not t:find("lfm", 1, true) and not t:find("lf%d+m", 1) then
      local prefixes = {
        "tank", "tanks", "heal", "heals", "healer", "healers", "dps", "dd", "dds",
        "mage", "mages", "lock", "locks", "warlock", "warlocks",
        "priest", "priests", "pala", "paladin", "paladins",
        "druid", "druids", "rogue", "rogues", "hunter", "hunters",
        "sham", "shaman", "shamans", "warrior", "warriors", "war",
      }
      -- Remove nível no início: "26 rogue …", "lvl 26 tank …", "level 60 dps …"
      local seek = t:gsub("^lvl%s*%d+%s+", "", 1):gsub("^level%s+%d+%s+", "", 1):gsub("^%d+%s+", "", 1)
      for _, prefix in ipairs(prefixes) do
        local rest = seek:match("^" .. prefix .. "%s+(.+)$")
        if rest then
          if rest:find("^lf[%s%d%.%-,!]", 1) or rest == "lf" or rest:find("^lf$", 1) then
            return true
          end
          if rest:find("^looking for ", 1, true) and not rest:find("looking for more", 1, true) then
            return true
          end
          if rest:find("^procuro%s+", 1) or rest:find("^busco%s+", 1) then
            return true
          end
        end
      end
    end
    -- "LF SFK group" / "lf ulda group" (LF + DG + group, sem pedir role)
    if t:find("^lf%s+%S+.*%sgroup", 1) then
      local afterLf = t:match("^lf%s+(%S+)")
      local recruitRoles = {
        tank = true, tanks = true, heal = true, heals = true, healer = true,
        dps = true, dd = true, mage = true, lock = true, priest = true,
        pala = true, paladin = true, druid = true, rogue = true, hunter = true,
        sham = true, shaman = true, warrior = true, warlock = true,
      }
      if afterLf and not recruitRoles[afterLf] then
        return true
      end
    end
    for _, needle in ipairs(LFG_I18N_NEEDLES) do
      if t:find(needle, 1, true) then
        return true
      end
    end
    return false
  end

  if isLfmRecruiting() and not isLfgSeekingGroup() then
    return "whisper"
  end
  if isLfgSeekingGroup() and not isLfmRecruiting() then
    return "invite"
  end
  if isLfmRecruiting() and isLfgSeekingGroup() then
    return "whisper"
  end
  -- Fallback genérico "LF …": sem número pedindo vagas (= LFG).
  -- "LF 1 …" / "LF 1-2 …" já caiu em isLfmRecruiting acima.
  if t:find("^lf%s+", 1) and not t:find("lfm", 1, true) and not t:find("need ", 1, true) then
    if t:find("^lf%s*%d+", 1) then
      return "whisper"
    end
    return "invite"
  end
  return "whisper"
end

function CEF.messageLooksLFG(text)
  local t = normalizeMessage(text)
  if t == "" then return false end
  for _, hint in ipairs(LFG_PLAIN) do
    if t:find(hint, 1, true) then
      return true
    end
  end
  return false
end

function CEF.looksLikeProfessionOrTradeRequest(text)
  local lower = (text or ""):lower()
  for _, phrase in ipairs(PROFESSION_TRADE_EXCLUDE) do
    if lower:find(phrase, 1, true) then
      return true
    end
  end
  return false
end

function CEF.looksLikeHardcoreDeathBroadcast(text)
  local lower = (text or ""):lower()
  for _, phrase in ipairs(HARDCORE_DEATH_EXCLUDE) do
    if lower:find(phrase, 1, true) then
      return true
    end
  end
  return false
end

-- Só lista anúncios ligados a masmorra/raid: precisa reconhecer instância e não ser pedido de profissão/craft.
function CEF.passesInstanceFinderFilter(text)
  if not text or text == "" then
    return false
  end
  if CEF.looksLikeProfessionOrTradeRequest(text) then
    return false
  end
  if CEF.looksLikeHardcoreDeathBroadcast(text) then
    return false
  end
  if CEF.detectInstance(text) == "—" then
    return false
  end
  return true
end

local function matchesAnyNeedle(padded, needles)
  for _, needle in ipairs(needles) do
    if padded:find(needle, 1, true) then
      return true
    end
  end
  return false
end

-- Filtro por função (tank/heal/dps) baseado no texto da mensagem.
function CEF.messageMatchesRoleFilter(text, roleKey)
  if roleKey == false or roleKey == nil then
    return true
  end
  local t = normalizeMessage(text)
  if t == "" then
    return false
  end
  local p = " " .. t .. " "

  if roleKey == "tank" then
    if p:find(" tank ", 1, true) or t:find("^tank ", 1, true) or t:find("^tank$", 1, true) then
      return true
    end
    if p:find(" tanks ", 1, true) or t:find("^tanks ", 1, true) then
      return true
    end
    if p:find(" prot ", 1, true) or t:find("^prot ", 1, true) or p:find("protwarr", 1, true) or p:find("prot warr", 1, true) then
      return true
    end
    if p:find("protection", 1, true) and p:find("war", 1, true) then
      return true
    end
    if p:find("feral tank", 1, true) or p:find("bear tank", 1, true) or p:find("bear ", 1, true) and p:find("tank", 1, true) then
      return true
    end
    if p:find("need tank", 1, true) or p:find("need a tank", 1, true) or p:find("need 1 tank", 1, true) or p:find("need 2 tank", 1, true) then
      return true
    end
    if p:find("lf tank", 1, true) or p:find("^lf tank", 1, true) or p:find("lftank", 1, true) then
      return true
    end
    if p:find(" pala tank", 1, true) or p:find(" paladin tank", 1, true) or p:find(" warr tank", 1, true) then
      return true
    end
    if p:find("looking for tank", 1, true) then
      return true
    end
    if (p:find("precisamos", 1, true) and p:find("tank", 1, true)) or (p:find("falta", 1, true) and p:find("tank", 1, true)) then
      return true
    end
    if matchesAnyNeedle(p, ROLE_I18N_NEEDLES.tank) then
      return true
    end
    return false
  end

  if roleKey == "heal" then
    if p:find(" healer", 1, true) or p:find(" healers", 1, true) or p:find(" healer ", 1, true) then
      return true
    end
    if p:find(" heals ", 1, true) or t:find("^heals ", 1, true) or t:find("^heals$", 1, true) then
      return true
    end
    if p:find(" heal ", 1, true) or t:find("^heal ", 1, true) then
      return true
    end
    if p:find("need heal", 1, true) or p:find("need heals", 1, true) or p:find("need a heal", 1, true) then
      return true
    end
    if p:find("lf heal", 1, true) or p:find("lf heals", 1, true) then
      return true
    end
    if p:find(" resto ", 1, true) or t:find("^resto ", 1, true) or p:find("restoration", 1, true) then
      return true
    end
    if p:find(" holy ", 1, true) and (p:find("pal", 1, true) or p:find("priest", 1, true)) then
      return true
    end
    if p:find("disc ", 1, true) or p:find(" disc ", 1, true) or p:find("discipline", 1, true) then
      return true
    end
    if p:find("rdudu", 1, true) or p:find("tree ", 1, true) or p:find("resto dru", 1, true) then
      return true
    end
    if p:find("priest heal", 1, true) or p:find("sacer", 1, true) and p:find("heal", 1, true) then
      return true
    end
    if (p:find("precisamos", 1, true) and p:find("heal", 1, true)) or (p:find("falta", 1, true) and p:find("heal", 1, true)) then
      return true
    end
    if matchesAnyNeedle(p, ROLE_I18N_NEEDLES.heal) then
      return true
    end
    return false
  end

  if roleKey == "dps" then
    if p:find(" dps", 1, true) or p:find("dps ", 1, true) or t:find("^dps ", 1, true) or t:find("^dps$", 1, true) then
      return true
    end
    if p:find("need dps", 1, true) or p:find("lf dps", 1, true) or p:find("need 1 dps", 1, true) or p:find("need 2 dps", 1, true) then
      return true
    end
    if p:find("ranged dps", 1, true) or p:find("melee dps", 1, true) or p:find(" rdps", 1, true) or p:find(" mdps", 1, true) then
      return true
    end
    if p:find(" warlock", 1, true) or p:find(" lock ", 1, true) or t:find("^lock ", 1, true) then
      return true
    end
    if p:find(" mage ", 1, true) or t:find("^mage ", 1, true) or t:find("^mage$", 1, true) then
      return true
    end
    if p:find(" rogue ", 1, true) or t:find("^rogue ", 1, true) or t:find("^rogue$", 1, true) then
      return true
    end
    if p:find(" hunter ", 1, true) or t:find("^hunter ", 1, true) then
      return true
    end
    if p:find("shadow", 1, true) or p:find("spriest", 1, true) then
      return true
    end
    if p:find("boomkin", 1, true) or p:find("moonkin", 1, true) or p:find(" owl ", 1, true) then
      return true
    end
    if p:find("ele sham", 1, true) or p:find("elemental", 1, true) or p:find("enhance", 1, true) or p:find("enh sham", 1, true) then
      return true
    end
    if p:find(" fury ", 1, true) or t:find("^fury ", 1, true) or p:find(" arms ", 1, true) or t:find("^arms ", 1, true) then
      return true
    end
    if p:find("ret pal", 1, true) or p:find("retrib", 1, true) or p:find("ret pala", 1, true) then
      return true
    end
    if p:find("feral cat", 1, true) or p:find(" kitty", 1, true) or p:find("cat dru", 1, true) then
      return true
    end
    if p:find(" ladino", 1, true) or p:find(" mago ", 1, true) or p:find("cacador", 1, true) then
      return true
    end
    if (p:find("precisamos", 1, true) and p:find("dps", 1, true)) or (p:find("falta", 1, true) and p:find("dps", 1, true)) then
      return true
    end
    if matchesAnyNeedle(p, ROLE_I18N_NEEDLES.dps) then
      return true
    end
    return false
  end

  return true
end

function CEF.stripRealm(name)
  if not name then return "" end
  return (name:match("^([^%-]+)%-") or name:match("^([^%-]+)$") or name)
end

-- Leitura para a UI “Termos” (referência às listas de messageLooksLFG / exclusões).
function CEF.getMessageDetectionCatalog()
  return {
    lfgHints = LFG_PLAIN,
    professionTradeExclude = PROFESSION_TRADE_EXCLUDE,
    hardcoreDeathExclude = HARDCORE_DEATH_EXCLUDE,
  }
end

