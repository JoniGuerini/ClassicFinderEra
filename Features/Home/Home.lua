-- Módulo: agregação da aba Home — demanda Chat + Premade (instâncias com funções).

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Home = CEF.Home or {}
local Home = CEF.Home

local TOP_PER_CATEGORY = 10

local function normalizeLabel(s)
  s = tostring(s or "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

local function ensureInstRow(map, label, instanceKey)
  local row = map[label]
  if not row then
    row = {
      label = label,
      instanceKey = instanceKey,
      chat = 0,
      lfg = 0,
      total = 0,
      tank = 0,
      heal = 0,
      dps = 0,
      maxNumPlayers = 0,
    }
    map[label] = row
  elseif instanceKey and not row.instanceKey then
    row.instanceKey = instanceKey
  end
  return row
end

local function rowIsRaid(row)
  if row.instanceKey and CEF.instanceKeyIsRaid and CEF.instanceKeyIsRaid(row.instanceKey) then
    return true
  end
  local mp = tonumber(row.maxNumPlayers) or 0
  return mp > 5
end

local function lfgOpenRoles(result)
  local open = { tank = 0, heal = 0, dps = 0 }
  local slots = result and result.roleSlots
  if type(slots) == "table" and #slots > 0 then
    for _, slot in ipairs(slots) do
      if not slot.filled then
        local role = slot.role
        if role == "TANK" then
          open.tank = open.tank + 1
        elseif role == "HEALER" then
          open.heal = open.heal + 1
        elseif role == "DAMAGER" then
          open.dps = open.dps + 1
        end
      end
    end
    return open
  end
  -- Fallback RoleCount: marca função se o grupo ainda parece incompleto e a contagem é baixa.
  local c = result and result.counts
  local n = tonumber(result and result.numMembers) or 0
  if type(c) == "table" and n > 0 and n < 5 then
    if (tonumber(c.TANK) or 0) < 1 then
      open.tank = 1
    end
    if (tonumber(c.HEALER) or 0) < 1 then
      open.heal = 1
    end
    local dps = tonumber(c.DAMAGER) or 0
    if dps < 3 and (5 - n) > 0 then
      open.dps = math.min(3 - dps, 5 - n)
      if open.dps < 0 then
        open.dps = 0
      end
    end
  end
  return open
end

local function sortAndTrim(list, limit)
  table.sort(list, function(a, b)
    if a.total ~= b.total then
      return a.total > b.total
    end
    return a.label < b.label
  end)
  while #list > limit do
    list[#list] = nil
  end
  return list
end

--- Snapshot ao vivo para a aba Home.
function Home.buildSnapshot()
  local merged = {}
  local intent = { invite = 0, whisper = 0 }
  local chatCount, lfgCount = 0, 0

  local entries = (CEF.Entries and CEF.Entries.getAll and CEF.Entries.getAll()) or {}
  for _, e in ipairs(entries) do
    chatCount = chatCount + 1
    local intentKey = CEF.classifyMessageIntent and CEF.classifyMessageIntent(e.text) or "whisper"
    if intentKey == "invite" then
      intent.invite = intent.invite + 1
    else
      intent.whisper = intent.whisper + 1
    end

    local instList = e.instances
    if type(instList) ~= "table" or #instList == 0 then
      if e.instance and e.instance ~= "" and e.instance ~= "—" then
        instList = { e.instance }
      else
        instList = {}
      end
    end

    local labels = {}
    for _, ik in ipairs(instList) do
      local label = (CEF.getInstanceDisplayName and CEF.getInstanceDisplayName(ik)) or ik
      label = normalizeLabel(label)
      if label ~= "" then
        local row = ensureInstRow(merged, label, ik)
        row.chat = row.chat + 1
        row.total = row.chat + row.lfg
        labels[#labels + 1] = label
      end
    end

    if #labels > 0 then
      for _, rk in ipairs({ "tank", "heal", "dps" }) do
        if CEF.messageMatchesRoleFilter and CEF.messageMatchesRoleFilter(e.text, rk) then
          for _, label in ipairs(labels) do
            local row = merged[label]
            row[rk] = (row[rk] or 0) + 1
          end
        end
      end
    end
  end

  local results = (CEF.LFG and CEF.LFG.getResults and CEF.LFG.getResults()) or {}
  for _, r in ipairs(results) do
    lfgCount = lfgCount + 1
    local open = lfgOpenRoles(r)
    local mp = tonumber(r.roleDisplay and r.roleDisplay.maxNumPlayers)
      or tonumber(r.maxNumPlayers)
      or 0

    local entries = r.instanceEntries
    if type(entries) ~= "table" or #entries == 0 then
      local label = normalizeLabel(r.activityName)
      if label ~= "" and label ~= "—" then
        local instKey = nil
        if CEF.resolveInstanceKeyFromName then
          instKey = CEF.resolveInstanceKeyFromName(r.activityName)
        end
        entries = { { key = instKey, name = label, maxNumPlayers = mp } }
      else
        entries = {}
      end
    end

    for _, ie in ipairs(entries) do
      local instKey = ie.key
      local label
      if instKey and CEF.getInstanceDisplayName then
        label = normalizeLabel(CEF.getInstanceDisplayName(instKey))
      else
        label = normalizeLabel(ie.name or "")
      end
      if label ~= "" and label ~= "—" then
        local row = ensureInstRow(merged, label, instKey)
        row.lfg = row.lfg + 1
        row.total = row.chat + row.lfg
        local ieMp = tonumber(ie.maxNumPlayers) or mp
        if ieMp > (row.maxNumPlayers or 0) then
          row.maxNumPlayers = ieMp
        end
        row.tank = row.tank + open.tank
        row.heal = row.heal + open.heal
        row.dps = row.dps + open.dps
      end
    end
  end

  local dungeons, raids = {}, {}
  for _, row in pairs(merged) do
    if rowIsRaid(row) then
      raids[#raids + 1] = row
    else
      dungeons[#dungeons + 1] = row
    end
  end
  sortAndTrim(dungeons, TOP_PER_CATEGORY)
  sortAndTrim(raids, TOP_PER_CATEGORY)

  return {
    chatCount = chatCount,
    lfgCount = lfgCount,
    intent = intent,
    dungeons = dungeons,
    raids = raids,
    -- Compat: lista unificada (masmorras primeiro, depois raids).
    instances = (function()
      local all = {}
      for _, row in ipairs(dungeons) do
        all[#all + 1] = row
      end
      for _, row in ipairs(raids) do
        all[#all + 1] = row
      end
      return all
    end)(),
  }
end
