--[[
  Classic Era Finder — entrypoint: eventos, comandos e sincronização mínima com a UI.
  Lógica de dados → ClassicEraFinder.Entries / DB / Filters / Messages / Instances / Guild
  Construção da janela → ClassicEraFinder.UI
]]

ClassicEraFinder = ClassicEraFinder or {}
local CEF = ClassicEraFinder

local ADDON_NAME = "ClassicEraFinder"

CEF.state = CEF.state or {}
CEF.state.filterSearchText = CEF.state.filterSearchText or ""
-- Sets { [key]=true }; vazios = sem filtro neste eixo (multi-seleção nos dropdowns).
CEF.state.filterInstanceKeys = CEF.state.filterInstanceKeys or {}
CEF.state.filterIntentKeys = CEF.state.filterIntentKeys or {}
CEF.state.filterRoleKeys = CEF.state.filterRoleKeys or {}
CEF.state.filterGuildSearchText = CEF.state.filterGuildSearchText or ""
CEF.state.filterGuildClassKeys = CEF.state.filterGuildClassKeys or {}
CEF.state.filterGuildRankKeys = CEF.state.filterGuildRankKeys or {}
CEF.state.filterGuildOnlineKey = CEF.state.filterGuildOnlineKey
if CEF.state.filterGuildOnlineKey == nil then
  CEF.state.filterGuildOnlineKey = false
end
CEF.state.filterGuildLevelMin = CEF.state.filterGuildLevelMin or 1
CEF.state.filterGuildLevelMax = CEF.state.filterGuildLevelMax
  or (CEF.getMaxPlayerLevel and CEF.getMaxPlayerLevel())
  or 60

local mainFrame
local scrollFrame
local scrollChild
local rowFrames = {}
CEF.UI = CEF.UI or {}
CEF.UI.rowFrames = rowFrames

local uiTicker

local function refreshRelativeTimesOnly()
  CEF.UIEngine.refreshRelativeTimesOnly()
end

local function refreshUI()
  CEF.UIEngine.layoutRows()
  CEF.UIEngine.applyColumnWidths()
end

local function refreshGuildUI()
  if CEF.GuildUI and CEF.GuildUI.refresh then
    CEF.GuildUI.refresh()
  end
end

local function refreshChatUI()
  if CEF.ChatUI and CEF.ChatUI.refresh then
    CEF.ChatUI.refresh()
  end
end

local function refreshGroupUI()
  if CEF.GroupUI and CEF.GroupUI.refresh then
    CEF.GroupUI.refresh()
  end
end

CEF.UI.refreshRelativeTimesOnly = refreshRelativeTimesOnly
CEF.UI.refreshUI = refreshUI
CEF.UI.refreshGuildUI = refreshGuildUI
CEF.UI.refreshChatUI = refreshChatUI
CEF.UI.refreshGroupUI = refreshGroupUI

local function hideAllFilterDropdowns()
  CEF.UIFilters.hideAllFilterDropdowns(mainFrame)
end

local function purgeStaleEntries()
  if CEF.Entries.purgeStaleEntries() and mainFrame then
    refreshUI()
  end
end

-- Canais de broadcast do Hardcore (mortes etc.) — não são LFG.
local function isIgnoredChatChannel(channelBaseName)
  if not channelBaseName or channelBaseName == "" then
    return false
  end
  return channelBaseName:lower():find("hardcoredeaths", 1, true) ~= nil
end

local function onChatChannel(...)
  local text, playerName, _, _, _, _, _, _, channelBaseName, _, _, playerGUID = ...
  if not text or not playerName then
    return
  end
  if isIgnoredChatChannel(channelBaseName) then
    return
  end
  CEF.Entries.upsertEntry(playerName, playerGUID, text, channelBaseName or "")
  refreshUI()
end

local function createMainUI()
  local f = CEF.UI and CEF.UI.createMainUI and CEF.UI.createMainUI() or nil
  if not f then
    return mainFrame
  end
  mainFrame = f
  scrollFrame = CEF.UI.scrollFrame
  scrollChild = CEF.UI.scrollChild
  uiTicker = CEF.UI.uiTicker
  return f
end

local function toggleMainFrame()
  createMainUI()
  if not mainFrame then
    return
  end
  if mainFrame:IsShown() then
    CEF.UIUtils.cefTooltipHide()
    hideAllFilterDropdowns()
    if CEF.Chat and CEF.Chat.discardEmptyActive then
      CEF.Chat.discardEmptyActive()
    end
    if mainFrame.chatEditBox then
      mainFrame.chatEditBox:SetText("")
      if mainFrame.chatEditBox.ClearFocus then
        mainFrame.chatEditBox:ClearFocus()
      end
    end
    mainFrame:Hide()
    if uiTicker then
      uiTicker:Hide()
    end
  else
    if CEF.Minimap and CEF.Minimap.collapseExternalCollectors then
      CEF.Minimap.collapseExternalCollectors()
    end
    mainFrame:Show()
    if scrollFrame and scrollChild and mainFrame.header then
      scrollChild:SetWidth(scrollFrame:GetWidth())
      CEF.UILayout.layoutHeaderColumns(mainFrame.header)
    end
    refreshUI()
    if mainFrame.cefNavTab == "guild" then
      refreshGuildUI()
    elseif mainFrame.cefNavTab == "messages" then
      refreshChatUI()
    end
    if uiTicker then
      uiTicker:Show()
    end
  end
end

CEF.UI.toggleMainFrame = toggleMainFrame

local function openWhisperInHub(name)
  if not name or name == "" then
    return
  end
  createMainUI()
  if not mainFrame then
    return
  end
  -- Garante que nenhum overlay de menu/guilda fica a bloquear.
  if CEF.GuildUI and CEF.GuildUI.hideMemberContextMenu then
    CEF.GuildUI.hideMemberContextMenu()
  end
  if CEF.UIFilters and CEF.UIFilters.hideAllFilterDropdowns then
    CEF.UIFilters.hideAllFilterDropdowns(mainFrame)
  end
  if not mainFrame:IsShown() then
    if CEF.Minimap and CEF.Minimap.collapseExternalCollectors then
      CEF.Minimap.collapseExternalCollectors()
    end
    mainFrame:Show()
    if uiTicker then
      uiTicker:Show()
    end
  end
  if ChatEdit_GetActiveWindow and ChatEdit_DeactivateChat then
    local edit = ChatEdit_GetActiveWindow()
    if edit then
      pcall(ChatEdit_DeactivateChat, edit)
    end
  elseif ChatFrame1EditBox then
    ChatFrame1EditBox:Hide()
    if ChatFrame1EditBox.ClearFocus then
      ChatFrame1EditBox:ClearFocus()
    end
  end
  if CEF.Chat and CEF.Chat.focusWhisperAndShow then
    CEF.Chat.focusWhisperAndShow(name)
  end
end

CEF.UI.openWhisperInHub = openWhisperInHub

local function createMinimapButton()
  if CEF.Minimap and CEF.Minimap.create then
    CEF.Minimap.create(toggleMainFrame)
  end
end

local eventFrame = CreateFrame("Frame")
local staleAgeAcc = 0
local guildRosterAcc = 0
local groupRefreshAcc = 0
eventFrame:SetScript("OnUpdate", function(_, elapsed)
  elapsed = elapsed or 0
  staleAgeAcc = staleAgeAcc + elapsed
  if staleAgeAcc >= 1 then
    staleAgeAcc = 0
    purgeStaleEntries()
  end
  -- Refresh leve do roster enquanto a aba Guilda está visível.
  if mainFrame and mainFrame:IsShown() and mainFrame.cefNavTab == "guild" and CEF.Guild and CEF.Guild.isInGuild() then
    guildRosterAcc = guildRosterAcc + elapsed
    if guildRosterAcc >= 15 then
      guildRosterAcc = 0
      CEF.Guild.requestRoster()
    end
  else
    guildRosterAcc = 0
  end
  -- Morte/zona não disparam GROUP_ROSTER_UPDATE; refresh leve com a aba aberta.
  if mainFrame and mainFrame:IsShown() and mainFrame.cefNavTab == "group" and CEF.Group then
    groupRefreshAcc = groupRefreshAcc + elapsed
    if groupRefreshAcc >= 5 then
      groupRefreshAcc = 0
      CEF.Group.refreshFromApi()
      refreshGroupUI()
    end
  else
    groupRefreshAcc = 0
  end
end)
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER")
eventFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
eventFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
eventFrame:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
eventFrame:RegisterEvent("BN_FRIEND_INFO_CHANGED")
eventFrame:RegisterEvent("MINIMAP_UPDATE_ZOOM")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PARTY_LEADER_CHANGED")
eventFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
-- Premade Group Finder: só no cliente que expõe C_LFGList / eventos LFG_LIST_*.
-- No TBC 2.5.6 RegisterEvent de evento inexistente pode abortar o load.
do
  local function canRegisterLfgListEvent(name)
    if C_EventUtils and C_EventUtils.IsEventValid then
      return C_EventUtils.IsEventValid(name) == true
    end
    return C_LFGList ~= nil
  end
  local lfgListEvents = {
    "LFG_LIST_SEARCH_RESULTS_RECEIVED",
    "LFG_LIST_SEARCH_FAILED",
    "LFG_LIST_SEARCH_RESULT_UPDATED",
    "LFG_LIST_AVAILABILITY_UPDATE",
  }
  for _, ev in ipairs(lfgListEvents) do
    if canRegisterLfgListEvent(ev) then
      eventFrame:RegisterEvent(ev)
    end
  end
end
eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if (...) == ADDON_NAME then
      CEF.DB.init()
      if CEF.Locale and CEF.Locale.resolveAndApply then
        CEF.Locale.resolveAndApply()
      end
      if CEF.refreshIntentLocaleLabels then
        CEF.refreshIntentLocaleLabels()
      end
      if CEF.refreshRoleLocaleLabels then
        CEF.refreshRoleLocaleLabels()
      end
      if CEF.Guild and CEF.Guild.refreshLocaleLabels then
        CEF.Guild.refreshLocaleLabels()
      end
      CEF.Entries.loadFromDB()
      if CEF.Chat and CEF.Chat.loadFromDB then
        CEF.Chat.loadFromDB()
      end
    end
  elseif event == "PLAYER_LOGIN" then
    -- Temporada/realm/flavor já disponíveis: reconstrói o menu de instâncias
    -- (SoD / TBC) e recarrega listagens no escopo certo
    -- (ADDON_LOADED pode ter rodado antes de C_Seasons estar pronto).
    if CEF.invalidateFlavorCaches then
      CEF.invalidateFlavorCaches()
    end
    if CEF.rebuildInstanceFilterMenuOpts then
      CEF.rebuildInstanceFilterMenuOpts()
    end
    if CEF.clearInstanceDisplayNameCache then
      CEF.clearInstanceDisplayNameCache()
    end
    if CEF.Entries and CEF.Entries.loadFromDB then
      CEF.Entries.loadFromDB()
    end
    createMainUI()
    createMinimapButton()
    refreshUI()
  elseif event == "PLAYER_LOGOUT" then
    CEF.Entries.persist()
    if CEF.Chat and CEF.Chat.persist then
      CEF.Chat.persist()
    end
  elseif event == "CHAT_MSG_CHANNEL" then
    onChatChannel(...)
  elseif event == "CHAT_MSG_WHISPER"
    or event == "CHAT_MSG_WHISPER_INFORM"
    or event == "CHAT_MSG_BN_WHISPER"
    or event == "CHAT_MSG_BN_WHISPER_INFORM"
    or event == "CHAT_MSG_SYSTEM"
    or event == "BN_FRIEND_LIST_SIZE_CHANGED"
    or event == "BN_FRIEND_INFO_CHANGED" then
    if CEF.Chat and CEF.Chat.handleEvent then
      CEF.Chat.handleEvent(event, ...)
    end
  elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED"
    or event == "LFG_LIST_SEARCH_FAILED"
    or event == "LFG_LIST_SEARCH_RESULT_UPDATED"
    or event == "LFG_LIST_AVAILABILITY_UPDATE" then
    if CEF.LFG and CEF.LFG.handleEvent then
      CEF.LFG.handleEvent(event, ...)
    end
  elseif event == "MINIMAP_UPDATE_ZOOM" then
    if CEF.Minimap and CEF.Minimap.place then
      CEF.Minimap.place()
    end
  elseif event == "GUILD_ROSTER_UPDATE" then
    if CEF.Guild then
      CEF.Guild.refreshFromApi()
      if mainFrame and mainFrame:IsShown() and mainFrame.cefNavTab == "guild" then
        refreshGuildUI()
      end
    end
  elseif event == "GROUP_ROSTER_UPDATE"
    or event == "PARTY_LEADER_CHANGED"
    or event == "PARTY_LOOT_METHOD_CHANGED" then
    if CEF.Group then
      CEF.Group.refreshFromApi()
      if mainFrame and mainFrame:IsShown() and mainFrame.cefNavTab == "group" then
        refreshGroupUI()
      end
    end
  elseif event == "PLAYER_GUILD_UPDATE" then
    if CEF.Guild then
      if CEF.Guild.isInGuild() then
        CEF.Guild.requestRoster()
      else
        CEF.Guild.refreshFromApi()
        if mainFrame and mainFrame:IsShown() and mainFrame.cefNavTab == "guild" then
          refreshGuildUI()
        end
      end
    end
  end
end)

SLASH_CLASSICERAFINDER1 = "/cef"
SLASH_CLASSICERAFINDER2 = "/classicerafinder"
SlashCmdList["CLASSICERAFINDER"] = function(msg)
  msg = tostring(msg or "")
  local single = msg:match("^%s*(%S+)%s*$")
  if single and strlower(single) == "listchat" then
    if CEF.Chat and CEF.Chat.debugListConversations then
      local lines = CEF.Chat.debugListConversations()
      if #lines == 0 then
        print("|cffffcc66CEF:|r nenhuma conversa salva.")
      else
        print("|cffffcc66CEF:|r conversas salvas:")
        for _, line in ipairs(lines) do
          print("  " .. line)
        end
      end
    end
    return
  end
  local cmd, fromName, toName = msg:match("^%s*(%S+)%s+(%S+)%s+(%S+)")
  if cmd and strlower(cmd) == "movechat" then
    if not (CEF.Chat and CEF.Chat.moveConversationByNames) then
      return
    end
    local ok, info = CEF.Chat.moveConversationByNames(fromName, toName)
    if ok then
      print("|cffffcc66CEF:|r conversa de |cff00fff6" .. fromName .. "|r movida para |cff00fff6" .. tostring(info) .. "|r.")
      if CEF.ChatUI and CEF.ChatUI.refresh then
        CEF.ChatUI.refresh()
      end
    elseif info == "source_not_found" then
      print("|cffffcc66CEF:|r não achei conversa com o nome '" .. fromName .. "'.")
    elseif info == "target_not_found" then
      print("|cffffcc66CEF:|r não achei amigo Battle.net com o nome '" .. toName .. "'.")
    elseif info == "same_conversation" then
      print("|cffffcc66CEF:|r origem e destino são a mesma conversa.")
    else
      print("|cffffcc66CEF:|r uso: /cef movechat NomeOrigem NomeDestino")
    end
    return
  end
  toggleMainFrame()
end
