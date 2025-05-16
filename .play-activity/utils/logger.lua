--- @module logger
-- Simple debug logger that writes to a file with line buffering.

local logger = {}

local file

--- Creates log file (call this once)
function logger.create()
  -- Ensure the logs directory exists (safe to call even if it already exists)
  love.filesystem.createDirectory("logs")
  file = io.open("logs/debug.log", "w")
  if file then file:setvbuf("line") end
end

--- Writes a line to the debug log.
-- All arguments are joined with tabs and followed by a newline.
-- @param ... any List of values to log; they are converted to strings and tab-separated.
function logger.line(...)
  if file then
    file:write(table.concat({...}, "\t") .. "\n")
  end
end

--- Closes the log file.
-- Should be called on app exit.
function logger.close()
  if file then
    file:close()
    file = nil
  end
end

return logger
