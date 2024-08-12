local httpService = game:GetService('HttpService')
local ThemeManager = {} do
    ThemeManager.Folder = 'LinoriaLibSettings'
    -- if not isfolder(ThemeManager.Folder) then makefolder(ThemeManager.Folder) end

    ThemeManager.Library = nil
    ThemeManager.BuiltInThemes = {
        ['Default'] = { 1, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1c1c1c","AccentColor":"0055ff","BackgroundColor":"141414","OutlineColor":"323232"}') },
        ['BBot'] = { 2, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1e1e","AccentColor":"7e48a3","BackgroundColor":"232323","OutlineColor":"141414"}') },
        ['Fatality'] = { 3, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"1e1842","AccentColor":"c50754","BackgroundColor":"191335","OutlineColor":"3c355d"}') },
        ['Jester'] = { 4, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"db4467","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
        ['Mint'] = { 5, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"242424","AccentColor":"3db488","BackgroundColor":"1c1c1c","OutlineColor":"373737"}') },
        ['Tokyo Night'] = { 6, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"191925","AccentColor":"6759b3","BackgroundColor":"16161f","OutlineColor":"323232"}') },
        ['Ubuntu'] = { 7, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"3e3e3e","AccentColor":"e2581e","BackgroundColor":"323232","OutlineColor":"191919"}') },
        ['Quartz'] = { 8, httpService:JSONDecode('{"FontColor":"ffffff","MainColor":"232330","AccentColor":"426e87","BackgroundColor":"1d1b26","OutlineColor":"27232f"}') },
    }

    -- Add a variable to track the rainbow effect state
    ThemeManager.RainbowEffectEnabled = false

    function ThemeManager:ApplyTheme(theme)
        local customThemeData = self:GetCustomTheme(theme)
        local data = customThemeData or self.BuiltInThemes[theme]

        if not data then return end

        local scheme = data[2]
        for idx, col in next, customThemeData or scheme do
            self.Library[idx] = Color3.fromHex(col)

            if Options[idx] then
                Options[idx]:SetValueRGB(Color3.fromHex(col))
            end
        end

        self:ThemeUpdate()
    end

    function ThemeManager:ThemeUpdate()
        local options = { "FontColor", "MainColor", "AccentColor", "BackgroundColor", "OutlineColor" }
        for i, field in next, options do
            if Options and Options[field] then
                self.Library[field] = Options[field].Value
            end
        end

        self.Library.AccentColorDark = self.Library:GetDarkerColor(self.Library.AccentColor)
        self.Library:UpdateColorsUsingRegistry()
    end

    -- Function to handle the Rainbow effect
    function ThemeManager:StartRainbowEffect()
        if self.RainbowEffectEnabled then
            spawn(function()
                while self.RainbowEffectEnabled do
                    local hue = tick() % 5 / 5 -- cycling hue
                    local color = Color3.fromHSV(hue, 1, 1)
                    self.Library.AccentColor = color
                    self.Library.AccentColorDark = self.Library:GetDarkerColor(color)
                    self.Library:UpdateColorsUsingRegistry()
                    wait(0.1)
                end
            end)
        end
    end

    function ThemeManager:CreateThemeManager(groupbox)
        groupbox:AddLabel('Background color'):AddColorPicker('BackgroundColor', { Default = self.Library.BackgroundColor })
        groupbox:AddLabel('Main color'):AddColorPicker('MainColor', { Default = self.Library.MainColor })
        groupbox:AddLabel('Accent color'):AddColorPicker('AccentColor', { Default = self.Library.AccentColor })
        groupbox:AddLabel('Outline color'):AddColorPicker('OutlineColor', { Default = self.Library.OutlineColor })
        groupbox:AddLabel('Font color'):AddColorPicker('FontColor', { Default = self.Library.FontColor })

        local ThemesArray = {}
        for Name, Theme in next, self.BuiltInThemes do
            table.insert(ThemesArray, Name)
        end

        table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

        groupbox:AddDivider()
        groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Theme list', Values = ThemesArray, Default = 1 })

        groupbox:AddButton('Set as default', function()
            self:SaveDefault(Options.ThemeManager_ThemeList.Value)
            self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_ThemeList.Value))
        end)

        Options.ThemeManager_ThemeList:OnChanged(function()
            self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
        end)

        -- Adding the Accent Effect dropdown
        groupbox:AddDivider()
        groupbox:AddDropdown('ThemeManager_AccentEffect', { 
            Text = 'Accent Effect', 
            Values = { 'Default', 'Rainbow' }, 
            Default = 1 
        })

        Options.ThemeManager_AccentEffect:OnChanged(function()
            if Options.ThemeManager_AccentEffect.Value == 'Rainbow' then
                self.RainbowEffectEnabled = true
                self:StartRainbowEffect()
            else
                self.RainbowEffectEnabled = false
                self:ApplyTheme(Options.ThemeManager_ThemeList.Value) -- Reapply the theme to reset to default accent color
            end
        end)

        groupbox:AddDivider()
        groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom theme name' })
        groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
        groupbox:AddDivider()

        groupbox:AddButton('Save theme', function() 
            self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

            Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            Options.ThemeManager_CustomThemeList:SetValue(nil)
        end):AddButton('Load theme', function() 
            self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
        end)

        groupbox:AddButton('Refresh list', function()
            Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
            Options.ThemeManager_CustomThemeList:SetValue(nil)
        end)

        groupbox:AddButton('Set as default', function()
            if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
                self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
                self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
            end
        end)

        ThemeManager:LoadDefault()

        local function UpdateTheme()
            self:ThemeUpdate()
        end

        Options.BackgroundColor:OnChanged(UpdateTheme)
        Options.MainColor:OnChanged(UpdateTheme)
        Options.AccentColor:OnChanged(UpdateTheme)
        Options.OutlineColor:OnChanged(UpdateTheme)
        Options.FontColor:OnChanged(UpdateTheme)
    end
end

return ThemeManager
