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
WORKING_DIR = '/'

local function color(text, text_color) return '<color='..text_color..'>'..text..'<'..'/color>' end

local function file_error(msg)
    print(color('ERROR: ','#E58357') .. msg)
end

local function get_fs_item(path, ignore_last)
    local dir, prev_dir = FILESYSTEM, nil
    if path:sub(1,1) ~= '/' then dir = get_fs_item(WORKING_DIR) end

    for name in path:gsub('\\', '/'):gmatch('[^/]+') do
        if not dir or dir.type == FS.file then
            file_error('No such file `'..path..'`.')
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
        file_error('No such file `'..path..'`.')
        return nil
    end

    return dir
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

    output(contents, 2)
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