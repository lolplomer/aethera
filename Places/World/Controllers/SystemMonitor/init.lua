local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SystemMonitor = Knit.CreateController { Name = "SystemMonitor" }

local loaded = false;

SystemMonitor.Trackers = {};

type PredicateLabel = (string) -> string
local GUI

function SystemMonitor:KnitStart()
    GUI = Knit.GetController('GUI')

    GUI:LoadInterface(script.Interface, 'SystemMonitor')
    loaded = true;
end

function SystemMonitor.newTracker(predicateLabel: PredicateLabel)
    local tracker = {
        Label = predicateLabel,
        Changed = Signal.new(),
    }

    table.insert(SystemMonitor.Trackers, tracker)

    if loaded == true then
        GUI:UpdateUI('SystemMonitor')
    end

    return tracker
end

function SystemMonitor.newAttributeTracker(source: Instance, attributeName: string, predicateLabel: PredicateLabel)
    local tracker = SystemMonitor.newTracker(predicateLabel)

    source:SetAttribute(attributeName, source:GetAttribute(attributeName) or 0)

    tracker._attributeChanged = source:GetAttributeChangedSignal(attributeName):Connect(function()
        tracker.Changed:Fire(source:GetAttribute(attributeName))
    end)

    return tracker
end

return SystemMonitor
