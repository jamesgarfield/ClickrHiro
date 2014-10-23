#include <MsgBoxConstants.au3>
#include <Array.au3>

Global Const $VERSION = "0.1.0"

Global Const $DEBUG = False

Global Const $WINDOW = "Clicker Heroes"
Global Const $CLICK_DELAY = 5

;Pixels Go Here
   ;Game area
   Global Const $BOARD_WIDTH = 1133
   Global Const $BOARD_HEIGHT = 639

   ;Top of scroll bar, under up arrow
   Global Const $SCROLL_TOP[] = [547, 201]

   ;Page scrolling postions (4 heroes per page)
   Global Const $PAGE_SCROLL[] = [201, 304, 359, 419, 474, 529, 559]

   ;Level Button Positioning
   Global Const $HERO_ROW_X = 91
   Global Const $HERO_ROW_Y[] = [224, 330, 436, 542]
;End of Pixels

;Used to find the game board within the browser window
Global Const $LEFT_EDGE_COLOR = 0x875508
Global Const $TOP_EDGE_COLOR = 0xBB7A19
Global Const $TOP_OFFSET = -3

Global Const $CANNOT_BUY_COLOR = 0xFE8743


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


Main()

Func Main()
   ScrollToPage(2)
   LevelUp($CID, 162)
EndFunc

; LevelUp a Hero a given number of levels
; @param {HeroEnum} $hero
; @param {Int} [$levels]
Func LevelUp($hero, $levels=1)
   If $levels <= 0 Then
      Return
   EndIf

   $page = $HERO_BUTTON[$hero][0]
   $row = $HERO_BUTTON[$hero][1]

   ScrollToPage($page)

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
   Click($SCROLL_TOP[0], $PAGE_SCROLL[$p])
EndFunc

; Click on the game board a given number of times.
; Performs x,y coordinate translations from board x,y to screen x,y
; @param {Int} $row
Func Click($x, $y, $count=1)
   Local $board = FindBoard()
   For $i = 0 To $count-1
	  MouseClick("left", $x + $board[0], $y + $board[1], 1)
	  Sleep($CLICK_DELAY)
   Next
EndFunc

; Find the game board within the browser window
; @return {Array<Int,Int>}
Func FindBoard()
   WinActivate($WINDOW)

   Local $poz = WinGetPos($WINDOW)

   Local $boardLeftX = $poz[0]
   Local $boardTopY = $poz[1]
   Local $width = $poz[2]
   Local $height = $poz[3]

   Local $leftCutoff =  $boardLeftX + Int($width/2)
   Local $topCutoff =  $boardTopY + Int($height/2)

   Local $leftYSearchPos = $boardTopY + Floor($height/2)
   Local $topXSearchPos = $boardLeftX + Floor($width/2 - $BOARD_WIDTH/4)

   Local $left = ColorSearch($boardLeftX, $leftYSearchPos, $leftCutoff, $leftYSearchPos, $LEFT_EDGE_COLOR, 20)
   Local $top = ColorSearch($topXSearchPos, $boardTopY, $topXSearchPos, $topCutoff, $TOP_EDGE_COLOR, 20)

   Local $coord[] = [$left[0], $top[1] + $TOP_OFFSET]
   Return $coord
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

; Map a function over an array
; @param {function} $f
; @param {Array} $a
Func Map($f, ByRef $a)
   Local $len = UBound($a)
   Local $result[$len]

   For $i = 0 To $len-1 Step 1
	  $result[$i] = $funcName($a[$i])
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