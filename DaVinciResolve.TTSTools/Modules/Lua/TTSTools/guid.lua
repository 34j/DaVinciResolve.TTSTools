local guid = {}

math.randomseed(os.clock())

---Generate random string
---@param length integer
---@return string
function guid.randomString(length)
    local res = ""
    for i = 1, length do
        res = res .. string.char(math.random(97, 122))
    end
    return res
end

---GUID
---@return string
function guid.guid()
    return guid.randomString(64)
end

return guid