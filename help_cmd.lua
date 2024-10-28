COMMANDS = {}
SORTED_COMMANDS = {}
BUILTIN_COMMANDS = {
	print = true,
	error = true,
	sleep = true,
	systime = true,
	sysdate = true,
	time = true,
}

local allow_text_fmt = true

--Don't include these tags in length calculation if text formatting is allowed
local open_tags = {
	"color=[^>|]+", --colors (invalid color names / codes are UB)
	"size=[^>|]+", --custom size
	"sup", --superscript
	"sub", --subscript
	"[ibus]", --italic, bold, underline, strikethrough
	"align=left",
	"align=right",
	"align=center",
	"cspace=[^>|]+",
	"line-height=[^>|]+", --height in pixels
	"line-indent=[^>|]+", --indent in pixels (every time this tag occurs)
	"lowercase", --converts text to lowercase
	"uppercase", --converts text to uppercase
	"smallcaps", --small uppercase???
	"margin=[^>|]+", --same as line-indent but only once per line.
	"mark=[^>|]+", --highlight text
	"mspace=[^>|]+", --override font spacing!!!!
	"nobr",
	"page", --no closing tag
	"pos=[^>|]+",
	"space=[^>|]+",
	"sprite[^>|]+", --emojis. all the same width! no closing tag
	"voffset=[^>|]+",
	"width=[^>|]+", --override max width
}

local close_tags = {
	"color",
	"size",
	"sup",
	"sub",
	"[ibus]",
	"align",
	"align",
	"cspace",
	"line-height",
	"line-indent",
	"lowercase",
	"uppercase",
	"smallcaps",
	"margin",
	"mark",
	"mspace",
	"nobr",
	"pos",
	"space",
	"voffset",
	"width",
}

local glyphs = {
	["\r"]=0.24752000000000002,
	[" "]=0.24752000000000002,
	["!"]=0.36816000000000004,
	["\""]=0.37856, --"
	["#"]=0.92248,
	["$"]=0.68016,
	["%"]=0.86216,
	["&"]=0.80912,
	["'"]=0.2028,
	["("]=0.5044000000000001,
	[")"]=0.5044000000000001,
	["*"]=0.53872,
	["+"]=0.70096,
	[","]=0.26416,
	["-"]=0.6063200000000001,
	["."]=0.27040000000000003,
	["/"]=0.50544,
	["0"]=0.67184,
	["1"]=0.37648000000000004,
	["2"]=0.59696,
	["3"]=0.6229600000000001,
	["4"]=0.68744,
	["5"]=0.66976,
	["6"]=0.6656,
	["7"]=0.5699200000000001,
	["8"]=0.66872,
	["9"]=0.6510400000000001,
	[":"]=0.27352,
	[";"]=0.33696000000000004,
	["<"]=0.60736,
	["="]=0.76752,
	[">"]=0.5896800000000001,
	["?"]=0.55952,
	["@"]=1.09304,
	["A"]=0.74464,
	["B"]=0.66872,
	["C"]=0.79872,
	["D"]=0.74568,
	["E"]=0.55328,
	["F"]=0.5512,
	["G"]=0.79872,
	["H"]=0.74568,
	["I"]=0.28912,
	["J"]=0.5928000000000001,
	["K"]=0.68952,
	["L"]=0.47736,
	["M"]=0.93496,
	["N"]=0.7644,
	["O"]=0.8164,
	["P"]=0.6323200000000001,
	["Q"]=0.81848,
	["R"]=0.66664,
	["S"]=0.63336,
	["T"]=0.6000800000000001,
	["U"]=0.72488,
	["V"]=0.7394400000000001,
	["W"]=1.0649600000000001,
	["X"]=0.7134400000000001,
	["Y"]=0.66144,
	["Z"]=0.59904,
	["["]=0.51688,
	["\\"]=0.78624,
	["]"]=0.5158400000000001,
	["^"]=0.7072,
	["_"]=0.8216,
	["`"]=0.28184000000000003,
	["a"]=0.70512,
	["b"]=0.70512,
	["c"]=0.6260800000000001,
	["d"]=0.70512,
	["e"]=0.64168,
	["f"]=0.3588,
	["g"]=0.70512,
	["h"]=0.68744,
	["i"]=0.28912,
	["j"]=0.28912,
	["k"]=0.60736,
	["l"]=0.28912,
	["m"]=1.08992,
	["n"]=0.68744,
	["o"]=0.66352,
	["p"]=0.70512,
	["q"]=0.70512,
	["r"]=0.42016000000000003,
	["s"]=0.5668000000000001,
	["t"]=0.40352000000000005,
	["u"]=0.68744,
	["v"]=0.6229600000000001,
	["w"]=0.87776,
	["x"]=0.5616,
	["y"]=0.6292000000000001,
	["z"]=0.50232,
	["{"]=0.52832,
	["|"]=0.32136000000000003,
	["}"]=0.52832,
	["~"]=0.6156800000000001,
	[" "]=0.24752000000000002,
	["¡"]=0.36816000000000004,
	["¢"]=0.68952,
	["£"]=0.68016,
	["¤"]=0.5834400000000001,
	["¥"]=0.66144,
	["¦"]=0.364,
	["§"]=0.6052799999999999,
	["¨"]=0.35152000000000005,
	["©"]=0.8164,
	["ª"]=0.48048,
	["«"]=0.54184,
	["¬"]=0.70824,
	["­"]=0.6063200000000001,
	["®"]=0.53664,
	["¯"]=0.41808000000000006,
	["°"]=0.46176,
	["±"]=0.7030400000000001,
	["²"]=0.3744,
	["³"]=0.37128000000000005,
	["´"]=0.26,
	["µ"]=0.70512,
	["¶"]=0.69264,
	["·"]=0.2808,
	["¸"]=0.3068,
	["¹"]=0.23712,
	["º"]=0.468,
	["»"]=0.54184,
	["¼"]=0.7592000000000001,
	["½"]=0.78728,
	["¾"]=0.8434400000000001,
	["¿"]=0.55952,
	["À"]=0.74464,
	["Á"]=0.74464,
	["Â"]=0.74464,
	["Ã"]=0.74464,
	["Ä"]=0.74464,
	["Å"]=0.74464,
	["Æ"]=0.97448,
	["Ç"]=0.79872,
	["È"]=0.55328,
	["É"]=0.55328,
	["Ê"]=0.55328,
	["Ë"]=0.55328,
	["Ì"]=0.28912,
	["Í"]=0.28912,
	["Î"]=0.28912,
	["Ï"]=0.28912,
	["Ð"]=0.75504,
	["Ñ"]=0.7644,
	["Ò"]=0.8164,
	["Ó"]=0.8164,
	["Ô"]=0.8164,
	["Õ"]=0.8164,
	["Ö"]=0.8164,
	["×"]=0.6968000000000001,
	["Ø"]=0.8164,
	["Ù"]=0.72488,
	["Ú"]=0.72488,
	["Û"]=0.72488,
	["Ü"]=0.72488,
	["Ý"]=0.66144,
	["Þ"]=0.6323200000000001,
	["ß"]=0.7560800000000001,
	["à"]=0.70512,
	["á"]=0.70512,
	["â"]=0.70512,
	["ã"]=0.70512,
	["ä"]=0.70512,
	["å"]=0.70512,
	["æ"]=1.12008,
	["ç"]=0.6260800000000001,
	["è"]=0.64168,
	["é"]=0.64168,
	["ê"]=0.64168,
	["ë"]=0.64168,
	["ì"]=0.30160000000000003,
	["í"]=0.30160000000000003,
	["î"]=0.30160000000000003,
	["ï"]=0.30160000000000003,
	["ð"]=0.66352,
	["ñ"]=0.68744,
	["ò"]=0.66352,
	["ó"]=0.66352,
	["ô"]=0.66352,
	["õ"]=0.66352,
	["ö"]=0.66352,
	["÷"]=0.6739200000000001,
	["ø"]=0.6593600000000001,
	["ù"]=0.68744,
	["ú"]=0.68744,
	["û"]=0.68744,
	["ü"]=0.68744,
	["ý"]=0.6292000000000001,
	["þ"]=0.70512,
	["ÿ"]=0.6292000000000001,
	[""]=1.11488,
	[""]=1.09408,
	[""]=0.63336,
	[""]=0.5668000000000001,
	[""]=0.66144,
	[""]=0.59904,
	[""]=0.50232,
	[""]=0.34736,
	[""]=0.32968000000000003,
	[""]=0.39624000000000004,
	[""]=0.7300800000000001,
	[""]=0.96408,
	[""]=0.286,
	[""]=0.286,
	[""]=0.26104,
	[""]=0.49608,
	[""]=0.49608,
	[""]=0.47216,
	[""]=0.64168,
	[""]=0.64168,
	[""]=0.49920000000000003,
	[""]=0.7228000000000001,
	[""]=1.1606400000000001,
	[""]=0.32864,
	[""]=0.32864,
	[""]=0.83096,
	[""]=0.87776,
}

local function char_width(char)
	if glyphs[char] ~= nil then
		return glyphs[char]
	else
		--If an unknown glyph, return the average of all glyph widths.
		--That way it should at least be close to correct.
		return 0.61105936073059
	end
end

local function text_width(text)
	local total_width = 0
	local i = 0
	while i < #text do
		i = i + 1

		local this_char = text:sub(i,i)
		local skip_this = false
		if allow_text_fmt and this_char == "<" then
			--Check for format tags
			local match = nil
			if text:sub(i+1,i+1) == "/" then
				--closing tags
				for _, tag in pairs(close_tags) do
					match = text:match(tag..">", i+1)
					if match ~= nil then i = i + 2; break end
				end
			else
				--opening tags
				for _, tag in pairs(open_tags) do
					match = text:match(tag..">", i+1)
					if match ~= nil then i = i + 1; break end
				end
			end

			if match ~= nil then
				i = i + #match - 1
				skip_this = true
			end
		end

		if not skip_this then
			total_width = total_width + char_width(this_char)
		end
	end
	return total_width
end


if not output then output = function(text) print(text) end end
if not output_array then output_array = function(array)
	print('[') for i = 1, #array do print('  '..array[i]) end print(']')
end end

function ADD_CMDS(new_cmds)
	local valid_cmds = {}

	for _, cmd_text in ipairs(new_cmds) do
		local items = {}
		for str in cmd_text:gmatch("[^:]+") do
			table.insert(items, str)
		end
		COMMANDS[items[1]] = {
			name = items[1],
			value = items[2] or "any",
			help = items[3] or "",
			width = text_width(items[1]),
		}
	end
	
	SORTED_COMMANDS = {}
	for name, cmd in pairs(COMMANDS) do
		table.insert(SORTED_COMMANDS, name)
		if not BUILTIN_COMMANDS[name] then table.insert(valid_cmds, name..":"..cmd.value) end
	end
	table.sort(SORTED_COMMANDS)

	output_array(valid_cmds, 1)
end

ADD_CMDS({
	"clear:null:Clears the screen.",
	"help:null:Displays help text about commands.",
	"play:boolean:Plays a sound from the Plasma sound library. The sound EMPTY will stop playback. Returns true if a valid sound is given, false otherwise.",
	"beep:null:Plays a beep on the speaker.",
	"shutdown:null:Turns off the computer.",
	"print:null:Takes any number of parameters and prints them to the screen.",
	"error:null:Takes any number of parameters and prints them to the screen, with error flavor text.",
	"sleep:null:Pauses execution for the given number of seconds.",
	"systime:number:Gets the IRL time.\n(seconds since midnight)",
	"sysdate:array[number]:Gets the IRL date.\n(day, month, year)",
	"time:number:Gets the in-game time.\n(seconds since midnight)",
	"reboot:null:Reboots the computer.",
	"nfc:any:Read data from an NFC tag.\n<color=yellow>`nfc [CHANNEL]`</color>.\nIf channel is not specified, the channel stays at the current value. Returns the read data, or null on failure.",
	"nfcwrite:null:Write data to an NFC tag.\n<color=yellow>`nfcwrite [DATA] [CHANNEL]`</color>.\nIf channel is not specified, the channel stays at the current value."
})

local function color(text, text_color) return "<color="..text_color..">"..text.."</color"..">" end
local function size(text, text_size) return "<size="..text_size..">"..text.."</size"..">" end
local function italic(text) return "<".."i>"..text.."</i"..">" end
local function bold(text) return "<".."b>"..text.."</b"..">" end
local function indent(text) return "<indent=10%"..">"..text.."</indent"..">" end

function PAGE()
	--Max 12 items per page
	local col_width = 10
	local row_count = 6
	local col_count = 2
	local items_per_page = row_count * col_count

	--Get the page number, and make sure it's within the bounds
	local page = V1
	if type(page) ~= "number" then page = 1 end
	local page_ct = math.ceil(#SORTED_COMMANDS / items_per_page)
	page = math.min(page_ct, math.max(1, math.floor(page))) - 1

	--Organize this page into rows and columns
	local beg = page * items_per_page
	if beg + items_per_page > #SORTED_COMMANDS then
		items_per_page = #SORTED_COMMANDS - beg
	end

	local page_offset = math.ceil(items_per_page / col_count)
	local rows = {}

	--This math was a pain to get right.
	--Basically it makes the commands be sorted by COLUMN, not row.
	for i = 0, items_per_page - 1 do
		local col = i % col_count
		local row = math.floor(i / col_count)

		local index = i % col_count * (page_offset) + row + beg + 1
		row = row + 1
		col = col + 1

		if not rows[row] then rows[row] = {} end
		rows[row][col] = SORTED_COMMANDS[index]
	end

	local result = color("\nAvailable Commands (" .. (page + 1) .. "/" .. page_ct .. ")\n", "lightblue")
	for row = 1, #rows do

		--Print the row, calculating the width each line should be.
		local line = ""
		for col = 1, #rows[row] - 1 do
			local cmd_name = rows[row][col]
			local pad_ct = (col_width - COMMANDS[cmd_name].width) / char_width(" ")
			line = line .. cmd_name .. string.rep(" ", pad_ct)
		end
		result = result .. line .. rows[row][#rows[row]] .. "\n" --append the last item
	end

    --Pad extra lines to make output consistent
    for i = #rows, row_count - 1 do
        result = result .. "\n"
    end

	result = result .. "<line-height=50%>\n</line-height>" .. size("Run "..color("`help {page}`", "yellow").." to list more commands.", "80%")
	result = result .. "\n" .. size("Run "..color("`help {command}`", "yellow").." for detailed command info.", "80%")
	result = result .. "\n" .. size("Run "..color("`help terminal`", "yellow").." for terminal info.", "80%")

	output(result, 2)
end

function INFO()
	local name = V1 or ""
	local cmd = COMMANDS[name]

	if cmd then
		local typecolor = "green"
		if cmd.value == "null" then typecolor = "grey" end
		output(color(name, "yellow").."\n"..indent(cmd.help.."\nReturns: "..color(cmd.value, typecolor)), 2)
	else
		output(color("ERROR:", "#E58357").." No help text found for `"..name.."`.", 2)
	end
end

function APPEND()
	local new_cmds = V1
	if type(new_cmds) ~= 'table' then return end
	ADD_CMDS(new_cmds)
end
