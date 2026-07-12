-- Módulo: grupo/raide atual do jogador — leitura da API e vista para a aba Grupo.

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

CEF.Group = CEF.Group or {}
local Group = CEF.Group

local members = {}
-- Lista pronta para render: linhas "hdr" (subgrupo, só em raid) + "member".
local displayList = {}
local inRaid = false
-- Modo demo: roster falso para validar layout sem outro jogador (/cef mockgroup).
local mockActive = false
local mockAsLeader = true
local mockAsAssist = false

function Group.isMock()
  return mockActive
end

function Group.isInGroup()
  if mockActive then
    return #members > 0
  end
  if IsInRaid and IsInRaid() then
    return true
  end
  if IsInGroup then
    return IsInGroup() and true or false
  end
  return (GetNumGroupMembers and GetNumGroupMembers() or 0) > 0
end

function Group.isRaid()
  return inRaid
end

function Group.getMembers()
  return members
end

function Group.getDisplayList()
  return displayList
end

local function stripName(name)
  if CEF.stripRealm then
    return CEF.stripRealm(name or "") or ""
  end
  return name or ""
end

-- GetLootMethod: em party mlParty 0 = próprio jogador, 1..4 = partyN;
-- em raid mlRaid = índice do roster.
local function lootMasterInfo()
  if not GetLootMethod then
    return nil, nil
  end
  local method, mlParty, mlRaid = GetLootMethod()
  if method ~= "master" then
    return nil, nil
  end
  return mlParty, mlRaid
end

local function partyMemberFromUnit(unit, mlParty, partyIndex)
  local name = UnitName(unit)
  if not name or name == "" or (UNKNOWNOBJECT and name == UNKNOWNOBJECT) then
    return nil
  end
  local _, classFile = UnitClass(unit)
  local isSelf = UnitIsUnit and UnitIsUnit(unit, "player") or (unit == "player")
  local isML = false
  if mlParty ~= nil then
    if mlParty == 0 then
      isML = isSelf
    else
      isML = (partyIndex == mlParty)
    end
  end
  return {
    unit = unit,
    name = name,
    nameShort = stripName(name),
    level = (UnitLevel and UnitLevel(unit)) or 0,
    classFile = classFile or "",
    -- Zona só é conhecida para o próprio jogador fora de raid.
    zone = isSelf and ((GetRealZoneText and GetRealZoneText()) or "") or "",
    online = (not UnitIsConnected) or (UnitIsConnected(unit) and true or false),
    isDead = (UnitIsDeadOrGhost and UnitIsDeadOrGhost(unit)) and true or false,
    subgroup = 1,
    isLeader = (UnitIsGroupLeader and UnitIsGroupLeader(unit)) and true or false,
    isAssist = false,
    isML = isML,
    isSelf = isSelf,
  }
end

local function buildDisplayList()
  wipe(displayList)
  if #members == 0 then
    return
  end
  if inRaid then
    table.sort(members, function(a, b)
      if a.subgroup ~= b.subgroup then
        return a.subgroup < b.subgroup
      end
      if a.isLeader ~= b.isLeader then
        return a.isLeader
      end
      if a.isAssist ~= b.isAssist then
        return a.isAssist
      end
      return strlower(a.nameShort or "") < strlower(b.nameShort or "")
    end)
    local currentSub = nil
    for _, m in ipairs(members) do
      if m.subgroup ~= currentSub then
        currentSub = m.subgroup
        displayList[#displayList + 1] = { kind = "hdr", subgroup = currentSub }
      end
      displayList[#displayList + 1] = { kind = "member", member = m }
    end
  else
    table.sort(members, function(a, b)
      if a.isLeader ~= b.isLeader then
        return a.isLeader
      end
      return strlower(a.nameShort or "") < strlower(b.nameShort or "")
    end)
    for _, m in ipairs(members) do
      displayList[#displayList + 1] = { kind = "member", member = m }
    end
  end
end

function Group.refreshFromApi()
  -- Não sobrescreve o roster mock com a API real (evento/timer).
  if mockActive then
    buildDisplayList()
    return
  end

  wipe(members)
  inRaid = (IsInRaid and IsInRaid()) and true or false

  if not Group.isInGroup() then
    buildDisplayList()
    return
  end

  local mlParty, mlRaid = lootMasterInfo()

  if inRaid then
    local n = (GetNumGroupMembers and GetNumGroupMembers()) or 0
    local myName = UnitName and stripName(UnitName("player")) or ""
    for i = 1, n do
      local name, rank, subgroup, level, _, classFile, zone, online, isDead, _, isML = GetRaidRosterInfo(i)
      if name and name ~= "" then
        local short = stripName(name)
        members[#members + 1] = {
          unit = "raid" .. i,
          raidIndex = i,
          name = name,
          nameShort = short,
          level = tonumber(level) or 0,
          classFile = classFile or "",
          zone = zone or "",
          online = online and true or false,
          isDead = isDead and true or false,
          subgroup = tonumber(subgroup) or 1,
          isLeader = (rank == 2),
          isAssist = (rank == 1),
          isML = (isML and true or false) or (mlRaid ~= nil and mlRaid == i),
          isSelf = (short ~= "" and strlower(short) == strlower(myName)),
        }
      end
    end
  else
    local me = partyMemberFromUnit("player", mlParty, 0)
    if me then
      members[#members + 1] = me
    end
    for i = 1, 4 do
      local unit = "party" .. i
      if UnitExists and UnitExists(unit) then
        local m = partyMemberFromUnit(unit, mlParty, i)
        if m then
          members[#members + 1] = m
        end
      end
    end
  end

  buildDisplayList()
end

function Group.getCounts()
  local total, online, dead = 0, 0, 0
  local leader = nil
  for _, m in ipairs(members) do
    total = total + 1
    if m.online then
      online = online + 1
    end
    if m.isDead then
      dead = dead + 1
    end
    if m.isLeader then
      leader = m
    end
  end
  return {
    total = total,
    online = online,
    dead = dead,
    leader = leader,
  }
end

-- ===== Edição do grupo (mover subgrupos, liderança, remoção) =====

function Group.playerIsLeader()
  if mockActive then
    return mockAsLeader
  end
  return (UnitIsGroupLeader and UnitIsGroupLeader("player")) and true or false
end

function Group.playerIsAssist()
  if mockActive then
    return mockAsAssist and not mockAsLeader
  end
  return (UnitIsGroupAssistant and UnitIsGroupAssistant("player")) and true or false
end

--- Pode arrastar/mover membros entre subgrupos (só em raid, líder ou assistente).
function Group.canEditRaid()
  return inRaid and (Group.playerIsLeader() or Group.playerIsAssist())
end

function Group.subgroupCount(subgroup)
  local n = 0
  for _, m in ipairs(members) do
    if m.subgroup == subgroup then
      n = n + 1
    end
  end
  return n
end

local function editGuard()
  if not Group.canEditRaid() then
    return false, "GROUP_ERR_NO_PERMISSION"
  end
  if not mockActive and InCombatLockdown and InCombatLockdown() then
    return false, "GROUP_ERR_COMBAT"
  end
  return true
end

local function mockRefreshUI()
  buildDisplayList()
  if CEF.GroupUI and CEF.GroupUI.refresh then
    CEF.GroupUI.refresh()
  end
end

--- Move um membro para o subgrupo alvo. Devolve ok, chaveDeErro.
function Group.moveToSubgroup(member, subgroup)
  local ok, err = editGuard()
  if not ok then
    return false, err
  end
  subgroup = tonumber(subgroup)
  if not member or not member.raidIndex or not subgroup or subgroup < 1 or subgroup > 8 then
    return false, nil
  end
  if member.subgroup == subgroup then
    return false, nil
  end
  if Group.subgroupCount(subgroup) >= 5 then
    return false, "GROUP_ERR_FULL"
  end
  if mockActive then
    member.subgroup = subgroup
    mockRefreshUI()
    return true
  end
  SetRaidSubgroup(member.raidIndex, subgroup)
  return true
end

--- Troca dois membros de subgrupo (para quando o destino está cheio).
function Group.swapMembers(a, b)
  local ok, err = editGuard()
  if not ok then
    return false, err
  end
  if not a or not b or not a.raidIndex or not b.raidIndex or a.raidIndex == b.raidIndex then
    return false, nil
  end
  if mockActive then
    a.subgroup, b.subgroup = b.subgroup, a.subgroup
    mockRefreshUI()
    return true
  end
  SwapRaidSubgroup(a.raidIndex, b.raidIndex)
  return true
end

function Group.promoteToLeader(member)
  if not Group.playerIsLeader() or not member or member.isSelf then
    return false, "GROUP_ERR_NOT_LEADER"
  end
  if mockActive then
    for _, m in ipairs(members) do
      if m.isSelf then
        m.isLeader = false
        m.isAssist = true
      else
        m.isLeader = false
      end
    end
    member.isLeader = true
    member.isAssist = false
    -- Continua podendo arrastar no mock (você vira assist visualmente).
    mockAsLeader = false
    mockAsAssist = true
    mockRefreshUI()
    return true
  end
  PromoteToLeader(member.name)
  return true
end

function Group.promoteToAssistant(member)
  if not inRaid or not Group.playerIsLeader() or not member or member.isSelf then
    return false, "GROUP_ERR_NOT_LEADER"
  end
  if mockActive then
    member.isAssist = true
    mockRefreshUI()
    return true
  end
  PromoteToAssistant(member.name)
  return true
end

function Group.demoteFromAssistant(member)
  if not inRaid or not Group.playerIsLeader() or not member then
    return false, "GROUP_ERR_NOT_LEADER"
  end
  if mockActive then
    member.isAssist = false
    mockRefreshUI()
    return true
  end
  DemoteAssistant(member.name)
  return true
end

function Group.removeFromGroup(member)
  if not (Group.playerIsLeader() or Group.playerIsAssist()) or not member or member.isSelf then
    return false, "GROUP_ERR_NO_PERMISSION"
  end
  if mockActive then
    for i, m in ipairs(members) do
      if m == member or (m.nameShort and member.nameShort and strlower(m.nameShort) == strlower(member.nameShort)) then
        table.remove(members, i)
        break
      end
    end
    mockRefreshUI()
    return true
  end
  UninviteUnit(member.name)
  return true
end

-- ===== Mock / demo layout =====

local MOCK_CLASSES = {
  "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID",
}
local MOCK_ZONES = {
  "Orgrimmar", "Ironforge", "Stormwind City", "Thunder Bluff", "Darnassus",
  "Stratholme", "Blackrock Mountain", "Molten Core", "Onyxia's Lair", "Naxxramas",
}

local function playerShortName()
  local n = (UnitName and UnitName("player")) or "You"
  return stripName(n)
end

local function makeMockMember(opts)
  local name = opts.name or "Player"
  local short = stripName(name)
  return {
    unit = opts.unit or "player",
    raidIndex = opts.raidIndex,
    name = name,
    nameShort = short,
    level = opts.level or 60,
    classFile = opts.classFile or "WARRIOR",
    zone = opts.zone or "",
    online = opts.online ~= false,
    isDead = opts.isDead and true or false,
    subgroup = opts.subgroup or 1,
    isLeader = opts.isLeader and true or false,
    isAssist = opts.isAssist and true or false,
    isML = opts.isML and true or false,
    isSelf = opts.isSelf and true or false,
  }
end

function Group.clearMock()
  mockActive = false
  mockAsLeader = true
  mockAsAssist = false
  wipe(members)
  inRaid = false
  buildDisplayList()
end

--- scenario: "party" | "raid" | "raidfull" | "clear"
function Group.applyMock(scenario)
  scenario = strlower(tostring(scenario or "raid"))
  if scenario == "clear" or scenario == "off" or scenario == "none" then
    Group.clearMock()
    return "clear"
  end

  wipe(members)
  mockActive = true
  mockAsLeader = true
  mockAsAssist = false
  local me = playerShortName()

  if scenario == "party" then
    inRaid = false
    members[#members + 1] = makeMockMember({
      unit = "player", name = me, level = 60, classFile = "WARRIOR",
      zone = "Orgrimmar", isLeader = true, isML = true, isSelf = true, subgroup = 1,
    })
    local party = {
      { "Thralladin", "PALADIN", 58 },
      { "Shadowmend", "PRIEST", 60 },
      { "Arrowshot", "HUNTER", 55 },
      { "Frostbolt", "MAGE", 59 },
    }
    for i, row in ipairs(party) do
      members[#members + 1] = makeMockMember({
        unit = "party" .. i, name = row[1], level = row[3], classFile = row[2],
        zone = "", online = i ~= 3, isDead = i == 2, subgroup = 1,
      })
    end
    buildDisplayList()
    return "party"
  end

  -- raid / raidfull
  inRaid = true
  local dense = (scenario == "raidfull" or scenario == "full")
  local names = {
    "Ironshield", "Lightmend", "Nightstalk", "Stormcall", "Felbolt",
    "Wildclaw", "Quickshot", "Shadowmend", "Battlecry", "Frostnova",
    "Earthward", "Silverdagger", "Pyroblast", "Naturebond", "Deathgrip",
    "Holyflame", "Windrunner", "Skullcrush", "Moonfire", "Soulburn",
    "Anvilrage", "Lifebloom", "Backstab", "Chainheal", "Arcaneorb",
    "Doomguard", "Bearform", "Trueshot", "Shieldwall", "Mindflay",
  }
  local count = dense and 40 or 22
  members[#members + 1] = makeMockMember({
    unit = "raid1", raidIndex = 1, name = me, level = 60, classFile = "WARRIOR",
    zone = "Molten Core", isLeader = true, isML = true, isSelf = true, subgroup = 1,
  })
  for i = 2, count do
    local sub = math.floor((i - 1) / 5) + 1
    if sub > 8 then
      sub = 8
    end
    local class = MOCK_CLASSES[((i - 1) % #MOCK_CLASSES) + 1]
    local zone = MOCK_ZONES[((i - 1) % #MOCK_ZONES) + 1]
    local nm = names[((i - 2) % #names) + 1] .. (i > (#names + 1) and tostring(i) or "")
    members[#members + 1] = makeMockMember({
      unit = "raid" .. i,
      raidIndex = i,
      name = nm,
      level = 50 + ((i * 3) % 11),
      classFile = class,
      zone = zone,
      online = (i % 7) ~= 0,
      isDead = (i % 11) == 0,
      subgroup = sub,
      isLeader = false,
      isAssist = (i == 2 or i == 3),
      isML = false,
      isSelf = false,
    })
  end
  buildDisplayList()
  return dense and "raidfull" or "raid"
end

-- Rótulo da coluna Função (Líder / Assistente / Membro) + ícone de mestre do saque.
local ICON_ML = "|TInterface\\GroupFrame\\UI-Group-MasterLooter:12:12:0:0|t"

function Group.roleRichText(m)
  if not m then
    return ""
  end
  local label
  if m.isLeader then
    label = "|cffffcc66" .. CEF.L.GROUP_ROLE_LEADER .. "|r"
  elseif m.isAssist then
    label = "|cffffe9a0" .. CEF.L.GROUP_ROLE_ASSIST .. "|r"
  else
    label = "|cffbbbbbb" .. CEF.L.GROUP_ROLE_MEMBER .. "|r"
  end
  if m.isML then
    label = label .. "  " .. ICON_ML
  end
  return label
end

-- Nome com ícone de líder/assistente e cor da classe.
local ICON_LEADER = "|TInterface\\GroupFrame\\UI-Group-LeaderIcon:14:14:0:0|t"
local ICON_ASSIST = "|TInterface\\GroupFrame\\UI-Group-AssistantIcon:14:14:0:0|t"

function Group.nameRichText(m)
  if not m then
    return ""
  end
  local prefix = ""
  if m.isLeader then
    prefix = ICON_LEADER .. " "
  elseif m.isAssist then
    prefix = ICON_ASSIST .. " "
  end
  local colorTag = "|cffffffff"
  if CEF.Guild and CEF.Guild.classColorPrefix then
    colorTag = CEF.Guild.classColorPrefix(m.classFile)
  end
  local name = colorTag .. (m.nameShort or m.name or "") .. "|r"
  if m.isSelf then
    name = name .. " |cff888888(" .. CEF.L.CHAT_YOU .. ")|r"
  end
  return prefix .. name
end

function Group.statusRichText(m)
  if not m then
    return ""
  end
  if not m.online then
    return "|cff888888" .. CEF.L.STATUS_OFFLINE .. "|r"
  end
  if m.isDead then
    return "|cffff5544" .. CEF.L.STATUS_DEAD .. "|r"
  end
  return "|cff66ff66" .. CEF.L.STATUS_ONLINE .. "|r"
end

-- Resumo da barra superior: tipo · membros · líder.
function Group.summaryRichText()
  if not Group.isInGroup() or #members == 0 then
    return "|cff888888" .. CEF.L.GROUP_EMPTY_NOT_IN_GROUP .. "|r"
  end
  local c = Group.getCounts()
  local typeLabel = inRaid and CEF.L.GROUP_TYPE_RAID or CEF.L.GROUP_TYPE_PARTY
  local out = "|cffffcc66" .. typeLabel .. "|r  |cffaaaaaa·|r  " .. CEF.L("GROUP_MEMBERS_FMT", c.total)
  if c.online < c.total then
    out = out .. " |cffaaaaaa(" .. CEF.L("GROUP_ONLINE_FMT", c.online) .. ")|r"
  end
  if c.leader then
    local colorTag = "|cffffffff"
    if CEF.Guild and CEF.Guild.classColorPrefix then
      colorTag = CEF.Guild.classColorPrefix(c.leader.classFile)
    end
    out = out .. "  |cffaaaaaa·|r  |cffaaaaaa" .. CEF.L.GROUP_LEADER_LABEL .. "|r " .. colorTag .. (c.leader.nameShort or "") .. "|r"
  end
  return out
end
