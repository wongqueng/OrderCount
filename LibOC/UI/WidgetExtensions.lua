-- ------------------------------------------------------------------------------ --
--                                OrderCount                                --
--                          https://tradeskillmaster.com                          --
--    All Rights Reserved - Detailed license information included with addon.     --
-- ------------------------------------------------------------------------------ --

local OC = select(2, ...) ---@type OC
local WidgetExtensions = OC.Init("UI.WidgetExtensions")
local Theme = OC.Include("Util.Theme")
local TextureAtlas = OC.Include("Util.TextureAtlas")
local ScriptWrapper = OC.Include("Util.ScriptWrapper")
local private = {
	extensions = nil,
	cancellables = {},
}



-- ============================================================================
-- Default Extensions
-- ============================================================================

private.extensions = {
	_base = {
		OCSetShown = function(obj, shown)
			if shown then
				obj:Show()
			else
				obj:Hide()
			end
		end,
		OCSetSize = function(obj, width, height)
			obj:SetWidth(width)
			obj:SetHeight(height)
		end,
		OCSetPoints = function(obj, points)
			obj:ClearAllPoints()
			for _, point in ipairs(points) do
				obj:SetPoint(unpack(point))
			end
		end,
		OCSetScript = function(obj, script, handler, ...)
			if type(handler) == "function" then
				ScriptWrapper.Set(obj, script, handler, ...)
			elseif handler == nil then
				ScriptWrapper.Clear(obj, script)
			end
		end,
		OCSetOnUpdate = function(obj, handler, ...)
			obj:OCSetScript("OnUpdate", handler, ...)
		end,
		OCCancelAll = function(obj)
			if not private.cancellables[obj] then
				return
			end
			for _, cancellable in pairs(private.cancellables[obj]) do
				cancellable:Cancel()
			end
			wipe(private.cancellables[obj])
		end,
		_OCSetOrUpdateCancellable = function(obj, key, publisher)
			private.cancellables[obj] = private.cancellables[obj] or {}
			if private.cancellables[obj][key] then
				private.cancellables[obj][key]:Cancel()
			end
			private.cancellables[obj][key] = publisher
			publisher:Stored()
		end
	},
	Frame = {
		_OCSetBackdropColor = function(frame, color)
			frame:SetBackdropColor(color:GetFractionalRGBA())
		end,
		OCSubscribeBackdropColor = function(texture, color)
			texture:_OCSetOrUpdateCancellable("backdropColor", Theme.GetPublisher(color)
				:CallMethod(texture, "_OCSetBackdropColor")
			)
		end,
	},
	Button = {
		OCSetEnabled = function(button, enabled)
			if enabled then
				button:Enable()
			else
				button:Disable()
			end
		end,
		OCSetHighlightLocked = function(button, locked)
			if locked then
				button:LockHighlight()
			else
				button:UnlockHighlight()
			end
		end,
	},
	Texture = {
		_OCSetColorTexture = function(texture, color)
			texture:SetColorTexture(color:GetFractionalRGBA())
		end,
		OCSubscribeColorTexture = function(texture, color)
			texture:_OCSetOrUpdateCancellable("colorTexture", Theme.GetPublisher(color)
				:CallMethod(texture, "_OCSetColorTexture")
			)
		end,
		_OCSetVertexColor = function(texture, color)
			texture:SetVertexColor(color:GetFractionalRGBA())
		end,
		OCSubscribeVertexColor = function(texture, color)
			texture:_OCSetOrUpdateCancellable("vertexColor", Theme.GetPublisher(color)
				:CallMethod(texture, "_OCSetVertexColor")
			)
		end,
		OCSetTextureAndSize = function(texture, atlasKey)
			TextureAtlas.SetTextureAndSize(texture, atlasKey)
		end,
		OCSetTextureAndCoord = function(texture, value)
			if type(value) == "string" and TextureAtlas.IsValid(value) then
				TextureAtlas.SetTexture(texture, value)
			else
				texture:SetTexture(value)
				texture:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
			end
		end,
		OCSetSize = function(texture, widthOrAtlasKey, height)
			if type(widthOrAtlasKey) == "string" then
				assert(height == nil)
				TextureAtlas.SetSize(texture, widthOrAtlasKey)
			else
				texture:SetWidth(widthOrAtlasKey)
				texture:SetHeight(height)
			end
		end,
	},
	FontString = {
		_OCSetTextColor = function(text, color)
			text:SetTextColor(color:GetFractionalRGBA())
		end,
		OCSubscribeTextColor = function(text, color)
			text:_OCSetOrUpdateCancellable("textColor", Theme.GetPublisher(color)
				:CallMethod(text, "_OCSetTextColor")
			)
		end,
		OCSetFont = function(text, font)
			if type(font) == "string" then
				font = Theme.GetFont(font)
			end
			text:SetFont(font:GetWowFont())
		end,
	},
	AnimationGroup = {
		OCSetPlaying = function(ag, playing)
			if playing then
				ag:Play()
			else
				ag:Stop()
			end
		end,
	},
	EditBox = {
		OCSetEnabled = function(editbox, enabled)
			if enabled then
				editbox:Enable()
			else
				editbox:Disable()
			end
		end,
		_OCSetTextColor = function(editbox, color)
			editbox:SetTextColor(color:GetFractionalRGBA())
		end,
		OCSubscribeTextColor = function(texture, color)
			texture:_OCSetOrUpdateCancellable("textColor", Theme.GetPublisher(color)
				:CallMethod(texture, "_OCSetTextColor")
			)
		end,
		OCSetFont = function(editbox, font)
			if type(font) == "string" then
				font = Theme.GetFont(font)
			end
			editbox:SetFont(font:GetWowFont())
		end,
		OCSetFocused = function(editbox, focused)
			if focused then
				editbox:SetFocus()
			else
				editbox:ClearFocus()
			end
		end,
		OCSetAllHighlighted = function(editbox, highlighted)
			if highlighted then
				editbox:HighlightText(0, -1)
			else
				editbox:HighlightText(0, 0)
			end
		end,
	},
}



-- ============================================================================
-- Module Functions
-- ============================================================================

---Adds all registered extensions to an object.
---@param obj table The widget object
function WidgetExtensions.AddToObject(obj)
	local extensions = private.extensions[obj:GetObjectType()]
	if extensions then
		for name, func in pairs(extensions) do
			assert(not obj[name])
			obj[name] = func
		end
	end
	for name, func in pairs(private.extensions._base) do
		if not obj[name] then
			obj[name] = func
		end
	end
end
