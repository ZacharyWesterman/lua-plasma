FS = {
    dir = 0,
    file = 1,
}

FILESYSTEM = {
    name = '/',
    parent = nil,
    type = FS.dir,
    contents = {},
}

local function mkfs(path_names, filename, file_contents)
    local fs_item = FILESYSTEM
    for i = 1, #path_names do
        local name = path_names[i]
        if not fs_item.contents[name] then
            local new_fs_item = {
                name = name,
                parent = fs_item,
                type = FS.dir,
                contents = {},
            }
            fs_item.contents[name] = new_fs_item
        end
        fs_item = fs_item.contents[name]
    end

    if filename then
        if not file_contents then file_contents = '' end
        fs_item.contents[filename] = {
            name = filename,
            parent = fs_item,
            type = FS.file,
            contents = file_contents,
        }
    end
end

--Make built-in syntax highlighting files.
mkfs({ 'etc', 'syntax' }, 'theme.lua', [[
--Color scheme used to highlight syntax.
theme = {
    variable = {"color", "#d0e0ff"},
    special_var = {{"color", "#d0e0ff"}, {"i"}},
    escape = {"color", "#e2c868"},
    literal = {"color", "#2580da"},
    string = {"color", "#ddb13f"},
    keyword = {"color", "#9654ab"},
    operator = {"color", "#6c9dc3"},
    number = {"color", "#d6b129"},
    punctuation = {"color", "#aaaaaa"},
    object = {"color", "#3ac5c2"},
    functions = {"color", "#e2c868"},
    special_functions = {"color", "#6c9dc3"},
    noformat = {"color", "white"},
    comment = {"color", "#777"},
}
]])

--Paisley syntax
mkfs({ 'etc', 'syntax', 'paisley' }, 'files.txt', '%.p$\n%.pai$\n%.paisley$')
mkfs({ 'etc', 'syntax', 'paisley' }, 'patterns.lua', [[
patterns = {
    comment = {
        pattern = "#.*$",
        display = "comment",
    },

    escape_char = {
        pattern = { "\\[nt\"\'\\r %{%}]", "\\%^%-%^", "\\:relaxed:", "\\:P", "\\:yum:", "\\<3", "\\:heart_eyes:", "\\B%)", "\\:sunglasses:", "\\:D", "\\:grinning:", "\\%^o%^", "\\:smile:", "\\XD", "\\:laughing:", "\\:lol:", "\\=D", "\\:smiley:", "\\:sweat_smile:", "\\DX", "\\:tired_face:", "\\;P", "\\:stuck_out_tongue_winking_eye:", "\\:%-%*", "\\;%-%*", "\\:kissing_heart:", "\\:kissing:", "\\:rofl:", "\\:%)", "\\:slight_smile:", "\\:%(", "\\:frown:", "\\:frowning:" },
        display = "escape",
        greedy = true,
    },

    param = {
        pattern = "[^ \t\n\r\"\'{};$]+", --"
        display = "param",         --Just use the same color I guess
    },
    param_num = {
        pattern = { "%d+%.%d*", "%d+", "%.%d+" },
        display = "number",
    },

    label = {
        pattern = "[a-zA-Z0-9_]+:",
        display = "special_functions",
    },

    --keywords
    kwd_1 = {
        --parser auto-detects if it's at a word boundary
        pattern = { "for", "in", "if", "elif", "while", "delete", "break", "cache", "continue", "define", "match", "return", "catch" },
        --apply coloring from theme.keyword
        display = "keyword",
        --change scope (so commands aren't highlighted)
        scope = "normal",
    },
    kwd_2 = {
        pattern = { "do", "then", "else", "end", "stop", "try" },
        display = "keyword",
        scope = "initial",
    },
    kwd_3 = {
        pattern = { "gosub", "break[ \\t]+cache" },
        display = "keyword",
        push = "lbl",
    },
    kwd_4 = {
        pattern = "subroutine",
        display = "keyword",
        push = "lbl",
    },
    expr_keywords = {
        pattern = { "if", "else" },
        display = "keyword",
    },
    expr_keywords2 = {
        pattern = "for",
        display = "keyword",
        push = "listcomp",
    },
    listcomp = {
        pattern = "in",
        display = "keyword",
        pop = true,
    },

    lbl = {
        pattern = "[^ \t\n\r\"\'{};$#]+",
        display = "special_functions",
        pop = true,
    },

    lambda = {
        pattern = "!+[a-zA-Z0-9_]*",
        display = "special_functions",
    },

    --variables look like {var}, {{var}}, {#var}, {#*}, {*} or any combination thereof
    expr_start = {
        pattern = "{",
        display = "punctuation",
        push = "expression",
    },

    expr_stop = {
        pattern = "}",
        display = "punctuation",
        pop = true,
    },

    operator = {
        pattern = { "and", "or", "not", "xor", "in", "[%+%-%*/%%:&><=,]", "~=", "!=", "exists", "like" },
        display = "operator",
    },

    variable = {
        pattern = { "[a-zA-Z_][a-zA-Z_0-9]*" },
        display = "variable",
    },

    var_special = {
        pattern = { "%$", "@%d*" },
        display = "special_var",
    },

    number = {
        pattern = { "0[xb][0-9_a-fA-F]*", "[0-9]*%.[0-9]+", "[0-9]+" },
        display = "number",
    },

    constant = {
        pattern = { "true", "false", "null" },
        display = "literal",
    },

    let = {
        pattern = { "let", "initial" },
        display = "keyword",
        scope = "let",
    },

    equals = {
        pattern = "=",
        display = "operator",
        scope = "normal",
    },

    inline_command = {
        pattern = "%$%{",
        display = "punctuation",
        push = "inl_command",
    },

    --command names cannot have spaces or equal signs, but any other characters are fine
    command = {
        pattern = "[^ \t\n\r\"\'{};$#]+",
        display = "object",
        scope = "normal", --change scope to this.
    },

    inl_command = {
        pattern = "[^ \t\n\r\"\'{};$#]+",
        display = "object",
        scope = "inline_cmd", --change scope to this.
    },

    endline = {
        pattern = "[;\n]",
        display = "punctuation",
        scope = "initial",
    },

    --Double-quoted strings: Parsing
    string_start = {
        pattern = "\"", --"
        display = "string",
        push = "string", --push this scope onto the stack, overriding global until it is popped off.
    },

    string_end = {
        pattern = "\"", --"
        pop = true, --pop this scope off the stack. afterwards (if there are no more scopes) revert to global scope.
    },

    --Single-quoted strings: NO parsing
    string2_start = {
        pattern = "'",
        display = "string",
        push = "string2",
    },

    string2_end = {
        pattern = "'",
        pop = true,
    },

    functions = {
        pattern = {"[%w_]+", "\\[^ \t\n\r\"\'{}();$#]+"},
        display = "functions",
        lookahead = " *%(",
    },
}
]])
mkfs({ 'etc', 'syntax', 'paisley' }, 'scopes.lua', [[
--Each "scope" has a list of patterns that will be highlighted.
scopes = {
    --This is a special scope that is the FIRST one visible when scope stack is empty
    --This global scope is visible IN ADDITION TO the current scope.
    global = {
        "comment",
        "kwd_3",
        "kwd_1",
        "kwd_2",
        "kwd_4",
        "expr_start",
        "string_start",
        "string2_start",
        "inline_command",
        "endline",
    },

    --This is a special scope that is set as the default when a line starts
    initial = {
        "let",
        "label",
        "command",
        "param_num",
        "param",
        "inline_command",
    },

    lbl = {
        "lbl",
    },

    lbl2 = {
        "lbl2",
    },

    normal = {
        "param_num",
        "param",
    },

    string = {
        "string_end",
        "expr_start",
        "escape_char",
        "inline_command",
    },

    string2 = {
        "string2_end",
        "escape_char",
    },

    expression = {
        "comment",
        "expr_keywords",
        "expr_keywords2",
        "escape_char",
        "string_start",
        "string2_start",
        "expr_stop",
        "operator",
        "number",
        "functions",
        "constant",
        "variable",
        "expr_start",
        "inline_command",
        "var_special",
        "lambda",
    },

    let = {
        "expr_start",
        "variable",
        "equals",
    },

    inl_command = {
        "kwd_3",
        "expr_stop",
        "inl_command",
        "expr_start",
        "string_start",
        "string2_start",
        "inline_command",
    },

    inline_cmd = {
        "expr_stop",
        "param_num",
        "param",
        "expr_start",
        "string_start",
        "string2_start",
        "inline_command",
    },

    listcomp = {
        "listcomp",
        "variable",
    },
}
]])

--Lua syntax
mkfs({ 'etc', 'syntax', 'lua' }, 'files.txt', '%.lua$')
mkfs({ 'etc', 'syntax', 'lua' }, 'patterns.lua', [[
patterns = {
    comment = {
        pattern = "%-%-.*$",
        display = "comment",
    },

    escape_char = {
        pattern = "\\.",
        display = "escape",
        greedy = true,
    },

    keyword = {
        pattern = {"for", "in", "if", "elseif", "else", "while", "break", "continue", "do", "then", "end", "until", "return", "repeat", "function", "local", "and", "or", "not"}, --parser auto-detects if it's at a word boundary
        display = "keyword", --apply coloring from theme.keyword
    },

    functions = {
        pattern = "[%w_]+",
        display = "functions",
        lookahead = " *%(",
    },

    special_functions = {
        pattern = {"print", "error", "output", "output_array", "V[12345678]", "read_var", "write_var"},
        display = "special_functions",
    },

    variable = {
        pattern = "[%w_]+",
        display = "variable",
    },

    typename = {
        pattern = {"true", "false", "nil"},
        display = "literal",
    },

    operator = {
        pattern = {"[%-+*/%%^#=><]", "~=", "%.%.%.?"},
        display = "operator",
    },

    number = {
        pattern = "%d[%w_%.]*",
        display = "number",
    },

    punctuation = {
        pattern = "[%[%]%(%)%{%};:,.]",
        display = "punctuation",
    },

    string_start = {
        pattern = "\"", --"
        display = "string",
        push = "string", --push this scope onto the stack, overriding global until it is popped off.
    },

    string_end = {
        pattern = "\"", --"
        pop = true, --pop this scope off the stack. afterwards (if there are no more scopes) revert to global scope.
    },

    string2_start = {
        pattern = "'",
        display = "string",
        push = "string2",
    },

    string2_end = {
        pattern = "'",
        pop = true,
    },
}
]])
mkfs({ 'etc', 'syntax', 'lua' }, 'scopes.lua', [[
--Each "scope" has a list of patterns that will be highlighted.
scopes = {
    --This is a special scope that is the FIRST one visible when scope stack is empty
    --This global scope is visible IN ADDITION TO the current scope.
    global = {
        "comment",
        "keyword",
        "typename",
        "number",
        "operator",
        "special_functions",
        "functions",
        "variable",
        "punctuation",
        "string_start",
        "string2_start",
    },

    --This is a special scope that is set as the default when a line starts
    initial = {},

    string = {
        "string_end",
        "escape_char",
    },

    string2 = {
        "string2_end",
        "escape_char",
    },
}
]])

--JSON syntax
mkfs({ 'etc', 'syntax', 'json' }, 'files.txt', '%.json$')
mkfs({ 'etc', 'syntax', 'json' }, 'patterns.lua', [[
patterns = {
    escape_char = {
        pattern = {"\\u....", "\\."},
        display = "escape",
        greedy = true,
    },

    literal = {
        pattern = {"true", "false", "null"},
        display = "literal",
    },

    number = {
        pattern = "%d[%d_%.]*",
        display = "number",
    },

    punctuation = {
        pattern = "[%[%]%{%}:,]",
        display = "punctuation",
    },

    string_start = {
        pattern = "\"", --"
        display = "string",
        push = "string", --push this scope onto the stack, overriding global until it is popped off.
    },

    string_end = {
        pattern = "\"", --"
        pop = true, --pop this scope off the stack. afterwards (if there are no more scopes) revert to global scope.
    },
}
]])
mkfs({ 'etc', 'syntax', 'json' }, 'scopes.lua', [[
--Each "scope" has a list of patterns that will be highlighted.
scopes = {
    --This is a special scope that is the FIRST one visible when scope stack is empty
    --This global scope is visible IN ADDITION TO the current scope.
    global = {},

    initial = {
        "punctuation",
        "string_start",
        "number",
        "literal"
    },

    string = {
        "escape_char",
        "string_end"
    }
}
]])

--XML syntax
mkfs({ 'etc', 'syntax', 'xml' }, 'files.txt', '%.xml$\n%.x?html?$\n%.pml$')
mkfs({ 'etc', 'syntax', 'xml' }, 'patterns.lua', [[
patterns = {
    comment = {
        pattern = {"<!%-%-.-%-%->", "<!%-%-.-$"}, --XML comments
        display = "comment",
    },

    tag_open = {
        pattern = "<",
        display = "punctuation",
        push = "in_tag",
    },

    tag_close = {
        pattern = ">",
        display = "punctuation",
        pop = true,
    },

    tag_slash = {
        pattern = "/",
        display = "punctuation",
    },

    entity = {
        pattern = "&%a+;",
        display = "escape",
    },

    tag_type = {
        pattern = "[^%s<>=/]+",
        display = "keyword",
        scope = "property",
    },

    property = {
        pattern = "[^%s<>=/]+",
        display = "functions",
        scope = "value",
    },

    value = {
        pattern = {"\"[^\"]*\"", "[^%s<>=/]+"},
        display = "string",
        scope = "property",
    },

    op_equals = {
        pattern = "=",
        display = "punctuation",
    },
}
]])
mkfs({ 'etc', 'syntax', 'xml' }, 'scopes.lua', [[
--Each "scope" has a list of patterns that will be highlighted.
scopes = {
    --This is a special scope that is the FIRST one visible when scope stack is empty
    --This global scope is visible IN ADDITION TO the current scope.
    global = {
        "comment",
        "entity",
    },

    --This is a special scope that is set as the default when a line starts
    initial = {
        "tag_open",
    },

    in_tag = {
        "tag_close",
        "tag_slash",
        "tag_type",
    },

    property = {
        "tag_close",
        "tag_slash",
        "property",
    },

    value = {
        "op_equals",
        "tag_close",
        "tag_slash",
        "value",
    },
}
]])

mkfs({ 'bin' })
mkfs({ 'home' }, 'README',
    "This filesystem has been pre-loaded with an example directory structure. Feel free to rearrange it to your heart's content!\nThough, you probably want to keep `/etc` as-is... it contains configuration files for syntax highlighting. <sprite=5>\n\n/bin: User scripts can be stored here.\n/etc: Config files can be stored here.\n/home: Everything else can be stored here.")
WORKING_DIR = '/home'

local function color(text, text_color) return '<color=' .. text_color .. '>' .. text .. '<' .. '/color>' end

local function file_error(msg)
    print(color('ERROR: ', '#E58357') .. msg)
end

local function get_fs_item(path, ignore_last, quiet)
    local dir, prev_dir = FILESYSTEM, nil
    if path:sub(1, 1) ~= '/' then dir = get_fs_item(WORKING_DIR) end

    for name in path:gsub('\\', '/'):gmatch('[^/]+') do
        if not dir or dir.type == FS.file then
            if not quiet then file_error('No such file `' .. path .. '`.') end
            return nil
        end

        prev_dir = dir
        if name == '..' then
            dir = dir.parent
        elseif name ~= '.' then
            dir = dir.contents[name]
        end
    end

    if ignore_last and prev_dir then dir = prev_dir end

    if not dir then
        if not quiet then file_error('No such file `' .. path .. '`.') end
        return nil
    end

    return dir
end

local function file_exists(path)
    local fs_item = get_fs_item(path, false, true)
    if not fs_item then return false end
    return fs_item.type == FS.file
end

local function get_fs_contents(path)
    local fs_item = get_fs_item(path, false, true)
    if not fs_item then return nil end
    return fs_item.contents
end

local function get_fs_full_path(fs_item)
    local path = fs_item.name

    while fs_item.parent do
        fs_item = fs_item.parent
        if fs_item.parent then path = fs_item.name .. '/' .. path end
    end

    if path:sub(1, 1) == '/' then return path else return '/' .. path end
end

local function get_fs_basename(path)
    local basename = path:match('[^/]*$')
    if not basename then
        basename = path:match('[^/]+/$')
        if basename then
            basename = basename:sub(1, #basename - 1)
        end
    end
    return basename
end

local function fs_deep_copy(parent_node, child_node)
    local result = {
        name = child_node.name,
        parent = parent_node,
        type = child_node.type,
    }

    if child_node.type == FS.file then
        result.contents = child_node.contents
    else
        result.contents = {}
        for key, value in pairs(child_node.contents) do
            result.contents[key] = fs_deep_copy(result, value)
        end
    end

    return result
end

local function command_return(value)
    if type(value) == 'table' then
        if #value == 0 then
            ---@diagnostic disable-next-line
            output(nil, 4)
        else
            ---@diagnostic disable-next-line
            output_array(value, 1)
        end
    else
        ---@diagnostic disable-next-line
        output(value, 1)
    end
end

local function run_paisley_script(script)
    ---@diagnostic disable-next-line
    output_array(script, 3)
end

local function run_lua_script(script_args)
    ---@diagnostic disable-next-line
    output_array(script_args, 6)
end

--[[
    Methods:
        json.parse(text) to parse a JSON string into data.
        json.stringify(data, [indent]) to convert data into a JSON string. Text will only be pretty-printed if indent is specified.
--]]
---@diagnostic disable-next-line
json = {
    ---Convert arbitrary data into a JSON string representation.
    ---Will error if data is something that cannot be serialized, such as a function, userdata or thread.
    ---@param data any The data to serialize.
    ---@param indent integer|nil The number of spaces to indent on each scope change.
    ---@param return_error boolean|nil If true, return the error as a second parameter. Otherwise halts program execution on error.
    ---@return string, string|nil
    stringify = function(data, indent, return_error)
        local function __stringify(data, indent, __indent)
            local tp = type(data)

            if tp == 'table' then
                local next_indent

                if indent ~= nil then
                    if __indent == nil then __indent = 0 end
                    next_indent = indent + __indent
                end

                --Check if a table is an array or an object
                local is_array = true
                local meta = getmetatable(data)
                if meta and meta.is_array ~= nil then
                    is_array = meta.is_array
                else
                    for key, value in pairs(data) do
                        if type(key) ~= 'number' then
                            is_array = false
                            break
                        end
                    end
                end

                local result = ''
                if is_array then
                    if indent ~= nil then result = '[\n' else result = '[' end
                    for key = 1, #data do
                        local str = __stringify(data[key], indent, next_indent)
                        if key ~= #data then str = str .. ',' end
                        if indent ~= nil then
                            result = result .. (' '):rep(next_indent) .. str .. '\n'
                        else
                            result = result .. str
                        end
                    end
                    if indent ~= nil then return result .. (' '):rep(__indent) .. ']' else return result .. ']' end
                else
                    if indent ~= nil then result = '{\n' else result = '{' end
                    local colon = ':'
                    if indent ~= nil then colon = ': ' end
                    local ct = 0
                    for key, value in pairs(data) do
                        local str = __stringify(tostring(key), indent, next_indent) ..
                            colon .. __stringify(value, indent, next_indent)
                        if indent ~= nil then
                            if ct > 0 then result = result .. ',\n' end
                            result = result .. (' '):rep(next_indent) .. str
                        else
                            if ct > 0 then result = result .. ',' end
                            result = result .. str
                        end
                        ct = ct + 1
                    end
                    if indent ~= nil then return result .. '\n' .. (' '):rep(__indent) .. '}' else return result .. '}' end
                end
            elseif tp == 'string' then
                local repl_chars = {
                    { '\\', '\\\\' },
                    { '\"', '\\"' },
                    { '\n', '\\n' },
                    { '\t', '\\t' },
                }
                local result = data
                local i
                for i = 1, #repl_chars do
                    result = result:gsub(repl_chars[i][1], repl_chars[i][2])
                end
                return '"' .. result .. '"'
            elseif tp == 'number' then
                return tostring(data)
            elseif data == true then
                return 'true'
            elseif data == false then
                return 'false'
            elseif data == nil then
                return 'null'
            else
                local msg = 'Unable to stringify data "' .. tostring(data) .. '" of type ' .. tp .. '.'
                if return_error then
                    return '', msg
                else
                    error(msg)
                end
            end
        end

        return __stringify(data, indent)
    end,

    ---Parse a JSON string representation into arbitrary data.
    ---Will error if the JSON string is invalid.
    ---@param text string The JSON string to parse.
    ---@param return_error boolean|nil If true, return the error as a second parameter. Otherwise halts program execution on error.
    ---@return any, string|nil
    parse = function(text, return_error)
        local line = 1
        local col = 1
        local tokens = {}

        local _tok = {
            literal = 0,
            comma = 1,
            colon = 2,
            lbrace = 3,
            rbrace = 4,
            lbracket = 5,
            rbracket = 6,
        }

        local newtoken = function(value, kind)
            return {
                value = value,
                kind = kind,
                line = line,
                col = col,
            }
        end

        local do_error = function(msg)
            error('JSON parse error at [' .. line .. ':' .. col .. ']: ' .. msg)
        end

        if return_error then
            do_error = function(msg)
                return nil, 'JSON parse error at [' .. line .. ':' .. col .. ']: ' .. msg
            end
        end

        --Split JSON string into tokens
        local in_string = false
        local escaped = false
        local i = 1
        local this_token = ''
        local paren_stack = {}
        while i <= #text do
            local chr = text:sub(i, i)

            col = col + 1
            if chr == '\n' then
                line = line + 1
                col = 0
                if in_string then
                    return do_error('Unexpected line ending inside string.')
                end
            elseif in_string then
                if escaped then
                    if chr == 'n' then chr = '\n' end
                    if chr == 't' then chr = '\t' end
                    this_token = this_token .. chr
                    escaped = false
                elseif chr == '\\' and text:sub(i + 1, i + 1) ~= 'u' then
                    --Don't mangle unicode sequences... we usually can't render those, so just leave them as-is.
                    --All others can be handled properly.
                    escaped = true
                elseif chr == '"' then
                    --End string, append token
                    table.insert(tokens, newtoken(this_token, _tok.literal))
                    this_token = ''
                    in_string = false
                else
                    this_token = this_token .. chr
                end
            elseif chr == '[' then
                table.insert(tokens, newtoken(chr, _tok.lbracket))
                table.insert(paren_stack, chr)
            elseif chr == ']' then
                table.insert(tokens, newtoken(chr, _tok.rbracket))
                if #paren_stack == 0 then return do_error('Unexpected closing bracket "]".') end
                if table.remove(paren_stack) ~= '[' then return do_error('Bracket mismatch (expected "}", got "]").') end
            elseif chr == '{' then
                table.insert(tokens, newtoken(chr, _tok.lbrace))
                table.insert(paren_stack, chr)
            elseif chr == '}' then
                table.insert(tokens, newtoken(chr, _tok.rbrace))
                if #paren_stack == 0 then return do_error('Unexpected closing brace "}".') end
                if table.remove(paren_stack) ~= '{' then return do_error('Brace mismatch (expected "]", got "}").') end
            elseif chr == ':' then
                table.insert(tokens, newtoken(chr, _tok.colon))
            elseif chr == ',' then
                table.insert(tokens, newtoken(chr, _tok.comma))
            elseif chr:match('%s') then
                --Ignore white space outside of strings
            elseif chr == '"' then
                --Start a string token
                in_string = true
            elseif chr == 't' and text:sub(i, i + 3) == 'true' then
                table.insert(tokens, newtoken(true, _tok.literal))
                i = i + 3
            elseif chr == 'f' and text:sub(i, i + 4) == 'false' then
                table.insert(tokens, newtoken(false, _tok.literal))
                i = i + 4
            elseif chr == 'n' and text:sub(i, i + 3) == 'null' then
                table.insert(tokens, newtoken(nil, _tok.literal))
                i = i + 3
            else
                local num = text:match('^%-?%d+%.?%d*', i)
                if num == nil then
                    return do_error('Invalid character "' .. chr .. '".')
                else
                    table.insert(tokens, newtoken(tonumber(num), _tok.literal))
                    i = i + #num - 1
                end
            end

            i = i + 1 --Next char
        end

        if in_string then
            col = col - #this_token
            return do_error('Unterminated string.')
        end

        if #paren_stack > 0 then
            local last = table.remove(paren_stack)
            if last == '[' then
                return do_error('No terminating "]" bracket.')
            else
                return do_error('No terminating "}" brace.')
            end
        end

        local lex_error = function(token, msg)
            line = token.line
            col = token.col
            local r1, r2 = do_error(msg)
            return r1, nil, r2
        end

        --Now that the JSON data is confirmed to only have valid tokens, condense the tokens into valid data
        --Note that at this point, braces are guaranteed to be in the right order and matching open/close braces.
        local function lex(i)
            local this_object
            local this_token = tokens[i]

            if this_token.kind == _tok.literal then
                return this_token.value, i
            elseif this_token.kind == _tok.lbracket then
                --Generate array-like tables
                this_object = setmetatable({}, { is_array = true })
                i = i + 1
                this_token = tokens[i]

                while this_token.kind ~= _tok.rbracket do
                    local value
                    value, i = lex(i)
                    table.insert(this_object, value)
                    this_token = tokens[i + 1]
                    if this_token.kind == _tok.comma then
                        i = i + 1
                    elseif this_token.kind ~= _tok.rbracket then
                        return lex_error(this_token, 'Unexpected token "' .. this_token.value ..
                            '" (expected "," or "]").')
                    end
                    i = i + 1
                    this_token = tokens[i]
                end
                return this_object, i
            elseif this_token.kind == _tok.lbrace then
                --Generate object-like tables
                this_object = setmetatable({}, { is_array = false })
                i = i + 1
                this_token = tokens[i]

                while this_token.kind ~= _tok.rbrace do
                    --Only exact keys are allowed‚ no objects as keys
                    if this_token.kind ~= _tok.literal then
                        return lex_error(this_token, 'Unexpected token "' .. this_token.value .. '" (expected literal).')
                    end
                    local key = this_token.value

                    this_token = tokens[i + 1]
                    if this_token.kind ~= _tok.colon then
                        return lex_error(this_token, 'Unexpected token "' .. this_token.value .. '" (expected ":").')
                    end

                    this_object[key], i = lex(i + 2)
                    this_token = tokens[i + 1]
                    if this_token.kind == _tok.comma then
                        i = i + 1
                    elseif this_token.kind ~= _tok.rbrace then
                        return lex_error(this_token, 'Unexpected token "' .. this_token.value ..
                            '" (expected "," or "}").')
                    end
                    i = i + 1
                    this_token = tokens[i]
                end
                return this_object, i
            else
                return lex_error(this_token, 'Unexpected token "' .. this_token.value .. '".')
            end
        end

        if #tokens == 0 then return nil end
        local r1, r2, r3 = lex(1)
        return r1, r3
    end,


    ---Check if a JSON string is valid.
    ---Returns false and a descriptive error message if the text contains invalid JSON, or true if valid.
    ---@param text string The JSON string to parse.
    ---@return boolean, string|nil
    verify = function(text)
        local res, err = json.parse(text, true)
        if err ~= nil then
            return false, err
        end
        return true
    end,
}

function LS()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then path_list = { WORKING_DIR } end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then break end

        if fs_item.type ~= FS.dir then
            file_error('`' .. path_list[i] .. '` is not a directory.')
            break
        end

        if #path_list > 1 then
            print(path_list[i] .. ':')
        elseif not fs_item.parent and not next(fs_item.contents) then
            print(color('/', 'blue'))
        end

        if fs_item.parent then
            print(color('..', 'blue')) --Indicate that the dir DOES exist.
        end

        for name, item in pairs(fs_item.contents) do
            if item.type == FS.dir then
                print(color(name, 'blue'))
            elseif item.type == FS.file then
                print(name)
            else
                print(color(name, 'red'))
            end
        end
    end

    command_return(nil)
end

function MKDIR()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then
        file_error('No directories given to create.')
        command_return(false)
    end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i], true)
        if not fs_item then
            command_return(false)
            return
        end

        if fs_item.type == FS.file then
            file_error('`' .. path_list[i] .. '` is not a directory.')
            command_return(false)
            return
        end

        local create_name = path_list[i]:match('[^/]*$')
        if not create_name then
            create_name = path_list[i]:match('[^/]+/$')
            if create_name then
                create_name = create_name:sub(1, #create_name - 1)
            end
        end

        if not create_name or fs_item.contents[create_name] then
            file_error('`' .. path_list[i] .. '` already exists.')
            command_return(false)
            return
        end

        fs_item.contents[create_name] = {
            name = create_name,
            parent = fs_item,
            type = FS.dir,
            contents = {},
        }
    end

    command_return(true)
end

function TOUCH()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then
        file_error('No files given to create.')
        command_return(false)
        return
    end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i], true)
        if not fs_item then
            command_return(false)
            return
        end

        if fs_item.type == FS.file then
            file_error('`' .. path_list[i] .. '` is not a directory.')
            command_return(false)
            return
        end

        local create_name = get_fs_basename(path_list[i])
        if not create_name or (fs_item.contents[create_name] and fs_item.contents[create_name].type == FS.dir) then
            file_error('`' .. path_list[i] .. '` already exists.')
            command_return(false)
            return
        end

        fs_item.contents[create_name] = {
            name = create_name,
            parent = fs_item,
            type = FS.file,
            contents = '',
        }
    end

    command_return(true)
end

function MKFILE()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 2 then
        file_error('Expected exactly 2 params (filename and contents), but got ' .. #path_list .. '.')
        command_return(false)
        return
    end

    local fs_dir = get_fs_item(path_list[1], true)
    if not fs_dir then
        command_return(false)
        return
    end
    if fs_dir.type == FS.file then
        file_error('`' .. path_list[1] .. '` is not a directory.')
        command_return(false)
        return
    end

    local create_name = get_fs_basename(path_list[1])
    if not create_name or (fs_dir.contents[create_name] and fs_dir.contents[create_name].type == FS.dir) then
        file_error('Cannot overwrite directory `' .. path_list[1] .. '`.')
        command_return(false)
        return
    end

    fs_dir.contents[create_name] = {
        name = create_name,
        parent = fs_dir,
        type = FS.file,
        contents = path_list[2],
    }

    command_return(true)
end

function CD()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got ' .. #path_list)
        command_return(false)
        return
    end

    local fs_item = get_fs_item(path_list[1])
    if not fs_item or fs_item.type == FS.file then
        command_return(false)
        return
    end

    WORKING_DIR = get_fs_full_path(fs_item)
    command_return(true)
end

function DIR()
    command_return(WORKING_DIR)
end

function PWD()
    print(WORKING_DIR)
    command_return(nil)
end

function READ()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got ' .. #path_list)
        command_return(nil)
        return
    end

    local fs_item = get_fs_item(path_list[1])
    if not fs_item or fs_item.type == FS.dir then
        command_return(nil)
        return
    end

    command_return(fs_item.contents)
end

function CAT()
    command_return(nil)

    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got ' .. #path_list)
        return
    end

    local fs_item = get_fs_item(path_list[1])
    if not fs_item then return end

    if fs_item.type == FS.dir then
        file_error('`' .. path_list[1] .. '` is not a file.')
        return
    end

    print(fs_item.contents)
end

EDIT_PATH = {
    dir = {},
    name = '<NONE>',
}
function EDIT()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got ' .. #path_list)
        command_return(false)
        return
    end

    local fs_item = get_fs_item(path_list[1], true)
    if not fs_item then
        command_return(false)
        return
    end

    if fs_item.type == FS.file then
        file_error('`' .. get_fs_full_path(fs_item) .. '` is not a directory.')
        command_return(false)
        return
    end

    local create_fs_item = get_fs_item(path_list[1], false, true)
    local create_name = get_fs_basename(path_list[1])
    if not create_name or (create_fs_item and create_fs_item.type == FS.dir) then
        file_error('Cannot overwrite directory `' .. path_list[1] .. '`.')
        command_return(false)
        return
    end

    local contents = '' --Actually want to differentiate between "empty file" and "nonexistent file"?
    if create_fs_item then
        ---@diagnostic disable-next-line
        contents = create_fs_item.contents
        create_name = create_fs_item.name
    end

    EDIT_PATH = {
        dir = fs_item,
        name = create_name,
    }

    --Check if syntax highlighting is enabled for this file type.
    --If so, load the appropriate files and send the settings to the editor.
    local syntax_enabled = "0"
    local syntax_theme = ""
    local syntax_scope = ""
    local syntax_pattern = ""
    local syn_dir = get_fs_item("/etc/syntax", false, true)
    if syn_dir and syn_dir.type == FS.dir then
        if file_exists("/etc/syntax/theme.lua") then
            ---@diagnostic disable-next-line
            syntax_theme = get_fs_contents("/etc/syntax/theme.lua")
        end

        --Allow manual syntax specification with a shebang-type thing.
        ---@diagnostic disable-next-line
        local shebang, offset = contents:match("^#![^\n]+\n"), 2
        ---@diagnostic disable-next-line
        if not shebang then shebang, offset = contents:match("^%-%-![^\n]+\n"), 3 end
        if shebang then
            shebang = shebang:sub(offset + 1, #shebang - 1):lower()
        end

        for name, dir in pairs(syn_dir.contents) do
            if dir.contents['files.txt'] and dir.contents['patterns.lua'] and dir.contents['scopes.lua'] then
                for pattern in dir.contents['files.txt'].contents:gmatch("[^\n]+") do
                    if (name:lower() == shebang) or (not shebang and create_name:lower():match(pattern:lower())) then
                        syntax_enabled = "1"
                        syntax_scope = dir.contents['scopes.lua'].contents
                        syntax_pattern = dir.contents['patterns.lua'].contents
                        break
                    end
                end

                if syntax_enabled == "1" then break end
            end
        end
    end


    output_array({
        contents,
        syntax_enabled,
        syntax_theme,
        syntax_scope,
        syntax_pattern,
        ---@diagnostic disable-next-line
    }, 2)
end

function EDIT_RETURN()
    ---@diagnostic disable-next-line
    local contents = V2

    if not contents then
        command_return(false)
        return
    end

    EDIT_PATH.dir.contents[EDIT_PATH.name] = {
        parent = EDIT_PATH.dir,
        name = EDIT_PATH.name,
        type = FS.file,
        contents = contents,
    }

    command_return(true)
end

function RM()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then
        file_error('No files or directories given to delete.')
        command_return(false)
    end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            command_return(false)
            return
        end

        if not fs_item.parent then
            file_error('Cannot delete filesystem root.')
            command_return(false)
            return
        end

        ---@diagnostic disable-next-line
        fs_item.parent.contents[fs_item.name] = nil
    end

    command_return(true)
end

function RUN()
    ---@diagnostic disable-next-line
    ---@type table
    local path_list = V1
    if #path_list == 0 then
        file_error('Expected at least 1 argument, got ' .. #path_list)
        command_return(false)
        return
    end

    local filename = table.remove(path_list, 1)

    local fs_item = get_fs_item(filename)
    if not fs_item then
        command_return(false)
        return
    end

    if fs_item.type == FS.dir then
        file_error('`' .. filename .. '` is not a file.')
        command_return(false)
        return
    end

    --Check the interpreter type of this file.
    --.lua files (or files with a --!lua shebang) will run in a Lua function node.
    --Anything else is assumed to be Paisley
    local interpreter = 'paisley'

    --Allow manual syntax specification with a shebang-type thing.
    --If no shebang, then use file extension to deduce.
    local shebang, offset = fs_item.contents:match("^#![^\n]+\n"), 2
    if not shebang then shebang, offset = fs_item.contents:match("^%-%-![^\n]+\n"), 3 end
    if shebang then
        interpreter = shebang:sub(offset + 1, #shebang - 1):lower()
    elseif fs_item.name:lower():match(".lua$") then
        interpreter = 'lua'
    end

    if interpreter ~= 'lua' and interpreter ~= 'paisley' then
        file_error('Unknown interpreter `' .. interpreter .. '`. Expected "lua" or "paisley".')
        command_return(false)
        return
    end

    --Pass arguments to script
    local args = { fs_item.contents, filename }
    for i = 1, #path_list do table.insert(args, path_list[i]) end

    if interpreter == 'lua' then
        run_lua_script(args)
    else
        command_return(true)
        run_paisley_script(args)
    end
end

function CP()
    ---@diagnostic disable-next-line
    local path_list = V1

    --Check if destination exists
    if #path_list < 2 then
        file_error('No destination specified.')
        command_return(false)
        return
    end

    local destination = nil
    local destination_name = nil
    if #path_list > 2 then
        destination = get_fs_item(path_list[#path_list])
        if destination and destination.type == FS.file then
            file_error('Destination exists but is not a directory.')
            command_return(false)
            return
        end
    else
        destination = get_fs_item(path_list[#path_list], false, true)
        if not destination then
            destination = get_fs_item(path_list[#path_list], true)
            destination_name = get_fs_basename(path_list[#path_list])
            if destination and destination.type == FS.file then
                file_error('Destination exists but is not a directory.')
                command_return(false)
                return
            end
        else
            if destination.type == FS.file then
                --We want to overwrite the file.
                destination_name = destination.name
            end
        end
    end
    if not destination then
        command_return(false)
        return
    end

    --Check if source(s) exist and can be copied to the destination without overwriting data.
    for i = 1, #path_list - 1 do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            command_return(false)
            return
        end

        local dest_dir = destination.contents[fs_item.name]
        if dest_dir and dest_dir.type == FS.dir then
            file_error('Cannot overwrite directory `' .. path_list[#path_list] .. '/' .. fs_item.name .. '`.')
            command_return(false)
            return
        end

        if not fs_item.parent then
            file_error('Cannot copy filesystem root.')
            command_return(false)
            return
        end
    end

    for i = 1, #path_list - 1 do
        --We've already checked that the file exists above,
        --But if there was some weird nesting, one or more could cease to exist partway through moving.
        --Just ignore that, as it means we did successfully move all the data over.

        local fs_item = get_fs_item(path_list[i], false, true)
        if fs_item then
            local dest_name = fs_item.name
            if destination_name then dest_name = destination_name end
            local dest = destination

            if destination.type == FS.file then dest = dest.parent end

            ---@diagnostic disable-next-line
            dest.contents[dest_name] = fs_deep_copy(dest, fs_item)
            ---@diagnostic disable-next-line
            dest.contents[dest_name].name = dest_name
        end
    end

    command_return(true)
end

function MV()
    ---@diagnostic disable-next-line
    local path_list = V1

    --Check if destination exists
    if #path_list < 2 then
        file_error('No destination specified.')
        command_return(false)
        return
    end

    local destination = nil
    local destination_name = nil
    if #path_list > 2 then
        destination = get_fs_item(path_list[#path_list])
        if destination and destination.type == FS.file then
            file_error('Destination exists but is not a directory.')
            command_return(false)
            return
        end
    else
        destination = get_fs_item(path_list[#path_list], false, true)
        if not destination then
            destination = get_fs_item(path_list[#path_list], true)
            destination_name = get_fs_basename(path_list[#path_list])
            if destination and destination.type == FS.file then
                file_error('Destination exists but is not a directory.')
                command_return(false)
                return
            end
        else
            if destination.type == FS.file then
                --We want to overwrite the file.
                destination_name = destination.name
            end
        end
    end
    if not destination then
        command_return(false)
        return
    end

    --Check if source(s) exist and can be moved to the destination without overwriting data.
    for i = 1, #path_list - 1 do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            command_return(false)
            return
        end

        local dest_dir = destination.contents[fs_item.name]
        if dest_dir and dest_dir.type == FS.dir then
            file_error('Cannot overwrite directory `' .. path_list[#path_list] .. '/' .. fs_item.name .. '`.')
            command_return(false)
            return
        end

        if get_fs_full_path(destination):match('^' .. get_fs_full_path(fs_item)) then
            file_error('Cannot move `' ..
                get_fs_full_path(fs_item) .. '` into its own subdirectory `' .. get_fs_full_path(destination) .. '`.')
            command_return(false)
            return
        end

        if not fs_item.parent then
            file_error('Cannot move filesystem root.')
            command_return(false)
            return
        end
    end

    for i = 1, #path_list - 1 do
        --We've already checked that the file exists above,
        --But if there was some weird nesting, one or more could cease to exist partway through moving.
        --Just ignore that, as it means we did successfully move all the data over.

        local fs_item = get_fs_item(path_list[i], false, true)
        if fs_item then
            local dest_name = fs_item.name
            if destination_name then dest_name = destination_name end

            if destination.type == FS.dir then
                destination.contents[dest_name] = {
                    name = dest_name,
                    parent = destination,
                    type = fs_item.type,
                    contents = fs_item.contents,
                }
            else
                destination.contents = fs_item.contents
            end

            ---@diagnostic disable-next-line
            fs_item.parent.contents[fs_item.name] = nil
        end
    end

    command_return(true)
end

function EXISTS()
    ---@diagnostic disable-next-line
    local path_list = V1
    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i], false, true)
        if not fs_item then
            command_return(false)
            return
        end
    end
    command_return(true)
end

function ISFILE()
    ---@diagnostic disable-next-line
    local path_list = V1
    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i], false, true)
        if not fs_item or fs_item.type == FS.dir then
            command_return(false)
            return
        end
    end
    command_return(true)
end

function ISDIR()
    ---@diagnostic disable-next-line
    local path_list = V1
    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i], false, true)
        if not fs_item or fs_item.type == FS.file then
            command_return(false)
            return
        end
    end
    command_return(true)
end

function STAR()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then path_list = { "" } end

    local results = {}
    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            command_return({})
            return
        end

        if fs_item.type == FS.dir then
            local path = path_list[i]
            if path:sub(#path, #path) == '/' then path = path:sub(1, #path - 1) end

            for name, item in pairs(fs_item.contents) do
                local item_path = name
                if path_list[i] ~= "" then item_path = path .. '/' .. name end
                table.insert(results, item_path)
            end
        else
            table.insert(results, path_list[i])
        end
    end

    command_return(results)
end

function STARDIR()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then path_list = { WORKING_DIR } end

    local results = {}
    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            command_return({})
            return
        end

        if fs_item.type == FS.dir then
            local path = path_list[i]
            if path:sub(#path, #path) == '/' then path = path:sub(1, #path - 1) end

            for name, item in pairs(fs_item.contents) do
                if item.type == FS.dir then
                    local item_path = name
                    if path_list[i] ~= "" then item_path = path .. '/' .. name end
                    table.insert(results, item_path)
                end
            end
        end
    end

    command_return(results)
end

function STARFILE()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then path_list = { WORKING_DIR } end

    local results = {}
    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            command_return({})
            return
        end

        if fs_item.type == FS.dir then
            local path = path_list[i]
            if path:sub(#path, #path) == '/' then path = path:sub(1, #path - 1) end

            for name, item in pairs(fs_item.contents) do
                if item.type == FS.file then
                    local item_path = name
                    if path_list[i] ~= "" then item_path = path .. '/' .. name end
                    table.insert(results, item_path)
                end
            end
        else
            table.insert(results, path_list[i])
        end
    end

    command_return(results)
end

function WGET()
    ---@diagnostic disable-next-line
    local params = V1

    local url, output_file = params[1], params[2]

    if not url or url == "" then
        file_error('No URL given to fetch.\nUsage: <color=yellow>`wget [URL] [file (optional)]`</color>')
        command_return(false)
        return
    end

    --If output file is not specified, deduce output file from the url.
    if not output_file or output_file == "" then
        local url_path = url:gmatch("[^?]+")()
        if not url_path then
            file_error('Invalid URL, unable to deduce the file name.')
            command_return(false)
            return
        end

        local deduced_file = ""
        for i in url_path:gmatch("[^/]+") do deduced_file = i end

        if deduced_file == "" then
            file_error('Invalid URL, unable to deduce the file name.')
            command_return(false)
            return
        end

        output_file = deduced_file
    end

    --Make sure we aren't trying to overwrite a directory
    local overwrite_fs_item = get_fs_item(output_file, false, true)
    if overwrite_fs_item and overwrite_fs_item.type == FS.dir then
        file_error('Cannot overwrite directory `' .. output_file .. '`.')
        command_return(false)
        return
    end

    --Make sure the destination directory exists
    local destination_dir = get_fs_item(output_file, true)
    if not destination_dir then
        command_return(false)
        return
    end

    EDIT_PATH = {
        dir = destination_dir,
        name = get_fs_basename(output_file),
    }
    ---@diagnostic disable-next-line
    output(url, 5)
end

function WGET_RETURN()
    ---@diagnostic disable-next-line
    local response, error_msg = V3, V4

    if error_msg then
        file_error(error_msg)
        command_return(false)
        return
    end

    EDIT_PATH.dir.contents[EDIT_PATH.name] = {
        parent = EDIT_PATH.dir,
        name = EDIT_PATH.name,
        type = FS.file,
        contents = response,
    }
    command_return(true)
end

function FSDUMP()
    ---@diagnostic disable-next-line
    local params = V1

    local function minify_fs(fs_item)
        if fs_item.type == FS.file then return fs_item.contents end

        local result = {}
        for name, item in pairs(fs_item.contents) do
            result[name] = minify_fs(item)
        end
        return result
    end

    local result = {}
    for i = 1, #params do
        local fs_item = get_fs_item(params[i])
        if not fs_item then
            command_return(nil)
            return
        end

        result[fs_item.name] = minify_fs(fs_item)
    end

    command_return(json.stringify(result))
end

function FSLOAD()
    ---@diagnostic disable-next-line
    local params = V1

    if #params < 2 then
        file_error('Usage: ' .. color('`fsload [OUT_DIR] [DATA]`', 'yellow'))
        command_return(false)
        return
    end

    local output_dir = get_fs_item(params[1])
    if not output_dir then
        command_return(false)
        return
    end
    if output_dir.type == FS.file then
        file_error('Output location is not a directory.')
        command_return(false)
        return
    end

    local mini_fs, err = json.parse(params[2], true)
    if err then
        file_error(err)
        command_return(false)
        return
    end

    local function verify_fs(minfs)
        if type(minfs) == 'string' then return true end
        if type(minfs) ~= 'table' then return false end

        for key, value in pairs(minfs) do
            if type(key) ~= 'string' then return false end
            if key ~= '/' and key:match('/') then return false end
            if key == '.' or key == '..' then return false end

            if not verify_fs(value) then return false end
        end
        return true
    end

    if not verify_fs(mini_fs) then
        file_error('Filesystem dump is not formatted correctly, unable to load.')
        command_return(false)
        return
    end

    local function merge_fs(fs_dir, minfs)
        for key, value in pairs(minfs) do
            local fs_item_type = FS.dir
            if type(value) == 'string' then fs_item_type = FS.file end
            if key == '/' then key = '__rootfs__' end

            if not fs_dir.contents[key] then
                if fs_item_type == FS.dir then
                    fs_dir.contents[key] = {
                        name = key,
                        parent = fs_dir,
                        type = FS.dir,
                        contents = {},
                    }
                else
                    fs_dir.contents[key] = {
                        name = key,
                        parent = fs_dir,
                        type = FS.file,
                        contents = '<FSLOAD ERROR>',
                    }
                end
            end

            local fs_item = fs_dir.contents[key]

            if fs_item.type ~= fs_item_type then
                file_error('Unable to deserialize into `' .. get_fs_full_path(fs_item) .. '` due to file/dir mismatch.')
            elseif fs_item_type == FS.file then
                fs_item.contents = value
            else
                merge_fs(fs_item, value)
            end
        end
    end

    merge_fs(output_dir, mini_fs)
    command_return(true)
end
