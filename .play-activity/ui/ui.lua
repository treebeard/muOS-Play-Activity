--- @module ui
-- Handles rendering of app UI: title, stats, background, page number, and footer.

local cfg      = require("config")
local artcache = require("ui.artcache")
local utils    = require("utils.utils")
local lg       = love.graphics

local ui = {}

local state, fonts, layout = nil, nil, {}
local formattedStats
local textWidths   

--- Injects the app state into the UI module.
-- This is used to read screen dimensions, selection, etc.
-- @param s table A shared mutable state object from main.
function ui.setState(s)
  state = s
end

--- Sets the font table used by the UI.
-- Each font corresponds to a role (title, stats, footer, etc.).
-- @param f table A table of Love2D Font objects keyed by role name.
function ui.setFonts(f)
  fonts = f
end

--- Precomputes layout, depends on fonts + screen size (in state)
-- Called in love.load and whenever fonts change.
function ui.updateScreenLayout()
  -- title
  layout.title = {
    offsetY = cfg.title.marginTop,
    baseX   = cfg.title.marginLeft,
    windowW = state.screenW - cfg.title.marginLeft - cfg.title.marginRight,
  }

  -- page number
  layout.page = {
    offsetY = cfg.title.marginTop
              + fonts.title:getHeight()
              + cfg.pagenumber.marginTop,
    baseX   = cfg.pagenumber.marginLeft,
    windowW = state.screenW - cfg.pagenumber.marginLeft - cfg.pagenumber.marginRight,
  }

  -- stats list
  local widest = 0
  for _, template in ipairs(cfg.playtimeDataFormat) do
    widest = math.max(widest, fonts.stats:getWidth(template.label))
  end
  local lineHeight = fonts.stats:getHeight()
  layout.stats = {
    offsetY      = cfg.title.marginTop
                   + fonts.title:getHeight()
                   + cfg.pagenumber.marginTop
                   + fonts.pagenumber:getHeight()
                   + cfg.stats.marginTop,
    baseX        = cfg.stats.marginLeft + widest + (cfg.stats.labelValueGap or 0),
    windowW      = state.screenW
                   - (cfg.stats.marginLeft + widest + (cfg.stats.labelValueGap or 0))
                   - cfg.stats.marginRight,
    widestLabel  = widest,
    lineHeight   = lineHeight,
    rowHeight    = lineHeight * cfg.stats.rowSpacingFactor,
    labelX       = cfg.stats.marginLeft,
    labelGap     = cfg.stats.labelValueGap or 0,
  }

  -- footer
  layout.footer = {
    offsetY = state.screenH - fonts.footer:getHeight() - cfg.footer.marginBottom,
  }
end

--- Called on new game load to compute game dependent layouts and values.
function ui.updateGameText()
  ui.formatStatValues()
  ui.updateTextWidths()
end

--- Formats stat values and stores formatted data in layout.
-- Called on new game load.
function ui.formatStatValues()
  formattedStats = {}
  local game = state.games[state.selectedGameIndex]
  if not game then return end
  for i, template in ipairs(cfg.playtimeDataFormat) do
    formattedStats[i] = utils.formatStat(game, template.key, template.format)
  end
end

--- Updates the width for title and formatted stats values
-- Called on both new game load and font change to measure widths.
function ui.updateTextWidths()
  local game = state.games[state.selectedGameIndex]
  if not game or not formattedStats then return end

  textWidths = {}
  textWidths.title = fonts.title:getWidth(game.name)
  textWidths.titleCycle = textWidths.title + cfg.anim.marqueePad

  textWidths.stat = {}
  for i, str in ipairs(formattedStats) do
    textWidths.stat[i] = fonts.stats:getWidth(str)
  end
end

--- Draws the "no data found" screen when no games are available.
function ui.drawNoData()
  lg.setFont(fonts.nodata)
  lg.setColor(cfg.colors.white)
  lg.printf("No data found", 0, state.screenH / 2, state.screenW, "center")
end

--- Draws the full-screen background artwork for the current game.
-- Applies scaling and dark overlay to make foreground text readable.
function ui.drawBackground()
  local game = state.games[state.selectedGameIndex]
  if not game then return end
  
  local img, scale, offsetX, offsetY = artcache.getArtwork(game)
  if not img then return end

  lg.setColor(cfg.colors.white)
  lg.draw(img, offsetX, offsetY, 0, scale, scale)

  lg.setColor(cfg.colors.backgroundOverlay)
  lg.rectangle("fill", 0, 0, state.screenW, state.screenH)

  lg.setColor(cfg.colors.white)
end

--- Draws the game title at the top of the screen.
-- Adds horizontal marquee scrolling if the title is too wide.
function ui.drawTitle()
  local game = state.games[state.selectedGameIndex]
  if not game then return end
  
  lg.setFont(fonts.title)
  lg.setColor(state.selectedStatIndex == 0 and cfg.colors.cyan or cfg.colors.white)

  local l = layout.title
  local text = game.name
  local textW = textWidths and textWidths.title or 0
  local cycle = textWidths and textWidths.titleCycle or 0

  if state.selectedStatIndex == 0 and textW > l.windowW then
    local shift = state.marqueeOffset % cycle
    lg.print(text, l.baseX - shift, l.offsetY)
    lg.print(text, l.baseX - shift + cycle, l.offsetY)
  else
    lg.print(text, l.baseX, l.offsetY)
  end
  lg.setColor(cfg.colors.white)
end

--- Draws the page number and current sort mode beneath the title.
function ui.drawPageNumber()
  lg.setFont(fonts.pagenumber)
  lg.setColor(cfg.colors.white)

  local l = layout.page
  local label = cfg.sortModeLabels[state.sortMode] or state.sortMode
  local text   = ("%d/%d (Sort: %s)"):format(state.selectedGameIndex, #state.games, label)

  lg.printf(text, l.baseX, l.offsetY, l.windowW, "left")
end


--- Draws the list of game stat rows (e.g., playtime, launches).
-- Highlights the selected stat and adds marquee scroll for overflowing text.
function ui.drawStats()
  local game = state.games[state.selectedGameIndex]
  if not game then return end

  lg.setFont(fonts.stats)

  local l = layout.stats
  local y = l.offsetY
  for i, template in ipairs(cfg.playtimeDataFormat) do
    local str = formattedStats and formattedStats[i] or ""
    local width = textWidths and textWidths.stat and textWidths.stat[i] or 0
    local isSelected = (state.selectedStatIndex == i)

    -- label
    if isSelected then lg.setColor(cfg.colors.cyan) end
    lg.print(template.label, l.labelX, y)

    -- value (with clip + marquee)
    lg.setScissor(l.baseX, y, l.windowW, l.lineHeight)
    if width <= l.windowW or not isSelected then
      lg.print(str, l.baseX, y)
    else
      local shift = math.min(state.marqueeOffset, width - l.windowW)
      lg.print(str, l.baseX - shift, y)
    end
    lg.setScissor()

    if isSelected then lg.setColor(cfg.colors.white) end
    y = y + l.rowHeight
  end
end

--- Draws the footer command hints at the bottom of the screen.
-- @param onlyQuit boolean If true, show only the Quit button
function ui.drawFooter(onlyQuit)
  lg.setFont(fonts.footer)
  lg.setColor(cfg.colors.white)

  local l = layout.footer
  local text = onlyQuit
    and "Quit (B)"
    or "Quit (B) • Sort (Y) • Font (X) • Art (A)"

  lg.printf(text, 0, l.offsetY, state.screenW, "center")
end

return ui
