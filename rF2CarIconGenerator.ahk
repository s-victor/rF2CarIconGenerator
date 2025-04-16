; This script requires AutoHotKey v2 to run
; Icon generating requires ImageMagick 7.0 (https://imagemagick.org) or higher

#SingleInstance Ignore
#NoTrayIcon
KeyHistory 0

; Metadata
TITLE := "rF2 Car Icon Generator"
DESCRIPTION := "Fully automated car skin livery icon generator for rF2."
AUTHOR := "S.Victor"
VERSION := "0.2.0"

; Player path check
if (!FileExist(A_WorkingDir "\Bin64\rFactor2.exe"))
{
    MsgBox(
        "This program must be placed in 'rFactor 2' root folder to run.`n`n"
        "Please place this program in 'rFactor 2' root folder, then try again.`n`n",
        TITLE,
    )
    ExitApp
}

; Constant & Variable
EXE_NAME := "rFactor2"
CRLF := "`r`n"
URL_SOURCE := [
    "http://localhost:5397/rest/garage/summary",
    "http://localhost:5397/rest/tuning/skins",
]
DEFAULT_SOURCE := 1  ; use "2" if "1" fails
OUTPUT_FOLDER_NAME := "IconOutput"
PATH_SCREENSHOT := ""
PATH_OUTPUTICON := ""
IS_RUNNING := false
IS_MONITORING := false
LAST_RUNNING := false
LAST_TIMESTAMP := A_Now  ; set launch time for file-modified-date check
LAST_APIDATA := "None"
VALID_CARNAME := false
MAX_LEN_CARNAME := 50

ConnRestAPI := ComObject("WinHttp.WinHttpRequest.5.1")

; GUI
ToolGui := Gui(, TITLE " v" VERSION)
ToolGui.SetFont(, "Arial")
ToolGui.OnEvent("Close", DialogClose)
StatBar := ToolGui.Add("StatusBar", , "")

panel_width := 400
win_margin_x := ToolGui.MarginX
win_margin_y := ToolGui.MarginY

; Status
status_pos_y := win_margin_y
status_height := 70

ToolGui.Add("GroupBox", "x" win_margin_x " y" status_pos_y " w" panel_width " h" status_height, "Status")
IsRunningText := ToolGui.Add("Text", "x20 y" status_pos_y + 22 " w250", "")
IsMonitoringText := ToolGui.Add("Text", "x20 y" status_pos_y + 44 " w250", "")
DevModeChecker := ToolGui.Add("Checkbox", "x333 y" status_pos_y + 19 " w70 h20", "Dev Mode")
GenIconChecker := ToolGui.Add("Checkbox", "x310 y" status_pos_y + 41 " w100 h20 Checked", "Generate Icon")
DevModeChecker.OnEvent("Click", SetDetectionMode)

SetDetectionMode()

; Vehicle info
vehicleinfo_pos_y := status_pos_y + status_height + 6
vehicleinfo_height := 53

ToolGui.Add("GroupBox", "x" win_margin_x " y" vehicleinfo_pos_y " w" panel_width " h" vehicleinfo_height, "Vehicle File Name (VEH)")
VehicleNameText := ToolGui.Add("Edit", "x20 y" vehicleinfo_pos_y + 22 " w233 h21 ReadOnly")
ButtonStart := ToolGui.Add("Button", "x" 258 " y" vehicleinfo_pos_y + 21 " h23", "Start Monitoring")
ButtonStart.OnEvent("Click", StartMonitoringStatus)
ButtonStop := ToolGui.Add("Button", "x" 363 " y" vehicleinfo_pos_y + 21 " h23", "Stop")
ButtonStop.OnEvent("Click", StopMonitoringStatus)

UpdateRunningStatus(False)
StopMonitoringStatus()

; Buttons
button_pos_y := vehicleinfo_pos_y + vehicleinfo_height + 8

ButtonClear := ToolGui.Add("Button", "x" win_margin_x - 1 " y" button_pos_y " h23", "Clear Log")
ButtonClear.OnEvent("Click", DialogConfirmClear)
ButtonRegen := ToolGui.Add("Button", "x" win_margin_x + 73 " y" button_pos_y " h23", "Regenerate")
ButtonRegen.OnEvent("Click", DialogConfirmRegen)
ButtonAbout := ToolGui.Add("Button", "x365 y" button_pos_y " h23", "About")
ButtonAbout.OnEvent("Click", DialogAbout)
FinishBeepChecker := ToolGui.Add("Checkbox", "x" win_margin_x + 160 " y" button_pos_y + 2 " w90 h20 Checked", "Finish Beep")
StayOnTopChecker := ToolGui.Add("Checkbox", "x" win_margin_x + 250 " y" button_pos_y + 2 " w90 h20", "Stay On Top")
StayOnTopChecker.OnEvent("Click", ToggleStayOnTop)

; Output tab
output_pos_y := button_pos_y + 32
output_height := 383

OutputLog := ToolGui.Add(
    "Edit",
    " x" win_margin_x
    " y" output_pos_y
    " w" panel_width
    " h" output_height - output_pos_y
    " ReadOnly"
)
OutputLog.SetFont(, "Consolas")
ToolGui.Add("GroupBox", "x" win_margin_x " y" output_height + 1 " w401 h30 cGray",)
GenProgress := ToolGui.Add("Progress", "x" win_margin_x + 1 " y" output_height + 9 " w398 h20 cGreen vMyProgress", 100)

; Start GUI
ToolGui.Show()

; Main loop
SetTimer MainLoop, 100


MainLoop()
{
    global LAST_RUNNING
    is_running := WinExist("ahk_exe" EXE_NAME ".exe")
    if (LAST_RUNNING != is_running)
    {
        LAST_RUNNING := is_running
        UpdateRunningStatus(is_running)
    }
    if (is_running and IS_MONITORING)
    {
        MonitorScreenShots()
    }
}


; Function
UpdateVehicleInfo()
{
    global LAST_APIDATA, VALID_CARNAME
    api_data := GetRestAPIData()
    if (LAST_APIDATA != api_data)
    {
        LAST_APIDATA := api_data
        if (api_data == "" or StrLen(api_data) > MAX_LEN_CARNAME or api_data == "Error (abort)")
        {
            VehicleNameText.Value := ""
            VALID_CARNAME := false
        }
        else
        {
            VehicleNameText.Value := api_data
            VALID_CARNAME := true
        }
    }
}


GetRestAPIData()
{
    try
    {
        ConnRestAPI.Open("GET", URL_SOURCE[DEFAULT_SOURCE], true)
        ConnRestAPI.Send()
        ConnRestAPI.WaitForResponse(3)  ; 3 sec timeout
        if (DEFAULT_SOURCE == 1)
        {
            data := ParseJSON(ConnRestAPI.ResponseText)
        }
        else
        {
            data := Trim(ConnRestAPI.ResponseText, "[`"]")
        }
        return data
    }
    catch Error
    {
        return "Error (abort)"
    }
}


ParseJSON(data)
{
    counter := 0
    Loop Parse, data, "{},:"
    {
        if (A_LoopField == "`"vehFile`"")
        {
            counter += 1
            continue
        }
        if (counter == 1)
        {
            counter += 1
        }
        else if (counter == 2)
        {
            return StrReplace(StrSplit(A_LoopField, "\\")[-1], ".VEH`"")
        }
    }
    return ""
}


MonitorScreenShots()
{
    global LAST_TIMESTAMP
    Loop Files, PATH_SCREENSHOT "\GRAB_*.png"
    {
        if (LAST_TIMESTAMP < A_LoopFileTimeCreated)
        {
            UpdateVehicleInfo()
            LAST_TIMESTAMP := A_LoopFileTimeCreated
            date := FormatTime(A_LoopFileTimeCreated, "HH:mm:ss")
            if (VALID_CARNAME)
            {
                ToggleGenerateState(false)
                short_name := VehicleNameText.Value
                new_veh_name := short_name ".png"
                try
                {
                    FileMove(A_LoopFileFullPath, PATH_SCREENSHOT "\" new_veh_name, 1)
                    EditPaste(date " " A_LoopFileName " > " new_veh_name " (OK)" CRLF, OutputLog)
                    if (FinishBeepChecker.Value)
                    {
                        SoundBeep(400, 100)
                        SoundBeep(400, 100)
                    }
                    if (GenIconChecker.Value)
                    {
                        StatBar.SetText(" Generating icons, please wait...")
                        GenerateSkinIcon(new_veh_name, short_name)
                        if (FinishBeepChecker.Value)
                        {
                            SoundBeep(600, 500)
                            SoundBeep(600, 500)
                        }
                        StatBar.SetText(" Generating completed.")
                    }
                }
                catch Error
                {
                    EditPaste(date " " A_LoopFileName " > " new_veh_name " (ERROR)" CRLF, OutputLog)
                    SoundBeep(500, 500)
                }
                ToggleGenerateState(true)
            }
        }
    }
}


GenerateSkinIcon(file_name, short_name)
{
    source_path := "magick convert `"" PATH_SCREENSHOT "\" file_name "`" -format png"
    dist_path := "`"" PATH_OUTPUTICON "\" short_name
    log_path := OUTPUT_FOLDER_NAME "\" short_name
    GenProgress.Value := 10
    try
    {
        RunWait source_path " -background none -trim -resize 480 -gravity Center -extent 512x512 " dist_path "icon.png`"", , "Hide"
        EditPaste(log_path "icon.png" CRLF, OutputLog)
        GenProgress.Value := 25

        RunWait source_path " -trim -resize x72 " dist_path "-icon-128x72.png`"", , "Hide"
        EditPaste(log_path "-icon-128x72.png" CRLF, OutputLog)
        GenProgress.Value := 40

        RunWait source_path " -trim -resize x144 " dist_path "-icon-256x144.png`"", , "Hide"
        EditPaste(log_path "-icon-256x144.png" CRLF, OutputLog)
        GenProgress.Value := 55

        RunWait source_path " -trim -resize x288 " dist_path "-icon-512x288.png`"", , "Hide"
        EditPaste(log_path "-icon-512x288.png" CRLF, OutputLog)
        GenProgress.Value := 70

        RunWait source_path " -trim -resize x576 " dist_path "-icon-1024x576.png`"", , "Hide"
        EditPaste(log_path "-icon-1024x576.png" CRLF, OutputLog)
        GenProgress.Value := 85

        RunWait source_path " -trim -resize x1152 " dist_path "-icon-2048x1152.png`"", , "Hide"
        EditPaste(log_path "-icon-2048x1152.png" CRLF, OutputLog)
    }
    catch Error
    {
        MsgBox("Unable to generate icon, make sure 'ImageMagick' is installed.", "Error")
    }
    GenProgress.Value := 100
}


UpdateRunningStatus(is_running)
{
    if (is_running)
    {
        IsRunningText.Value := EXE_NAME ": Running"
    }
    else
    {
        IsRunningText.Value := EXE_NAME ": Not running"
    }
}


StartMonitoringStatus(*)
{
    global IS_MONITORING
    IS_MONITORING := true
    IsMonitoringText.Value := "Screenshots: Monitoring"
    ButtonStart.Enabled := false
    ButtonStop.Enabled := true
}


StopMonitoringStatus(*)
{
    global IS_MONITORING
    IS_MONITORING := false
    IsMonitoringText.Value := "Screenshots: Not monitoring"
    ButtonStart.Enabled := true
    ButtonStop.Enabled := false
}


SetDetectionMode(*)
{
    global EXE_NAME
    if (DevModeChecker.Value)
    {
        EXE_NAME := "rFactor2 Mod Mode"
        UpdatePath("\ModDev\UserData\ScreenShots")
    }
    else
    {
        EXE_NAME := "rFactor2"
        UpdatePath("\UserData\ScreenShots")
    }
    UpdateRunningStatus(WinExist("ahk_exe" EXE_NAME ".exe"))
}


UpdatePath(path)
{
    global PATH_SCREENSHOT, PATH_OUTPUTICON
    ; ScreenShots path check
    PATH_SCREENSHOT := A_WorkingDir path
    if (!DirExist(PATH_SCREENSHOT))
    {
        DirCreate(PATH_SCREENSHOT)
    }
    ; Output icon path check
    PATH_OUTPUTICON := PATH_SCREENSHOT "\" OUTPUT_FOLDER_NAME
    if (!DirExist(PATH_OUTPUTICON))
    {
        DirCreate(PATH_OUTPUTICON)
    }
}


DialogAbout(*)
{
    ToolGui.Opt("+OwnDialogs")
    info := TITLE " v" VERSION CRLF "by " AUTHOR CRLF CRLF DESCRIPTION CRLF CRLF
    MsgBox(info, "About")
}


DialogConfirmClear(*)
{
    if (OutputLog.Value == "")
        return
    ToolGui.Opt("+OwnDialogs")
    choice := MsgBox(
        "Clear all log?",
        "Confirm",
        "YesNo"
    )
    if (choice == "Yes")
    {
        OutputLog.Value := ""
    }
}


DialogConfirmRegen(*)
{
    ToolGui.Opt("+OwnDialogs")
    choice := MsgBox(
        "Regenerate all icons from 'ScreenShots' to 'IconOutput' folder?`n`n"
        "Icon files in 'IconOutput' folder with the same name will be overridden.",
        "Regenerate Icon",
        "YesNo"
    )
    if (choice == "Yes")
    {
        ToggleGenerateState(false)
        StatBar.SetText(" Generating icons, please wait...")
        counter := 0
        Loop Files, PATH_SCREENSHOT "\*.png"
        {
            if (InStr(A_LoopFileName, "GRAB_", 1) != 1)
            {
                GenerateSkinIcon(A_LoopFileName, StrReplace(A_LoopFileName, ".png"))
                counter := A_Index
            }
        }
        StatBar.SetText(" Generating completed, processed icons:" counter)
        ToggleGenerateState(true)
    }
}


ToggleGenerateState(state)
{
    ButtonClear.Enabled := state
    ButtonRegen.Enabled := state
    DevModeChecker.Enabled := state
    GenIconChecker.Enabled := state
}


ToggleStayOnTop(*)
{
    WinSetAlwaysOnTop(StayOnTopChecker.Value, TITLE)
}


DialogClose(*)
{
    ; Stop event loops
    SetTimer MainLoop, 0
}