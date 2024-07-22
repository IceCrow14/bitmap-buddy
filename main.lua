-- Bitmap buddy

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

function RecoverBitmapCommand(invader_path, halo_path, bitmap_path)
    -- Returns a command string to extract (recover) the bitmap to the data folder from a bitmap tag, expects bitmap_path to be relative to the tags directory
    local invader_recover_path = InvaderRecoverPath(invader_path)
    local tags_path = TagsPath(halo_path)
    local data_path = DataPath(halo_path)
    local recover_bitmap_command = {}
    table.insert(recover_bitmap_command, utils.add_quotes(invader_recover_path))
    table.insert(recover_bitmap_command, "-d")
    table.insert(recover_bitmap_command, utils.add_quotes(data_path))
    table.insert(recover_bitmap_command, "-t")
    table.insert(recover_bitmap_command, utils.add_quotes(tags_path))
    table.insert(recover_bitmap_command, utils.add_quotes(bitmap_path))
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
    -- Returns a relative bitmap tag path ending in ".bitmap"
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
                -- Set to empty string so table counts match, and this can be parsed properly by other functions
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

function recoverBaseMaps(invader_path, halo_path, bitmap_path_list)
    -- Recovers (extracts) base maps to their respective data bitmaps folder non-destructively (doesn't overwrite existing files)
    for i, v in ipairs(bitmap_path_list) do
        if v == "" then
            -- No bitmap to be recovered
        else
            local command = RecoverBitmapCommand(invader_path, halo_path, v)
            local process
            command = addCallOnWindowsHost(command)
            process = io.popen(command)
            if not process then
                print("error: failed to run Invader command to recover base map \""..v.."\"")
            end
            process:close()
        end
    end
end

function createTemporaryDataFile(halo_path, shader_path_list, bitmap_path_list)
    -- Creates a temporary file containing a list of shader name & absolute bitmap path pairs to be processed by 3DS Max
    local data_path = DataPath(halo_path)
    local path = "./temporary-data-file.txt"
    local file = io.open(path, "w")
    if not file then
        print("error: failed to create temporary data file, bitmaps will not be imported to MAX")
        return
    end
    -- Write the shader count at the start of the file
    file:write(#shader_path_list)
    file:write("\n")
    for i, v in ipairs(shader_path_list) do
        local bitmap_path = bitmap_path_list[i]
        local shader_name = utils.get_file_name(v)
        local absolute_bitmap_path = ""
        if bitmap_path ~= "" then
            absolute_bitmap_path = utils.generate_path(utils.remove_path_quotes(data_path), "/", bitmap_path)
            -- According to The Reclaimers Library (c20), Invader-recover produces .TIF files from bitmap tags:
            -- So, the .bitmap file extension must be replaced with .tif when exported to the data file read by Max, in order to point to the right source file
            absolute_bitmap_path = string.sub(absolute_bitmap_path, 1, -8) -- Removes ".bitmap"
            absolute_bitmap_path = absolute_bitmap_path..".tif" -- Adds ".tif"
        end
        file:write(shader_name)
        file:write("\n")
        file:write(absolute_bitmap_path)
        file:write("\n")
    end
    file:close()
end

-- ===== Execution =====
-- Expects three arguments: the full path to the Invader installation, the full path to the Halo installation, and the GBXmodel path relative to the tags folder
local invader_path
local halo_path
local gbxmodel_path
local shader_count
local shader_list
local bitmap_list
if #arg < 3 then
    print("error: insufficient arguments, aborting script")
    return 1
end
invader_path = arg[1]
halo_path = arg[2]
gbxmodel_path = arg[3]
shader_count = getShaderCount(invader_path, halo_path, gbxmodel_path)
shader_list = getShaderPathList(invader_path, halo_path, gbxmodel_path)
bitmap_list = getBaseMapPathList(invader_path, halo_path, shader_list)

print("Bitmap Buddy")
print("===== Getting shader and bitmap data... =====")
-- print("===== Shader count =====")
-- print(shader_count)
-- print("===== Shader list =====")
-- for i, v in ipairs(shader_list) do
--     print(i.." - "..v)
-- end
-- print("===== Bitmap list =====")
-- for i, v in ipairs(bitmap_list) do
--     print(i.." - "..v)
-- end
print("===== Recovering bitmaps... =====")
recoverBaseMaps(invader_path, halo_path, bitmap_list)
-- print("===== Shader file names =====")
-- for i, v in ipairs(shader_list) do
--     print("Shader file name", i, utils.get_file_name(v))
-- end
print("===== Creating temporary data file... =====")
createTemporaryDataFile(halo_path, shader_list, bitmap_list)
print("Done")