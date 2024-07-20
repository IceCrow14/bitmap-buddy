-- Bitmap buddy

-- Has three modes: help, setup, and standard

-- MAXScript is a steaming pile of garbage, I can't stand it, so I decided to delegate as much code as possible to Lua

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

-- TODO: function to get the GBXModelShaderList
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

-- TODO: function to recover all valid bitmaps from valid shaders

function getShaderCount(invader_path, halo_path, gbxmodel_path)
    local command = GBXModelGetShaderCountCommand(invader_path, halo_path, gbxmodel_path)
    local is_windows_host = utils.is_windows_host()
    local process
    local count
    if is_windows_host then
        -- Programs in quotes don't run in Windows unless called explicitly, using CALL is just more convenient for this
        command = "CALL "..command
    end
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

local get_shader_count_command = GBXModelGetShaderCountCommand(invader_path, halo_path, gbxmodel_path)

local shader_count = getShaderCount(invader_path, halo_path, gbxmodel_path)

print(shader_count)

local get_shader_command_list = {}
for i = 0, shader_count - 1 do
    local get_shader_command = {}
    table.insert(get_shader_command, utils.add_quotes(invader_edit_path))
    table.insert(get_shader_command, "-G")
    -- This will collect all the shaders from the list, regardless of the "permutation" value 
    -- The GBXModel importer script should only import shaders from the selected permutation anyway
    table.insert(get_shader_command, "shaders["..i.."].shader")
    table.insert(get_shader_command, utils.add_quotes(gbxmodel_path))
    get_shader_command = table.concat(get_shader_command, " ")
    table.insert(get_shader_command_list, get_shader_command)
    -- print(get_shader_command)
end

local shader_list = {}
local get_bitmap_command_list
for i = 1, shader_count do
    local shader = shader_list[i]

    local shader_extension -- TODO

    local get_bitmap_command = {}

    -- There are multiple shader tag types, though only some of them have a base bitmap that can be displayed naturally in 3DS Max
    -- At the moment, I only know about the following:
    -- shader_environment
    -- shader_model
    -- Other shader types are:
    -- shader_transparent_chicago
    -- shader_transparent_chicago_extended
    -- shader_transparent_generic
    -- shader_transparent_glass
    -- shader_transparent_meter
    -- shader_transparent_plasma
    -- shader_transparent_water

    if shader_extension == "shader_environment" then

    elseif shader_extension == "shader_model" then

    end

end

-- This is here only so I can see the window launched from Max
-- os.execute("TIMEOUT /T 15")