
local packages = game.ReplicatedStorage:WaitForChild"Packages"
local knit = require(packages:WaitForChild("Knit"))
local signal = require(packages:WaitForChild"Signal")
local symbol = require(packages:WaitForChild"Symbol")

local controller = knit.CreateController{Name = script.Name}

local GUIUtilities = game.ReplicatedStorage:WaitForChild"Utilities":WaitForChild"GUI"
local roact = require(game.ReplicatedStorage.Utilities:WaitForChild'Roact')

local player = game.Players.LocalPlayer

controller.Theme = "Default"

local Elements = nil
local Interfaces = {}
local Popups = {}

local interfaceModules = GUIUtilities:WaitForChild"Interfaces"
local misc = game.ReplicatedStorage.Utilities:WaitForChild"Misc"

local TWS = game:GetService"TweenService"
local TweenConfig = TweenInfo.new(0.25)

controller.Popup = require(GUIUtilities:WaitForChild"Popup")
controller.Color = require(misc:WaitForChild"ColorUtil")
controller.UIPropertyChanged = signal.new()

function controller.Tween(object, goal, customTweenConfig)
    TWS:Create(object, customTweenConfig or TweenConfig, goal):Play()
end

function controller.newElement(Element, props, children)
    local element = roact.createElement(Elements[Element], props or {}, children)
    return element
end

function controller:UpdateUI(name, props)
    assert(Interfaces[name], `Interface named {name} doesn't exist`)
    local tree = Interfaces[name].tree
    
    local component = roact.createElement(require(interfaceModules[name]), props)
    tree = roact.update(tree, component)
  --  print("updating", name)
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
    if Interfaces[InterfaceName].props.Disabled == true then return end
   self:UpdateUI(InterfaceName, {Disabled = true})
end

function controller:EnableUI(InterfaceName)
   --  if Interfaces[InterfaceName].props.Disabled == false then return end
  -- print ('Enabling '.. InterfaceName) 
    self:UpdateUI(InterfaceName, {Disabled = false})
end

function controller:DisableAllExcept(ExceptionInterfaceNames: {string}, DoNothing)
    for name, _ in Interfaces do
        if not table.find(ExceptionInterfaceNames, name) then
          --  print("--- Disabling", name)
            self:DisableUI(name)
        else
       --     print("--- --- Enabling", name)
            self:EnableUI(name)
        end
    end
end

function controller:CreatePopup(element, id, props)
    --self:ClosePopup(id)
    props = props or {}

    props.DeselectedCallback = function()
        self:ClosePopup(id)
    end
    local layout = self.Popup.CreateLayout(element, props)

    if Popups[id] then
        self:UpdatePopup(id, layout)
    else
        local tree = roact.mount(layout, player.PlayerGui, 'Popup')
        Popups[id] = tree
    end
    
end

function controller:UpdatePopup(id, newElement)
    if Popups[id] then
        Popups[id] = roact.update(Popups[id], newElement)
    end
end

function controller:ClosePopup(id)
    local tree = Popups[id]
    if tree then
        roact.unmount(tree)
    end
    Popups[id] = nil
end

function controller:EnableAll()
    for name, _ in Interfaces do
      --  print("(ALL) --- --- Enabling", name)
        self:EnableUI(name)
    end
end

function controller:KnitStart()

    roact.setGlobalConfig({
        elementTracing = true
    })

    controller.Icon = require(GUIUtilities:WaitForChild"IconManager")
    controller.Window = require(GUIUtilities:WaitForChild"WindowManager")

    self:ReloadUI()

    for _, interfaceModule in interfaceModules:GetChildren() do
        local interface = require(interfaceModule)
        interface.Name = interfaceModule.Name
        if interface.Disabled then continue end
        task.spawn(function()
            local component = roact.createElement(interface)
            Interfaces[interfaceModule.Name] = {
                tree = roact.mount(component, player.PlayerGui, interfaceModule.Name),
                props = {Disabled = false}
            }
        end)
    end
end

return controller