local inspect = require "TTSTools/inspect"
local json = require "TTSTools/json"
local split = require "TTSTools/split"
local fun = require "TTSTools/fun"
local UTF8toSJISNext = require "TTSTools/UTF8toSJISNext"
local folders = require "TTSTools/folders"
local guid = require "TTSTools/guid"

local ui = fu.UIManager

---@class LayerInfo
---@field localPath string
---@field name string
---@field safeName string
---@field isVisible boolean
---@field isGroup boolean
---@field children LayerInfo[]


---@param layerInfo LayerInfo
---@param paths string[]
local function getVisibleLayerPaths(layerInfo, paths)
    if layerInfo.isVisible then
        if layerInfo.isGroup then
            for i, child in ipairs(layerInfo.children) do
                getVisibleLayerPaths(child, paths)
            end
        else
            paths[#paths + 1] = layerInfo.localPath
        end
    end
    return paths
end

local function execr(cmd)
    local f = assert(io.popen(cmd))
    local data = f:read('*a')
    f:close()
    return data
end

local function generateImage(layerInfo, folderPath)
    print('Generating image for ' .. folderPath)
    local imagePaths = getVisibleLayerPaths(layerInfo, {})

    -- Calling multiple commands at once not working, so we use absolute paths.
    local outFileNameUTF8 = folderPath .. '/' .. guid.randomString(12) .. ".png"
    local outFileName = UTF8toSJISNext:Convert(outFileNameUTF8)
    for i = 1, #imagePaths do
        imagePaths[i] = UTF8toSJISNext:Convert(folderPath .. '/' .. imagePaths[i])
    end

    -- Create commands
    local magickCommand = 'magick ' ..
        table.concat(imagePaths, ' ') .. ' -background None -layers Flatten ' .. outFileName
    -- local command = '"' .. 'cd ' .. folderPath .. ' & ' .. magickCommand .. '"'
    -- local command2 = 'start /d "' .. folderPath .. '" '.. magickCommand
    -- Call it
    print(execr(magickCommand))
    return outFileNameUTF8
end

---comment
---@param layerInfos LayerInfo[]
---@param parentTreeItem TreeView
local function addChildTreeItems(layerInfos, parentTreeItem, tree)
    for i, layerInfo in ipairs(layerInfos) do
        local treeItem = tree:NewItem()
        treeItem.Flags = {
            ItemIsSelectable = true,
            ItemIsEnabled = true,
            ItemIsUserCheckable = true, -- without this, the checkbox cannot be edited
        }
        treeItem.CheckState[0] = layerInfo.isVisible and "Checked" or "Unchecked"
        treeItem.Text[0] = layerInfo.name
        treeItem:SetData(0, "UserRole", layerInfo.localPath) -- without this, the events will not be triggered
        parentTreeItem:AddChild(treeItem)

        if layerInfo.isGroup then
            addChildTreeItems(layerInfo.children, treeItem, tree)
        end
    end
end

---comment
---@param layerInfos LayerInfo[]
local function updateLayerInfo(layerInfos, parentTreeItem)
    for i, layerInfo in ipairs(layerInfos) do
        local treeItem = parentTreeItem:Child(i - 1)
        assert(treeItem.Text[0] == layerInfo.name, treeItem.Text[0] .. " != " .. layerInfo.name)
        layerInfos[i].isVisible = treeItem.CheckState[0] == "Checked"
        if layerInfo.isGroup then
            layerInfos[i].children = updateLayerInfo(layerInfos[i].children, treeItem)
        end
    end
    return layerInfos
end

---comment
---@param folderPath string
local function formatFolderPath(folderPath)
    folderPath = folderPath:gsub("\\", "/")
    if folderPath:sub(#folderPath) == '/' then
        folderPath = folderPath:sub(1, #folderPath - 1)
    end
    return folderPath
end

---@param layerInfo LayerInfo
local function populateTree(layerInfo, tree, win)
    local rootTreeItem = tree:NewItem()
    rootTreeItem.Text[0] = "Root"
    tree:AddTopLevelItem(rootTreeItem)

    addChildTreeItems(layerInfo.children, rootTreeItem, tree)

    function win.On.Tree.ItemChanged(ev)
        if ev.item then
            layerInfo.children = updateLayerInfo(layerInfo.children, rootTreeItem)
        end
    end
end

local function readLayerInfo(path)
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    local layerInfos = json.decode(content)
    return layerInfos
end

local function showWindow()
    local disp = bmd.UIDispatcher(ui)
    local layerInfo = nil
    local projectManager = resolve:GetProjectManager()
    local project = projectManager:GetCurrentProject()
    local mediaPool = project:GetMediaPool()

    local win = disp:AddWindow({
        ID = "Dialog",
        WindowTitle = "Generate Comp",
        ui:VGroup {
            ui:HGroup {
                Weight = 0,
                ui:LineEdit { ID = "Path", },
                ui:Button { ID = "Browse", Text = "Browse" },
            },
            ui:HGroup {
                Weight = 0,
                ui:Button { ID = "Generate", Text = "Generate" },
            },
            ui:Tree {
                ID = "Tree",
                SortingEnabled = false,
                HeaderHidden = true,
                Events = { CurrentItemChanged = true, ItemChanged = true, },
            }
        }
    })
    local winItems = win:GetItems()

    function win.On.Browse.Clicked(ev)
        local path = fu:RequestDir()
        if path then
            winItems.Path.Text = path
        end
    end

    function win.On.Path.TextChanged(ev)
        local folderPath = formatFolderPath(winItems.Path.Text) ---@type string
        local jsonPath = folderPath .. '/' .. split.path(folderPath)[#split.path(folderPath)] .. '.json'
        jsonPath = assert(UTF8toSJISNext:Convert(jsonPath))
        layerInfo = readLayerInfo(jsonPath)
        populateTree(layerInfo, winItems.Tree, win)
    end

    function win.On.Generate.Clicked(ev)
        if layerInfo then
            local imagePath = generateImage(layerInfo, formatFolderPath(winItems.Path.Text))
            print(imagePath)
            local folder = folders.GetOrCreateFolder(mediaPool, "TTSTools/Png")
            mediaPool:SetCurrentFolder(folder)
            local poolItem = mediaPool:ImportMedia(imagePath)
            mediaPool:AppendToTimeline(poolItem)
        end
    end

    function win.On.Dialog.Close(ev)
        disp:ExitLoop()
    end

    win:Show()
    disp:RunLoop()
    win:Hide()
end

showWindow()
