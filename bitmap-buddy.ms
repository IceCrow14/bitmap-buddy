-- Bitmap buddy 3DS Max test script

-- This script is meant to be run right after importing a GBXModel using the GBXModel Importer script (with all material import checkboxes checked)
-- This script is meant to be left at the project root folder, or it will not run correctly
-- And last, but not least important: this script was developed in 3ds Max 2016, for Windows x64: I can't guarantee that it will run in older versions of Max, Windows, or both

-- Keep in mind: avoid using reserved names for variables
-- Keep in mind: to convert a variable to another data type, add "as [data type]" at the end of the assignment
-- Keep in mind: The default working directory is the installation directory of 3DS Max, because that's where the desktop shortcut starts Max,
--                        and that's where files are created by default when using "createFile"
-- Keep in mind: Relative paths cannot be used to get the script location because then it is not possible to locate the Bitmap Buddy project directory, so I made a function to retrieve the project location

-- TODO: find a way to close the rollout automatically after certain triggers
-- The more I know about the GBXmodel importer as well as about MAXScript, I believe the best course of action is to merge this code with my own version of a GUI & scriptable GBXModel importer
-- Assigning materials in an already created scene, where multimaterials are not named, and their shader count might not match that of the GBXmodel (like when it has less than 10 materials, and Max creates 10 anyway) makes things harder for a standalone script (solved)

version = "v1.0.0"

function getBitmapBuddyLocation = (
	scriptPath = getSourceFileName()
	scriptDirectory = pathConfig.removePathLeaf(scriptPath)
	return scriptDirectory
)

function getSettingsFilePath = (
	return pathConfig.appendPath (getBitmapBuddyLocation()) "settings.txt"
)

function getTemporaryDataFilePath = (
	return pathConfig.appendPath (getBitmapBuddyLocation()) "temporary-data-file.txt"
)

function isSettingsPathsReady invaderPath haloPath = (
	-- This function checks whether the Invader path and Halo path have been set: returns true if all paths have been set; otherwise, false
	-- Expects arguments to be the "text" property of the respective textboxes (edittext) from the rollout
	if invaderPath != undefined and invaderPath != "" \
		and haloPath != undefined and haloPath != "" then (
		return true
	)
	return false
)

function saveSettingsPaths invaderPath haloPath = (
	-- Creates a new settings file to save the Invader and Halo installation paths, and load them in the future automatically
	-- Expects the argument paths to be -not- in quotes, they are -not- added automatically to paths returned from "getSavePath"
	settingsFilePath = getSettingsFilePath()
	settingsFile = openFile settingsFilePath
	if settingsFile != undefined then (
		close settingsFile
		settingsFile = openFile settingsFilePath mode:"w"
		if settingsFile != undefined then (
			-- Each "%" sign in the format string is one of the arguments to "format", no additional quotes are added (\n is for new line jumps)
			-- The "to" option specifies the output file stream (the settings file, in this case)
			-- It it also possible to write to a file using "print" instead of "format", but it is not preferred because "print" adds another set of quotes to the text automatically
			format "%\n" invaderPath to:settingsFile
			format "%\n" haloPath to:settingsFile
			close settingsFile
			messageBox "Settings saved successfully" title:"Information"
		) else (
			messageBox "Failed to create settings file" title:"Error"
		)
	) else (
		settingsFile = createFile settingsFilePath
		if settingsFile != undefined then (
			close settingsFile
			settingsFile = openFile mode:"w"
			format "%" invaderPath to:settingsFile
			format "%" haloPath to:settingsFile
			close settingsFile
			messageBox "Settings saved successfully" title:"Information"
		) else (
			messageBox "Failed to create settings file" title:"Error"
		)
	)
)

function loadSettingsPaths invaderTextbox haloTextbox = (
	-- Loads the settings file, and loads the Invader and Halo installation paths automatically if the file is found
	-- Expects the arguments to be the textbox (edittext) objects of the rollout, where paths will be pasted
	-- Paths saved to the file are not stored in quotes
	settingsFilePath = getSettingsFilePath()
	settingsFile = openFile settingsFilePath
	if settingsFile != undefined then (
		invaderPath = readLine settingsFile as String
		haloPath = readLine settingsFile as String
		close settingsFile
		invaderTextbox.text = invaderPath
		haloTextbox.text = haloPath
	) else (
		-- Nothing, no settings file was found and no action is taken
	)
)

function isRolloutReady invader_path halo_path model_path = (
	-- This function checks whether the Invader path, Halo path and the GBXModel path have been set: returns true if all paths have been set; otherwise, false
	-- Expects arguments to be the "text" property of the respective textboxes (edittext) from the rollout
	if invader_path != undefined and invader_path != "" \
		and halo_path != undefined and halo_path != "" \ 
		and model_path != undefined and model_path != "" then (
		return true
	)
	return false
)

function runLuaLauncher invaderPath haloPath modelPath = (
	-- TODO: at the moment, for Windows only. I don't know if 3DS Max has built-in OS detection functions (or a replacement for DOSCommand in Linux)
	-- The launcher path must be quoted too because it is passed to a shell window, to ensure it is passed as a single argument in case it contains space characters
	luaLauncherPath = pathConfig.appendPath (getBitmapBuddyLocation()) "launcher-windows.cmd"
	command = "\"" + luaLauncherPath + "\"" \
		+ " \"" + invaderPath + "\"" \
		+ " \"" + haloPath + "\"" \
		+ " \"" + modelPath + "\"" as String
	-- Calls the launcher script from the DOSCommand window: runs the Lua script that calls Invader
	DOSCommand ("CALL " + command)
)

function getDataFromDataFile = (
	-- Returns an array containing two arrays: one array of shader names and one array of bitmap absolute paths (or empty string)
	temporaryDataFilePath = getTemporaryDataFilePath()
	temporaryDataFile = openFile temporaryDataFilePath mode:"r"
	if temporaryDataFile != undefined then (
		--messageBox "Opened temporary data file" title:"Information"
		shaderCount = readLine temporaryDataFile as Integer
		-- Two dimensional array, contains the shader name array as the first element, and the absolute bitmap path array as the second element
		data = #(#(), #())
		shaders = data[1]
		bitmaps = data[2]
-- 		messageBox (shaderCount as String) title:"Shader count"
		for i = 1 to shaderCount do (
			shaders[i] = readLine temporaryDataFile as String
			bitmaps[i] = readLine temporaryDataFile as String
		)
		close temporaryDataFile
		--messageBox "Closed temporary data file" title:"Information"
		return data
	) else (
		messageBox "Failed to open temporary data file" title:"Error"
		return undefined
	)
)

function setupSceneMaterials dataSuperArray = (
	-- When more than one GBXModel has been imported to scene, there is no straightforward way to tell which material from the scene materials library is the multimaterial of the selected GBXModel
	-- This is because the name of the multimaterial is not set by the GBXModel importer script (defaults to "Multimaterial"), so, the way to find this out is to iterate over their sub-materials and compare them one by one to check that all of them match
	-- This stuff is barely documented in the documentation, I will take some inspiration from other scripts that modify the material library
	shaders = dataSuperArray[1]
	bitmaps = dataSuperArray[2]
	for i = 1 to sceneMaterials.count do (
		-- These materials may be standard or multimaterials, we are only interested in multimaterials, because the GBXModel Importer only creates multimaterials at the top level
		material = sceneMaterials[i]
		if (ClassOf material as String) == "Multimaterial" then (
			shaderMatches = 0
			for j = 1 to material.count do (
				-- Expects all submaterials to be Standard materials
				subMaterial = material[j]
				--This command was a little useful for debugging and research, I'm keeping it here for the record: showProperties subMaterial
				-- If materials have been removed manually from the multimaterial, this will prevent the script from crashing
				if subMaterial != undefined then (
					for k = 1 to shaders.count do (
						shaderName = shaders[k]
						-- The "name" property is the Sub-material name, the name from the "Name" slot that shows up on the Material Editor is seemingly useless and does not relate to the "name" property in MaxScript
						if subMaterial.name == shaderName then (
							--messageBox ("Shader match: " + (shaderName as String) + " at Multimaterial #" + (i as String))
							shaderMatches = shaderMatches + 1
						)
					)
				)
			)
			if shaderMatches == shaders.count then (
				-- messageBox ("Your multimaterial is scene material #" + (i as String))
				-- Run the loop over all submaterials again, only this time assign the bitmaps from the data super array, and also delete padding materials
				-- This loop runs in reverse to adjust the iterator to decrease after removing materials, a forward loop crashes the script
				for j = material.count to 1 by -1 do (	
					-- Expects all submaterials to be Standard materials
					subMaterial = material[j]
					-- If materials have been removed manually from the multimaterial, this will prevent the script from crashing
					if subMaterial != undefined then (
						subMaterialSubString = substring subMaterial.name 1 10
						if subMaterialSubString == "Material #" then (
							-- messageBox ("This is a bloat material: " + subMaterial.name)
							-- Removes empty submaterials
							-- TODO: Fix, if possible. This works flawlessly unless the user deletes materials manually from the multimaterial
							deleteItem material.materialIDList j
						) else (
							-- TODO: I advise you not to call this script multiple times for the same GBXModel on the same scene file, or you may end up with a huge Map library containing duplicate bitmaps
							-- The parent class of BitmapTexture is TextureMap, and diffuseMap can take any instance of TextureMap, just saying
							newMap = bitmaptexture filename: (bitmaps[j])
							subMaterial.diffuseMap = newMap
							-- Toggles "on" the "show shaded materials in viewport" option of the submaterial
							subMaterial.showInViewport = on
							-- This allows changing the display diffuse color, not used here, keeping it for the record: subMaterial.diffuse = random (color 0 0 0) (color 255 255 255)
						)
					)
				)
			)
		)
	)	
)

rollout myRollout "Bitmap Buddy (GBXModel Bitmap Importer)" width:480 --width:640 height:480
(
	-- GroupBox has a name and a title, and may have dimensions: when using it instead of group(), it must not have parentheses enclosing its contents, and they must be arranged manually using "pos", it seems
    --GroupBox file_group "Load Paths"
	group "Load Paths" -- Default height for vertical group padding seems to be 24, horizontal, 12
    (
		-- In this group, separate labels are used to identify each textbox because their label and text are hardly visible with "enabled: false"
        button invader_button "Set Invader Installation Path" pos:[12,24] width:222 height:32 -- width:302 when rollout width is 640
		button halo_button "Set Halo Installation Path" pos:[12 + 222 + 12,24] width:222 height:32 -- width:302 when rollout width is 640
		label invader_label "Invader: " -- Default height for these seems to be 16
		edittext invader_textbox "" text:"" enabled:false --height:24
		label halo_label "Halo: "
		edittext halo_textbox "" text:"" enabled:false --height:24
		button save_settings_button "(Optional) Save Paths" width: 160 height:32
    )
	group "Load Model"
	(
		button model_button "Load Model" width:160 height:32 --width:616 --pos:[12,168] -- 168 = 24 + 32 + 64 + 24 + 24
		label model_label "Model: "
		edittext model_textbox "" enabled:false
	)
	group "Import bitmaps"
	(
		button import_bitmaps_button "Import Bitmaps" width:160 height:32 enabled:false --width:616
		label version_label version align:#right
	)
	
	on myRollout open do (
		invaderTextbox = invader_textbox
		haloTextbox = halo_textbox
		loadSettingsPaths invaderTextbox haloTextbox
	)
	
	on myRollout close do (
	)
	
	on invader_button pressed do (
		invader_path = getSavePath caption:"Select Invader Installation Folder" --\
			--initialDir:""
		if invader_path != undefined then (
			invader_textbox.text = invader_path
		)
		if isRolloutReady invader_textbox.text halo_textbox.text model_textbox.text then (
			import_bitmaps_button.enabled = true
		)
	)
	
	on halo_button pressed do (
		halo_path = getSavePath caption:"Select Halo Installation Folder" --\
			--initialDir:""
		if halo_path != undefined then (
			halo_textbox.text = halo_path
		)
		if isRolloutReady invader_textbox.text halo_textbox.text model_textbox.text then (
			import_bitmaps_button.enabled = true
		)
	)
	
	on save_settings_button pressed do (
		invaderPath = invader_textbox.text
		haloPath = halo_textbox.text
		saveSettingsPaths invaderPath haloPath
	)
	
	on model_button pressed do (
		model_path = getOpenFileName caption:"" \
			types:"GBXModel Tag (*.gbxmodel)|*.gbxmodel" --\
			--filename:"" \
		if model_path != undefined then (
			model_textbox.text = model_path
		)
		if isRolloutReady invader_textbox.text halo_textbox.text model_textbox.text then (
			import_bitmaps_button.enabled = true
		)
	)
	
	on import_bitmaps_button pressed do (
		runLuaLauncher invader_textbox.text halo_textbox.text model_textbox.text
		dataSuperArray = getDataFromDataFile()
		if dataSuperArray != undefined then (
			setupSceneMaterials dataSuperArray
		)
	)
	
)

createDialog myRollout --width:250 height:100