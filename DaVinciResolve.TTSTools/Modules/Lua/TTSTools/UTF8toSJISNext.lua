local UTF8toSJIS = require "TTSTools/UTF8toSJIS"

local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

local UTF8toSJISNext = {}
local UTF8SJIS_PATH = script_path() .. "./Utf8Sjis.tbl"
local f = assert(io.open(UTF8SJIS_PATH, "r"))

---Convert UTF-8 to Shift-JIS
---@param str string
---@return string|nil
function UTF8toSJISNext:Convert(str)
    if str == nil then
        error("str is nil.")
    end
    return UTF8toSJIS:UTF8_to_SJIS_str_cnv(f, str)
end

return UTF8toSJISNext

