-- Bitmap buddy

-- Has three modes: help, setup, and standard

-- MAXScript is a steaming pile of garbage, I can't stand it, so I decided to delegate as much code as possible to Lua

-- TODO: when all of this is finished, for the release version I will post release packages with an embedded Lua interpreter, I won't bother creating executables anymore

local utils = require("./system_utilities")

-- ===== Functions =====
function InvaderEditPath(invader_path)
    local is_windows_host = utils.is_windows_host()
    if is_windows_host then
        return utils.generate_path(utils.remove_path_quotes(invader_path), "/invader-edit.exe")
    end
    return utils.generate_path(utils.remove_path_quotes(invader_path), "/invader-edit")
end

function InvaderRecoverPath(invader_path)
    local is_windows_host = utils.is_windows_host()
    if is_windows_host then
        return utils.generate_path(utils.remove_path_quotes(invader_path), "/invader-recover.exe")
    end
    return utils.generate_path(utils.remove_path_quotes(invader_path), "/invader-recover")
end

function TagsPath(halo_path)
    return utils.generate_path(utils.remove_path_quotes(halo_path), "/tags")
end

function DataPath(halo_path)
    return utils.generate_path(utils.remove_path_quotes(halo_path), "/data")
end

function GBXModelGetShaderCountCommand(invader_path, halo_path, gbxmodel_path)
    -- Returns a command string to get the shader count of a given GBXmodel, expects gbxmodel_path to be relative to the tags directory
    local invader_edit_path = InvaderEditPath(invader_path)
    local tags_path = TagsPath(halo_path)
    local get_shader_count_command = {}
    table.insert(get_shader_count_command, utils.add_quotes(invader_edit_path))
    table.insert(get_shader_count_command, "-t")
    table.insert(get_shader_count_command, utils.add_quotes(tags_path))
    table.insert(get_shader_count_command, "-C")
    table.insert(get_shader_count_command, "shaders")
    table.insert(get_shader_count_command, utils.add_quotes(gbxmodel_path))
    get_shader_count_command = table.concat(get_shader_count_command, " ")
    return get_shader_count_command
end

function GBXModelGetShaderPathCommand(invader_path, halo_path, gbxmodel_path, shader_index_base_zero)
    -- Returns a command string to get the shader path of shader at a given index, from a given GBXmodel, expects gbxmodel_path to be relative to the tags directory
    local invader_edit_path = InvaderEditPath(invader_path)
    local tags_path = TagsPath(halo_path)
    local get_shader_command = {}
    table.insert(get_shader_command, utils.add_quotes(invader_edit_path))
    table.insert(get_shader_command, "-t")
    table.insert(get_shader_command, utils.add_quotes(tags_path))
    table.insert(get_shader_command, "-G")
    table.insert(get_shader_command, "shaders["..shader_index_base_zero.."].shader")
    table.insert(get_shader_command, utils.add_quotes(gbxmodel_path))
    get_shader_command = table.concat(get_shader_command, " ")
    return get_shader_command
end

-- TODO: individual functions to get the base map of other shader types

function ShaderModelGetBaseMapCommand(invader_path, halo_path, shader_path)
    -- Returns a command string to get the bitmap path from a shader_model, expects shader_path to be relative to the tags directory
    local invader_edit_path = InvaderEditPath(invader_path)
    local tags_path = TagsPath(halo_path)
    local get_base_map_command = {}
    table.insert(get_base_map_command, utils.add_quotes(invader_edit_path))
    table.insert(get_base_map_command, "-t")
    table.insert(get_base_map_command, utils.add_quotes(tags_path))
    table.insert(get_base_map_command, "-G")
    table.insert(get_base_map_command, "base_map")
    table.insert(get_base_map_command, utils.add_quotes(shader_path))
    get_base_map_command = table.concat(get_base_map_command, " ")
    return get_base_map_command
end

-- TODO: function to get a table of valid shader-bitmap pairs

function RecoverBitmapCommand(invader_path, halo_path, bitmap_path)
    -- Returns a command string to extract (recover) the bitmap to the data folder from a bitmap tag, expects bitmap_path to be relative to the tags directory
    local invader_recover_path = InvaderRecoverPath(invader_path)
    local tags_path = TagsPath(halo_path)
    local data_path = DataPath(halo_path)
    local recover_bitmap_command = {}
    table.insert(get_base_map_command, utils.add_quotes(invader_recover_path))
    table.insert(get_base_map_command, "-d")
    table.insert(get_base_map_command, utils.add_quotes(data_path))
    table.insert(get_base_map_command, "-t")
    table.insert(get_base_map_command, utils.add_quotes(tags_path))
    table.insert(get_base_map_command, utils.add_quotes(bitmap_path))
    recover_bitmap_command = table.concat(recover_bitmap_command, " ")
    return recover_bitmap_command
end

function addCallOnWindowsHost(command)
    local is_windows_host = utils.is_windows_host()
    local new_command = command
    if is_windows_host then
        -- Programs in quotes don't run in Windows unless called explicitly, using CALL is just more convenient for this
        new_command = "CALL "..new_command
    end
    return new_command
end

function getShaderCount(invader_path, halo_path, gbxmodel_path)
    local command = GBXModelGetShaderCountCommand(invader_path, halo_path, gbxmodel_path)
    local process
    local count
    command = addCallOnWindowsHost(command)
    process = io.popen(command)
    if not process then
        print("error: failed to run Invader command to get shader count from GBXModel")
        return
    end
    -- Calling this command from Invader should print a single line containing an integer indicating the shader count of the GBXModel, anything else is wrong
    count = tonumber(process:read("*l"))
    process:close()
    return count
end

function getShaderPath(invader_path, halo_path, gbxmodel_path, shader_index_base_zero)
    local command = GBXModelGetShaderPathCommand(invader_path, halo_path, gbxmodel_path, shader_index_base_zero)
    local process
    local path
    command = addCallOnWindowsHost(command)
    process = io.popen(command)
    if not process then
        print("error: failed to run Invader command to get shader path from GBXModel (shader #"..shader_index_base_zero..", base zero)")
        return
    end
    -- Calling this command from Invader should print a single line containing the relative path of a shader from a GBXModel, relative to the tags directory
    path = tostring(process:read("*l"))
    process:close()
    return path
end

function getShaderPathList(invader_path, halo_path, gbxmodel_path)
    -- This will collect all the shaders from the shader list of the GBXModel, regardless of the "permutation" value of each shader struct
    -- The GBXModel importer script should only import shaders from the selected permutation anyway
    local shader_count = getShaderCount(invader_path, halo_path, gbxmodel_path)
    local shader_list = {}
    for i = 0, shader_count - 1 do
        local shader = getShaderPath(invader_path, halo_path, gbxmodel_path, i)
        -- After this step, shader indeces are no longer base zero
        table.insert(shader_list, shader)
    end
    return shader_list
end

-- There are multiple shader tag types, though only some of them have a base bitmap that can be displayed naturally in 3DS Max
-- At the moment, I only know how to import some of them to Max:
-- shader_environment
-- shader_model
-- TODO: research and figure out how to handle the rest of them
function getShaderModelBaseMapPath(invader_path, halo_path, shader_path)
    local command = ShaderModelGetBaseMapCommand(invader_path, halo_path, shader_path)
    local process
    local path
    command = addCallOnWindowsHost(command)
    process = io.popen(command)
    if not process then
        print("error: failed to run Invader command to get base map path from shader \""..shader_path.."\"")
        return
    end
    -- Calling this command from Invader should print a single line containing the relative path of the base map from a valid shader, relative to the tags directory
    path = tostring(process:read("*l"))
    process:close()
    return path
end

function getBaseMapPathList(invader_path, halo_path, shader_path_list)
    local bitmap_list = {}
    for i, v in ipairs(shader_path_list) do
        -- If no base map is found for a shader, or if the base map is inaccessible, it is ignored and set to something not nil so shader and bitmap table counts match
        local extension = utils.get_file_extension(v)
        local bitmap_path = ""
        -- TODO: implement logic for unimplemented shader types
        if extension == "shader_environment" then
        elseif extension == "shader_model" then
            bitmap_path = getShaderModelBaseMapPath(invader_path, halo_path, v)
            if not bitmap_path then
                bitmap_path = ""
            end
        elseif extension == "shader_transparent_chicago" then
        elseif extension == "shader_transparent_chicago_extended" then
        elseif extension == "shader_transparent_generic" then
        elseif extension == "shader_transparent_glass" then
        elseif extension == "shader_transparent_meter" then
        elseif extension == "shader_transparent_plasma" then
        elseif extension == "shader_transparent_water" then
        else
            print("error: unrecognized shader file extension, this is not expected to happen with Halo Custom Edition tags!")
        end
        table.insert(bitmap_list, bitmap_path)
    end
    return bitmap_list
end

-- ===== Execution =====
print("Bitmap Buddy")

-- TODO: remove these test paths
-- Expects the full path to the Invader installation, the full path to the Halo installation, and the GBXmodel path relative to the tags folder
local invader_path = utils.generate_path("C:/All/Halo/tools/invader-0-52-4")
local halo_path = utils.generate_path("C:/All/Halo")
local gbxmodel_path = utils.generate_path("vehicles/warthog/warthog.gbxmodel")

-- Windows is chill in this regard and doesn't care if we omit the .exe extension, as long as the file is a .exe: the extension is appended implicitly
local invader_edit_path = utils.generate_path(utils.remove_path_quotes(invader_path), "/invader-edit")
local tags_path = utils.generate_path(utils.remove_path_quotes(halo_path), "/tags")
local data_path = utils.generate_path(utils.remove_path_quotes(halo_path), "/data")

local shader_count = getShaderCount(invader_path, halo_path, gbxmodel_path)
local shader_list = getShaderPathList(invader_path, halo_path, gbxmodel_path)
local bitmap_list = getBaseMapPathList(invader_path, halo_path, shader_list)

-- TODO: test, remove when finished
print("===== Shader count =====")
print(shader_count)
print("===== Shader list =====")
for i, v in ipairs(shader_list) do
    print(i.." - "..v)
end
print("===== Bitmap list =====")
for i, v in ipairs(bitmap_list) do
    print(i.." - "..v)
end
-- End of test

-- This is here only so I can see the window launched from Max
-- os.execute("TIMEOUT /T 15")