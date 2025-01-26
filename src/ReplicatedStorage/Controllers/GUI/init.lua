local ReplicatedStorage = game:GetService("ReplicatedStorage")

local packages = game.ReplicatedStorage:WaitForChild"Packages"
local knit = require(packages:WaitForChild("Knit"))
local signal = require(packages:WaitForChild"Signal")
local symbol = require(packages:WaitForChild"Symbol")
local react =require(packages:WaitForChild('react'))
local react_roblox = require(packages:WaitForChild('react-roblox'))

local controller = knit.CreateController{Name = script.Name}

local GUIUtilities = game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"GUI"
local roact_old = require(game.ReplicatedStorage.Utilities:WaitForChild'Roact')


local player = game.Players.LocalPlayer

controller.Theme = "Default"

local Elements = nil
local Interfaces = {}
local Popups = {}
local Groups = {}

local interfaceModules = ReplicatedStorage.GameModules.Interfaces
local misc = game.ReplicatedStorage.Utilities:WaitForChild"Misc"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TWS = game:GetService"TweenService"
local TweenConfig = TweenInfo.new(0.25)

controller.Popup = require(GUIUtilities:WaitForChild"Popup")
controller.Color = require(misc:WaitForChild"ColorUtil")
controller.UIPropertyChanged = signal.new()
controller.DisableScroll = false

local modules = {}

local function createHandle(name)
    
    local handle = Instance.new('ScreenGui')
    handle.Parent = game.Players.LocalPlayer.PlayerGui
    handle.ZIndexBehavior =Enum.ZIndexBehavior.Sibling
    handle.IgnoreGuiInset = true
    handle.Name = name or 'ScreenGui'
    handle.ResetOnSpawn = false

    return handle
end

controller.CreateHandle = createHandle

function controller.Tween(object, goal, customTweenConfig)
    TWS:Create(object, customTweenConfig or TweenConfig, goal):Play()
end

function controller.newElement(Element, props, children)
    local element = react.createElement(Elements[Element], props or {}, children)
    return element
end

function controller.GetComponent(Element)
    return Elements[Element]
end

function controller:UpdateUI(name, props)
    
    assert(Interfaces[name], `Interface named {name} doesn't exist`)
    local tree = Interfaces[name].tree
    props = props or Interfaces[name].props
    local interface = require(modules[name])
    local component = react.createElement(interface.Component or interface, props)
    tree:render(component)
 --   warn("updating", name)
    Interfaces[name].props = props
end

function controller:ReloadUI()

    local ThemeFolder = GUIUtilities:WaitForChild("Theme")[self.Theme]

    Elements = setmetatable({},{
        __index = function(_, index)
            return require(ThemeFolder.Elements[index])
        end
    })

    for name, _ in Interfaces do
        self:UpdateUI(name)
    end
end

function controller:GetProps(InterfaceName)
    local interface = Interfaces[InterfaceName]
    if interface then
        return interface.props
    end
end

function controller:DisableUI(InterfaceName)
    --if Interfaces[InterfaceName].props.Disabled == true then return end
   --self:UpdateUI(InterfaceName, {Disabled = true})
   Interfaces[InterfaceName].handle.Enabled = false
end

function controller:EnableUI(InterfaceName)
   --  if Interfaces[InterfaceName].props.Disabled == false then return end
  -- print ('Enabling '.. InterfaceName) 
    --self:UpdateUI(InterfaceName, {Disabled = false})
    Interfaces[InterfaceName].handle.Enabled = true
end

function controller:DisableAllExcept(ExceptionInterfaceNames: {string})
    for name, data in Interfaces do
        if not table.find(ExceptionInterfaceNames, name) then
          --  print("--- Disabling", name)
            if not data.props.Disabled then

                data.previousDisabledProp = false

                self:DisableUI(name)    
            end
            
        else
       --     print("--- --- Enabling", name)
            self:EnableUI(name)
        end
    end
end

function controller:AddToGroup(interfaceName, group)
    if not Groups[group] then
        Groups[group] = {}
    end

    table.insert(Groups[group],interfaceName)

    
end

function controller:CreatePopup(id, element, props, DeselectedCallback)
    --self:ClosePopup(id)
    props = props or {}

    props.DeselectedCallback =  props.DeselectedCallback or DeselectedCallback or function()
        self:ClosePopup(id)
    end
    props.Id = id
    local layout = self.Popup.CreateLayout(element, props)

    if Popups[id] then
        self:UpdatePopup(id, layout)
    else
        --local tree = roact.mount(layout, player.PlayerGui, 'Popup')
        local handle = createHandle()
        handle.Name = id
        local root = react_roblox.createRoot(handle)
        root:render(layout)
        Popups[id] = {root = root, handle = handle}
    end
    
end

function controller:UpdatePopup(id, newElement)
    if Popups[id] then
        Popups[id].root:render(newElement)
        --Popups[id] = roact.update(Popups[id], newElement)
    end
end

function controller:ClosePopup(id)
    if Popups[id] then
        Popups[id].root:unmount()
        Popups[id].handle:Destroy()
        --roact.unmount(tree)
    end
    Popups[id] = nil
end

function controller:EnableAll(fromPreviousDisabledProp)
    if fromPreviousDisabledProp then
        for name, data in Interfaces do
            --  print("(ALL) --- --- Enabling", name)
          if data.previousDisabledProp ~= nil then
                self:EnableUI(name)
           end
            data.previousDisabledProp = nil
        end
    else
        for name in Interfaces do
            self:EnableUI(name)
        end
    end
   
end

function controller:KnitInit()
    local ContextActionService = game:GetService("ContextActionService")


    ContextActionService:BindAction("DisableScroll",
        function ()
            return self.DisableScroll and Enum.ContextActionResult.Sink or Enum.ContextActionResult.Pass
        end, false, Enum.UserInputType.MouseWheel)
end

function controller:EnableGroup(group)
    if Groups[group] then
        controller:DisableAllExcept(Groups[group])
    end
end

function controller:DisableGroup(group)
    if Groups[group] then
        for _, interfaceName in Groups[group] do
            controller:DisableUI(interfaceName)
        end
    end
end

local function initiate(interface, interfaceModule)
    local handle
    if interface.Handle then
        handle = interface.Handle(interface.Name)
    else
        handle = createHandle(interface.Name)
    end
    if interface.Disabled then
        handle.Enabled = false
    end

    local root = react_roblox.createRoot(handle)


    Interfaces[interface.Name] = {
        tree = root,
        props = {Handle = handle},--{Disabled = interface.Disabled == nil and true or interface.Disabled},
        handle = handle
    }

    root:render(react.createElement(interface.Component or interface, Interfaces[interface.Name].props))

    if interface.HUD then
        controller:AddToGroup(interface.Name, 'HUD')
    end

end

function controller:IsLoaded(name)
    return Interfaces[name] ~= nil
end

function controller:UnloadInterface(name)
    if Interfaces[name] then
        Interfaces[name].tree:unmount();
        Interfaces[name].handle:Destroy();
    end
    modules[name] = nil;
    Interfaces[name] = nil;
end
controller.Unload = controller.UnloadInterface

function controller:LoadInterface(interfaceModule: ModuleScript, name: string)

    name = name or interfaceModule.Name
    modules[name] = interfaceModule
    local interface = require(interfaceModule)
    
    interface.Name = name
    
    xpcall(initiate, warn, interface, interfaceModule)
end
controller.Load = controller.LoadInterface

function controller:LoadFolder(folder: Folder)
    for _,v in folder:GetChildren() do
        if v:IsA'ModuleScript' then
           
            self:LoadInterface(v)
        end
    end
end

function controller:KnitStart()

    -- roact_old.setGlobalConfig({
    --     elementTracing = true
    -- })

    local DisabledCoreGuis = {
        Enum.CoreGuiType.Backpack,
        Enum.CoreGuiType.PlayerList,
        Enum.CoreGuiType.EmotesMenu,
        Enum.CoreGuiType.Health
    }

    for _,v in DisabledCoreGuis do
        game.StarterGui:SetCoreGuiEnabled(v, false)
    end

    controller.Icon = require(GUIUtilities:WaitForChild"IconManager")
    controller.Window = require(GUIUtilities:WaitForChild"WindowManager")

    self:ReloadUI()


    local Nametag = require(script.Nametags)
    require(script.ProximityPrompt)

    Nametag.Init()

 
    self:LoadFolder(interfaceModules)
    self:LoadFolder(ReplicatedStorage.PlaceShared.Interfaces)

    controller.Started = true;
end

return controller