-- Bitmap buddy 3DS Max test script
-- The more I know about the GBXmodel importer as well as about MAXScript, I believe the best course of action is to merge this code with my own version of a scriptable GBXModel importer}
-- Assigning materials in an already created scene, where multimaterials are not named, and their shader count might not match that of the GBXmodel (like when it has less than 10 materials, and Max creates 10 anyway) makes things harder for a standalone script
-- Lesson learned: avoid using reserved names for variables
-- Lesson learned: to convert a variable to another data type, add "as [data type]" at the end of the assignment

-- Holy shit, this is a piece of... I will use this thing only to...
-- TODO: find a way to close the rollout automatically after certain triggers
-- TODO: add "on pressed" events for "save paths" and "import bitmaps" buttons

-- Aw, nah, the default working directory is the installation directory of 3DS Max: 
-- "C:\Program Files\Autodesk\3ds Max 2016\", because that's where the desktop shortcut starts Max... 
-- And that's where files created by default when using "createFile"
-- I can't use relative paths because, what if the user launches Max from another random directory? So I made a function to retrieve the Bitmap Buddy project location
-- This script is meant to be left at the project root folder, or it will not run correctly

version = "v0.1.0"

function getBitmapBuddyLocation = (
	scriptPath = getSourceFileName()
	scriptDirectory = pathConfig.removePathLeaf(scriptPath)
	return scriptDirectory
)

function getSettingsFilePath = (
	return pathConfig.appendPath (getBitmapBuddyLocation()) "settings.txt"
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
	-- Calls the launcher script from the DOSCommand window
	-- (Runs the Lua script that calls Invader)
	DOSCommand ("CALL " + command)
)

function getDataFromDataFile temporaryDataFilePath = (
	-- TODO
	-- Returns a... An array? Containing two arrays: one array of shader names and one array of bitmap absolute paths (or empty string)
	
	temporaryDataFile = openFile temporaryDataFilePath mode:"r"
	
	if temporaryDataFile != undefined then (
		messageBox "Opened temporary data file" title:"Information"
		
		shaderCount = readLine temporaryDataFile as Integer
		
		-- Two dimensional array, contains the shader name array as the first element, and the absolute bitmap path array as the second element
		data = #(#(), #())
		shaders = data[1]
		bitmaps = data[2]
		
		messageBox (shaderCount as String) title:"Shader count"
		
		for i = 1 to shaderCount do (
			
		)
		
		close temporaryDataFile
	) else (
		messageBox "Failed to open temporary data file" title:"Error"
	)
	
)

rollout myRollout "Bitmap Buddy (GBXModel Bitmap Importer)" width:640 --height:480
(
	-- GroupBox has a name and a title, and may have dimensions: must not have parentheses
    --GroupBox file_group "Load Paths"
	group "Load Paths" -- Default height for vertical group padding seems to be 24, horizontal, 12
    (
		-- In this group, separate labels are used to identify each textbox because their label and text are hardly visible with "enabled: false"
        button invader_button "Set Invader Installation Path" pos:[12,24] width:302 height:32
		button halo_button "Set Halo Installation Path" pos:[12 + 302 + 12,24] width:302 height:32
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
		--
	)
	
	on myRollout close do (
		--
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
		--
		runLuaLauncher invader_textbox.text halo_textbox.text model_textbox.text
		--
		
		
	)
	
)

createDialog myRollout --width:250 height:100