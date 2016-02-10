Set shell = WScript.CreateObject("WScript.Shell")
Set fs = CreateObject("Scripting.FileSystemObject")
Set darRegex = New RegExp
With darRegex
	.Pattern = "Video:.*DAR (\d+):(\d+)"
	.IgnoreCase = True
End With
Set resolutionRegex = New RegExp
With resolutionRegex
	.Pattern = "Video:.*, (\d+)x(\d+)"
	.IgnoreCase = True
End With
Dim line
Dim width
Dim height
Dim command
Dim FFMPEG_EXECUTABLE_PATH
Dim OUTPUT_PATH


FFMPEG_EXECUTABLE_PATH = "bin\\ffmpeg.exe"
OUTPUT_PATH = "out.alpha.3g2"

If Not fs.FileExists(WScript.Arguments(0)) Then
	WScript.Echo("Video file does not exist: " & WScript.Arguments(0))
	WScript.Quit(1)
End If

Set exec = shell.exec("CMD /S /C "" " & FFMPEG_EXECUTABLE_PATH & " -i """ & WScript.Arguments(0) & """ >video.info 2>&1 """)
Do While exec.Status = 0
	WScript.Sleep(50)
Loop

Set aspectRatioFile = fs.OpenTextFile("video.info", 1)
line = ""
Do While aspectRatioFile.AtEndOfStream <> True
	line = line & aspectRatioFile.ReadLine()
Loop

Set darRegexMatch = darRegex.Execute(line)

If darRegexMatch.Count > 0 Then
	width = darRegexMatch.Item(0).Submatches(0)
	height = darRegexMatch.Item(0).Submatches(1)
Else
	Set resolutionRegexMatch = resolutionRegex.Execute(line)

	If resolutionRegexMatch.Count = 0 Then
		WScript.Echo("Could not find aspect ratio of video")
		WScript.Quit(1)
	End If

	width = resolutionRegexMatch.Item(0).Submatches(0)
	height = resolutionRegexMatch.Item(0).Submatches(1)
End If

WScript.Echo("Video display aspect ratio determined to be " & width & ":" & height)

height2 = CStr(2 * CInt(height))

REM Entered characters won't print while ffmpeg is executing, so take over ffmpeg's task of asking user whether to overwrite
If fs.FileExists(OUTPUT_PATH) Then
	WScript.StdOut.Write("Output file " & OUTPUT_PATH & " already exists, do you want to overwrite? [yN] ")

	answer = WScript.StdIn.ReadLine
	if Not InStr(answer, "y") = 1 And Not InStr(answer, "Y") = 1 Then
		WScript.Quit(1)
	End If
End If

command = "CMD /S /C "" " & FFMPEG_EXECUTABLE_PATH & " -i """ & WScript.Arguments(0) & """ -vf ""[orig] transpose=dir=2 [rotated]; [rotated] split [a][b]; [b] alphaextract [alphaAsGrayscale]; [alphaAsGrayscale] pad=iw*2:ih:iw:0 [alphaAsGrayscalePadded]; [alphaAsGrayscalePadded][a] overlay"" -vcodec mpeg4 -s 176x144 -aspect " & height2 & ":" & width & " -vb 215000 -r 20 -acodec aac -strict experimental -ar 22050 -y " & OUTPUT_PATH & " 2>&1 """
WScript.Echo(command)
Set conversionExec = shell.exec(command)

Do While conversionExec.Status = 0
	Do While Not conversionExec.StdOut.AtEndOfStream
		WScript.StdOut.Write(conversionExec.StdOut.Read(1))
	Loop

	WScript.Sleep(50)
Loop

REM Print any remaining stdout lines
WScript.StdOut.Write(conversionExec.StdOut.ReadAll())
