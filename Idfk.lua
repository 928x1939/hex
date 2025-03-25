
			ZIndex = 5;
			Parent = Container;
		});

		Groupbox:AddBlank(1);

		local TextBoxOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, 20);
			ZIndex = 5;
			Parent = Container;
		});

		local TextBoxInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = TextBoxOuter;
		});

		Library:AddToRegistry(TextBoxInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:OnHighlight(TextBoxOuter, TextBoxOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, TextBoxOuter)
		end

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = TextBoxInner;
		});

		local Container = Library:Create('Frame', {
			BackgroundTransparency = 1;
			ClipsDescendants = true;

			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -5, 1, 0);

			ZIndex = 7;
			Parent = TextBoxInner;
		})

		local Box = Library:Create('TextBox', {
			BackgroundTransparency = 1;

			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromScale(5, 1),

			Font = Library.Font;
			PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
			PlaceholderText = Info.Placeholder or '';

			Text = Info.Default or '';
			TextColor3 = Library.FontColor;
			TextSize = 14;
			TextStrokeTransparency = 0;
			TextXAlignment = Enum.TextXAlignment.Left;

			ZIndex = 7;
			Parent = Container;
		});

		Library:ApplyTextStroke(Box);

		function Textbox:SetValue(Text)
			if Info.MaxLength and #Text > Info.MaxLength then
				Text = Text:sub(1, Info.MaxLength);
			end;

			if Textbox.Numeric then
				if (not tonumber(Text)) and Text:len() > 0 then
					Text = Textbox.Value
				end
			end

			Textbox.Value = Text;
			Box.Text = Text;

			Library:SafeCallback(Textbox.Callback, Textbox.Value);
			Library:SafeCallback(Textbox.Changed, Textbox.Value);
		end;

		if Textbox.Finished then
			Box.FocusLost:Connect(function(enter)
				if not enter then return end

				Textbox:SetValue(Box.Text);
				Library:AttemptSave();
			end)
		else
			Box:GetPropertyChangedSignal('Text'):Connect(function()
				Textbox:SetValue(Box.Text);
				Library:AttemptSave();
			end);
		end

		-- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
		-- thank you nicemike40 :)

		local function Update()
			local PADDING = 2
			local reveal = Container.AbsoluteSize.X

			if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
				-- we aren't focused, or we fit so be normal
				Box.Position = UDim2.new(0, PADDING, 0, 0)
			else
				-- we are focused and don't fit, so adjust position
				local cursor = Box.CursorPosition
				if cursor ~= -1 then
					-- calculate pixel width of text from start to cursor
					local subtext = string.sub(Box.Text, 1, cursor-1)
					local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X

					-- check if we're inside the box with the cursor
					local currentCursorPos = Box.Position.X.Offset + width

					-- adjust if necessary
					if currentCursorPos < PADDING then
						Box.Position = UDim2.fromOffset(PADDING-width, 0)
					elseif currentCursorPos > reveal - PADDING - 1 then
						Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
					end
				end
			end
		end

		task.spawn(function() pcall(Update) end)

		Box:GetPropertyChangedSignal('Text'):Connect(Update)
		Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
		Box.FocusLost:Connect(Update)
		Box.Focused:Connect(Update)

		Library:AddToRegistry(Box, {
			TextColor3 = 'FontColor';
		});

		function Textbox:OnChanged(Func)
			Textbox.Changed = Func;
			Func(Textbox.Value);
		end;

		Groupbox:AddBlank(5);
		Groupbox:Resize();

		Options[Idx] = Textbox;

		return Textbox;
	end;

	function Funcs:AddToggle(Idx, Info)
		assert(Info.Text, 'AddInput: Missing `Text` string.')

		local Toggle = {
			Value = Info.Default or false;
			Type = 'Toggle';

			Callback = Info.Callback or function(Value) end;
			Addons = {},
			Risky = Info.Risky,
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local ToggleOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(0, 13, 0, 13);
			ZIndex = 5;
			Parent = Container;
		});

		Library:AddToRegistry(ToggleOuter, {
			BorderColor3 = 'Black';
		});

		local ToggleInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = ToggleOuter;
		});

		Library:AddToRegistry(ToggleInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local ToggleLabel = Library:CreateLabel({
			Size = UDim2.new(0, 216, 1, 0);
			Position = UDim2.new(1, 6, 0, 0);
			TextSize = 14;
			Text = Info.Text;
			TextXAlignment = Enum.TextXAlignment.Left;
			ZIndex = 6;
			Parent = ToggleInner;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 4);
			FillDirection = Enum.FillDirection.Horizontal;
			HorizontalAlignment = Enum.HorizontalAlignment.Right;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = ToggleLabel;
		});

		local ToggleRegion = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(0, 170, 1, 0);
			ZIndex = 8;
			Parent = ToggleOuter;
		});

		Library:OnHighlight(ToggleRegion, ToggleOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' }
		);

		function Toggle:UpdateColors()
			Toggle:Display();
		end;

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, ToggleRegion)
		end

		function Toggle:Display()
			ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
			ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

			Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
			Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
		end;

		function Toggle:OnChanged(Func)
			Toggle.Changed = Func;
			pcall(Func,Toggle.Value);
		end;

		function Toggle:SetValue(Bool)
			Bool = (not not Bool);

			Toggle.Value = Bool;
			Toggle:Display();

			for _, Addon in next, Toggle.Addons do
				if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
					Addon.Toggled = Bool
					Addon:Update()
				end
			end
			pcall(function()
				Library:SafeCallback(Toggle.Callback, Toggle.Value);
				Library:SafeCallback(Toggle.Changed, Toggle.Value);
			end)
			Library:UpdateDependencyBoxes();
		end;

		ToggleRegion.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
				Library:AttemptSave();
			end;
		end);

		if Toggle.Risky then
			Library:RemoveFromRegistry(ToggleLabel)
			ToggleLabel.TextColor3 = Library.RiskColor
			Library:AddToRegistry(ToggleLabel, { TextColor3 = 'RiskColor' })
		end

		Toggle:Display();
		Groupbox:AddBlank(Info.BlankSize or 5 + 2);
		Groupbox:Resize();

		Toggle.TextLabel = ToggleLabel;
		Toggle.Container = Container;
		setmetatable(Toggle, BaseAddons);

		Toggles[Idx] = Toggle;

		Library:UpdateDependencyBoxes();

		return Toggle;
	end;

function Funcs:AddSlider(Idx, Info)
    assert(Info.Default, 'AddSlider: Missing default value.')
    assert(Info.Text, 'AddSlider: Missing slider text.')
    assert(Info.Min, 'AddSlider: Missing minimum value.')
    assert(Info.Max, 'AddSlider: Missing maximum value.')
    assert(Info.Rounding, 'AddSlider: Missing rounding value.')

    local Slider = {
        Value = Info.Default,
        Min = Info.Min,
        Max = Info.Max,
        Rounding = Info.Rounding,
        MaxSize = 232,
        Type = 'Slider',
        Callback = Info.Callback or function(Value) end,
    }

    local Groupbox = self
    local Container = Groupbox.Container

    local SliderOuter = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderColor3 = Color3.new(0, 0, 0),
        Size = UDim2.new(1, -4, 0, 10), -- Adjusted height to be smaller
        ZIndex = 5,
        Parent = Container,
    })

    Library:AddToRegistry(SliderOuter, {
        BorderColor3 = 'Black',
    })

    local SliderInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,
        BorderColor3 = Library.OutlineColor,
        BorderMode = Enum.BorderMode.Inset,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 6,
        Parent = SliderOuter,
    })

    Library:AddToRegistry(SliderInner, {
        BackgroundColor3 = 'MainColor',
        BorderColor3 = 'OutlineColor',
    })

    local Fill = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderColor3 = Library.AccentColorDark,
        Size = UDim2.new(0, 0, 1, 0),
        ZIndex = 7,
        Parent = SliderInner,
    })

    Library:AddToRegistry(Fill, {
        BackgroundColor3 = 'AccentColor',
        BorderColor3 = 'AccentColorDark',
    })

    local HideBorderRight = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
        ZIndex = 8,
        Parent = Fill,
    })

    Library:AddToRegistry(HideBorderRight, {
        BackgroundColor3 = 'AccentColor',
    })

    local DisplayLabel = Library:CreateLabel({
        Size = UDim2.new(1, 0, 1, 0),
        TextSize = 14,
        Text = '', -- Initial text set to empty
        TextXAlignment = Enum.TextXAlignment.Center, -- Center the text
        ZIndex = 9,
        Parent = SliderInner,
    })

    Library:OnHighlight(SliderOuter, SliderOuter, {
        BorderColor3 = 'AccentColor',
    }, {
        BorderColor3 = 'Black',
    })

    if type(Info.Tooltip) == 'string' then
        Library:AddToolTip(Info.Tooltip, SliderOuter)
    end

    function Slider:UpdateColors()
        Fill.BackgroundColor3 = Library.AccentColor
        Fill.BorderColor3 = Library.AccentColorDark
    end

    function Slider:Display()
        local Suffix = Info.Suffix or ''
        DisplayLabel.Text = string.format('%s %s/%s', Info.Text, Slider.Value .. Suffix, Slider.Max .. Suffix) -- Display the text correctly
        local X = math.ceil(Library:MapValue(Slider.Value, Slider.Min, Slider.Max, 0, Slider.MaxSize))
        Fill.Size = UDim2.new(0, X, 1, 0)
        HideBorderRight.Visible = not (X == Slider.MaxSize or X == 0)
    end

    function Slider:OnChanged(Func)
        Slider.Changed = Func
        Func(Slider.Value)
    end

    local function Round(Value)
        if Slider.Rounding == 0 then
            return math.floor(Value)
        end

        return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
    end

    function Slider:GetValueFromXOffset(X)
        return Round(Library:MapValue(X, 0, Slider.MaxSize, Slider.Min, Slider.Max))
    end

    function Slider:SetValue(Str)
        local Num = tonumber(Str)

        if not Num then
            return
        end

        Num = math.clamp(Num, Slider.Min, Slider.Max)
        Slider.Value = Num
        Slider:Display()
        Library:SafeCallback(Slider.Callback, Slider.Value)
        Library:SafeCallback(Slider.Changed, Slider.Value)
    end

    SliderInner.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
            local mPos = Mouse.X
            local gPos = Fill.Size.X.Offset
            local Diff = mPos - (Fill.AbsolutePosition.X + gPos)

            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                local nMPos = Mouse.X
                local nX = math.clamp(gPos + (nMPos - mPos) + Diff, 0, Slider.MaxSize)
                local nValue = Slider:GetValueFromXOffset(nX)
                local OldValue = Slider.Value
                Slider.Value = nValue
                Slider:Display()

                if nValue ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                RenderStepped:Wait()
            end

            Library:AttemptSave()
        end
    end)

    Slider:Display()
    Groupbox:AddBlank(Info.BlankSize or 6)
    Groupbox:Resize()

    Options[Idx] = Slider

    return Slider
end

	function Funcs:AddDropdown(Idx, Info)
		if Info.SpecialType == 'Player' then
			Info.Values = GetPlayersString();
			Info.AllowNull = true;
		elseif Info.SpecialType == 'Team' then
			Info.Values = GetTeamsString();
			Info.AllowNull = true;
		end;

		assert(Info.Values, 'AddDropdown: Missing dropdown value list.');
		assert(Info.AllowNull or Info.Default, 'AddDropdown: Missing default value. Pass `AllowNull` as true if this was intentional.')

		if (not Info.Text) then
			Info.Compact = true;
		end;

		local Dropdown = {
			Values = Info.Values;
			Value = Info.Multi and {};
			Multi = Info.Multi;
			Type = 'Dropdown';
			SpecialType = Info.SpecialType; -- can be either 'Player' or 'Team'
			Callback = Info.Callback or function(Value) end;
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local RelativeOffset = 0;

		if not Info.Compact then
			local DropdownLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 10);
				TextSize = 14;
				Text = Info.Text;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextYAlignment = Enum.TextYAlignment.Bottom;
				ZIndex = 5;
				Parent = Container;
			});

			Groupbox:AddBlank(3);
		end

		for _, Element in next, Container:GetChildren() do
			if not Element:IsA('UIListLayout') then
				RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
			end;
		end;

		local DropdownOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			Size = UDim2.new(1, -4, 0, 20);
			ZIndex = 5;
			Parent = Container;
		});

		Library:AddToRegistry(DropdownOuter, {
			BorderColor3 = 'Black';
		});

		local DropdownInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 6;
			Parent = DropdownOuter;
		});

		Library:AddToRegistry(DropdownInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		Library:Create('UIGradient', {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
			});
			Rotation = 90;
			Parent = DropdownInner;
		});

		local DropdownArrow = Library:Create('ImageLabel', {
			AnchorPoint = Vector2.new(0, 0.5);
			BackgroundTransparency = 1;
			Position = UDim2.new(1, -16, 0.5, 0);
			Size = UDim2.new(0, 12, 0, 12);
			Image = '';
			ZIndex = 8;
			Parent = DropdownInner;
		});

		local ItemList = Library:CreateLabel({
			Position = UDim2.new(0, 5, 0, 0);
			Size = UDim2.new(1, -5, 1, 0);
			TextSize = 14;
			Text = '--';
			TextXAlignment = Enum.TextXAlignment.Left;
			TextWrapped = true;
			ZIndex = 7;
			Parent = DropdownInner;
		});

		Library:OnHighlight(DropdownOuter, DropdownOuter,
			{ BorderColor3 = 'AccentColor' },
			{ BorderColor3 = 'Black' }
		);

		if type(Info.Tooltip) == 'string' then
			Library:AddToolTip(Info.Tooltip, DropdownOuter)
		end

		local MAX_DROPDOWN_ITEMS = 8;

		local ListOuter = Library:Create('Frame', {
			BackgroundColor3 = Color3.new(0, 0, 0);
			BorderColor3 = Color3.new(0, 0, 0);
			ZIndex = 20;
			Visible = false;
			Parent = ScreenGui;
		});

		local function RecalculateListPosition()
			ListOuter.Position = UDim2.fromOffset(DropdownOuter.AbsolutePosition.X, DropdownOuter.AbsolutePosition.Y + DropdownOuter.Size.Y.Offset + 1);
		end;

		local function RecalculateListSize(YSize)
			ListOuter.Size = UDim2.fromOffset(DropdownOuter.AbsoluteSize.X, YSize or (MAX_DROPDOWN_ITEMS * 20 + 2))
		end;

		RecalculateListPosition();
		RecalculateListSize();

		DropdownOuter:GetPropertyChangedSignal('AbsolutePosition'):Connect(RecalculateListPosition);

		local ListInner = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BorderColor3 = Library.OutlineColor;
			BorderMode = Enum.BorderMode.Inset;
			BorderSizePixel = 0;
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 21;
			Parent = ListOuter;
		});

		Library:AddToRegistry(ListInner, {
			BackgroundColor3 = 'MainColor';
			BorderColor3 = 'OutlineColor';
		});

		local Scrolling = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			CanvasSize = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			ZIndex = 21;
			Parent = ListInner;

			TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
			BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Library.AccentColor,
		});

		Library:AddToRegistry(Scrolling, {
			ScrollBarImageColor3 = 'AccentColor'
		})

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 0);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Scrolling;
		});

		function Dropdown:Display()
			local Values = Dropdown.Values;
			local Str = '';

			if Info.Multi then
				for Idx, Value in next, Values do
					if Dropdown.Value[Value] then
						Str = Str .. Value .. ', ';
					end;
				end;

				Str = Str:sub(1, #Str - 2);
			else
				Str = Dropdown.Value or '';
			end;

			ItemList.Text = (Str == '' and '--' or Str);
		end;

		function Dropdown:GetActiveValues()
			if Info.Multi then
				local T = {};

				for Value, Bool in next, Dropdown.Value do
					table.insert(T, Value);
				end;

				return T;
			else
				return Dropdown.Value and 1 or 0;
			end;
		end;

		function Dropdown:BuildDropdownList()
			local Values = Dropdown.Values;
			local Buttons = {};

			for _, Element in next, Scrolling:GetChildren() do
				if not Element:IsA('UIListLayout') then
					Element:Destroy();
				end;
			end;

			local Count = 0;

			for Idx, Value in next, Values do
				local Table = {};

				Count = Count + 1;

				local Button = Library:Create('Frame', {
					BackgroundColor3 = Library.MainColor;
					BorderColor3 = Library.OutlineColor;
					BorderMode = Enum.BorderMode.Middle;
					Size = UDim2.new(1, -1, 0, 20);
					ZIndex = 23;
					Active = true,
					Parent = Scrolling;
				});

				Library:AddToRegistry(Button, {
					BackgroundColor3 = 'MainColor';
					BorderColor3 = 'OutlineColor';
				});

				local ButtonLabel = Library:CreateLabel({
					Active = false;
					Size = UDim2.new(1, -6, 1, 0);
					Position = UDim2.new(0, 6, 0, 0);
					TextSize = 14;
					Text = Value;
					TextXAlignment = Enum.TextXAlignment.Left;
					ZIndex = 25;
					Parent = Button;
				});

				Library:OnHighlight(Button, Button,
					{ BorderColor3 = 'AccentColor', ZIndex = 24 },
					{ BorderColor3 = 'OutlineColor', ZIndex = 23 }
				);

				local Selected;

				if Info.Multi then
					Selected = Dropdown.Value[Value];
				else
					Selected = Dropdown.Value == Value;
				end;

				function Table:UpdateButton()
					if Info.Multi then
						Selected = Dropdown.Value[Value];
					else
						Selected = Dropdown.Value == Value;
					end;

					ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
					Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
				end;

				ButtonLabel.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						local Try = not Selected;

						if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
						else
							if Info.Multi then
								Selected = Try;

								if Selected then
									Dropdown.Value[Value] = true;
								else
									Dropdown.Value[Value] = nil;
								end;
							else
								Selected = Try;

								if Selected then
									Dropdown.Value = Value;
								else
									Dropdown.Value = nil;
								end;

								for _, OtherButton in next, Buttons do
									OtherButton:UpdateButton();
								end;
							end;

							Table:UpdateButton();
							Dropdown:Display();

							Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
							Library:SafeCallback(Dropdown.Changed, Dropdown.Value);

							Library:AttemptSave();
						end;
					end;
				end);

				Table:UpdateButton();
				Dropdown:Display();

				Buttons[Button] = Table;
			end;

			Scrolling.CanvasSize = UDim2.fromOffset(0, (Count * 20) + 1);

			local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
			RecalculateListSize(Y);
		end;

		function Dropdown:SetValues(NewValues)
			if NewValues then
				Dropdown.Values = NewValues;
			end;

			Dropdown:BuildDropdownList();
		end;

		function Dropdown:OpenDropdown()
			ListOuter.Visible = true;
			Library.OpenedFrames[ListOuter] = true;
			DropdownArrow.Rotation = 180;
		end;

		function Dropdown:CloseDropdown()
			ListOuter.Visible = false;
			Library.OpenedFrames[ListOuter] = nil;
			DropdownArrow.Rotation = 0;
		end;

		function Dropdown:OnChanged(Func)
			Dropdown.Changed = Func;
			Func(Dropdown.Value);
		end;

		function Dropdown:SetValue(Val)
			if Dropdown.Multi then
				local nTable = {};

				for Value, Bool in next, Val do
					if table.find(Dropdown.Values, Value) then
						nTable[Value] = true
					end;
				end;

				Dropdown.Value = nTable;
			else
				if (not Val) then
					Dropdown.Value = nil;
				elseif table.find(Dropdown.Values, Val) then
					Dropdown.Value = Val;
				end;
			end;

			Dropdown:BuildDropdownList();

			Library:SafeCallback(Dropdown.Callback, Dropdown.Value);
			Library:SafeCallback(Dropdown.Changed, Dropdown.Value);
		end;

		DropdownOuter.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
				if ListOuter.Visible then
					Dropdown:CloseDropdown();
				else
					Dropdown:OpenDropdown();
				end;
			end;
		end);

		InputService.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

				if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
					or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

					Dropdown:CloseDropdown();
				end;
			end;
		end);

		Dropdown:BuildDropdownList();
		Dropdown:Display();

		local Defaults = {}

		if type(Info.Default) == 'string' then
			local Idx = table.find(Dropdown.Values, Info.Default)
			if Idx then
				table.insert(Defaults, Idx)
			end
		elseif type(Info.Default) == 'table' then
			for _, Value in next, Info.Default do
				local Idx = table.find(Dropdown.Values, Value)
				if Idx then
					table.insert(Defaults, Idx)
				end
			end
		elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
			table.insert(Defaults, Info.Default)
		end

		if next(Defaults) then
			for i = 1, #Defaults do
				local Index = Defaults[i]
				if Info.Multi then
					Dropdown.Value[Dropdown.Values[Index]] = true
				else
					Dropdown.Value = Dropdown.Values[Index];
				end

				if (not Info.Multi) then break end
			end

			Dropdown:BuildDropdownList();
			Dropdown:Display();
		end

		Groupbox:AddBlank(Info.BlankSize or 5);
		Groupbox:Resize();

		Options[Idx] = Dropdown;

		return Dropdown;
	end;

	function Funcs:AddDependencyBox()
		local Depbox = {
			Dependencies = {};
		};

		local Groupbox = self;
		local Container = Groupbox.Container;

		local Holder = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 0, 0);
			Visible = false;
			Parent = Container;
		});

		local Frame = Library:Create('Frame', {
			BackgroundTransparency = 1;
			Size = UDim2.new(1, 0, 1, 0);
			Visible = true;
			Parent = Holder;
		});

		local Layout = Library:Create('UIListLayout', {
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			Parent = Frame;
		});

		function Depbox:Resize()
			Holder.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y);
			Groupbox:Resize();
		end;

		Layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			Depbox:Resize();
		end);

		Holder:GetPropertyChangedSignal('Visible'):Connect(function()
			Depbox:Resize();
		end);

		function Depbox:Update()
			for _, Dependency in next, Depbox.Dependencies do
				local Elem = Dependency[1];
				local Value = Dependency[2];

				if Elem.Type == 'Toggle' and Elem.Value ~= Value then
					Holder.Visible = false;
					Depbox:Resize();
					return;
				end;
			end;

			Holder.Visible = true;
			Depbox:Resize();
		end;

		function Depbox:SetupDependencies(Dependencies)
			for _, Dependency in next, Dependencies do
				assert(type(Dependency) == 'table', 'SetupDependencies: Dependency is not of type `table`.');
				assert(Dependency[1], 'SetupDependencies: Dependency is missing element argument.');
				assert(Dependency[2] ~= nil, 'SetupDependencies: Dependency is missing value argument.');
			end;

			Depbox.Dependencies = Dependencies;
			Depbox:Update();
		end;

		Depbox.Container = Frame;

		setmetatable(Depbox, BaseGroupbox);

		table.insert(Library.DependencyBoxes, Depbox);

		return Depbox;
	end;

	BaseGroupbox.__index = Funcs;
	BaseGroupbox.__namecall = function(Table, Key, ...)
		return Funcs[Key](...);
	end;
end;

-- < Create other UI elements >
do
	Library.NotificationArea = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 40);
		Size = UDim2.new(0, 300, 0, 200);
		ZIndex = 100;
		Parent = ScreenGui;
	});

	Library:Create('UIListLayout', {
		Padding = UDim.new(0, 4);
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = Library.NotificationArea;
	});

    local WatermarkOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, -25);
        Size = UDim2.new(0, 250, 0, 40);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(4, 0, 4, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(2, 2, 2);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(3, -3, 2, -3);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local WatermarkLabel = Library:CreateLabel2({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        TextSize = 14;
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;
    Library:MakeDraggable(Library.Watermark);

	local KeybindOuter = Library:Create('Frame', {
		AnchorPoint = Vector2.new(0, 0.5);
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 10, 0.5, 0);
		Size = UDim2.new(0, 210, 0, 20);
		Visible = false;
		ZIndex = 100;
		Parent = ScreenGui;
	});

	local KeybindInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(2, 0, 2, 0);
		ZIndex = 101;
		Parent = KeybindOuter;
	});

	Library:AddToRegistry(KeybindInner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	}, true);

	local ColorFrame = Library:Create('Frame', {
		BackgroundColor3 = Library.AccentColor;
		BorderSizePixel = 0;
		Size = UDim2.new(1, 0, 0, 2);
		ZIndex = 102;
		Parent = KeybindInner;
	});

	Library:AddToRegistry(ColorFrame, {
		BackgroundColor3 = 'AccentColor';
	}, true);

    local KeybindLabel = Library:CreateLabel2({
        Size = UDim2.new(1, 0, 0, 20);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Center,
        
        Text = '[ Keybinds ]';
        ZIndex = 104;
        Parent = KeybindInner;
    });

	local KeybindContainer = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Size = UDim2.new(1, 0, 1, -20);
		Position = UDim2.new(0, 0, 0, 20);
		ZIndex = 1;
		Parent = KeybindInner;
	});

	Library:Create('UIListLayout', {
		FillDirection = Enum.FillDirection.Vertical;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = KeybindContainer;
	});

	Library:Create('UIPadding', {
		PaddingLeft = UDim.new(0, 5),
		Parent = KeybindContainer,
	})

	Library.KeybindFrame = KeybindOuter;
	Library.KeybindContainer = KeybindContainer;
	Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
	Library.Watermark.Visible = Bool;
end;

function Library:SetWatermark(Text)
	local X, Y = Library:GetTextBounds(Text, Library.Font, 14);
	Library.Watermark.Size = UDim2.new(0, X + 15, 0, (Y * 1.5) + 3);
	Library:SetWatermarkVisibility(true)

	Library.WatermarkText.Text = Text;
end;

function Library:Notify(Text, Time)
	local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

	YSize = YSize + 7

	local NotifyOuter = Library:Create('Frame', {
		BorderColor3 = Color3.new(0, 0, 0);
		Position = UDim2.new(0, 100, 0, 10);
		Size = UDim2.new(0, 0, 0, YSize);
		ClipsDescendants = true;
		ZIndex = 100;
		Parent = Library.NotificationArea;
	});

	local NotifyInner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.OutlineColor;
		BorderMode = Enum.BorderMode.Inset;
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 101;
		Parent = NotifyOuter;
	});

	Library:AddToRegistry(NotifyInner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	}, true);

	local InnerFrame = Library:Create('Frame', {
		BackgroundColor3 = Color3.new(1, 1, 1);
		BorderSizePixel = 0;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 102;
		Parent = NotifyInner;
	});

	local Gradient = Library:Create('UIGradient', {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
			ColorSequenceKeypoint.new(1, Library.MainColor),
		});
		Rotation = -90;
		Parent = InnerFrame;
	});

	Library:AddToRegistry(Gradient, {
		Color = function()
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
				ColorSequenceKeypoint.new(1, Library.MainColor),
			});
		end
	});

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });


	local LeftColor = Library:Create('Frame', {
		BackgroundColor3 = Library.AccentColor;
		BorderSizePixel = 0;
		Position = UDim2.new(0, -1, 0, -1);
		Size = UDim2.new(0, 3, 1, 2);
		ZIndex = 104;
		Parent = NotifyOuter;
	});

	Library:AddToRegistry(LeftColor, {
		BackgroundColor3 = 'AccentColor';
	}, true);
	local function inputBegan(input)
		pcall(function() if input.UserInputType == Enum.UserInputType.MouseButton1 then
				task.spawn(function() pcall(function()

						NotifyOuter:TweenSize(UDim2.new(0, 0, 0, 20), 'Out', 'Quad', 0.4, true);

						task.wait(0.4);

						NotifyOuter:Destroy();
					end) end);
			end end)
	end

	InnerFrame.InputBegan:Connect(inputBegan)
	pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

	task.spawn(function()
		wait(Time or 5);

		pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

		wait(0.4);

		NotifyOuter:Destroy();
	end);
end;

function Library:CreateWindow(...)
	local Arguments = { ... }
	local Config = { AnchorPoint = Vector2.zero }

	if type(...) == 'table' then
		Config = ...;
	else
		Config.Title = Arguments[1]
		Config.AutoShow = Arguments[2] or false;
	end

	if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
	if type(Config.TabPadding) ~= 'number' then Config.TabPadding = 0 end
	if type(Config.MenuFadeTime) ~= 'number' then Config.MenuFadeTime = 0.2 end

	if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
	if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(550, 600) end

	if Config.Center then
		Config.AnchorPoint = Vector2.new(0.5, 0.5)
		Config.Position = UDim2.fromScale(0.5, 0.5)
	end

	local Window = {
		Tabs = {};
	};

	local Outer = Library:Create('Frame', {
		AnchorPoint = Config.AnchorPoint,
		BackgroundColor3 = Color3.new(0, 0, 0);
		BorderSizePixel = 0;
		Position = Config.Position,
		Size = Config.Size,
		Visible = false;
		ZIndex = 1;
		Parent = ScreenGui;
	});

	Library:MakeDraggable(Outer, 25);

	local Inner = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		BorderColor3 = Library.AccentColor;
		BorderMode = Enum.BorderMode.Inset;
		Position = UDim2.new(0, 1, 0, 1);
		Size = UDim2.new(1, -2, 1, -2);
		ZIndex = 1;
		Parent = Outer;
	});

	Library:AddToRegistry(Inner, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'AccentColor';
	});

    local WindowLabel = Library:CreateLabel2({
        Position = UDim2.new(0, 7, 0, 0);
        Size = UDim2.new(0, 0, 0, 25);
        RichText = true;
        Text = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = 1;
        Parent = Inner;
    });

	local MainSectionOuter = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BorderColor3 = Library.OutlineColor;
		Position = UDim2.new(0, 8, 0, 25);
		BackgroundTransparency = 1;
		Size = UDim2.new(1, -16, 1, -33);
		ZIndex = 1;
		Parent = Inner;
	});

	Library:AddToRegistry(MainSectionOuter, {
		BackgroundColor3 = 'BackgroundColor';
		BorderColor3 = 'OutlineColor';
	});

	local MainSectionInner = Library:Create('Frame', {
		BackgroundColor3 = Library.BackgroundColor;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		ZIndex = 1;
		Parent = MainSectionOuter;
	});

	Library:AddToRegistry(MainSectionInner, {
		BackgroundColor3 = 'BackgroundColor';
	});

	local TabArea = Library:Create('Frame', {
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 8, 0, 8);
		Size = UDim2.new(1, -16, 0, 21);
		ZIndex = 1;
		Parent = MainSectionInner;
	});

	local TabListLayout = Library:Create('UIListLayout', {
		Padding = UDim.new(0, Config.TabPadding);
		FillDirection = Enum.FillDirection.Horizontal;
		SortOrder = Enum.SortOrder.LayoutOrder;
		Parent = TabArea;
	});

	local TabContainer = Library:Create('Frame', {
		BackgroundColor3 = Library.MainColor;
		Position = UDim2.new(0, 8, 0, 30);
		Size = UDim2.new(1, -16, 1, -38);
		BorderSizePixel = 0;
		ZIndex = 2;
		Parent = MainSectionInner;
	});


	Library:AddToRegistry(TabContainer, {
		BackgroundColor3 = 'MainColor';
		BorderColor3 = 'OutlineColor';
	});

	function Window:SetWindowTitle(Title)
		WindowLabel.Text = Title;
	end;

	function Window:AddTab(Name)
		local Tab = {
			Groupboxes = {};
			Tabboxes = {};
		};

		local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);

		local TabButton = Library:Create('Frame', {
			BackgroundColor3 = Library.BackgroundColor;
			BorderColor3 = Library.OutlineColor;
			BackgroundTransparency = 1;
			Size = UDim2.new(0, TabButtonWidth + 8 + 4, 1, 0);
			ZIndex = 1;
			Parent = TabArea;
		});

		Library:AddToRegistry(TabButton, {
			BackgroundColor3 = 'BackgroundColor';
			BorderColor3 = 'OutlineColor';
		});

		local TabButtonLabel = Library:CreateLabel({
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, -1);
			Text = Name;
			ZIndex = 1;
			Parent = TabButton;
		});

		local Blocker = Library:Create('Frame', {
			BackgroundColor3 = Library.MainColor;
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 0, 1, 0);
			Size = UDim2.new(1, 0, 0, 1);
			ZIndex = 3;
			Parent = TabButton;
		});

		Library:AddToRegistry(Blocker, {
			BackgroundColor3 = 'MainColor';
		});

		local TabFrame = Library:Create('Frame', {
			Name = 'TabFrame',
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, 0);
			Size = UDim2.new(1, 0, 1, 0);
			Visible = false;
			ZIndex = 2;
			Parent = TabContainer;
		});

		local LeftSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0, 8 - 1, 0, 8 - 1);
			Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		local RightSide = Library:Create('ScrollingFrame', {
			BackgroundTransparency = 1;
			BorderSizePixel = 0;
			Position = UDim2.new(0.5, 4 + 1, 0, 8 - 1);
			Size = UDim2.new(0.5, -12 + 2, 0, 507 + 2);
			CanvasSize = UDim2.new(0, 0, 0, 0);
			BottomImage = '';
			TopImage = '';
			ScrollBarThickness = 0;
			ZIndex = 2;
			Parent = TabFrame;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = LeftSide;
		});

		Library:Create('UIListLayout', {
			Padding = UDim.new(0, 8);
			FillDirection = Enum.FillDirection.Vertical;
			SortOrder = Enum.SortOrder.LayoutOrder;
			HorizontalAlignment = Enum.HorizontalAlignment.Center;
			Parent = RightSide;
		});

		for _, Side in next, { LeftSide, RightSide } do
			Side:WaitForChild('UIListLayout'):GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
				Side.CanvasSize = UDim2.fromOffset(0, Side.UIListLayout.AbsoluteContentSize.Y);
			end);
		end;

		function Tab:ShowTab()
			for _, Tab in next, Window.Tabs do
				Tab:HideTab();
			end;

			Blocker.BackgroundTransparency = 1;
			TabButtonLabel.TextColor3 = Library.AccentColor;
			TabButton.BackgroundColor3 = Library.MainColor;
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'MainColor';
			TabFrame.Visible = true;
		end;

		function Tab:HideTab()
			Blocker.BackgroundTransparency = 1;
			TabButtonLabel.TextColor3 = Color3.new(1,1,1);
			TabButton.BackgroundColor3 = Library.BackgroundColor;
			Library.RegistryMap[TabButton].Properties.BackgroundColor3 = 'BackgroundColor';
			TabFrame.Visible = false;
		end;

		function Tab:SetLayoutOrder(Position)
			TabButton.LayoutOrder = Position;
			TabListLayout:ApplyLayout();
		end;

		function Tab:AddGroupbox(Info)
			local Groupbox = {};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BackgroundTransparency = 0.75;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 507 + 2);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);
				BackgroundTransparency = 0.75;

				-- BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			local Highlight = Library:Create('Frame', {
				BackgroundColor3 = Library.AccentColor;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 0, 2);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = 'AccentColor';
			});

			local GroupboxLabel = Library:CreateLabel({
				Size = UDim2.new(1, 0, 0, 18);
				Position = UDim2.new(0, 4, 0, 2);
				TextSize = 14;
				Text = Info.Name;
				TextXAlignment = Enum.TextXAlignment.Left;
				ZIndex = 5;
				Parent = BoxInner;
			});

			local Container = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 4, 0, 20);
				Size = UDim2.new(1, -4, 1, -20);
				ZIndex = 1;
				Parent = BoxInner;
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Vertical;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = Container;
			});

			function Groupbox:Resize()
				local Size = 0;

				for _, Element in next, Groupbox.Container:GetChildren() do
					if (not Element:IsA('UIListLayout')) and Element.Visible then
						Size = Size + Element.Size.Y.Offset;
					end;
				end;

				BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
			end;

			Groupbox.Container = Container;
			setmetatable(Groupbox, BaseGroupbox);

			Groupbox:AddBlank(3);
			Groupbox:Resize();

			Tab.Groupboxes[Info.Name] = Groupbox;

			return Groupbox;
		end;

		function Tab:AddLeftGroupbox(Name)
			return Tab:AddGroupbox({ Side = 1; Name = Name; });
		end;

		function Tab:AddRightGroupbox(Name)
			return Tab:AddGroupbox({ Side = 2; Name = Name; });
		end;

		function Tab:AddTabbox(Info)
			local Tabbox = {
				Tabs = {};
			};

			local BoxOuter = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Library.OutlineColor;
				BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, 0, 0, 0);
				ZIndex = 2;
				Parent = Info.Side == 1 and LeftSide or RightSide;
			});

			Library:AddToRegistry(BoxOuter, {
				BackgroundColor3 = 'BackgroundColor';
				BorderColor3 = 'OutlineColor';
			});

			local BoxInner = Library:Create('Frame', {
				BackgroundColor3 = Library.BackgroundColor;
				BorderColor3 = Color3.new(0, 0, 0);
				-- BorderMode = Enum.BorderMode.Inset;
				Size = UDim2.new(1, -2, 1, -2);
				Position = UDim2.new(0, 1, 0, 1);
				ZIndex = 4;
				Parent = BoxOuter;
			});

			Library:AddToRegistry(BoxInner, {
				BackgroundColor3 = 'BackgroundColor';
			});

			local Highlight = Library:Create('Frame', {
				BackgroundColor3 = Library.AccentColor;
				BorderSizePixel = 0;
				Size = UDim2.new(1, 0, 0, 2);
				ZIndex = 10;
				Parent = BoxInner;
			});

			Library:AddToRegistry(Highlight, {
				BackgroundColor3 = 'AccentColor';
			});

			local TabboxButtons = Library:Create('Frame', {
				BackgroundTransparency = 1;
				Position = UDim2.new(0, 0, 0, 1);
				Size = UDim2.new(1, 0, 0, 18);
				ZIndex = 5;
				Parent = BoxInner;
			});

			Library:Create('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal;
				HorizontalAlignment = Enum.HorizontalAlignment.Left;
				SortOrder = Enum.SortOrder.LayoutOrder;
				Parent = TabboxButtons;
			});

			function Tabbox:AddTab(Name)
				local Tab = {};

				local Button = Library:Create('Frame', {
					BackgroundColor3 = Library.MainColor;
					BorderColor3 = Color3.new(0, 0, 0);
					Size = UDim2.new(0.5, 0, 1, 0);
					ZIndex = 6;
					Parent = TabboxButtons;
				});

				Library:AddToRegistry(Button, {
					BackgroundColor3 = 'MainColor';
				});

				local ButtonLabel = Library:CreateLabel({
					Size = UDim2.new(1, 0, 1, 0);
					TextSize = 14;
					Text = Name;
					TextXAlignment = Enum.TextXAlignment.Center;
					ZIndex = 7;
					Parent = Button;
				});

				local Block = Library:Create('Frame', {
					BackgroundColor3 = Library.BackgroundColor;
					BorderSizePixel = 0;
					Position = UDim2.new(0, 0, 1, 0);
					Size = UDim2.new(1, 0, 0, 1);
					Visible = false;
					ZIndex = 9;
					Parent = Button;
				});

				Library:AddToRegistry(Block, {
					BackgroundColor3 = 'BackgroundColor';
				});

				local Container = Library:Create('Frame', {
					BackgroundTransparency = 1;
					Position = UDim2.new(0, 4, 0, 20);
					Size = UDim2.new(1, -4, 1, -20);
					ZIndex = 1;
					Visible = false;
					Parent = BoxInner;
				});

				Library:Create('UIListLayout', {
					FillDirection = Enum.FillDirection.Vertical;
					SortOrder = Enum.SortOrder.LayoutOrder;
					Parent = Container;
				});

				function Tab:Show()
					for _, Tab in next, Tabbox.Tabs do
						Tab:Hide();
					end;

					Container.Visible = true;
					Block.Visible = true;

					Button.BackgroundColor3 = Library.BackgroundColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';

					Tab:Resize();
				end;

				function Tab:Hide()
					Container.Visible = false;
					Block.Visible = false;

					Button.BackgroundColor3 = Library.MainColor;
					Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
				end;

				function Tab:Resize()
					local TabCount = 0;

					for _, Tab in next, Tabbox.Tabs do
						TabCount = TabCount + 1;
					end;

					for _, Button in next, TabboxButtons:GetChildren() do
						if not Button:IsA('UIListLayout') then
							Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
						end;
					end;

					if (not Container.Visible) then
						return;
					end;

					local Size = 0;

					for _, Element in next, Tab.Container:GetChildren() do
						if (not Element:IsA('UIListLayout')) and Element.Visible then
							Size = Size + Element.Size.Y.Offset;
						end;
					end;

					BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2 + 2);
				end;

				Button.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
						Tab:Show();
						Tab:Resize();
					end;
				end);

				Tab.Container = Container;
				Tabbox.Tabs[Name] = Tab;

				setmetatable(Tab, BaseGroupbox);

				Tab:AddBlank(3);
				Tab:Resize();

				-- Show first tab (number is 2 cus of the UIListLayout that also sits in that instance)
				if #TabboxButtons:GetChildren() == 2 then
					Tab:Show();
				end;

				return Tab;
			end;

			Tab.Tabboxes[Info.Name or ''] = Tabbox;

			return Tabbox;
		end;

		function Tab:AddLeftTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 1; });
		end;

		function Tab:AddRightTabbox(Name)
			return Tab:AddTabbox({ Name = Name, Side = 2; });
		end;

		TabButton.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 then
				Tab:ShowTab();
			end;
		end);

		-- This was the first tab added, so we show it by default.
		if #TabContainer:GetChildren() == 1 then
			Tab:ShowTab();
		end;

		Window.Tabs[Name] = Tab;
		return Tab;
	end;

	local ModalElement = Library:Create('TextButton', {
		BackgroundTransparency = 1;
		Size = UDim2.new(0, 0, 0, 0);
		Visible = true;
		Text = '';
		Modal = false;
		Parent = ScreenGui;
	});

	local TransparencyCache = {};
	local Toggled = false;
	local Fading = false;

	function Library:Toggle()
		if Fading then
			return;
		end;

		local FadeTime = Config.MenuFadeTime;
		Fading = true;
		Toggled = (not Toggled);
		ModalElement.Modal = Toggled;



		for _, Desc in next, Outer:GetDescendants() do
			local Properties = {};

			if Desc:IsA('ImageLabel') then
				table.insert(Properties, 'ImageTransparency');
				table.insert(Properties, 'BackgroundTransparency');
			elseif Desc:IsA('TextLabel') or Desc:IsA('TextBox') then
				table.insert(Properties, 'TextTransparency');
			elseif Desc:IsA('Frame') or Desc:IsA('ScrollingFrame') then
				table.insert(Properties, 'BackgroundTransparency');
			elseif Desc:IsA('UIStroke') then
				table.insert(Properties, 'Transparency');
			end;

			local Cache = TransparencyCache[Desc];

			if (not Cache) then
				Cache = {};
				TransparencyCache[Desc] = Cache;
			end;

			for _, Prop in next, Properties do
				if not Cache[Prop] then
					Cache[Prop] = Desc[Prop];
				end;

				if Cache[Prop] == 1 then
					continue;
				end;

				TweenService:Create(Desc, TweenInfo.new(FadeTime, Enum.EasingStyle.Linear), { [Prop] = Toggled and Cache[Prop] or 1 }):Play();
			end;
		end;

		task.wait(FadeTime);

		Outer.Visible = Toggled;

		Fading = false;
	end

	Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
		if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
			if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
				task.spawn(Library.Toggle)
			end
		elseif Input.KeyCode == Enum.KeyCode.RightControl or (Input.KeyCode == Enum.KeyCode.RightShift and (not Processed)) then
			task.spawn(Library.Toggle)
		end
	end))

	if Config.AutoShow then task.spawn(Library.Toggle) end

	Window.Holder = Outer;

	return Window;
end;

local function OnPlayerChange()
	local PlayerList = GetPlayersString();

	for _, Value in next, Options do
		if Value.Type == 'Dropdown' and Value.SpecialType == 'Player' then
			Value:SetValues(PlayerList);
		end;
	end;
end;

Players.PlayerAdded:Connect(OnPlayerChange);
Players.PlayerRemoving:Connect(OnPlayerChange);
getgenv().Library = Library;
return Library
