' Launch aria2c in background (no window); used by start.bat and autostart
Option Explicit
Dim fso, sh, base, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh = CreateObject("WScript.Shell")
base = fso.GetParentFolderName(WScript.ScriptFullName)
sh.CurrentDirectory = base
cmd = """" & base & "\aria2c.exe""" & _
      " --conf-path=""" & base & "\conf\aria2.conf""" & _
      " --input-file=""" & base & "\conf\aria2.session"""
sh.Run cmd, 0, False