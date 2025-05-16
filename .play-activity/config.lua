--- @module config
-- Central configuration table for file paths, UI layout, fonts, colors, sorting, and initial state.

local config = {}

--- Maximum number of images to keep in the LRU image cache.
config.MAX_IMAGE_CACHE_SIZE = 10

--- Root search paths for data files.
-- These are checked in order to find relevant data and config files.
config.ROOTS = {
  "/mnt/sdcard",
  "/mnt/mmc"
}

--- Relative paths to important data files.
config.PATHS = {
  playtime_data = "/MUOS/info/track/playtime_data.json", -- Game playtime records
  core_base = "/MUOS/info/core/", -- Emulator config data (per system)
  catalogue_base = "/MUOS/info/catalogue/" -- Artwork catalog location
}

--- Format definition for game stats display.
-- Each entry defines a label, the key from game data, and the formatting type.
config.playtimeDataFormat = {
  {label = "Total Time:", key = "total_time", format = "duration"},
  {label = "Launches:", key = "launches", format = "number"},
  {label = "Last Played:", key = "start_time", format = "datetime"},
  {label = "Last Session:", key = "last_session", format = "duration"},
  {label = "Avg Session:", key = "avg_time", format = "duration"}
}

--- Order of sort modes cycled with the 'Sort' button.
config.sortCycle = {"time", "launches", "name", "recent"}

--- Human-readable labels for each sort mode.
config.sortModeLabels = {
  time = "Total Time",
  launches = "Launches",
  name = "Alphabetical",
  recent = "Recently Played"
}

--- Paths to font files
config.fontFiles = {
  "assets/LeagueMono.ttf", -- default font
  "assets/Orbitron.ttf",
  "assets/Commodore64.ttf",
  "assets/PressStart2P.ttf",
}

--- Font configuration for different UI text roles.
-- sizePct is relative to screen height.
config.fontConfig = {
  title      = {sizePct = 0.08},
  pagenumber = {sizePct = 0.042},
  stats      = {sizePct = 0.042},
  footer     = {sizePct = 0.034},
  nodata     = {sizePct = 0.042}
}

--- Layout margins and spacing for title text.
config.title = {
  marginTop = 8,
  marginLeft = 8,
  marginRight = 8
}

--- Layout margins for page number display.
config.pagenumber = {
  marginTop = 8,
  marginLeft = 8,
  marginRight = 8
}

--- Layout and spacing for game stats display.
config.stats = {
  marginTop = 24,
  marginLeft = 24,
  marginRight = 24,
  rowSpacingFactor = 1.35, -- Vertical spacing between stat rows (multiplier)
  labelValueGap = 8 -- Gap between the label colon and the value 
}

--- Layout for the footer command bar.
config.footer = {
  marginBottom = 8
}

--- Animation-related constants.
config.anim = {
  marqueeSpeed = 80, -- Pixels per second for scrolling text
  marqueePad = 40, -- Spacing between repeated marquee cycles
  transitionDuration = 0.5 -- Duration in seconds for page switch transition effect
}

--- RGBA color definitions for UI text and highlights.
config.colors = {
  cyan = {0, 1, 1, 1}, -- Cyan
  white = {1, 1, 1, 1}, -- White
  backgroundOverlay = {0, 0, 0, 0.5}, -- Transparent Black
  transitionOverlay = {0, 0, 0} -- RGB only; alpha is added dynamically
}

--- Initial state values when the app starts or resets.
config.state = {
  initialStatIndex = 0, -- Initially selected stat row (0 = title)
  initialMarqueeOffset = 0 -- Initial scroll position for marquee text
}

return config
