#include-once

#include <Utils.au3>
#include <ClickrConstants.au3>

Func SkillEnabled($skill)
   Local $range = NewPixelRange($TOP_COOLDOWN[0], $TOP_COOLDOWN[1] + ($skill * $COOLDOWN_Y_OFFSET))
   Return Not BoardRangeContainsColor($range, $COOLDOWN_COLOR)
EndFunc

Func ProgressionEnabled()
   Local $range = $PROGRESSION_PIXEL_RANGE
   Local $color = $PROGRESSION_COLOR
   Return Not BoardRangeContainsColor($range, $color, 10)
EndFunc

; Indicates if the current zone is a boss
; @return {Boolean}
Func BossFight()
   Return Mod(GetZone(), 5) == 0
EndFunc

; Return the current zone
; @return {Int}
Func GetZone()
   Local $title = WinGetTitle($WINDOW)
   Return Int(StringRegExpReplace($title, "[^0-9]", ""))
EndFunc

; Tests if a color exists in a given board pixel range
; @param {Array<Int x1, Int y1, Int x2, Int y2>} $range
; @param {Hex|Int} $color
; @param {Int} [$variance]
; @return {Boolean}
Func BoardRangeContainsColor($range, $color, $variance=0)
   Local $coord = BoardSearch($range[0], $range[1], $range[2], $range[3], $color, $variance)
   Return IsArray($coord)
EndFunc

; Search the game board for a color in a given pixel range
; @param {Int} $left
; @param {Int} $top
; @param {Int} $right
; @param {Int} $bottom
; @param {Int|Hex} $color
; @param {Int} [$variance]
;
; @return {Array<Int,Int>}
Func BoardSearch($left, $top, $right, $bottom, $color, $variance=0)
   Local $topLeft       = TranslateCoords($left, $top)
   Local $bottomRight   = TranslateCoords($right, $bottom)

   $left    = $topLeft[0]
   $top     = $topLeft[1]
   $right   = $bottomRight[0]
   $bottom  = $bottomRight[1]

   Return ColorSearch($left, $top, $right, $bottom, $color, $variance)
EndFunc

; Find the game board within the browser window
; @param {Boolean} [$reset]
; @return {Array<Int,Int>}
Func FindBoard($reset = False)

   Static Local $lastLeftX = 0
   Static Local $lastTopY = 0
   Static Local $lastWidth = 0
   Static Local $lastHeight = 0
   Static Local $lastCoord[] = [0, 0]

   Local $poz = WinGetPos($WINDOW)

   Local $boardLeftX = $poz[0]
   Local $boardTopY = $poz[1]
   Local $width = $poz[2]
   Local $height = $poz[3]

   If Not $reset And _
      $boardLeftX = $lastLeftX And _
      $boardTopY  = $lastTopY And _
      $width      = $lastWidth And _
      $height     = $lastHeight Then
      Return $lastCoord
   EndIf

   $lastLeftX = $boardLeftX
   $lastTopY = $boardTopY
   $lastWidth = $width
   $lastHeight = $height

   Local $leftCutoff =  $boardLeftX + Int($width/2)
   Local $topCutoff =  $boardTopY + Int($height/2)

   Local $leftYSearchPos = $boardTopY + Floor($height/2)
   Local $topXSearchPos = $boardLeftX + Floor($width/2 - $BOARD_WIDTH/4)

   Local $left = ColorSearch($boardLeftX, $leftYSearchPos, $leftCutoff, $leftYSearchPos, $LEFT_EDGE_COLOR, 20)
   Local $top = ColorSearch($topXSearchPos, $boardTopY, $topXSearchPos, $topCutoff, $TOP_EDGE_COLOR, 20)

   $lastCoord[0] = $left[0]
   $lastCoord[1] = $top[1] + $TOP_OFFSET
   Return $lastCoord
EndFunc


Func TranslateCoords($x, $y)
   Local $board = FindBoard()
   Local $coords[] = [$x+$board[0], $y+$board[1]]
   Return $coords
EndFunc

Func ScreenCoordsToBoardCoords($x, $y=Null)
   If $y == Null And IsArray($x) Then
      $y = $x[1]
      $x = $x[0]
   EndIf

   Local $board = FindBoard(true)
   Local $coords[] = [$x - $board[0], $y - $board[1]]
   Return $coords
EndFunc 


Func CursorInfo()
   Static $info_on = False
   $info_on = Not $info_on

   
   While $info_on
      Local $mouse = MouseGetPos()
      Local $coord = ScreenCoordsToBoardCoords($mouse)

      Local $pixelHex = HexStr(PixelGetColor($mouse[0], $mouse[1]))

      Tooltip("Screen: " & CoordStr($mouse) & " Board: " & CoordStr($coord) & " " & "Hex: " & $pixelHex)
   Wend
EndFunc