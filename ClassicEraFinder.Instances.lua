-- Módulo: lógica de instâncias (detecção, formatação, filtros).
--
-- Dados estáticos (INSTANCE_ROWS, level range, Scarlet needles) vivem em
-- ClassicEraFinder.InstanceData.lua. Este módulo só consome e transforma.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

local D = CEF.InstanceData
local INSTANCE_ROWS         = D.INSTANCE_ROWS
local INSTANCE_LEVEL_RANGE  = D.INSTANCE_LEVEL_RANGE
local SCARLET_WING_KEYS     = D.SCARLET_WING_KEYS
local SCARLET_GENERIC_NEEDLES = D.SCARLET_GENERIC_NEEDLES

-- Cores vêm de CEF.Theme (fonte única). Ver ClassicEraFinder.Theme.lua.
local Hex = (CEF.Theme and CEF.Theme.Hex) or {}
local COLOR_LVL_ORANGE_MIN        = Hex.levelMin    or "|cffff9933"
local COLOR_LVL_GREEN_MAX         = Hex.levelMax    or "|cff33cc33"
local COLOR_INSTANCE_DUNGEON_NAME = Hex.dungeonName or "|cff9fd3ff"
local COLOR_INSTANCE_RAID_NAME    = Hex.raidName    or "|cffffb74d"
local COLOR_ERA_CLASSIC_COL       = Hex.eraClassic  or "|cffb8956b"
local COLOR_ERA_TBC_COL           = Hex.eraTbc      or "|cff33cc33"

-- ============================================================================
-- Índices derivados de INSTANCE_ROWS (por key).
-- ============================================================================
local INSTANCE_KEY_EXPANSION = {}
local INSTANCE_KEY_IS_RAID   = {}
for _, row in ipairs(INSTANCE_ROWS) do
  local k = row.key
  if not INSTANCE_KEY_EXPANSION[k] then
    INSTANCE_KEY_EXPANSION[k] = row.expansion or "classic"
  end
  if row.kind == "raid" then
    INSTANCE_KEY_IS_RAID[k] = true
  end
end

local function instanceMinLevelForSort(instanceKey)
  local plain = INSTANCE_LEVEL_RANGE[instanceKey]
  if not plain then
    return 999
  end
  local minV = plain:match("^(%d+)%-(%d+)$")
  if minV then
    return tonumber(minV) or 999
  end
  local solo = plain:match("^(%d+)$")
  if solo then
    return tonumber(solo) or 999
  end
  return 999
end

-- Entradas do menu do filtro: opção (key false = todas) ou cabeçalho de secção.
CEF.INSTANCE_FILTER_MENU_OPTS = {}
do
  local classicDungeons, tbcDungeons = {}, {}
  local classicRaids, tbcRaids = {}, {}
  local seen = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      local exp = row.expansion or "classic"
      if row.kind == "raid" then
        if exp == "tbc" then
          tbcRaids[#tbcRaids + 1] = k
        else
          classicRaids[#classicRaids + 1] = k
        end
      else
        if exp == "tbc" then
          tbcDungeons[#tbcDungeons + 1] = k
        else
          classicDungeons[#classicDungeons + 1] = k
        end
      end
    end
  end

  local sortKeys = function(a, b)
    local ka, kb = instanceMinLevelForSort(a), instanceMinLevelForSort(b)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a) < strlower(b)
  end

  table.sort(classicDungeons, sortKeys)
  table.sort(tbcDungeons, sortKeys)
  table.sort(classicRaids, sortKeys)
  table.sort(tbcRaids, sortKeys)

  local opts = {}
  local L = CEF.L or {}
  opts[#opts + 1] = { kind = "opt", key = false }
  opts[#opts + 1] = { kind = "hdr", text = L["dungeons"] or "Dungeons" }
  for _, k in ipairs(classicDungeons) do
    opts[#opts + 1] = { kind = "opt", key = k }
  end
  if #tbcDungeons > 0 then
    opts[#opts + 1] = { kind = "hdr", text = L["tbcDungeons"] or "TBC — dungeons" }
    for _, k in ipairs(tbcDungeons) do
      opts[#opts + 1] = { kind = "opt", key = k }
    end
  end
  opts[#opts + 1] = { kind = "hdr", text = L["raids"] or "Raids" }
  for _, k in ipairs(classicRaids) do
    opts[#opts + 1] = { kind = "opt", key = k }
  end
  if #tbcRaids > 0 then
    opts[#opts + 1] = { kind = "hdr", text = L["tbcRaids"] or "TBC — raids" }
    for _, k in ipairs(tbcRaids) do
      opts[#opts + 1] = { kind = "opt", key = k }
    end
  end

  CEF.INSTANCE_FILTER_MENU_OPTS = opts
end

-- ============================================================================
-- Rich text: nome da instância, faixa de níveis, linha de "Era".
-- ============================================================================
local function instanceNameRichOpenTag(instanceKey)
  if instanceKey and INSTANCE_KEY_IS_RAID[instanceKey] then
    return COLOR_INSTANCE_RAID_NAME
  end
  return COLOR_INSTANCE_DUNGEON_NAME
end

function CEF.instanceKeyIsRaid(instanceKey)
  return instanceKey ~= nil and instanceKey ~= false and INSTANCE_KEY_IS_RAID[instanceKey] == true
end

local function formatLevelRangeColored(plain)
  if not plain or plain == "—" then
    return "—"
  end
  local minV, maxV = plain:match("^(%d+)%-(%d+)$")
  if minV and maxV then
    return COLOR_LVL_ORANGE_MIN .. minV .. "|r-" .. COLOR_LVL_GREEN_MAX .. maxV .. "|r"
  end
  local solo = plain:match("^(%d+)$")
  if solo then
    return COLOR_LVL_ORANGE_MIN .. solo .. "|r-" .. COLOR_LVL_GREEN_MAX .. solo .. "|r"
  end
  return plain
end

local function recommendedLevelRichText(instanceKey)
  if not instanceKey or instanceKey == "—" then
    return "—"
  end
  local plain = INSTANCE_LEVEL_RANGE[instanceKey]
  if not plain then
    return "—"
  end
  return formatLevelRangeColored(plain)
end

function CEF.instanceLevelRangeRichText(instanceKey)
  return recommendedLevelRichText(instanceKey)
end

-- Linhas de deteção agrupadas (Classic vs TBC; mesma ideia que o menu de filtro).
function CEF.getInstanceDetectionRowsGroupedSorted()
  local dc, dt, rc, rt = {}, {}, {}, {}
  local seen = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local k = row.key
    if not seen[k] then
      seen[k] = true
      local exp = row.expansion or "classic"
      if row.kind == "raid" then
        if exp == "tbc" then
          rt[#rt + 1] = row
        else
          rc[#rc + 1] = row
        end
      else
        if exp == "tbc" then
          dt[#dt + 1] = row
        else
          dc[#dc + 1] = row
        end
      end
    end
  end
  local function sortFn(a, b)
    local ka, kb = instanceMinLevelForSort(a.key), instanceMinLevelForSort(b.key)
    if ka ~= kb then
      return ka < kb
    end
    return strlower(a.key) < strlower(b.key)
  end
  table.sort(dc, sortFn)
  table.sort(dt, sortFn)
  table.sort(rc, sortFn)
  table.sort(rt, sortFn)
  return {
    dungeonsClassic = dc,
    dungeonsTbc = dt,
    raidsClassic = rc,
    raidsTbc = rt,
  }
end

function CEF.instanceFilterOptionRichText(instKey)
  local L = CEF.L or {}
  if instKey == false or instKey == nil then
    return "|cffffffff" .. (L["allInstances"] or "All instances") .. "|r"
  end
  local displayName = CEF.LocalizeInstance and CEF.LocalizeInstance(instKey) or instKey
  return instanceNameRichOpenTag(instKey) .. displayName .. "|r  " .. recommendedLevelRichText(instKey)
end

-- ============================================================================
-- Scarlet Monastery: frase genérica sem nomear ala → full clear nas 4 alas.
-- ============================================================================
local function listContainsAnyKey(list, keys)
  for _, k in ipairs(list) do
    for _, w in ipairs(keys) do
      if k == w then
        return true
      end
    end
  end
  return false
end

-- «sm» como palavra (ex.: «lfg sm», «dps sm») sem apanhar «small», «asm», etc.
local function scarletSmAsIsolatedWord(lower)
  local pos = 1
  while true do
    local a, b = lower:find("sm", pos, true)
    if not a then
      break
    end
    local beforeLetter = (a > 1) and lower:sub(a - 1, a - 1):match("%a")
    local afterCh = lower:sub(b + 1, b + 1)
    local afterLetter = afterCh ~= "" and afterCh:match("%a")
    if not beforeLetter and not afterLetter then
      return true
    end
    pos = b + 1
  end
  return false
end

local function scarletGenericInText(lower)
  for _, n in ipairs(SCARLET_GENERIC_NEEDLES) do
    if lower:find(n, 1, true) then
      return true
    end
  end
  if scarletSmAsIsolatedWord(lower) then
    return true
  end
  return false
end

-- ============================================================================
-- Abreviações ambíguas no fim da linha: «DM» / «WC»
-- ============================================================================
-- «DM» sozinho no fim (ex.: «LF3M DPS DM», «… HEALER DM») — sem espaço depois do m.
local function direMaulIsolatedDmPos(lower)
  local t = lower:match("^%s*(.-)%s*$") or lower
  local a = t:find("[%s%p]dm$")
  if a then
    return a
  end
  if #t >= 3 and t:sub(-2) == "dm" then
    local prev = t:sub(-3, -3)
    if prev:match("[%s%p]") then
      return #t - 3
    end
  end
  if t == "dm" or t:find("^dm[%s%p]", 1) then
    return 1
  end
  return nil
end

-- «WC» como Wailing Caverns no fim (ex.: «LF1M DPS WC») ou só «wc» + separador.
local function wailingCavernsIsolatedWcPos(lower)
  local t = lower:match("^%s*(.-)%s*$") or lower
  local a = t:find("[%s%p]wc$")
  if a then
    return a
  end
  if #t >= 3 and t:sub(-2) == "wc" then
    local prev = t:sub(-3, -3)
    if prev:match("[%s%p]") then
      return #t - 3
    end
  end
  if t == "wc" or t:find("^wc[%s%p]", 1) then
    return 1
  end
  return nil
end

-- ============================================================================
-- Detecção principal
-- ============================================================================
-- Todas as instâncias reconhecidas na mensagem; ordem = primeira ocorrência no texto.
function CEF.detectInstances(text)
  if not text or text == "" then
    return {}
  end
  -- Igual a messageLooksLFG: minúsculas + espaços colapsados (evita falhar em «for  wc» no chat).
  local lower = CEF.normalizeMessage(text)
  if lower == "" then
    return {}
  end
  local hits = {}
  for _, row in ipairs(INSTANCE_ROWS) do
    local bestPos
    for _, n in ipairs(row.needles) do
      local pos = lower:find(n, 1, true)
      if pos and (not bestPos or pos < bestPos) then
        bestPos = pos
      end
    end
    if bestPos then
      hits[row.key] = bestPos
    end
  end

  if not hits["Dire Maul"] then
    local pDm = direMaulIsolatedDmPos(lower)
    if pDm then
      hits["Dire Maul"] = pDm
    end
  end

  if not hits["Wailing Caverns"] then
    local pWc = wailingCavernsIsolatedWcPos(lower)
    if pWc then
      hits["Wailing Caverns"] = pWc
    end
  end

  local tmp = {}
  for k, pos in pairs(hits) do
    tmp[#tmp + 1] = { key = k, pos = pos }
  end
  table.sort(tmp, function(a, b)
    if a.pos ~= b.pos then
      return a.pos < b.pos
    end
    return strlower(a.key) < strlower(b.key)
  end)

  local out = {}
  for _, item in ipairs(tmp) do
    out[#out + 1] = item.key
  end

  if scarletGenericInText(lower) and not listContainsAnyKey(out, SCARLET_WING_KEYS) then
    for _, w in ipairs(SCARLET_WING_KEYS) do
      out[#out + 1] = w
    end
  end

  return out
end

function CEF.detectInstance(text)
  local list = CEF.detectInstances(text)
  return list[1] or "—"
end

-- ============================================================================
-- Helpers para entry.instances (coluna da lista + tooltip)
-- ============================================================================
local function entryInstancesList(e)
  if not e then
    return {}
  end
  if type(e.instances) == "table" and #e.instances > 0 then
    return e.instances
  end
  if e.instance and e.instance ~= "" and e.instance ~= "—" then
    return { e.instance }
  end
  return {}
end

function CEF.entryHasInstance(e, key)
  if not key or key == false then
    return true
  end
  for _, k in ipairs(entryInstancesList(e)) do
    if k == key then
      return true
    end
  end
  return false
end

-- Coluna: nome + intervalo de níveis na mesma linha por instância.
function CEF.entryInstancesComboRichText(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return "—"
  end
  local parts = {}
  for _, k in ipairs(list) do
    local name = CEF.LocalizeInstance and CEF.LocalizeInstance(k) or k
    parts[#parts + 1] = instanceNameRichOpenTag(k) .. name .. "|r  " .. recommendedLevelRichText(k)
  end
  -- Quebra extra (linha em branco) para separar visualmente instâncias.
  return table.concat(parts, "\n\n")
end

-- Tooltip inline (uma linha) para não “quebrar” após o prefixo “Instância:”
function CEF.entryInstancesComboRichTextInline(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return "—"
  end
  local parts = {}
  for _, k in ipairs(list) do
    local name = CEF.LocalizeInstance and CEF.LocalizeInstance(k) or k
    parts[#parts + 1] = instanceNameRichOpenTag(k) .. name .. "|r  " .. recommendedLevelRichText(k)
  end
  return table.concat(parts, ", ")
end

function CEF.entryInstancesLineCount(e)
  local list = entryInstancesList(e)
  local c = #list
  if c < 1 then
    return 1
  end
  return c
end

function CEF.entryInstancesSearchBlob(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return strlower(e.instance or "")
  end
  local parts = {}
  for _, k in ipairs(list) do
    parts[#parts + 1] = strlower(k)
  end
  return table.concat(parts, " ")
end

-- Coluna «Era» na lista: Classic (marrom) / TBC (verde); misto = duas linhas.
function CEF.entryExpansionColumnRichText(e)
  local list = entryInstancesList(e)
  if #list == 0 then
    return (Hex.dim or "|cff888888") .. "—|r"
  end
  local hasC, hasT = false, false
  for _, k in ipairs(list) do
    if (INSTANCE_KEY_EXPANSION[k] or "classic") == "tbc" then
      hasT = true
    else
      hasC = true
    end
  end
  local L = CEF.L or {}
  local nameClassic = L["eraClassic"] or "Classic"
  local nameTbc = L["eraTbc"] or "TBC"
  if hasC and hasT then
    return COLOR_ERA_CLASSIC_COL .. nameClassic .. "|r\n" .. COLOR_ERA_TBC_COL .. nameTbc .. "|r"
  end
  if hasT then
    return COLOR_ERA_TBC_COL .. nameTbc .. "|r"
  end
  return COLOR_ERA_CLASSIC_COL .. nameClassic .. "|r"
end

-- Leitura para a UI “Termos” (somente referência; listas são as mesmas usadas na deteção).
function CEF.getInstanceDetectionCatalog()
  return {
    rows = INSTANCE_ROWS,
    scarletGeneric = SCARLET_GENERIC_NEEDLES,
    scarletGenericUiHints = {
      "(regra automática) «sm» como palavra isolada — ex.: lfg sm, dps sm, tank sm (não colado a outras letras; não conta se já nomeares GY/Lib/Arm/Cath)",
    },
  }
end
