local split = {}
---split string
---@param str string
---@param delimiter string
---@return string[]
function split.split(str, delimiter)
    if str == nil then
        error("str is nil.")
    elseif delimiter == nil then
        error("delimiter is nil.")
    end

    local result = {};
    local from   = 1;

    local delim_from, delim_to = string.find(str, delimiter, from);
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1));
        from                 = delim_to + 1;
        delim_from, delim_to = string.find(str, delimiter, from);
    end
    table.insert(result, string.sub(str, from));
    return result;
end

function split.splitLines(str)
    if str == nil then
        error("str is nil.")
    end
    str = str:gsub("\r\n", "\n")
    str = str:gsub("\r", "\n")
    return split.split(str, "\n")
end

function split.path(str)
    if str == nil then
        error("str is nil.")
    end
    str = str:gsub("\\", "/")
    return split.split(str, "/")
end

return split
