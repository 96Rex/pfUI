--GUI命令
SLASH_PFUI1 = '/pfui'
function SlashCmdList.PFUI(msg, editbox)
	if pfUI.gui:IsShown() then
		pfUI.gui:Hide()
	else
		pfUI.gui:Show()
	end
end

pfUI = CreateFrame("Frame", nil, UIParent)
pfUI:RegisterEvent("ADDON_LOADED")

-- 设置启动变量
pfUI.bootup = true

-- 初始化保存的变量
pfUI_playerDB = {}
pfUI_config = {}
pfUI_init = {}
pfUI_profiles = {}
pfUI_addon_profiles = {}
pfUI_cache = {}

-- 本地化
pfUI_locale = {}
pfUI_translation = {}

-- 初始化默认的变量
pfUI.cache = {}
pfUI.module = {}
pfUI.modules = {}
pfUI.skin = {}
pfUI.skins = {}
pfUI.environment = {}
pfUI.movables = {}
pfUI.version = {}
pfUI.hooks = {}
pfUI.env = {}

-- 插件基础路径
pfUI.name = "pfUI"--记得290引用了 该变量最终要删除
pfUI.path = "Interface\\AddOns\\pfUI"

-- 处理和转换媒体文件(图片/字体/其他)路径
pfUI.media = setmetatable({}, { __index = function(tab,key)
	local value = tostring(key)
	if strfind(value, "img:") then
		value = string.gsub(value, "img:", pfUI.path .. "\\img\\")
	elseif strfind(value, "font:") then
		value = string.gsub(value, "font:", pfUI.path .. "\\fonts\\")
	else
		value = string.gsub(value, "Interface\\AddOns\\pfUI\\", pfUI.path .. "\\")
	end
	rawset(tab,key,value)
	return value
end})

-- 设置客户端版本
pfUI.expansion = "vanilla"
pfUI.client = 11200

-- 设置命名空间(让 pfUI.env 可以访问全局环境)
setmetatable(pfUI.env, {__index = getfenv(0)})

-- 设置职业颜色
function pfUI:UpdateColors()

	RAID_CLASS_COLORS = {
		["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, colorStr = "ffc79c6e" },
		["MAGE"]    = { r = 0.41, g = 0.8,  b = 0.94, colorStr = "ff69ccf0" },
		["ROGUE"]   = { r = 1,    g = 0.96, b = 0.41, colorStr = "fffff569" },
		["DRUID"]   = { r = 1,    g = 0.49, b = 0.04, colorStr = "ffff7d0a" },
		["HUNTER"]  = { r = 0.67, g = 0.83, b = 0.45, colorStr = "ffabd473" },
		["SHAMAN"]  = { r = 0.14, g = 0.35, b = 1.0,  colorStr = "ff0070de" },
		["PRIEST"]  = { r = 1,    g = 1,    b = 1,    colorStr = "ffffffff" },
		["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, colorStr = "ff9482c9" },
		["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, colorStr = "fff58cba" },
	}
	--如果无法判断职业则使用灰色
	RAID_CLASS_COLORS = setmetatable(RAID_CLASS_COLORS, { __index = function(tab,key)
		return { r = 0.6,  g = 0.6,  b = 0.6,  colorStr = "ff999999" }
	end})

end

function pfUI:UpdateFonts()
	-- 检查配置是否就绪
	if not pfUI_config or not pfUI_config.global then return end

	-- 区域兼容字体路径
	local default, tooltip, unit, unit_name, combat

	default = pfUI.media[pfUI_config.global.font_default]
	tooltip = pfUI.media[pfUI_config.tooltip.font_tooltip]
	combat = pfUI.media[pfUI_config.global.font_combat]
	unit = pfUI.media[pfUI_config.global.font_unit]
	unit_name = pfUI.media[pfUI_config.global.font_unit_name]

	-- 写入到全局变量
	pfUI.font_default = default
	pfUI.font_combat = combat
	pfUI.font_unit = unit
	pfUI.font_unit_name = unit_name

	-- 启用原生字体时,跳过字体设置
	if pfUI_config.global.font_blizzard == "1" then
		return
	end

	-- 设置游戏字体
	STANDARD_TEXT_FONT = default
	DAMAGE_TEXT_FONT   = combat
	NAMEPLATE_FONT     = default
	UNIT_NAME_FONT     = unit_name

	-- 设置下拉菜单中字体的默认大小
	UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 11

	-- 改变游戏字体的样式
	SystemFont:SetFont(default, 15)
	GameFontNormal:SetFont(default, 12)
	GameFontBlack:SetFont(default, 12)
	GameFontNormalSmall:SetFont(default, 11)
	GameFontNormalLarge:SetFont(default, 16)
	GameFontNormalHuge:SetFont(default, 20)
	NumberFontNormal:SetFont(default, 14, "OUTLINE")
	NumberFontNormalSmall:SetFont(default, 14, "OUTLINE")
	NumberFontNormalLarge:SetFont(default, 16, "OUTLINE")
	NumberFontNormalHuge:SetFont(default, 30, "OUTLINE")
	QuestTitleFont:SetFont(default, 18)
	QuestFont:SetFont(default, 13)
	QuestFontHighlight:SetFont(default, 14)
	ItemTextFontNormal:SetFont(default, 15)
	MailTextFontNormal:SetFont(default, 15)
	SubSpellFont:SetFont(default, 12)
	DialogButtonNormalText:SetFont(default, 16)
	ZoneTextFont:SetFont(default, 34, "OUTLINE")
	SubZoneTextFont:SetFont(default, 24, "OUTLINE")
	GameTooltipText:SetFont(tooltip, pfUI_config.tooltip.font_tooltip_size)
	GameTooltipTextSmall:SetFont(tooltip, pfUI_config.tooltip.font_tooltip_size)
	GameTooltipHeaderText:SetFont(tooltip, pfUI_config.tooltip.font_tooltip_size + 1)
	WorldMapTextFont:SetFont(default, 102, "THICK")
	InvoiceTextFontNormal:SetFont(default, 12)
	InvoiceTextFontSmall:SetFont(default, 12)
	CombatTextFont:SetFont(combat, 25)
	ChatFontNormal:SetFont(default, 13, pfUI_config.chat.text.outline == "1" and "OUTLINE")
    TextStatusBarTextSmall:SetFont(default, 12, "NORMAL")
end

-- 本地化对象
local translations

-- 创建沙盒
function pfUI:GetEnvironment()
	-- 载入API到沙盒
	for m, func in pairs(pfUI.api or {}) do
		pfUI.env[m] = func
	end
	-- 设置翻译表
	if pfUI_config and pfUI_config.global and pfUI_config.global.language and not translations then
		local lang = pfUI_config and pfUI_config.global and pfUI_config.global.language and pfUI_translation[pfUI_config.global.language] and pfUI_config.global.language or GetLocale()
		pfUI.env.T = setmetatable(pfUI_translation[lang] or {}, { __index = function(tab,key)
			local value = tostring(key)
			rawset(tab,key,value)
			return value
		end})
		translations = true
	end
	-- 注入全局变量和快捷方式
	pfUI.env._G = getfenv(0)
	pfUI.env.C = pfUI_config
	pfUI.env.L = (pfUI_locale[GetLocale()] or pfUI_locale["enUS"])
	-- 返回沙盒对象
	return pfUI.env
end

-- 注册模块方法
function pfUI:RegisterModule(name, func)
	if pfUI.module[name] then return end

	pfUI.module[name] = func
	table.insert(pfUI.modules, name)
	if not pfUI.bootup then
		pfUI:LoadModule(name)
	end
end

-- 注册皮肤方法
function pfUI:RegisterSkin(name, func)
	if pfUI.skin[name] then return end

	pfUI.skin[name] = func
	table.insert(pfUI.skins, name)
	if not pfUI.bootup then
		pfUI:LoadSkin(name)
	end
end
-- 加载模块方法
function pfUI:LoadModule(m)
	setfenv(pfUI.module[m], pfUI:GetEnvironment())
	pfUI.module[m]()
end
-- 加载皮肤方法
function pfUI:LoadSkin(s)
	setfenv(pfUI.skin[s], pfUI:GetEnvironment())
	pfUI.skin[s]()
end
-- 入口方法
pfUI:SetScript("OnEvent", function()
	-- 每次事件都更新颜色
	pfUI:UpdateColors()

	-- 启动完成后更新字体
	if not pfUI.bootup then
		pfUI:UpdateFonts()
	end

	if arg1 == pfUI.name then
		-- 从toc文件读取版本号
		local major, minor, fix = pfUI.api.strsplit(".", tostring(GetAddOnMetadata(pfUI.name, "Version")))
		pfUI.version.major = tonumber(major) or 1
		pfUI.version.minor = tonumber(minor) or 2
		pfUI.version.fix   = tonumber(fix)   or 0
		pfUI.version.string = pfUI.version.major .. "." .. pfUI.version.minor .. "." .. pfUI.version.fix

		-- 在新安装时使用"Modern"作为默认配置文件
		if pfUI.api.isempty(pfUI_init) and pfUI.api.isempty(pfUI_config) then
			pfUI_config = pfUI.api.CopyTable(pfUI_profiles["Modern"]) or {}
		end

		pfUI:LoadConfig()
		pfUI:MigrateConfig()
		pfUI:UpdateFonts()

		-- 加载所有模块
		for _, m in pairs(this.modules) do
			if not ( pfUI_config["disabled"] and pfUI_config["disabled"][m]  == "1" ) then
				pfUI:LoadModule(m)
			end
		end

		-- 加载所有皮肤
		for _, s in pairs(this.skins) do
			if not ( pfUI_config["disabled"] and pfUI_config["disabled"]["skin_" .. s]  == "1" ) then
				pfUI:LoadSkin(s)
			end
		end

		pfUI.bootup = nil
	end
end)

-- 背景(内嵌边框1px)
pfUI.backdrop = {
	bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
	edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
	insets = {left = -1, right = -1, top = -1, bottom = -1},
}

-- 无顶背景
pfUI.backdrop_no_top = pfUI.backdrop

-- 背景(外接边框)
pfUI.backdrop_thin = {
	bgFile = "Interface\\BUTTONS\\WHITE8X8", tile = false, tileSize = 0,
	edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 1,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

-- 边框(悬浮效果)
pfUI.backdrop_hover = {
	edgeFile = "Interface\\BUTTONS\\WHITE8X8", edgeSize = 24,
	insets = {left = -1, right = -1, top = -1, bottom = -1},
}

-- 屏边显示
pfUI.backdrop_shadow = {
	edgeFile = pfUI.media["img:glow2"], edgeSize = 8,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

-- 暴雪背景
pfUI.backdrop_blizz_bg = {
	bgFile =  "Interface\\BUTTONS\\WHITE8X8", tile = true, tileSize = 8,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- 暴雪边框
pfUI.backdrop_blizz_border = {
	edgeFile = pfUI.media["img:border_blizz"], edgeSize = 6,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- 暴雪背景+暴雪边框
pfUI.backdrop_blizz_full = {
	bgFile =  "Interface\\BUTTONS\\WHITE8X8", tile = true, tileSize = 8,
	edgeFile = pfUI.media["img:border_blizz"], edgeSize = 6,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

-- 打印覆盖
message = function(msg)
	DEFAULT_CHAT_FRAME:AddMessage("|cffcccc33INFO: |cffffff55" .. ( msg or "nil" ))
end
print = print or message

-- 调试模式
error = function(msg)
	if PF_DEBUG_MODE then message(debugstack()) end
	if string.find(msg, "AddOns\\pfUI") then
		DEFAULT_CHAT_FRAME:AddMessage("|cffcc3333ERROR: |cffff5555".. (msg or "nil" ))
	elseif not pfUI_config or (pfUI_config.global and pfUI_config.global.errors == "1") then
		DEFAULT_CHAT_FRAME:AddMessage("|cffcc3333ERROR: |cffff5555".. (msg or "nil" ))
	end
end
seterrorhandler(error)

-- OOBE时对游戏的优化内容
function pfUI.SetupCVars()
	-- 关闭教程提示
	ClearTutorials()
	TutorialFrame_HideAllAlerts()
	-- 调整相机距离
	ConsoleExec("CameraDistanceMaxFactor 5")
	-- 自动自我施法
	SetCVar("autoSelfCast", "1")
	-- 关闭脏话过滤
	SetCVar("profanityFilter", "0")
	-- 显示所有动作条
	MultiActionBar_ShowAllGrids()
	ALWAYS_SHOW_MULTIBARS = "1"
	
	-- 显示增益时间
	SHOW_BUFF_DURATIONS = "1"
	-- 禁用任务文本淡出
	QUEST_FADING_DISABLE = "1"
	-- 启用姓名板
	NAMEPLATES_ON = "1"
	-- 禁用简单聊天
	SIMPLE_CHAT = "0"
end
