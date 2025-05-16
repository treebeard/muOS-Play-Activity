--- @module sorter
-- Sorts the game list based on total time, launches, name, or recent play.

local cfg = require("config")

local sorter = {}

-- Table of comparator functions for each sort mode.
-- Each comparator returns true if `a` should come before `b`.
local comparators = {
  time     = function(a, b) return (a.total_time  or 0) > (b.total_time or 0) end,
  launches = function(a, b) return (a.launches    or 0) > (b.launches   or 0) end,
  name     = function(a, b) return (a.name        or "") < (b.name      or "") end,
  recent   = function(a, b) return (a.start_time  or 0) > (b.start_time or 0) end,
}

-- Builds a `sorters` table that links each mode to its comparator and the next mode.
-- Enables easy cycling through sort modes.
local sorters = {}
for i, mode in ipairs(cfg.sortCycle) do
  local nextMode = cfg.sortCycle[(i % #cfg.sortCycle) + 1]
  assert(comparators[mode], "Unknown sort mode: " .. mode)
  sorters[mode] = {
    fn   = comparators[mode],
    next = nextMode
  }
end

--- Sorts a list of games using the specified sort mode.
-- @param mode string The current sort mode (`"time"`, `"launches"`, `"name"`, or `"recent"`).
-- @param games table A list of game tables to be sorted in-place.
function sorter.sort(mode, games)
  local sorter = sorters[mode] or sorters[cfg.sortCycle[1]]
  table.sort(games, sorter.fn)
end

--- Cycles to the next sort mode and applies it to the game list.
-- Returns the new mode after sorting.
-- @param currentMode string The current sort mode.
-- @param games table A list of game tables to be sorted.
-- @return string The next sort mode used.
function sorter.cycle(currentMode, games)
  local nextMode = (sorters[currentMode] and sorters[currentMode].next) or cfg.sortCycle[1]
  sorter.sort(nextMode, games)
  return nextMode
end

return sorter
