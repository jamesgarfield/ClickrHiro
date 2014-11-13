;This program is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 3 of the License, or
;(at your option) any later version.
;
;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with this program.  If not, see <http://www.gnu.org/licenses/>.
#include-once

#include <Utils.au3>
#include <BoardState.au3>
#include <ClickrConstants.au3>
#include <Color.au3>

Global Enum $SCROLL_MODE_UNKNOWN, $SCROLL_MODE_PAGE, $SCROLL_MODE_INCREMENT

Opt("MouseClickDelay", GlobalOrDefault("CLICK_DELAY", $DEFAULT_CLICK_DELAY))

InitControls()
Func InitControls()
   OnUnPause(ActivateBoard)
EndFunc


Func EnableProgression()
   ;Didn't find progression mode, turn it on!
   If Not ProgressionEnabled() Then
      Send("a")
   EndIf
EndFunc

Func EnableFarming()
   If ProgressionEnabled() Then
      Send("a")
   EndIf
EndFunc

Func BuyAllUpgrades()
   ScrollToBuyUpgrades()
   Click($BUY_UPGRADES_RANGE[0], $BUY_UPGRADES_RANGE[1], 3)
EndFunc


Func ClickInKillZone($count=1)
   Local $x = Random($GOLD_ZONE[0], $GOLD_ZONE[2], 1)
   Local $y = Random($GOLD_ZONE[1], $GOLD_ZONE[3], 1)

   Click($x, $y, $count)
EndFunc

Func MoveToGoldZone()
   Local $x = Random($GOLD_ZONE[0], $GOLD_ZONE[2], 1)
   Local $y = Random($GOLD_ZONE[1], $GOLD_ZONE[3], 1)
   Local $coord = TranslateCoords($x, $y)
   MouseMove($coord[0], $coord[1], $MOUSE_SPEED)
EndFunc 

; Send a given number of clicks to a hero row
; @param {Int} $row
; @param {Int} [$count]
Func ClickHeroRow($row, $count=1)
   If $count <= 0 Then
      Return
   EndIf

   If $count >= 100 Then
      Send("{CTRLDOWN}")
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], 1)
      Send("{CTRLUP}")
      Return ClickHeroRow($row, $count-100)
   ElseIf $count >= 25 Then
      Send("{z down}")
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], 1)
      Send("{z up}")
      Return ClickHeroRow($row, $count-25)
   ElseIf $count >= 10 Then
      Send("{SHIFTDOWN}")
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], 1)
      Send("{SHIFTUP}")
      Return ClickHeroRow($row, $count-10)
   Else
      Click($HERO_ROW_X, $HERO_ROW_Y[$row], $count)
   EndIf
EndFunc

Func ClickHeroTab()
   Local $x = $HERO_TAB[0]
   Local $y = $HERO_TAB[1]
   Click($x, $y)
EndFunc

Func ScrollMode($mode=Null)
   Static Local $scroll_mode = $SCROLL_MODE_PAGE
   If $mode <> NULL Then
      $scroll_mode = $mode
   EndIf
   Return $scroll_mode
EndFunc

; Scroll to a given hero page
; @param {Int} $page
Func ScrollToPage($p)
   Static Local $current_page = -1
   Static Local $delay = GlobalOrDefault("PAGE_SCROLL_DELAY", $DEFAULT_PAGE_SCROLL_DELAY)

   ScrollMode($SCROLL_MODE_PAGE)

   If $current_page <> $p Then
      ;Pages at the end get really close together, rescroll to top to ensure a good click
      If $current_page >= 5 And $p >= 5 Then
         Click($SCROLL_TOP[0], $PAGE_SCROLL[0])
         Sleep($delay)
      EndIf
      Click($SCROLL_TOP[0], $PAGE_SCROLL[$p])
      $current_page = $p
      Sleep($delay)
   EndIf
EndFunc

Func HeroRibbonOffset($offset=Null)
   Static Local $window_offset = 0
   If $offset <> Null Then
      $window_offset = $offset
   EndIf
   Return $window_offset
EndFunc

Func ClickScrollToHero($hero)
   
   Local $offset
   If ScrollMode() == $SCROLL_MODE_INCREMENT Then
      $offset = HeroWindowOffset()
   Else
      ScrollMode($SCROLL_MODE_INCREMENT)
      $offset = 0
   EndIf


   Local $heroDepth = ($hero * $HERO_ROW_HEIGHT) + $HERO_ROW_HEIGHT

   Local $windowHeight = PixelRangeHeight($HERO_WINDOW)

   
   
   Local $end = $offset + $windowHeight

   Local $moved
   While $end < $heroDepth And RunBot() And Not Paused()
      $moved = ScrollDown()
      $offset += $moved
      $end = $offset + $windowHeight
   WEnd

   HeroWindowOffset($offset)

   Local $heroY = $HERO_WINDOW[3] - ($end - ($heroDepth - Floor($HERO_ROW_HEIGHT/2)))

   Local $heroTarget = TranslateCoords($HERO_ROW_X, $heroY)

   MouseMove($heroTarget[0], $heroTarget[1], $MOUSE_SPEED)
EndFunc

Func VisibleHeroRibbon()
   Static Local $window_height = PixelRangeHeight($HERO_WINDOW)
   Static Local $left = $HERO_WINDOW[0]
   Static Local $right = $HERO_WINDOW[2]

   Local $offset = HeroRibbonOffset()
   Return NewPixelRange($left, $offset, $right, $offset + $window_height)
EndFunc

Func PixelRangeContains($container, $search)
   Local $horz = $search[0] >= $container[0] And $search[2] <= $container[2]
   Local $vert = $search[1] >= $container[1] And $search[3] <= $container[3]
   Return $horz And $vert
EndFunc

Func HeroYRibbon($hero)
   Return ($hero * $HERO_ROW_HEIGHT) + $HERO_ROW_HEIGHT
EndFunc

Func HeroYPanel($hero)
   Static Local $window_height = PixelRangeHeight($HERO_WINDOW)

   Local $offset = HeroWindowOffset()
   Local $heroDepth = HeroYRibbon()
   
   Local $ribbon = VisibleHeroRibbon()
   Local $ribbonBottom = $ribbon[3]
   Local $windowBottom = $HERO_WINDOW[3]

   Local $heroY = $windowBottom - ($ribbonBottom - ($heroDepth - Floor($HERO_ROW_HEIGHT/2)))

   Return $heroY         
EndFunc


Func ScrollDown()
   Local $window = TranslateRange($HERO_WINDOW)
   Local $pre = PixelColumn($window)
   ClickInRange($SCROLL_DOWN)
   ClickInRange($SCROLL_DOWN)
   Sleep(300)
   Local $post = PixelColumn($window)
   Local $o = Overlap($pre, $post)
   HeroRibbonOffset(HeroRibbonOffset() + $o[0])
EndFunc

Func Overlap($pre, $post)
   Local $MIN_MATCH = 10
   Local $MAX_MATCH = 54

   $pre = Map(NormalizeBoardRGB, $pre)
   $post = Map(NormalizeBoardRGB, $post)

   Local $len = UBound($post)
   Local $matched
   
   Local $subSeq[] = [0, 0]
   For $searchFrom in Range($len)
      $matched = 0
      For $i in Range($len-$searchFrom)
         If $pre[$searchFrom + $i] == $post[$i] Then
            $matched += 1

            If $matched >= $MAX_MATCH Then
               ExitLoop
            EndIf
         Else
            ExitLoop
         EndIf
      Next

      If $matched >= $MIN_MATCH And $matched > $subSeq[1] Then
         $subSeq[0] = $searchFrom
         $subSeq[1] = $matched
      EndIf

      If $matched >= $MAX_MATCH Then
         Return $subSeq
      EndIf
   Next
   Return $subSeq
EndFunc

Func NormalizeBoardRGB($c)
   Local $rgb = [_ColorGetRed($c), _ColorGetGreen($c), _ColorGetBlue($c)]
   Local $normalized = _ColorSetRGB(Map(RoundColorTo10, $rgb))
   Return $normalized
EndFunc

Func RoundColorTo10($n)
   Return _Min(Int(Round($n/10)*10), 255)
EndFunc

Func ScrollToHero($hero)
   Local $page = $HERO_BUTTON[$hero][0]
   ScrollToPage($page)
EndFunc

Func ScrollToBuyUpgrades()
   Static Local $page = UBound($PAGE_SCROLL) - 1
   ScrollToPage($page)
EndFunc

; Navigate options to put game data into the clipboard
Func CopyGameFile()
   OpenOptions()
   ClickSaveGame()
   CloseSaveWindow()
   CloseOptions()
EndFunc

; Click on the options wrench
Func OpenOptions()
   Static Local $delay = GlobalOrDefault("OPTIONS_DELAY", $DEFAULT_OPTIONS_DELAY)
   ClickInRange($OPTIONS_BUTTON)
   Sleep($delay)
EndFunc

; Click on the red X in the options window, to close it
Func CloseOptions()
   Static Local $delay = GlobalOrDefault("OPTIONS_DELAY", $DEFAULT_OPTIONS_DELAY)
   ClickInRange($CLOSE_OPTIONS)
   Sleep($delay)
EndFunc  

; Click the save buttton in the options menu
Func ClickSaveGame()
   Static Local $delay = GlobalOrDefault("OPTIONS_DELAY", $DEFAULT_OPTIONS_DELAY)
   ClickInRange($SAVE_BUTTON)
   Sleep($delay)
EndFunc

; Activate the "Save As" dialog from saving game data and close it
Func CloseSaveWindow()
   Static Local $delay = GlobalOrDefault("OPTIONS_DELAY", $DEFAULT_OPTIONS_DELAY)
   WinActivate("Save As")
   Send("{ESC}")
   Sleep($delay)
EndFunc

;Click in the center of a range a given number of times
; @param {PixelRange} $range
; @param {Int} [$count=1]
Func ClickInRange($range, $count=1)
   Local $x = Int($range[2] + ($range[2]-$range[0])/2)
   Local $y = Int($range[1] + ($range[1]-$range[3])/2)
   Click($x, $y, $count)
EndFunc

; Click on the game board a given number of times.
; Performs x,y coordinate translations from board x,y to screen x,y
; @param {Int} $row
Func Click($x, $y, $count=1)
   Local $board = FindBoard()
   MouseClick("left", $x + $board[0], $y + $board[1], $count, $MOUSE_SPEED)
EndFunc

Func ActivateBoard()
   WinActivate($WINDOW)
   FindBoard(true)
   ClickHeroTab()
   ScrollToPage(7)
   ScrollToPage(0)
EndFunc

; Get the display name of a hero
; @param {HeroEnum} $hero
; @return {String}
Func HeroName($hero)
   Return $HERO_NAME[$hero]
EndFunc