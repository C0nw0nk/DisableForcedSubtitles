@echo off & setLocal EnableDelayedExpansion

:: This script will uncheck the Forced subtitle flag on media items in your library i added some extra features you can enable below such as Removing tags and chapter markers.

:: Set the video formats to search for
set video_formats="-key1 .mkv"

:: Directory to scan
:: Path format can be Network share or Drive name
:: example
:: set plex_folder="C:\path\Movies"
:: set plex_folder="\\NAS\FOLDER\Movies"
set plex_folder=""

:: Remove all tags from media this will be XML data inside the video container that would contain information for a media player to display such as actors in a scene etc
:: 1 is to Remove
:: 0 is to Keep
set remove_all_tags=1

:: Remove all chapter markers if you do not want chapter markers or do not need them this is useful for removing them
:: 1 is to Remove
:: 0 is to Keep
set remove_all_chapter_markers=1

:: Check for the .PlexCleaner sidecar file to skip already modified media
:: 1 is to skip
:: 0 is to modify all
set check_for_sidecar=0

:: Instead of just closing the window after our automated tasking we pause to view and check once your happy you can set this to 0
:: 1 enabled
:: 0 disabled
set pause_window=1

:: Wait number of seconds
:: 0 disabled
:: 60 = 60 seconds etc
set wait_interval=0

:: If you want this script to not exit once finished and after task complete / wait interval passed recheck plex folders in a loop
:: 1 enabled
:: 0 disabled
set looping=0

:: End Edit DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOUR DOING!

TITLE C0nw0nk - Plex/Emby media disable forced subtitles

:: Make script configurable via command line with arguements example
:: "C:\path\DisableForceSubtitles.cmd" "\\NAS\path" "remove_all_tags" "remove_all_chapter_markers" "check_for_sidecar" "pause_window" "wait_interval" "looping" 2^>nul
:: Working example
:: "C:\path\DisableForceSubtitles.cmd" "\\NAS\path" "1" "1" "0" "1" "120" "1" 2^>nul

if "%~1"=="" goto :script_arguments_not_defined
set plex_folder="%~1"
set remove_all_tags=%~2
set remove_all_chapter_markers=%~3
set check_for_sidecar=%~4
set pause_window=%~5
set wait_interval=%~6
set looping=%~7
:script_arguments_not_defined

if "%plex_folder:"=%"=="" (
echo Input the Directory or Path you want to Remove Forced Subtitles flags on media items for example C:\path or you can use \\NAS\STORAGE\PATH
set /p "plex_folder="
)

set root_path="%~dp0"

if %PROCESSOR_ARCHITECTURE%==x86 (
	set programs_path=%ProgramFiles(x86)%
) else (
	set programs_path=%ProgramFiles%
)

goto :next_download
echo starting removing forced subtitle flags
:start_exe


:: Forced Subtitle code

set mkvtoolnix_path="%root_path:"=%mkvtoolnix\"
set "PATH=%PATH%;%mkvtoolnix_path:"=%"

pushd "%plex_folder:"=%" 2>nul
if errorlevel 1 goto notdir
goto :isdir

:notdir

		setlocal DisableDelayedExpansion
		echo Direct file path not a directory "%plex_folder:"=%"
		for /f "delims=" %%F in ("%plex_folder:"=%") do set "directory_path_name=%%~dpnF" && set "direct_file_name=%%~xF"
		:: Fix for files that are pasted in that are not MKV format mkvmerge and tool only accept mkv files
		if not "%direct_file_name:"=%" == ".mkv" set "plex_folder=%directory_path_name:"=%.mkv"

		rem This will remove tags and global tags from the media item if you like
		if [%remove_all_tags%]==[1] (
			echo Removing tags and global tags
			"%mkvtoolnix_path:"=%mkvpropedit.exe" "%plex_folder:"=%" --tags all:""
			if errorlevel 1 (
				echo Warnings/errors generated during removing tags and global tags
			) else (
				echo Successfully removed tags and global tags
			)
		)
		rem This will remove all chapter markers from the media item if you like
		if [%remove_all_chapter_markers%]==[1] (
			echo Removing Chapter markers
			"%mkvtoolnix_path:"=%mkvpropedit.exe" "%plex_folder:"=%" --chapters ""
			if errorlevel 1 (
				echo Warnings/errors generated during removing Chapter markers
			) else (
				echo Successfully removed Chapter markers
			)
		)
		if [%check_for_sidecar%]==[1] (
			if exist "%directory_path_name:"=%.PlexCleaner" (
				echo sidecar found
				break
			) else (
				for /f %%b in ('mkvmerge.exe -i "%plex_folder:"=%" ^| find /c /i "subtitles"') do (
					if [%%b]==[0] (
						echo "%plex_folder:"=%" has no subtitles
					) else (
						echo "%plex_folder:"=%" has subtitles
						for /l %%G in (1,1,%%b) do (
							echo Subtitle track number %%G
							"%mkvtoolnix_path:"=%mkvpropedit.exe" "%plex_folder:"=%" --edit track:s%%G --set flag-forced=0 --set name=""
							if errorlevel 1 (
								echo Warnings/errors generated during removing subtitle flags
							) else (
								echo Successfully removed subtitle flags
							)
							"%mkvtoolnix_path:"=%mkvpropedit.exe" "%plex_folder:"=%" --edit track:s%%G --set flag-default=0 --set name=""
							if errorlevel 1 (
								echo Warnings/errors generated during removing subtitle flags
							) else (
								echo Successfully removed subtitle flags
							)
						)
					)
				)
				echo creating empty sidecar on next run to not modify this already modified file
				echo "%directory_path_name:"=%.PlexCleaner"
				>"%directory_path_name:"=%.PlexCleaner" echo 1
			)
		) else (
			for /f %%b in ('mkvmerge.exe -i "%plex_folder:"=%" ^| find /c /i "subtitles"') do (
				if [%%b]==[0] (
					echo "%plex_folder:"=%" has no subtitles
				) else (
					echo "%plex_folder:"=%" has subtitles
					for /l %%G in (1,1,%%b) do (
						echo Subtitle track number %%G
						"%mkvtoolnix_path:"=%mkvpropedit.exe" "%plex_folder:"=%" --edit track:s%%G --set flag-forced=0 --set name=""
						if errorlevel 1 (
							echo Warnings/errors generated during removing subtitle flags
						) else (
							echo Successfully removed subtitle flags
						)
						"%mkvtoolnix_path:"=%mkvpropedit.exe" "%plex_folder:"=%" --edit track:s%%G --set flag-default=0 --set name=""
						if errorlevel 1 (
							echo Warnings/errors generated during removing subtitle flags
						) else (
							echo Successfully removed subtitle flags
						)
					)
				)
			)
		)
		setLocal EnableDelayedExpansion

goto :end_script

:isdir

set "comd=aws iam create-group %video_formats:"=%"
for /F "tokens=3*" %%p in ("%comd%") do set "tokens=%%q"
set n=0
set "key="
for %%a in (%tokens:-=%) do (
	if not defined key (
		set key=%%a
	) else (
		set /A n+=1
		set "token[!n!]=%%a"
		set "key="
	)
)
for /l %%i in (1,1,%n%) do (
	echo Enumerating all !token[%%i]!s under "%plex_folder:"=%"
	for /r "%plex_folder:"=%" %%a in (*!token[%%i]!) do (
		setlocal DisableDelayedExpansion
		rem echo filename %%~dpna fileextension %%~xa
		rem This will remove tags and global tags from the media item if you like
		if [%remove_all_tags%]==[1] (
			echo Removing tags and global tags
			"%mkvtoolnix_path:"=%mkvpropedit.exe" "%%a" --tags all:""
			if errorlevel 1 (
				echo Warnings/errors generated during removing tags and global tags
			) else (
				echo Successfully removed tags and global tags
			)
		)
		rem This will remove all chapter markers from the media item if you like
		if [%remove_all_chapter_markers%]==[1] (
			echo Removing Chapter markers
			"%mkvtoolnix_path:"=%mkvpropedit.exe" "%%a" --chapters ""
			if errorlevel 1 (
				echo Warnings/errors generated during removing Chapter markers
			) else (
				echo Successfully removed Chapter markers
			)
		)
		if [%check_for_sidecar%]==[1] (
			if exist "%%~dpna.PlexCleaner" (
				echo sidecar found
				break
			) else (
				for /f %%b in ('mkvmerge.exe -i "%%a" ^| find /c /i "subtitles"') do (
					if [%%b]==[0] (
						echo "%%a" has no subtitles
					) else (
						echo "%%a" has subtitles
						for /l %%G in (1,1,%%b) do (
							echo Subtitle track number %%G
							"%mkvtoolnix_path:"=%mkvpropedit.exe" "%%a" --edit track:s%%G --set flag-forced=0 --set name=""
							if errorlevel 1 (
								echo Warnings/errors generated during removing subtitle flags
							) else (
								echo Successfully removed subtitle flags
							)
							"%mkvtoolnix_path:"=%mkvpropedit.exe" "%%a" --edit track:s%%G --set flag-default=0 --set name=""
							if errorlevel 1 (
								echo Warnings/errors generated during removing subtitle flags
							) else (
								echo Successfully removed subtitle flags
							)
						)
					)
				)
				echo creating empty sidecar on next run to not modify this already modified file
				echo "%%~dpna.PlexCleaner"
				>"%%~dpna.PlexCleaner" echo 1
			)
		) else (
			for /f %%b in ('mkvmerge.exe -i "%%a" ^| find /c /i "subtitles"') do (
				if [%%b]==[0] (
					echo "%%a" has no subtitles
				) else (
					echo "%%a" has subtitles
					for /l %%G in (1,1,%%b) do (
						echo Subtitle track number %%G
						"%mkvtoolnix_path:"=%mkvpropedit.exe" "%%a" --edit track:s%%G --set flag-forced=0 --set name=""
						if errorlevel 1 (
							echo Warnings/errors generated during removing subtitle flags
						) else (
							echo Successfully removed subtitle flags
						)
						"%mkvtoolnix_path:"=%mkvpropedit.exe" "%%a" --edit track:s%%G --set flag-default=0 --set name=""
						if errorlevel 1 (
							echo Warnings/errors generated during removing subtitle flags
						) else (
							echo Successfully removed subtitle flags
						)
					)
				)
			)
		)
		setLocal EnableDelayedExpansion
	)
)

::End Forced Subtitle code

goto :end_script

goto :next_download
:start_download
set downloadurl=%downloadurl: =%
FOR /f %%i IN ("%downloadurl:"=%") DO set filename="%%~ni"& set fileextension="%%~xi"
set downloadpath="%root_path:"=%%filename%%fileextension%"
(
echo Dim oXMLHTTP
echo Dim oStream
echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
echo If Not fso.FileExists^("%downloadpath:"=%"^) Then
echo Set oXMLHTTP = CreateObject^("MSXML2.ServerXMLHTTP.6.0"^)
echo oXMLHTTP.Open "GET", "%downloadurl:"=%", False
echo oXMLHTTP.SetRequestHeader "User-Agent", "Mozilla/5.0 ^(Windows NT 10.0; Win64; rv:51.0^) Gecko/20100101 Firefox/51.0"
echo oXMLHTTP.SetRequestHeader "Referer", "https://www.google.co.uk/"
echo oXMLHTTP.SetRequestHeader "DNT", "1"
echo oXMLHTTP.Send
echo If oXMLHTTP.Status = 200 Then
echo Set oStream = CreateObject^("ADODB.Stream"^)
echo oStream.Open
echo oStream.Type = 1
echo oStream.Write oXMLHTTP.responseBody
echo oStream.SaveToFile "%downloadpath:"=%"
echo oStream.Close
echo End If
echo End If
echo ZipFile="%downloadpath:"=%"
echo ExtractTo="%root_path:"=%"
echo ext = LCase^(fso.GetExtensionName^(ZipFile^)^)
echo If NOT fso.FolderExists^(ExtractTo^) Then
echo fso.CreateFolder^(ExtractTo^)
echo End If
echo Set app = CreateObject^("Shell.Application"^)
echo Sub ExtractByExtension^(fldr, ext, dst^)
echo For Each f In fldr.Items
echo If f.Type = "File folder" Then
echo ExtractByExtension f.GetFolder, ext, dst
echo End If
echo If instr^(f.Path, "\%file_name_to_extract%"^) ^> 0 Then
echo If fso.FileExists^(dst ^& f.Name ^& "." ^& LCase^(fso.GetExtensionName^(f.Path^)^) ^) Then
echo Else
echo call app.NameSpace^(dst^).CopyHere^(f.Path^, 4^+16^)
echo End If
echo End If
echo Next
echo End Sub
echo If instr^(ZipFile, "zip"^) ^> 0 Then
echo ExtractByExtension app.NameSpace^(ZipFile^), "exe", ExtractTo
echo End If
if [%file_name_to_extract%]==[*] echo set FilesInZip = app.NameSpace^(ZipFile^).items
if [%file_name_to_extract%]==[*] echo app.NameSpace^(ExtractTo^).CopyHere FilesInZip, 4
if [%delete_download%]==[1] echo fso.DeleteFile ZipFile
echo Set fso = Nothing
echo Set objShell = Nothing
)>"%root_path:"=%%~n0.vbs"
cscript //nologo "%root_path:"=%%~n0.vbs"
del "%root_path:"=%%~n0.vbs"
:next_download

if not exist "%root_path:"=%mkvtoolnix\mkvmerge.exe" (

winget install Microsoft.DotNet.DesktopRuntime.6 >nul
winget install Microsoft.DotNet.DesktopRuntime.7 >nul

if not defined plexcleaner_exe (
	set downloadurl=https://mkvtoolnix.download/windows/releases/79.0/mkvtoolnix-64-bit-79.0.7z
	set delete_download=0
	set plexcleaner_exe=true
	goto :start_download
)


if not exist "%programs_path%\WinRAR\winrar.exe" (
if not defined winrar_exe (
	if %PROCESSOR_ARCHITECTURE%==x86 (
		set downloadurl=https://www.rarlab.com/rar/winrar-x32-620b2.exe
	) else (
		set downloadurl=https://www.rarlab.com/rar/winrar-x64-620b2.exe
	)
	set delete_download=0
	set winrar_exe=true
	goto :start_download
)
start /wait %downloadpath% /s
del %downloadpath%
(
echo RAR registration data
echo WinRAR
echo Unlimited Company License
echo UID=4b914fb772c8376bf571
echo 6412212250f5711ad072cf351cfa39e2851192daf8a362681bbb1d
echo cd48da1d14d995f0bbf960fce6cb5ffde62890079861be57638717
echo 7131ced835ed65cc743d9777f2ea71a8e32c7e593cf66794343565
echo b41bcf56929486b8bcdac33d50ecf773996052598f1f556defffbd
echo 982fbe71e93df6b6346c37a3890f3c7edc65d7f5455470d13d1190
echo 6e6fb824bcf25f155547b5fc41901ad58c0992f570be1cf5608ba9
echo aef69d48c864bcd72d15163897773d314187f6a9af350808719796
)>"%programs_path%\WinRAR\rarreg.key"
) else (
	call ^"%programs_path%\WinRAR\winrar.exe^" x ^"%root_path:"=%mkvtoolnix-64-bit-79.0.7z^" ^"*^" ^"%root_path:"=%^"
	del "%root_path:"=%mkvtoolnix-64-bit-79.0.7z"
)

)

goto :start_exe
:end_script

if %pause_window% == 1 pause

if not %wait_interval% == 0 TIMEOUT /T %wait_interval%

if %looping% == 1 goto :start_exe

exit /b
