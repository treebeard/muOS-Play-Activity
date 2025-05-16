--- @module artcache
-- Loads and caches artwork images with LRU eviction.

local cfg = require("config")
local fs  = require("data.filesystem")

local artcache   = {}

local pathCache  = {}  -- [ game.path|string ] = artworkPath|string or false
local imageCache = {}  -- [ artworkPath|string ] = { img, scale, offsetX, offsetY }
local lruKeys    = {}  -- [1..n] = artworkPath|string

--- Removes the least recently used image if the cache size exceeds the limit.
-- This helps control memory usage by evicting old textures.
local function evictIfNeeded()
  if #lruKeys > cfg.MAX_IMAGE_CACHE_SIZE then
    local oldest = table.remove(lruKeys, 1)
    imageCache[oldest] = nil
  end
end

--- Marks a given artwork path as recently used.
-- Moves it to the end of the LRU list.
-- @param path string The artwork path to mark as recently used.
local function markAsUsed(path)
  if lruKeys[#lruKeys] == path then return end

  for i = #lruKeys, 1, -1 do
    if lruKeys[i] == path then
      table.remove(lruKeys, i)
      break
    end
  end

  table.insert(lruKeys, path)
  evictIfNeeded()
end

--- Preload (load + scale + center) a game's background.
-- Called once in love.load and again on every page switch.
function artcache.loadArtwork(game, screenW, screenH)
  if not game or not game.path then return end

  -- resolve artwork file path (cached without LRU)
  local key     = game.path
  local artPath = pathCache[key]
  if artPath == nil then
    artPath = fs.findArtworkPath(game)
    pathCache[key] = artPath or false
  end
  if not artPath then return end

  -- if image already cached, just bump LRU
  if imageCache[artPath] then
    markAsUsed(artPath)
    return
  end

  -- load & compute scale/offset
  local img = fs.loadImageFromDisk(artPath)
  if not img then return end

  local w, h    = img:getDimensions()
  local scale   = math.min(screenW / w, screenH / h)
  local offsetX = (screenW - w * scale) / 2
  local offsetY = (screenH - h * scale) / 2

  imageCache[artPath] = { 
    img = img, 
    scale = scale, 
    offsetX = offsetX, 
    offsetY = offsetY 
  }
  markAsUsed(artPath)
end

--- Image cache lookup at draw time (no I/O).
-- Returns: img, scale, offsetX, offsetY, or nil.
function artcache.getArtwork(game)
  local artPath = pathCache[game.path]
  if not artPath then return nil end

  local entry = imageCache[artPath]
  if entry then
    markAsUsed(artPath)
    return entry.img, entry.scale, entry.offsetX, entry.offsetY
  end
  return nil
end

return artcache
