local fun = require "TTSTools/fun"
local folders = require "TTSTools/folders"
local split = require "TTSTools/split"
local UTF8toSJISNext = require "TTSTools/UTF8toSJISNext"

---Get frame rate of the project
---@param project Project
---@return number
local function GetFrameRate(project)
    local frameRate = project:GetSetting("timelineFrameRate")
    return frameRate
end

---comment
---@param filePath string
---@return string
local function ReadFile(filePath)
    return io.open(filePath, "r"):read("*a")
end

---comment
---@param filePath string
---@param str string
local function WriteFile(filePath, str)
    local file = io.open(filePath, "w")
    if file then
        file:write(str)
        file:close()
    else
        error("Could not open file.")
    end
end

---@class SubtitleTextItem
---@field num number
---@field speaker string
---@field text string

---@class SubRipItem
---@field startTime number
---@field endTime number
---@field text string

---@class SubtitleItem
---@field num number
---@field speaker string
---@field text string
---@field startTime number
---@field endTime number

---@alias trackType
---| '"audio"' # audio track
---| '"video"' # video track

---Generate SubRip Text
---@param subRipItems SubRipItem[]
---@return string
local function GenerateSubRipText(subRipItems)
    --- Covert Frame Number to Time string
    --- @param totalSeconds number
    --- @return string
    local function ConvertFrameNumToSubRipTime(totalSeconds)
        local milliseconds = totalSeconds % 1 * 1000
        local seconds = totalSeconds % 60
        local minutes = seconds / 60 % 60
        local hours = seconds / 60 / 60
        local time = string.format("%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
        return time
    end

    local subrip = ""
    for i, subRipItem in ipairs(subRipItems) do
        subrip = subrip ..
            i ..
            "\n" ..
            ConvertFrameNumToSubRipTime(subRipItem.startTime) ..
            " --> " ..
            ConvertFrameNumToSubRipTime(subRipItem.endTime) ..
            "\n" ..
            subRipItem.text ..
            "\n\n"
    end
    return subrip
end

---comment
---@param trackType trackType track type
---@return number #selected track number
local function SelectTrack(timeline, trackType)
    local n_tracks = timeline:GetTrackCount(trackType)
    local selection = 1
    if n_tracks > 1 then
        local tracks = {}

        -- ui
        local ui = fu.UIManager
        local disp = bmd.UIDispatcher(ui)
        local win = disp:AddWindow({
            ID = "SelectTimelineDialog",
            WindowTitle = "Select Timeline",
            Geometry = { 0, 0, 0, 0 },
            Spacing = 10,
            ui:VGroup {
                ui:Label { Text = "Select Timeline" },
                ui:ComboBox { ID = "TimelineComboBox" },
                ui:HGroup {
                    ui:Button { ID = "OKButton", Text = "OK" },
                    ui:Button { ID = "CancelButton", Text = "Cancel" },
                },
            }
        })
        local winItems = win:GetItems()
        local comboBox = winItems["TimelineComboBox"]
        local cancel = true


        comboBox:Clear()
        for i = 1, n_tracks do
            comboBox:AddItem(timeline:GetTrackName(trackType, i))
        end

        function win.On.OKButton.Clicked(ev)
            cancel = false
            selection = comboBox.CurrentIndex + 1
            print(timeline:GetTrackName(trackType, selection) .. " selected.")
            disp:ExitLoop()
        end

        function win.On.CancelButton.Clicked(ev)
            disp:ExitLoop()
        end

        function win.On.SelectTimelineDialog.Close(ev)
            disp:ExitLoop()
        end

        win:Show()
        disp:RunLoop()
        win:Hide()

        if cancel == true then
            return nil
        end
    end
    return selection
end

---Detect Subtitle files type
---@param folderPath string folderPath where subtitle files are located
---@return string subtitleType
---@return string[] subtitles
local function DetectSubtitlesType(folderPath)
    local filenames = io.popen("dir " .. folderPath .. "/b"):lines()
    local txtCount = 0
    local wavCount = 0
    for filename in filenames do
        if string.find(filename, ".txt") then
            txtCount = txtCount + 1
        end
        if string.find(filename, ".wav") then
            wavCount = wavCount + 1
        end
    end

    ---@type string[]
    local texts = {}
    for localPath in io.popen("dir " .. folderPath .. "/b"):lines() do
        if localPath:find(".txt") then
            local filePath = folderPath .. "/" .. localPath
            local text = ReadFile(filePath)
            texts[#texts + 1] = text
        end
    end

    if txtCount == 1 then
        return "single", texts
    elseif txtCount == wavCount then
        return "separated", texts
    elseif txtCount == 0 then
        return "none", texts
    elseif txtCount == wavCount + 1 then
        return "both", texts
    else
        return "unknown", texts
    end
end

---Read subtitle file(s)
---@param folderPath string folderpath where subtitle files are located
---@param sep string separator between speaker and text, in voicevox ',', in voiceroid/aivoice '＞'
---@return SubtitleTextItem[]
local function ReadSubtitleTextItems(folderPath, sep)
    local subtitlesType, texts = DetectSubtitlesType(folderPath)
    local rawTexts = {}
    if subtitlesType == "single" or subtitlesType == "both" then
        table.sort(texts, function (a, b)
            return a:len() > b:len()
        end)
        rawTexts = split.splitLines(texts[1])
    elseif subtitlesType == "separated" then
        rawTexts = texts
    else
        error("Subtitle files not recognized.")
    end
    fun.each(print, texts)
    fun.each(print, rawTexts)
    ---@type SubtitleTextItem[]
    local subtitles = {}
    for i, subtitle in ipairs(rawTexts) do
        ---@type string[]
        local match = split.split(subtitle, sep)
        local speaker = match[1]
        local text = match[2]
        print(speaker)
        if speaker ~= nil and text ~= nil then
            subtitles[#subtitles + 1] = {
                num = #subtitles + 1,
                speaker = speaker,
                text = text,
            } ---@as SubtitleTextItem
        end
    end
    return subtitles
end

local function GetUnique(array)
    local unique = {}
    for _, v in ipairs(array) do
        if not unique[v] then
            unique[v] = true
        end
    end
    local result = {}
    for k, v in pairs(unique) do
        result[#result + 1] = k
    end
    return result
end

---GroupBy function<br>
--->local array = {{fruit:'apple', weight:1}, {fruit:'orange', weight:2}, {fruit:'apple', weight:3}}<br>
---print(GroupBy(array, 'fruit'))<br>
---{apple = {{fruit:'apple', weight:1}, {fruit:'apple', weight:3}}, orange = {{fruit:'orange', weight:2}}}
---@generic TKey, TValue
---@param array table<TKey, TValue>
---@param key TKey
---@return table<TKey, TValue[]>
local function GroupBy(array, key)
    local result = {}
    for _, v in ipairs(array) do
        local k = v[key]
        if not result[k] then
            result[k] = {}
        end
        result[k][#result[k] + 1] = v
    end
    return result
end

---@param subtitleTextItems SubtitleTextItem[]
---@param timelineItems TimelineItem[]
---@return SubtitleItem[]
local function CreateSubtitleItems(project, subtitleTextItems, timelineItems)
    if #subtitleTextItems ~= #timelineItems then
        error(
            string.format("SubtitleTextItem (number of subtitles in the file) "..
            "and TimelineItem (number of voices in the track) count must be equal. %s, %s",
                #subtitleTextItems, #timelineItems)
        )
    end
    local frameRate = GetFrameRate(project)
    for i, timelineItem in ipairs(timelineItems) do
        subtitleTextItems[i].startTime = timelineItem:GetStart() / frameRate
        subtitleTextItems[i].endTime = timelineItem:GetEnd() / frameRate
    end
    return subtitleTextItems ---@as SubtitleItem[]
end

---Main function
---@param project Project
---@return string[]
local function CreateSubRipFromFileAndTimeline(project)
    local folderPath = tostring(fu:RequestDir())
    local subtitleTextItems = ReadSubtitleTextItems(folderPath, "＞")
    local timeline = project:GetCurrentTimeline()
    if not timeline then
        error("No timeline")
        return {}
    end

    -- select track
    local timelineItems = timeline:GetItemsInTrack('audio', SelectTrack(timeline, "audio"))
    -- create subtitle items (get start time and end time)
    local subtitleItems = CreateSubtitleItems(project, subtitleTextItems, timelineItems)
    ---@type string[]
    local subRipPaths = {}
    for speaker, speakerSubRips in pairs(GroupBy(subtitleItems, "speaker")) do
        local subrip = GenerateSubRipText(speakerSubRips--@as SubRipItem[]
        )
        local filePath = folderPath .. "/" .. UTF8toSJISNext:Convert(speaker) .. ".srt"
        WriteFile(filePath, subrip)
    end
    return subRipPaths
end

local function ImportSubRip(project, paths)
    local mediaPool = project:GetMediaPool()
    local folder = folders.GetOrCreateFolder(mediaPool, "TTSTools/SubRip")
    mediaPool:SetCurrentFolder(folder)
    local poolItems = mediaPool:ImportMedia(paths)
    --mediaPool:AppendToTimeline(poolItem)
end

local function Execute()
    local projectManager = resolve:GetProjectManager()
    local project = projectManager:GetCurrentProject()
    local subRipPaths = CreateSubRipFromFileAndTimeline(project)
    ImportSubRip(project, subRipPaths)
end

Execute()
