local cfg      = require("config")
local fs       = require("data.filesystem")
local sorter   = require("data.sorter")
local artcache = require("ui.artcache")
local ui       = require("ui.ui")
local utils    = require("utils.utils")
local lg       = love.graphics

--- Global app state shared across UI and logic.
local state = {
  games             = {},                              -- List of game data objects loaded from disk (set in love.load)
  selectedGameIndex = 1,                               -- Current selected game index (1-based)
  selectedStatIndex = cfg.state.initialStatIndex,      -- Current stat selection index (-1 = none, 0 = title, 1 - X = stats rows)
  marqueeOffset     = cfg.state.initialMarqueeOffset,  -- Horizontal scroll offset for marquee text
  showArt           = true,                            -- Whether to show background artwork
  sortMode          = cfg.sortCycle[1],                -- Current sort mode (e.g. "time", "launches")
  fontIndex         = 1,                               -- Current selected font
  screenW           = 0,                               -- Screen width in pixels (set in love.load)
  screenH           = 0,                               -- Screen height in pixels (set in love.load)
  transitionAlpha   = 0,                               -- Opacity of fade overlay (0 = none, 1 = full)
  transitionTimer   = 0,                               -- Countdown timer (in seconds) for transition fade
}

--- Initializes fonts, UI state, screen size, and game sorting.
function love.load()
  state.games = fs.loadPlaytimeData()
  state.screenW, state.screenH = lg.getDimensions()
  ui.setState(state)

  local fontPath = cfg.fontFiles[state.fontIndex]
  local fonts = utils.loadFonts(fontPath, cfg.fontConfig, state.screenH)
  ui.setFonts(fonts)

  ui.updateScreenLayout()

  if #state.games > 0 then
    sorter.sort(state.sortMode, state.games)
    ui.updateGameText()
    artcache.loadArtwork(state.games[state.selectedGameIndex], state.screenW, state.screenH)
  end
end

--- Updates marquee animation and page fade each frame.
-- @param dt number Delta time since last frame in seconds.
function love.update(dt)
  state.marqueeOffset = state.marqueeOffset + dt * cfg.anim.marqueeSpeed

  if state.transitionTimer > 0 then
    state.transitionTimer = state.transitionTimer - dt
    state.transitionAlpha = math.max(0, state.transitionTimer / cfg.anim.transitionDuration)
  end
end

--- Renders the current UI frame, including background, text, and footer.
function love.draw()
  if #state.games == 0 then
    ui.drawNoData()
    ui.drawFooter(true)
    return
  end

  if state.showArt then
    ui.drawBackground()
  end

  ui.drawTitle()
  ui.drawPageNumber()
  ui.drawStats()
  ui.drawFooter(false)

  if state.transitionAlpha > 0 then
    local r, g, b = unpack(cfg.colors.transitionOverlay)
    lg.setColor(r, g, b, state.transitionAlpha)
    lg.rectangle("fill", 0, 0, state.screenW, state.screenH)
    lg.setColor(cfg.colors.white)
  end
end

--- Handles key input for navigation, sorting, and toggling features.
-- @param k string The key that was pressed.
function love.keypressed(k)
  if k == "escape" then
    return love.event.quit()
  end
  if #state.games == 0 then
    -- only Quit available
    return
  end

  local gameSwitched = false

  if k == "right" then
    state.selectedGameIndex = utils.wrapGameSelection(state.selectedGameIndex + 1, #state.games)
    state.marqueeOffset = cfg.state.initialMarqueeOffset
    gameSwitched = true

  elseif k == "left" then
    state.selectedGameIndex = utils.wrapGameSelection(state.selectedGameIndex - 1, #state.games)
    state.marqueeOffset = cfg.state.initialMarqueeOffset
    gameSwitched = true

  elseif k == "down" then
    state.selectedStatIndex = utils.wrapStatSelection(state.selectedStatIndex, #cfg.playtimeDataFormat, 1)
    state.marqueeOffset = cfg.state.initialMarqueeOffset

  elseif k == "up" then
    state.selectedStatIndex = utils.wrapStatSelection(state.selectedStatIndex, #cfg.playtimeDataFormat, -1)
    state.marqueeOffset = cfg.state.initialMarqueeOffset

  elseif k == "s" then
    state.sortMode = sorter.cycle(state.sortMode, state.games)
    state.selectedGameIndex = 1
    state.selectedStatIndex = cfg.state.initialStatIndex
    state.marqueeOffset = cfg.state.initialMarqueeOffset
    gameSwitched = true

  elseif k == "a" then
    state.showArt = not state.showArt

  elseif k == "f" then
    state.fontIndex = (state.fontIndex % #cfg.fontFiles) + 1
    local nextFont = cfg.fontFiles[state.fontIndex]
    local fonts = utils.loadFonts(nextFont, cfg.fontConfig, state.screenH)

    ui.setFonts(fonts)
    ui.updateScreenLayout()
    ui.updateTextWidths()

    state.marqueeOffset = cfg.state.initialMarqueeOffset
  end

    -- Preload artwork on page switch
  if gameSwitched then
    state.transitionTimer = cfg.anim.transitionDuration
    state.transitionAlpha = 1
    ui.updateGameText()
    artcache.loadArtwork(state.games[state.selectedGameIndex], state.screenW, state.screenH)
  end
end
