local toolbar = plugin:CreateToolbar("y6rey")

local bodykitMaker = toolbar:CreateButton(
	"Bodykit Maker",
	"Bodykit Maker",
	""
)

local info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right, --From what side gui appears
	false, --Widget will be initially enabled
	false, --Don't overdrive previouse enabled state
	200, --default weight
	300, --default height
	150, --minimum weight (optional)
	150 --minimum height (optional)
)

local widget = plugin:CreateDockWidgetPluginGui(
	"BodykitMaker", --A unique and consistent identifier used to storing the widget’s dock state and other internal details
	info --dock widget info
)

widget.Title = 'Bodykit Maker'

bodykitMaker.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)