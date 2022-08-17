local fun = require "TTSTools/fun"
local folders = require "TTSTools/folders"

---Import voice files. Since DaVinci only allow import for selected track, we import all of them in single track for convinience.
---@param project Project
local function ImportVoice(project)
    local folderPath = tostring(fu:RequestDir())
    local mediaPool = project:GetMediaPool()
    local mediaStorage = resolve:GetMediaStorage()
    fun.each(print, mediaStorage:GetFileList(folderPath))
    local filePaths = {}
    for i, filePath in ipairs(mediaStorage:GetFileList(folderPath)) do
        if filePath:find('.wav') then
            filePaths[#filePaths + 1] = filePath
        end
    end

    -- set folder
    local folder = folders.GetOrCreateFolder(mediaPool, "TTSTools/Voice")
    mediaPool:SetCurrentFolder(folder)
    local mediaPoolItems = mediaPool:ImportMedia(filePaths)

    -- now mediaPoolItems are randomly ordered
    local timeline = project:GetCurrentTimeline()
    if not timeline then
        timeline = mediaPool:CreateEmptyTimeline('Timeline 1')
    end

    --track selection won't work
    --if not timeline:AddTrack("audio", "stereo") then
    --    error("Failed to add audio track.")
    --end
    --timeline:SetTrackEnable("audio", timeline:GetTrackCount("audio"), true)
    --timeline:SetTrackName("audio", timeline:GetTrackCount("audio"), "Voice")

    table.sort(mediaPoolItems,
        function(a, b)
            return a:GetName() < b:GetName()
        end
    )

    --assert(timeline:ImportIntoTimeline(filePaths[1]))--won't work
    mediaPool:AppendToTimeline(mediaPoolItems)
    --AppendToTimeline won't reorder the items in contrast.
end

local function Execute()
    local projectManager = resolve:GetProjectManager()
    local project = projectManager:GetCurrentProject()
    ImportVoice(project)
end

Execute()
