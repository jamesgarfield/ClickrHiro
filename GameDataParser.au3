#include-once

#include <Utils.au3>
#include <ClickrConstants.au3>
#include <Controls.au3>
#include <_Base64.au3>
#include <JSMN.au3>

; Get the currently cached game data
Func GameData($data=Null)
   Static Local $game_data = Null
   If $data <> Null Then
      $game_data = $data
   ElseIf $data == Null And $game_data == Null Then
      ResetGameData()
   EndIf
   Return $game_data
EndFunc

; Set the game data cache
Func ResetGameData()
   CopyGameFile()
   Return GameData(RetrieveGameData())
EndFunc

; Get the game file from the clipboard and parse it to an object
Func RetrieveGameData()
   Return ParseGameFile(GetClipboard())
EndFunc

; Get the current level for a given hero according to game data
; @param {HeroEnum} $hero
; @return {Int}
Func GameDataHeroLevel($hero)
   Local $data = GameData()
   Local $collection = Jsmn_ObjGet($data, "heroCollection")
   
   Local $heroes = Jsmn_ObjGet($collection, "heroes")
   
   Local $heroData = Jsmn_ObjGet($heroes, String($hero+1))
   Local $level = Jsmn_ObjGet($heroData, "level")
   Return $level
EndFunc

; Decrypt & parse the raw text of a game save file into a jsmn 'js' object
; Reference: http://www.rivsoft.net/content/click.html function Import()
; @param {String} $raw
; @return {String};
Func ParseGameFile($raw)
   Local Const $ANTI_CHEAT_CODE = "Fe12NAfA3R6z4k0z"
   Local Const $SALT = "af0ik392jrmt0nsfdghy0"

   Local $decrypt = ""
   If StringInStr($raw, $ANTI_CHEAT_CODE) Then
      Local $result = StringSplit($raw, $ANTI_CHEAT_CODE, 1)
      Local $data = $result[1]
      Local $hash = $result[2]
      
      For $i = 1 To StringLen($data) Step 2
         $decrypt = $decrypt & StringMid($data, $i, 1)
      Next
      
   EndIf
   Local $json = _Base64Decode($decrypt)
   Return Jsmn_Decode($json)
EndFunc


Func GetClipboard()
   Local $data = ClipGet()
   If @error Then
      If @error == 1 Then
         Dbg("Empty Clipboard")
      ElseIf @error == 2 Then
         Dbg("Non-Text")
      Else
         Dbg("Access Error:" & @error)
      EndIf
   EndIf
   Return $data
EndFunc