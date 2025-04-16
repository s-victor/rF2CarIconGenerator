# rF2CarIconGenerator

Fully automated car skin livery icon generator for `rFactor 2`.

This tool automates and streamlines the entire process of car skin livery icon creation, by automatically renaming showroom screenshots to corresponding vehicle file name and generating full set of rF2-standard icons.

With this tool, all it needs is to load up car in showroom, and press `in-game screenshot hotkey`, then this tool will take care of the rest and generate a whole set of icons in a second.

Special thanks to `DJCruicky` for the inspiration of utilizing rF2's Rest API via AHK.

![preview](https://github.com/user-attachments/assets/19d7624b-8141-491b-8daf-e301f9e80e89)

## Requirements

This tool requires installation `ImageMagick` v7.0 or higher for processing and resizing image file, it can be downloaded from (https://imagemagick.org). If `ImageMagick` is not installed, icon generating will not work.

Note, when installing `ImageMagick`, make sure `Add application directory to your system path` option is selected, otherwise it may not work.

## Usage

1. Download `rF2CarIconGenerator` from [Release](https://github.com/s-victor/rF2CarIconGenerator/releases) page, and install `ImageMagick`.

2. Extract `rF2CarIconGenerator.exe` file, place it in `rFactor 2` game root folder. This is required for correctly locating and accessing game's `ScreenShots` folder.

3. Launch `rF2CarIconGenerator`, click `Start Monitoring` button to enable automated screenshots `renaming` and icon `generating`.  
Note, if you are creating icons in `Dev Mode`, toggle on `Dev Mode` check-box.

4. Launch `rF2`, select a side view type showroom for creating icons, such as the `SideView UI` or `EasyIconCreatorShowroom` showroom.

5. Load a vehicle in showroom, and hide top bar (or side bar in Dev Mode), then Press `1` to hide showroom background.

6. Press `in-game screenshots hotkey`, and this tool will automatically rename and generate full icon set for selected vehicle, done. Repeat this step for other vehicles or skins to create more icons.

    > Note, screenshots must be done using in-game screenshots hotkey, which is defined in rF2's "Assign Controls" setting. Screenshots made using Steam "In Game" hotkey or from other APP will not work.

    > Generating progress is queued, which means you can start taking screenshots for next car skin while current icon generating is in progress.

Finally, generated icons are located in:
- For main game: `rFactor 2\UserData\ScreenShots\IconOutput`
- For Dev Mode: `rFactor 2\ModDev\UserData\ScreenShots\IconOutput`

## Options

- Dev Mode:
    - Enable this to detect and generate icons from `rF2 development mode`.
- Generate Icon:
    - Enable icon auto-generating.
- Finish Beep:
    - Play short beep sounds when screenshot file renamed, or icon set fully generated.
- Stay On Top:
    - Keep this tool on top of rF2 or other windows, useful for monitoring icon generating progress while taking screenshots. Note, rF2 must be running in `windowed` or `borderless` mode to allow this tool visible on top of rF2.

## Additional Notes

### How it works

While `Start Monitoring` enabled, this tool monitors `UserData\ScreenShots` folder for any changes made recently. If newly created screenshot is detected in this folder, this tool will automatically retrieve corresponding vehicle skin livery file name (VEH) info from `rF2 Rest API`, and rename new screenshot with this skin file name. Then it automatically activates icon set generating process and saving them to `ScreenShots\IconOutput` folder.

### What happens if multiple screenshots are taken for the same skin livery

Newer screenshot will simply override older ones of the same skin livery, and icon set will be regenerated for the same skin livery.

### Rest API & URL Port

The auto-renaming feature relies on rF2's `Rest API` to function correctly, which this tool will automatically connect to Rest API `URL Port` to retrieve vehicle data. This `URL Port` value, by game's default setting, points towards `5397`, which will work out of box automatically.

However, under extremely rare cases, the game may change its default Rest API `Port` value to something else, which could cause connection failure for this tool and show an `Error (abort)` message in `Vehicle File Name` box. If that happens, you will need to manually edit game's `player.json` file and fix the port value back to `5397`. This file is located in following folder:
- For main game: `rFactor 2\UserData\player`
- For Dev Mode: `rFactor 2\ModDev\UserData\player`

Once found `player.json` file, open it with notepad, search for `"WebUI port"`, and change its value back to `5397`, then save it (make sure game is closed before saving the file), and restart game to take effect.

### Regenerate icons

It is possible to regenerate icons by clicking `Regenerate`, provided that original screenshot files are available in `ScreenShots` folder. Generating progress can be viewed from `log` and `status bar`. Note, any screenshot file that starts with `GRAB_` prefix are excluded from regenerating process.

![gen_icon](https://github.com/user-attachments/assets/c9fa71f7-8ebc-4a77-b493-faee826ac156)

## License
rF2CarIconGenerator is licensed under the [MIT License](./LICENSE.txt).
