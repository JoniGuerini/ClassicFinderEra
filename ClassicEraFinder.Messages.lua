-- Módulo: lógica de mensagens (LFG/LFM, intenção, filtros de role)
-- Exposto em ClassicEraFinder.* para o entrypoint chamar.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

-- Labels dos filtros: resolvidos pelo locale via CEF.L no momento da UI.
-- Guardamos só a `key` interna aqui; o texto visível é consultado em runtime.
local function L(key, fallback)
  local tbl = CEF.L
  if tbl and tbl[key] then
    return tbl[key]
  end
  return fallback
end

local INTENT_FILTER_MENU_OPTS = {
  { key = false, labelKey = "allAnnouncements", labelFallback = "All announcements" },
  { key = "invite", labelKey = "intentSeekingGroup", labelFallback = "Looking for group" },
  { key = "whisper", labelKey = "intentRecruiting", labelFallback = "Looking for members" },
}
-- Compat: expõe com `label` preenchido dinamicamente (alguns call-sites podem ler).
for _, opt in ipairs(INTENT_FILTER_MENU_OPTS) do
  opt.label = L(opt.labelKey, opt.labelFallback)
end
CEF.INTENT_FILTER_MENU_OPTS = INTENT_FILTER_MENU_OPTS

function CEF.intentFilterOptionRichText(intentKey)
  if intentKey == false or intentKey == nil then
    return "|cffffffff" .. L("allAnnouncements", "All announcements") .. "|r"
  end
  for _, opt in ipairs(INTENT_FILTER_MENU_OPTS) do
    if opt.key == intentKey then
      return "|cffffffff" .. L(opt.labelKey, opt.labelFallback) .. "|r"
    end
  end
  return "|cffffffff—|r"
end

local ROLE_FILTER_MENU_OPTS = {
  { key = false, labelKey = "anyRole", labelFallback = "Any role" },
  { key = "tank", labelKey = "roleTank", labelFallback = "Tank" },
  { key = "heal", labelKey = "roleHeal", labelFallback = "Healer" },
  { key = "dps", labelKey = "roleDps", labelFallback = "DPS" },
}
for _, opt in ipairs(ROLE_FILTER_MENU_OPTS) do
  opt.label = L(opt.labelKey, opt.labelFallback)
end
CEF.ROLE_FILTER_MENU_OPTS = ROLE_FILTER_MENU_OPTS

function CEF.roleFilterOptionRichText(roleKey)
  if roleKey == false or roleKey == nil then
    return "|cffffffff" .. L("anyRole", "Any role") .. "|r"
  end
  for _, opt in ipairs(ROLE_FILTER_MENU_OPTS) do
    if opt.key == roleKey then
      return "|cffffffff" .. L(opt.labelKey, opt.labelFallback) .. "|r"
    end
  end
  return "|cffffffff—|r"
end

-- Padrões estáticos vêm de CEF.MessagePatterns (ver ClassicEraFinder.MessagePatterns.lua).
local P = CEF.MessagePatterns or {}
local RECRUIT_FIRST_WORDS_LIST = P.RECRUIT_FIRST_WORDS_LIST or {}
local RECRUIT_FIRST_WORDS      = P.RECRUIT_FIRST_WORDS or {}
local LFG_PLAIN                = P.LFG_PLAIN or {}
local PROFESSION_TRADE_EXCLUDE = P.PROFESSION_TRADE_EXCLUDE or {}

local function normalizeMessage(msg)
  if not msg then
    return ""
  end
  -- NBSP UTF-8 e códigos de cor do chat (evita «dm|r» ou espaço “invisível» sem match).
  msg = msg:gsub("\194\160", " ")
  msg = msg:gsub("|c[%x]+", ""):gsub("|r", ""):gsub("|T[^|]+|t", "")
  msg = msg:lower():gsub("%s+", " ")
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
    -- "lf <spec/classe/plural> ..." — recrutador descrevendo quem quer no grupo.
    -- Ex.: "lf resto sham and warlocks for gruul", "lf holy pala for kara",
    --      "lf warlocks for mag", "lf prot warr".
    -- Usa RECRUIT_FIRST_WORDS (lista no topo do arquivo, também exposta em Termos).
    local firstWord = t:match("^lf%s+([%a]+)")
    if firstWord and RECRUIT_FIRST_WORDS[firstWord] then
      return true
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
  if t:find("^lf%s+", 1) and not t:find("lfm", 1, true) and not t:find("need ", 1, true) then
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

-- Só lista anúncios ligados a masmorra/raid: precisa reconhecer instância e não ser pedido de profissão/craft.
function CEF.passesInstanceFinderFilter(text)
  if not text or text == "" then
    return false
  end
  if CEF.looksLikeProfessionOrTradeRequest(text) then
    return false
  end
  if CEF.detectInstance(text) == "—" then
    return false
  end
  return true
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
    return false
  end

  return true
end

function CEF.stripRealm(name)
  if not name then return "" end
  return (name:match("^([^%-]+)%-") or name:match("^([^%-]+)$") or name)
end

-- Leitura para a UI “Termos” (referência às listas de deteção).
function CEF.getMessageDetectionCatalog()
  return {
    lfgHints              = LFG_PLAIN,
    professionTradeExclude = PROFESSION_TRADE_EXCLUDE,
    recruitFirstWords     = RECRUIT_FIRST_WORDS_LIST,
    recruitingIntentHints = P.RECRUITING_INTENT_HINTS or {},
    seekingIntentHints    = P.SEEKING_INTENT_HINTS or {},
  }
end

