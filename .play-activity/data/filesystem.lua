--- @module filesystem
-- Provides functions to locate, read, and parse playtime data and associated artwork paths.

local cfg  = require("config")
local json = require("utils.dkjson")

local fs = {}

--- Searches all root paths for the first file matching the given relative path.
-- @param relativePath string The relative file path to search for (e.g., `/some/file.txt`).
-- @return string|nil The full path of the first match found, or nil if not found.
function fs.findFirstExistingFile(relativePath)
  for _, root in ipairs(cfg.ROOTS) do
    local fullPath = root .. relativePath
    local f = io.open(fullPath, "r")
    if f then
      f:close()
      return fullPath
    end
  end
end

--- Loads and parses the playtime data JSON file into a table of game entries.
-- Each key in the JSON becomes a `game.path`, and its value becomes the metadata.
-- @return table A list of game tables with `path` fields and associated playtime data.
function fs.loadPlaytimeData()
  local path = fs.findFirstExistingFile(cfg.PATHS.playtime_data)
  if not path then return {} end

  local f, err = io.open(path, "r")
  if not f then return {} end

  local raw = f:read("*a")
  f:close()

  local decoded, pos, decodeErr = json.decode(raw, 1, nil)
  if not decoded then return {} end

  local games = {}
  for key, val in pairs(decoded) do
    val.path = key
    table.insert(games, val)
  end
  return games
end

--- Loads an image file from disk and converts it into a Love2D Image object.
-- @param path string The full path to the image file.
-- @return love.Image|nil A Love2D image object if loading succeeded, or nil on failure.
function fs.loadImageFromDisk(path)
  local f = io.open(path, "rb")
  if not f then return nil end

  local raw = f:read("*a")
  f:close()

  local filedata = love.filesystem.newFileData(raw, path)
  local ok, img = pcall(love.graphics.newImage, filedata)
  if not ok then return nil end

  return img
end

--- Attempts to locate the artwork path for a game by parsing its corresponding config file.
-- Based on the game's path, it derives the ROM folder and filename, then resolves its catalogue.
-- @param game table A game object with a `.path` field.
-- @return string|nil The resolved artwork file path, or nil if not found.
function fs.findArtworkPath(game)
  if not game or not game.path then return nil end

  local romDir, gameFile = game.path:match("(.+)/([^/]+)$")
  local romFolder = romDir and romDir:match(".*/(.-)$")
  if not romFolder or not gameFile then return nil end

  local baseName = gameFile:match("([^/]+)%.%w+$")
  local cfgRelPath = cfg.PATHS.core_base .. romFolder:lower() .. "/" .. baseName .. ".cfg"
  local cfgPath = fs.findFirstExistingFile(cfgRelPath)
  if not cfgPath then return nil end

  local f = io.open(cfgPath, "r")
  if not f then return nil end

  local lines = {}
  for line in f:lines() do
    table.insert(lines, line)
    if #lines >= 3 then break end
  end
  f:close()

  local catalogue = lines[3]
  if not catalogue then return nil end

  local relPath = cfg.PATHS.catalogue_base .. catalogue .. "/preview/" .. baseName .. ".png"
  return fs.findFirstExistingFile(relPath)
end

return fs
