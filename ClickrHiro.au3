#include <MsgBoxConstants.au3>
#include <Array.au3>

Global Const $VERSION = "0.2.2"

Global Const $DEBUG = False

Global Const $WINDOW = "Lvl"
Global Const $CLICK_DELAY = 3
Global Const $MOUSE_SPEED = 3

;Pixels Go Here
   ;Game area
   Global Const $BOARD_WIDTH = 1133
   Global Const $BOARD_HEIGHT = 639

   ;Top of scroll bar, under up arrow
   Global Const $SCROLL_TOP[] = [547, 201]

   ;Page scrolling postions (4 heroes per page)
   Global Const $PAGE_SCROLL[] = [201, 304, 359, 419, 474, 529, 559]

   ; Cooldowns Position
   Global Const $TOP_COOLDOWN[] = [607, 169]
   Global Const $COOLDOWN_Y_OFFSET = 51.75

   ;Level Button Positioning
   Global Const $HERO_ROW_X = 91
   Global Const $HERO_ROW_Y[] = [224, 330, 436, 542]

   ;Farm Mode Positioning
   Global Const $PROGRESSION_PIXEL_RANGE = NewPixelRange(1104, 200, 1115, 208)
;End of Pixels

;Used to find the game board within the browser window
Global Const $LEFT_EDGE_COLOR = 0x875508
Global Const $TOP_EDGE_COLOR = 0xBB7A19
Global Const $TOP_OFFSET = -3

Global Const $CANNOT_BUY_COLORS[] = [0xFE8743, 0x7E4321]
Global Const $PROGRESSION_COLOR = 0xFF0000
Global Const $COOLDOWN_COLOR = 0xFFFFFF

;HeroEnum
Global Enum $CID, _
            $TREEBEAST, _
            $IVAN, _
            $BRITTANY, _
            $FISHERMAN, _
            $BETTY, _
            $SAMURAI, _
            $LEON, _
            $SEER, _
            $ALEXA, _
            $NATALIA, _
            $MERCEDES, _
            $BOBBY, _
            $BROYLE, _
            $GEORGE, _
            $MIDAS, _
            $REFRI, _
            $ABADON, _
            $MAZHU, _
            $AMENHOTEP, _
            $BEASTLORD, _
            $ATHENA, _
            $APHRODITE, _
            $SHINATOBE, _
            $GRANT, _
            $FROSTLEAF

;Hero Page/Row combos
Global Const $HERO_BUTTON[26][2] = _
            [  [0,0], [0,1], [0,2], [0,3], _    ;Cid, Tree, Ivan, Brit
               [1,0], [1,1], [1,2], [1,3], _    ;Fish, Betty, Sam, Leon
               [2,0], [2,1], [2,2], [2,3], _    ;Seer, Alexa, Nat, Merc
               [3,0], [3,1], [3,2], [3,3], _    ;Bobby, Broyle, George, Midas
               [4,0], [4,1], [4,2], [4,3], _    ;Refri, Abadon, MaZhu, Amen
               [5,0], [5,1], [5,2], [5,3], _    ;Beast, Ahtena, Aphro, Shina
                             [6,2], [6,3]]      ;Grant, FrostLeaf


;Key Press
Global Enum $KEY_CTRL, _
            $KEY_SHIFT, _
            $KEY_Z

Global Const $KEY_ACTION[3][2] = _
            [  ["{CTRLDOWN}", "{CTRLUP}"], _
               ["{SHIFTDOWN}", "{SHIFTUP}"], _
               ["{z down}", "{z up}"]]

Global $g_run = True

Global $g_page = -1
HotKeySet("^{PAUSE}", "Toggle_Pause")     ;Ctrl+Pause
HotKeySet("+!{END}", "Shut_Down")         ;Alt+Shift+End

Main()

Func Main()
   WinActivate($WINDOW)
   Local $cnt = 0

   Local $levelingHeros[] = [$BRITTANY, $IVAN, $TREEBEAST, $SAMURAI, $SEER]

   While $g_run
      If Mod($cnt, 30) == 0 Then
         Map(TryToLevelBy25, $levelingHeros)
         EnableProgression()
      EndIf
      PerformCooldowns()

      ClickInKillZone(40)

      $cnt += 1
   WEnd
EndFunc

Func PerformCooldowns()
   Local $cd_index = 1
   Local $cooldowns_ready[10] = []
   For $y = 0 To $COOLDOWN_Y_OFFSET * 8 Step +$COOLDOWN_Y_OFFSET
      Local $range = NewPixelRange($TOP_COOLDOWN[0], $y + $TOP_COOLDOWN[1])
      
      $cooldowns_ready[$cd_index] = BoardRangeContainsColor($range, $COOLDOWN_COLOR)
      $cd_index += 1
   Next

   If $cooldowns_ready[6] Then
      Send("123457")
      If $cooldowns_ready[8] And $cooldowns_ready[9] Then
         Send("869")
      EndIf
   ElseIf $cooldowns_ready[8] And $cooldowns_ready[9] Then
      Send("89")
   EndIf
EndFunc

Func EnableProgression()
   
   Local $range = $PROGRESSION_PIXEL_RANGE

   ;Didn't find progression mode, turn it on!
   If BoardRangeContainsColor($range, $PROGRESSION_COLOR, 10) Then
      Send("a")
   EndIf
EndFunc

Func ClickInKillZone($count=1)
   Local Const $x = Int(Floor($BOARD_WIDTH/4)*3)
   Local Const $y = Int(Floor($BOARD_HEIGHT/3)*2)

   Click($x, $y, $count)
EndFunc

Func TryToLevel($hero)
   Local $levelled = False
   While CanLevel($hero)
      LevelUp($hero, 1)
      ClickInKillZone()
      $levelled = True
   Wend

   ClickInKillZone()
   Return $levelled
EndFunc

Func TryToLevelBy10($hero)
   WithKeyPress($KEY_SHIFT, TryToLevel, $hero)
EndFunc

Func TryToLevelBy25($hero)
   WithKeyPress($KEY_Z, TryToLevel, $hero)
EndFunc

Func TryToLevelBy100($hero)
   WithKeyPress($KEY_CTRL, TryToLevel, $hero)
EndFunc

Func CanLevel($hero)
   ScrollToHero($hero)

   Local $row = $HERO_BUTTON[$hero][1]

   Local Const $SEARCH_RADIUS = 20

   Local $range = NewPixelRange( $HERO_ROW_X - $SEARCH_RADIUS, _
                              $HERO_ROW_Y[$row] - $SEARCH_RADIUS, _
                              $HERO_ROW_X + $SEARCH_RADIUS, _ 
                              $HERO_ROW_Y[$row] + $SEARCH_RADIUS)

   For $cannotBuyColor in $CANNOT_BUY_COLORS
      ;Found the CANNOT_BUY_COLOR, cannot buy this amount
      If BoardRangeContainsColor($range, $cannotBuyColor, 40) Then
         Return False
      EndIf
   Next


   Return True
EndFunc

Func CanLevelBy10($hero)
   Return WithKeyPress($KEY_SHIFT, CanLevel, $hero)
EndFunc

Func CanLevelBy25($hero)
   Return WithKeyPress($KEY_Z , CanLevel, $hero)
EndFunc

Func CanLevelBy100($hero)
   Return WithKeyPress($KEY_CTRL, CanLevel, $hero)
EndFunc



; LevelUp a Hero a given number of levels
; @param {HeroEnum} $hero
; @param {Int} [$levels]
Func LevelUp($hero, $levels=1)
   If $levels <= 0 Then
      Return
   EndIf

   ScrollToHero($hero)

   Local $row = $HERO_BUTTON[$hero][1]
   ClickHeroRow($row, $levels)
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

; Scroll to a given hero page
; @param {Int} $page
Func ScrollToPage($p)
   If $g_page <> $p Then
      Click($SCROLL_TOP[0], $PAGE_SCROLL[$p])
      $g_page = $p
   EndIf
EndFunc

Func ScrollToHero($hero)
   Local $page = $HERO_BUTTON[$hero][0]
   ScrollToPage($page)
EndFunc

; Click on the game board a given number of times.
; Performs x,y coordinate translations from board x,y to screen x,y
; @param {Int} $row
Func Click($x, $y, $count=1)
   Local $board = FindBoard()
   For $i = 0 To $count-1
     MouseClick("left", $x + $board[0], $y + $board[1], 1, $MOUSE_SPEED)
     Sleep($CLICK_DELAY)
   Next
EndFunc

; Create a Pixel Range array
; @param {Int} $left
; @param {Int} $top
; @param {Int} [$right]
; @param {Int} [$bottom]
; @return {Array<Int x1, Int y1, Int x2, Int y2>}
Func NewPixelRange($left, $top, $right=Null, $bottom=Null)
   If $right == Null Then
      $right = $left
   EndIf
   If $bottom == Null Then
      $bottom = $top
   EndIf
   Local $range[] = [$left, $top, $right, $bottom]
   Return $range
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
; @return {Array<Int,Int>}
Func FindBoard()

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

   If $boardLeftX = $lastLeftX And _
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

; Search for a color in a given pixel range
; @param {Int} $left
; @param {Int} $top
; @param {Int} $right
; @param {Int} $bottom
; @param {Int|Hex} $color
; @param {Int} [$variance]
;
; @return {Array<Int,Int>}
Func ColorSearch($left, $top, $right, $bottom, $color, $variance=0)
   If $DEBUG Then
     Local $d[] = ["ColorSearch", $left, $top, $right, $bottom, $color, $variance]
     Dbg($d)
   EndIf

   Return PixelSearch($left, $top, $right, $bottom, $color, $variance)
EndFunc

Func TranslateCoords($x, $y)
   Local $board = FindBoard()
   Local $coords[] = [$x+$board[0], $y+$board[1]]
   Return $coords
EndFunc

Func WithKeyPress($key, $f, $arg = Null)
   Local $result

   Send($KEY_ACTION[$key][0])
   Sleep(400)  ;Sometimes you need the delay to be sure the color has changed
   If $arg == Null Then
    $result = $f()
   Else
      $result = Call(FuncName($f), $arg)
   EndIf

   Send($KEY_ACTION[$key][1])

   Return $result
EndFunc

; Map a function over an array
; @param {function} $f
; @param {Array} $a
Func Map($f, ByRef $a)
   Local $len = UBound($a)
   Local $result[$len]

   For $i = 0 To $len-1 Step 1
     $result[$i] = $f($a[$i])
   Next

   Return $result
EndFunc

; Bind arguments to a given function and map it over an array
; @param {function} $f
; @param {Array} $arg
; @param {Array} $a
Func BindMap($f, ByRef $arg, ByRef $a)
   Local $funcName = FuncName($f)
   Local $len = UBound($a)
   Local $result[$len]

   Local $size = UBound($arg)+2
   Local $mapArg = $size-1


   Local $bindArg[] = ["CallArgArray"]

   _ArrayAdd($bindArg, $arg)
   ReDim $bindArg[UBound($bindArg) + 1]

   For $i = 0 To $len-1 Step 1
     $bindArg[$mapArg] = $a[$i]
     $result[$i] = Call($funcName, $bindArg)
   Next

   Return $result
EndFunc

; Bind arguments to the right side of a given function and map it over an array
; @param {function} $f
; @param {Array} $arg
; @param {Array} $a
Func BindRMap($f, ByRef $arg, ByRef $a)
   Local $funcName = FuncName($f)
   Local $len = UBound($a)
   Local $result[$len]

   Local $size = UBound($arg)+2
   Local $bindArg[2]

   Local $mapArg = 1

   $bindArg[0] = "CallArgArray"
   _ArrayAdd($bindArg, $arg, 2)


   For $i = 0 To $len-1 Step 1
     $bindArg[$mapArg] = $a[$i]
     $result[$i] = Call($funcName, $bindArg)
   Next

   Return $result
EndFunc

; Create a range of numbers
; @param {Int} $start
; @param {Int} [$end]
; @param {Int} [$step]
Func Range($start, $end=Null, $step = 1)
   If $end = Null Then
     $end = $start
     $start = 0
   EndIf

   Local $size = Int(Ceiling(($end - $start)/$step))
   Local $r[$size]
   Local $index = 0
   For $i = $start To $end-1 Step $step
     $r[$index] = $i
     $index += 1
   Next

   Return $r
EndFunc

Func Paused($pause=Null)
   Static Local $is_paused = False

   If $pause == Null Then
      Return $is_paused
   EndIf

   $is_paused = $pause
   Return $is_paused
EndFunc

Func Toggle_Pause()
   Paused(Not Paused())
   While Paused()
      Sleep(100)
      ToolTip("Paused", 0, 0)
   WEnd
   ToolTip("")
   WinActivate($WINDOW)
   $g_page = -1
EndFunc

Func Shut_Down()
    $g_run = False
    $g_page = -1
    ToolTip("")
EndFunc

Func HexStr($h)
   Return String("0x" & hex($h,6))
EndFunc

Func Pop($msg)
   MsgBox($MB_SYSTEMMODAL, "", $msg)
EndFunc

Func Dbg($msg)
   If IsArray($msg) Then
     ConsoleWrite(_ArrayToString($msg, ", ") & @CR)
   Else
     ConsoleWrite($msg & @CR)
   EndIf
EndFunc
