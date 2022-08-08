local folders = {}
local split = require "TTSTools/split"

---@class Folder
---@field GetClipList function
---@field GetClips function
---@field GetIsFolderStale function
---@field GetName function
---@field GetSubFolderList function
---@field GetSubFolders function
---@field GetUniqueId function

---@class MediaPool
---@field AddSubFolder function
---@field GetRootFolder function



---@param mediaPool MediaPool
---@param folder Folder
---@param name string
---@return Folder
local function GetOrCreateSubFolderDirect(mediaPool, folder, name)
    for _, subFolder in ipairs(folder:GetSubFolderList()) do
        if subFolder:GetName() == name then
            return subFolder
        end
    end
    return mediaPool:AddSubFolder(folder, name)
end

---Get or create sub folder
---@param mediaPool MediaPool
---@param folder Folder
---@param path string
---@return Folder
local function GetOrCreateSubFolder(mediaPool, folder, path)
    -- split string
    path = path:gsub("\\", "/")
    local splitted = split.split(path, "/")
    local name = splitted[1]
    local rest = table.concat(splitted, "/", 2)

    --- get direct sub folder
    local subFolder = GetOrCreateSubFolderDirect(mediaPool, folder, name)

    --- get rest sub folder
    if rest == "" then
        return subFolder
    else
        return GetOrCreateSubFolder(mediaPool, subFolder, rest)
    end
end

---Gets or creates folder
---@param mediaPool MediaPool
---@param folderName string
---@return Folder
function folders.GetOrCreateFolder(mediaPool, folderName)
    local rootFolder = mediaPool:GetRootFolder()
    return GetOrCreateSubFolder(mediaPool, rootFolder, folderName)
end

return folders
