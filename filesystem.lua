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
mkfs({'etc', 'syntax', 'paisley'}, 'files.txt', '.p$\n.pai$\n.paisley$')
mkfs({'etc', 'syntax', 'paisley'}, 'patterns.lua', [[
patterns = {
    comment = {
        pattern = "#.*$",
        display = "comment",
    },

    escape_char = {
        pattern = "\\.",
        display = "escape",
        greedy = true,
    },

    param = {
        pattern = "[^ \t\n\r\"\'{};$]+", --"
        display = "param", --Just use the same color I guess
    },
    param_num = {
        pattern = {"%d+%.%d*", "%d+", "%.%d+"},
        display = "number",
    },

    label = {
        pattern = "[a-zA-Z0-9_]+:",
        display = "special_functions",
    },

    --keywords
    kwd_1 = {
        pattern = {"for", "in", "if", "elif", "while", "delete", "break", "continue", "define", "match"}, --parser auto-detects if it's at a word boundary
        display = "keyword", --apply coloring from theme.keyword
        scope = "normal", --change scope (so commands aren't highlighted)
    },
    kwd_2 = {
        pattern = {"do", "then", "else", "end", "return", "stop"},
        display = "keyword",
        scope = "initial",
    },
    kwd_3 = {
        pattern = "gosub",
        display = "keyword",
        scope = "lbl",
    },
    kwd_4 = {
        pattern = "subroutine",
        display = "keyword",
        push = "lbl2",
    },
    expr_keywords = {
        pattern = {"if", "else"},
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
        pattern = "[a-zA-Z0-9_]+",
        display = "special_functions",
    },

    lbl2 = {
        pattern = "[a-zA-Z0-9_]+",
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
        pattern = {"and", "or", "not", "xor", "in", "[%+%-%*/%%:&><=,]", "~=", "!=", "exists", "like"},
        display = "operator",
    },

    variable = {
        pattern = {"[a-zA-Z_][a-zA-Z_0-9]*"},
        display = "variable",
    },

    var_special = {
        pattern = "[@%$]",
        display = "special_var",
    },

    number = {
        pattern = {"0[xb][0-9_a-fA-F]*", "[0-9]*%.[0-9]+", "[0-9]+"},
        display = "number",
    },

    constant = {
        pattern = {"true", "false", "null"},
        display = "literal",
    },

    let = {
        pattern = {"let", "initial"},
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
        pattern = "[%w_]+",
        display = "functions",
        lookahead = " *%(",
    },
}
]])
mkfs({'etc', 'syntax', 'paisley'}, 'scopes.lua', [[
--Each "scope" has a list of patterns that will be highlighted.
scopes = {
    --This is a special scope that is the FIRST one visible when scope stack is empty
    --This global scope is visible IN ADDITION TO the current scope.
    global = {
        "comment",
        "kwd_1",
        "kwd_2",
        "kwd_3",
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
mkfs({'etc', 'syntax'}, 'theme.lua', [[
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
mkfs({'etc', 'syntax', 'lua'}, 'files.txt', '.lua$')
mkfs({'etc', 'syntax', 'lua'}, 'patterns.lua', [[
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
mkfs({'etc', 'syntax', 'lua'}, 'scopes.lua', [[
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
mkfs({'bin'})
mkfs({'home'}, 'README', "This filesystem has been pre-loaded with an example directory structure. Feel free to rearrange it to your heart's content!\n\n/bin: User scripts can be stored here.\n/etc: Config files can be stored here.\n/home: Everything else can be stored here.")
WORKING_DIR = '/home'

local function color(text, text_color) return '<color='..text_color..'>'..text..'<'..'/color>' end

local function file_error(msg)
    print(color('ERROR: ','#E58357') .. msg)
end

local function get_fs_item(path, ignore_last, quiet)
    local dir, prev_dir = FILESYSTEM, nil
    if path:sub(1,1) ~= '/' then dir = get_fs_item(WORKING_DIR) end

    for name in path:gsub('\\', '/'):gmatch('[^/]+') do
        if not dir or dir.type == FS.file then
            if not quiet then file_error('No such file `'..path..'`.') end
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
        if not quiet then file_error('No such file `'..path..'`.') end
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
        if fs_item.parent then path = fs_item.name..'/'..path end
    end

    if path:sub(1,1) == '/' then return path else return '/'..path end
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


function LS()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then path_list = {WORKING_DIR} end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then break end

        if fs_item.type == FS.file then
            file_error('`'..path_list[i]..'` is not a directory.')
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
            else
                print(name)
            end
        end
    end

    output(nil, 1)
end

function MKDIR()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then
        file_error('No directories given to create.')
        output(false, 1)
    end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i], true)
        if not fs_item then
            output(false, 1)
            return
        end

        if fs_item.type == FS.file then
            file_error('`'..path_list[i]..'` is not a directory.')
            output(false, 1)
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
            file_error('`'..path_list[i]..'` already exists.')
            output(false, 1)
            return
        end

        fs_item.contents[create_name] = {
            name = create_name,
            parent = fs_item,
            type = FS.dir,
            contents = {},
        }
    end

    output(true, 1)
end

function TOUCH()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then
        file_error('No files given to create.')
        output(false, 1)
    end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i], true)
        if not fs_item then
            output(false, 1)
            return
        end

        if fs_item.type == FS.file then
            file_error('`'..path_list[i]..'` is not a directory.')
            output(false, 1)
            return
        end

        local create_name = get_fs_basename(path_list[i])
        if not create_name or (fs_item.contents[create_name] and fs_item.contents[create_name].type == FS.dir) then
            file_error('`'..path_list[i]..'` already exists.')
            output(false, 1)
            return
        end

        fs_item.contents[create_name] = {
            name = create_name,
            parent = fs_item,
            type = FS.file,
            contents = '',
        }
    end

    output(true, 1)
end

function MKFILE()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 2 then
        file_error('Expected exactly 2 params (filename and contents), but got '..#path_list..'.')
        output(false, 1)
        return
    end

    local fs_dir = get_fs_item(path_list[1], true)
    if not fs_dir then
        output(false, 1)
        return
    end
    if fs_dir.type == FS.file then
        file_error('`'..path_list[i]..'` is not a directory.')
        output(false, 1)
        return
    end

    local create_name = get_fs_basename(path_list[1])
    if not create_name or (fs_dir.contents[create_name] and fs_dir.contents[create_name].type == FS.dir) then
        file_error('`'..path_list[1]..'` already exists.')
        output(false, 1)
        return
    end

    fs_dir.contents[create_name] = {
        name = create_name,
        parent = fs_dir,
        type = FS.file,
        contents = path_list[2],
    }

    output(true, 1)
end

function CD()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got '..#path_list)
        output(false, 1)
        return
    end

    local fs_item = get_fs_item(path_list[1])
    if not fs_item or fs_item.type == FS.file then
        output(false, 1)
        return
    end

    WORKING_DIR = get_fs_full_path(fs_item)
    output(true, 1)
end

function DIR()
    output(WORKING_DIR, 1)
end

function PWD()
    print(WORKING_DIR)
    output(nil, 1)
end

function READ()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got '..#path_list)
        output(nil, 1)
        return
    end

    local fs_item = get_fs_item(path_list[1])
    if not fs_item or fs_item.type == FS.dir then
        output(nil, 1)
        return
    end

    output(fs_item.contents, 1)
end

function CAT()
    output(nil, 1)

    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got '..#path_list)
        return
    end

    local fs_item = get_fs_item(path_list[1])
    if not fs_item then return end

    if fs_item.type == FS.dir then
        file_error('`'..path_list[1]..'` is not a file.')
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
        file_error('Expected exactly 1 argument, got '..#path_list)
        output(false, 1)
        return
    end

    local fs_item = get_fs_item(path_list[1], true)
    if not fs_item then
        output(false, 1)
        return
    end

    if fs_item.type == FS.file then
        file_error('`'..get_fs_full_path(fs_item)..'` is not a directory.')
        output(false, 1)
        return
    end

    local create_name = get_fs_basename(path_list[1])
    if not create_name or (fs_item.contents[create_name] and fs_item.contents[create_name].type == FS.dir) then
        file_error('Cannot overwrite directory `'..path_list[1]..'`.')
        output(false, 1)
        return
    end

    local contents = '' --Actually want to differentiate between "empty file" and "nonexistent file"?
    if fs_item.contents[create_name] then
        contents = fs_item.contents[create_name].contents
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
        local shebang, offset = contents:match("^#![^\n]+\n"), 2
        if not shebang then shebang, offset = contents:match("^%-%-![^\n]+\n"), 3 end
        if shebang then
            shebang = shebang:sub(offset + 1, #shebang - 1)
        end

        for name, dir in pairs(syn_dir.contents) do
            if dir.contents['files.txt'] and dir.contents['patterns.lua'] and dir.contents['scopes.lua'] then
                for pattern in dir.contents['files.txt'].contents:gmatch("[^\n]+") do
                    if (name == shebang) or (not shebang and create_name:match(pattern)) then
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
    }, 2)
end

function EDIT_RETURN()
    ---@diagnostic disable-next-line
    local contents = V2

    if not contents then
        output(false, 1)
        return
    end

    EDIT_PATH.dir.contents[EDIT_PATH.name] = {
        parent = EDIT_PATH.dir,
        name = EDIT_PATH.name,
        type = FS.file,
        contents = contents,
    }

    output(true, 1)
end

function RM()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list == 0 then
        file_error('No files or directories given to delete.')
        output(false, 1)
    end

    for i = 1, #path_list do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            output(false, 1)
            return
        end

        if not fs_item.parent then
            file_error('Cannot delete filesystem root.')
            output(false, 1)
            return
        end

        fs_item.parent.contents[fs_item.name] = nil
    end

    output(true, 1)
end

function PLAY()
    if V1[1] then output(V1[1], 3) else output('', 3) end
    output(nil, 1)
end

function RUN()
    ---@diagnostic disable-next-line
    local path_list = V1
    if #path_list ~= 1 then
        file_error('Expected exactly 1 argument, got '..#path_list)
        output(false, 1)
        return
    end

    local fs_item = get_fs_item(path_list[1])
    if not fs_item then
        output(false, 1)
        return
    end

    if fs_item.type == FS.dir then
        file_error('`'..path_list[1]..'` is not a file.')
        output(false, 1)
        return
    end

    output(true, 1)
    output(fs_item.contents, 4)
end

function MV()
    ---@diagnostic disable-next-line
    local path_list = V1

    --Check if destination exists
    if #path_list < 2 then
        file_error('No destination specified.')
        output(false, 1)
        return
    end

    local destination = nil
    if #path_list > 2 then
        destination = get_fs_item(path_list[#path_list])
    else
        destination = get_fs_item(path_list[#path_list], false, true)
        if not destination then
            destination = get_fs_item(path_list[#path_list], true)
        end
    end
    if not destination then
        output(false, 1)
        return
    end
    if destination.type == FS.file then
        file_error('Destination exists but is not a directory.')
        output(false, 1)
        return
    end

    --Check if source(s) exist and can be moved to the destination without overwriting data.
    for i = 1, #path_list - 1 do
        local fs_item = get_fs_item(path_list[i])
        if not fs_item then
            output(false, 1)
            return
        end

        if destination.contents[fs_item.name] and destination.contents[fs_item.name].type == FS.dir then
            file_error('Cannot overwrite directory `'..path_list[#path_list]..'/'..fs_item.name..'`.')
            output(false, 1)
            return
        end

        if get_fs_full_path(destination):match(get_fs_full_path(fs_item)) then
            file_error('Cannot move `'..get_fs_full_path(fs_item)..'` into its own subdirectory `'..get_fs_full_path(destination)..'`.')
            output(false, 1)
            return
        end

        if not fs_item.parent then
            file_error('Cannot move filesystem root.')
            output(false, 1)
            return
        end
    end

    for i = 1, #path_list - 1 do
        --We've already checked that the file exists above,
        --But if there was some weird nesting, one or more could cease to exist partway through moving.
        --Just ignore that, as it means we did successfully move all the data over.
        local fs_item = get_fs_item(path_list[i], false, true)
        if fs_item then
            fs_item.parent = destination
            destination.contents[fs_item.name] = fs_item
            fs_item.parent.contents[fs_item.name] = nil
        end
    end

    output(true, 1)
end
