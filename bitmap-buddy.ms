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
	-- TODO: at the moment, for Windows only. I don't know if 3DS Max has built-in OS detection functions
	return pathConfig.appendPath (getBitmapBuddyLocation()) "settings.txt"
)

function isRolloutReady invader_path halo_path model_path = (
	-- This function checks whether the Invader path, Halo path and the GBXModel path have been set: returns true if all paths have been set; otherwise, returns undefined
	-- Expects arguments to be the "text" property of the respective textboxes (edittext) from this rollout
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
		-- Read settings if found, or set up the settings file
		settingsFilePath = getSettingsFilePath()
		
		--messageBox settingsFilePath
		
		
		
-- 		settingsFile = openFile (settingsFilePath) mode: "r"
-- 		
-- 		if settingsFile == undefined then (
-- 			
-- 			messageBox "Could not open settings file. Creating settings file... "
-- 			newSettingsFile = undefined -- createFile "C:\\Users\\icecr\\Desktop\\settings.txt"
-- 			
-- 			if newSettingsFile == undefined then (
-- 				messageBox "Created file is undefined"
-- 			) else (
-- 				messageBox "Writing to file... "
-- 				writeLine newSettingsFile "Hello!"
-- 				messageBox "Closing settings file... "
-- 				close newSettingsFile
-- 				messageBox "Closed settings file"
-- 			)
-- 		) else (
-- 			messageBox "Closing settings file... "
-- 			close settingsFile
-- 			messageBox "Closed settings file"
-- 		)
		
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
		
	)
	
)

createDialog myRollout --width:250 height:100

-- 	on myRollout open do (
-- 		messageBox "Started rollout"
-- 		settingsFile = openFile settingsFilePath mode: "r"
-- 		if settingsFile == undefined then (
-- 			messageBox "Could not open settings file. Creating settings file... "
-- 			newSettingsFile = undefined -- createFile "C:\\Users\\icecr\\Desktop\\settings.txt"
-- 			if newSettingsFile == undefined then (
-- 				messageBox "Created file is undefined"
-- 			) else (
-- 				messageBox "Writing to file... "
-- 				writeLine newSettingsFile "Hello!"
-- 				messageBox "Closing settings file... "
-- 				close newSettingsFile
-- 				messageBox "Closed settings file"
-- 			)
-- 		) else (
-- 			messageBox "Closing settings file... "
-- 			close settingsFile
-- 			messageBox "Closed settings file"
-- 		)
-- 	)

--nameb = "Bitmap Buddy"
--prompt = "Hello World! " + nameb + " started successfully."
--nameone = 123.09 as string
--messageBox (prompt) title:"Custom Message"

-- Expects the folder to contain a settings file, and creates it if absent
--theFile = openFile ".\settings.txt" mode: "r"
--if theFile == undefined then (
--	messageBox "Invalid or inaccessible file"
--	throw "Abrupt end, invalid file"
--	messageBox "Endo!"
--) else (
--	messageBox "Valid file"
--	line1 = readLine theFile
--	line2 = readLine theFile
--	close theFile
--)