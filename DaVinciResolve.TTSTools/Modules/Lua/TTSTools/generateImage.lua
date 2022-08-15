local inspect = require "TTSTools/inspect"
local json = require "TTSTools/json"
local split = require "TTSTools/split"
local fun = require "TTSTools/fun"
math.randomseed(os.clock())

local generateImage = {}

---@class LayerInfo
---@field localPath string
---@field name string
---@field safeName string
---@field isVisible boolean
---@field isGroup boolean
---@field children LayerInfo[]

---@class LayerUIInfo
---@field localPath string
---@field name string
---@field safeName string
---@field isVisible boolean
---@field isGroup boolean
---@field children LayerUIInfo[]
---@field GUID string
---@field isComboBox boolean

---Generate random string
---@param length integer
---@return string
local function RandomString(length)
    local res = ""
    for i = 1, length do
        res = res .. string.char(math.random(97, 122))
    end
    return res
end

---GUID
---@return string
local function GUID()
    return RandomString(64)
end

---comment
---@param layerInfos LayerUIInfo[]
---@param parent any
---@param win window
---@return LayerUIInfo[]
local function render(layerInfos, parent, win)
    local guid = GUID()
    local cbox = ui:ComboBox { ID = guid }
    parent:AddItem(cbox)
    for i, layerInfo in ipairs(layerInfos) do
        if layerInfo.name[1] == '*' then
            cbox:AddItem(layerInfo.name)
            layerInfos[i].GUID = guid
            layerInfos[i].isComboBox = true
            if layerInfo.isVisible then
                cbox:SetCurrentIndex(i)
            end
        elseif layerInfo.name[1] == '!' then

        else
            guid = GUID()
            layerInfos[i].GUID = guid
            layerInfos[i].isComboBox = false
            local checkBox = ui:CheckBox { ID = guid, Text = layerInfo.name, Checked = layerInfo.isVisible }
            parent:AddItem(checkBox)
        end

        if layerInfo.isGroup and layerInfo.isVisible then
            local group = ui:Group { ID = GUID() }
            parent:AddItem(group)
            layerInfos[i].children = render(layerInfo.children, group, win)
        end
    end
    return layerInfos
end

local function readLayerInfo(path)
    local file = io.open(path, "r")
    local content = file:read("*a")
    file:close()
    local layerInfos = json.decode(content)
    return layerInfos
end

local function showWindow()
    local ui = fu.UIManager
    local disp = bmd.UIDispatcher(ui)
    local win = disp:AddWindow({
        ID = "Dialog",
        WindowTitle = "Generate Comp",
        ui:HGroup {
            ui:LineEdit { ID = "Path", },
            ui:HGroup {
                ID = "Group"
            }
        }
    })
    local winItems = win:GetItems()
    local group = winItems.Group
    function win.On.Path.Modified(ev)
        for i, child in ipairs(group:GetChildren()) do
            group:RemoveChild(child)
        end
        local folderPath = winItems.Path.Text
        local layerInfos = readLayerInfo(folderPath .. '/' .. fun.tail(split.path(folderPath)) .. '.json')
    end

    function win.On.Dialog.Close(ev)
        disp:ExitLoop()
    end

    win:Show()
    disp:RunLoop()
    win:Hide()
end



local function generateComp(imagePaths)

end

function generateImage.init(node, folderPath)
    
end

function generateImage.createComp()

end

function generateImage.updateComp(timelienItem)

end

return generateImage
