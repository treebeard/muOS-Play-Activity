--- @module utils
-- Provides generic utility functions for duration formatting, font loading, and index wrapping.

local lg = love.graphics

local utils = {}

--- Loads all fonts defined in a config table, scaling each relative to screen height.
-- If a font file is not found, a default font is used instead.
-- @param fontPath string? If given, use this .ttf for *all* roles instead of spec.path.
-- @param fontConfig table A table of font specs with `sizePct`.
-- @param screenH number The height of the screen in pixels.
-- @return table A table of loaded Love2D Font objects keyed by role.
function utils.loadFonts(fontPath, fontConfig, screenH)
  local fonts = {}
  for name, spec in pairs(fontConfig) do
    local size = screenH * spec.sizePct
    if love.filesystem.getInfo(fontPath) then
      fonts[name] = love.graphics.newFont(fontPath, size)
    else
      fonts[name] = love.graphics.newFont(size)
    end
  end
  return fonts
end

--- Formats a number of seconds into a human-readable duration string.
-- Examples: "2h 15m 42s", "4m 3s", "0s"
-- @param n number The total number of seconds.
-- @return string A formatted duration string.
function utils.formatDuration(n)
  n = math.floor(tonumber(n) or 0)

  local h = math.floor(n / 3600)
  local m = math.floor((n % 3600) / 60)
  local s = n % 60

  local parts = {}
  if h > 0 then table.insert(parts, h .. "h") end
  if m > 0 or h > 0 then table.insert(parts, m .. "m") end
  table.insert(parts, s .. "s")

  return table.concat(parts, " ")
end

--- Formats a game stat value using the specified format type.
-- Supports duration, datetime, number, and fallback to string.
-- @param game table A game data table containing raw stat values.
-- @param key string The key to extract from the game table.
-- @param format string The formatting type: "duration", "datetime", "number", or default.
-- @return string A formatted string representation of the value.
function utils.formatStat(game, key, format)
  local val = game[key]
  if format == "duration" then
    return utils.formatDuration(val)
  elseif format == "datetime" then
    return os.date("%Y-%m-%d %H:%M:%S %Z", val)
  elseif format == "number" then
    return tostring(val or 0)
  else
    return tostring(val or "")
  end
end

--- Wraps the current game selection within the valid range [1, max], looping around.
-- Used when pressing left/right to cycle games.
-- @param selectedGameIndex number The current game index.
-- @param max number The total number of games.
-- @return number The wrapped game index.
function utils.wrapGameSelection(selectedGameIndex, max)
  return (selectedGameIndex - 1) % max + 1
end

--- Wraps the current stats row selection within the valid range [-1, max], looping around.
-- Used for navigating rows in the stat display (including -1 for "no selection").
-- @param sel number Current selection index.
-- @param max number Max stat index.
-- @param dir number Direction of movement (1 = down, -1 = up).
-- @return number The wrapped selection index.
function utils.wrapStatSelection(sel, max, dir)
  sel = sel + dir
  if sel > max then return -1
  elseif sel < -1 then return max
  else return sel end
end

return utils
