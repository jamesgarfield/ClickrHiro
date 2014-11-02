#include-once

#include <MsgBoxConstants.au3>
#include <Array.au3>
#include <Math.au3>

;Key Press
Global Enum $KEY_CTRL, _
            $KEY_SHIFT, _
            $KEY_Z

Global Const $KEY_ACTION[3][2] = _
            [  ["{CTRLDOWN}", "{CTRLUP}"], _
               ["{SHIFTDOWN}", "{SHIFTUP}"], _
               ["{z down}", "{z up}"]]

;Overide with $WITH_KEY_DELAY
Global Const $DEFAULT_WITH_KEY_DELAY = 300

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

Func MapInvoke($f, $args)
   Local $len = UBound($args)
   Local $result[$len]

   For $i = 0 To $len-1 Step 1
     $result[$i] = Invoke($f, $args[$i])
   Next

   Return $result
EndFunc

; Returns true if the provided function returns true for Every element of the array
Func Every($f, ByRef $a)
   Local $len = UBound($a)

   For $i = 0 To $len-1 Step 1
      If Not $f($a[$i]) Then
         Return False
      EndIf
   Next
   Return True
EndFunc

; Returns true if the provided function returns true for Any element of the array
Func Any($f, ByRef $a)
   Local $len = UBound($a)

   For $i = 0 To $len-1 Step 1
      If $f($a[$i]) Then
         Return True
      EndIf
   Next
   Return False
EndFunc

Func Invoke($f, $arg=Null)
   If $arg == Null Then
      Return $f()
   Else
      Local $bindArg = ArrayToCallArg($arg)
      Return Call(FuncName($f), $bindArg)
   EndIf
EndFunc

Func ArrayToCallArg(ByRef $a)
   Local $len = UBound($a)
   Local $callarg[$len+1]

   $callarg[0] = "CallArgArray"
   For $i in Range($len)
      $callarg[$i+1] = $a[$i]
   Next
   Return $callarg
EndFunc

Func Zip($a, $b)
   Local $len = _Min(UBound($a), UBound($b))
   Local $zipped[$len]
   For $i = 0 To $len-1 Step 1
      Local $x[] = [$a[$i], $b[$i]]
      $zipped[$i] = $x
   Next
   Return $zipped
EndFunc

; Returns true if the argument passed is true, otherwise, false
Func IsTrue($b)
   Return $b == True
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

   Local $max = _Max($start, $end)
   Local $min = _Min($start, $end)
   Local $size = Abs(Int(Ceiling(($max - $min)/$step)))
   Local $r[$size]
   Local $index = 0
   Local $i = $start
   Do
      $r[$index] = $i
      $index += 1
      $i += $step
   Until $i == $end

   Return $r
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

; Executes a function while 'holding' a key down
; @param {Array<KeyDown, KeyUp>} $key
; @param {Function} $f
; @param {Array|*} [$arg] Either a single value to pass as an argument, or a call arg array
; @returm {*} The result of the called function
Func WithKeyPress($key, $f, $arg = Null)
   Local $result
   Static Local $delay = GlobalOrDefault("WITH_KEY_DELAY", $DEFAULT_WITH_KEY_DELAY)

   Send($KEY_ACTION[$key][0])
   Sleep($delay)  ;Sometimes you need the delay to be sure the color has changed
   If $arg == Null Then
    $result = $f()
   Else
      $result = Call(FuncName($f), $arg)
   EndIf

   Send($KEY_ACTION[$key][1])

   Return $result
EndFunc

Func GlobalOrDefault($global, $default)
   If IsDeclared($global) Then
      Return Eval($global)
   Else
      Return $default
   EndIf
EndFunc

Func Noop($a=Null, $b=Null, $c=Null, $d=Null)
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

;Serialize a coordinates array into a string
Func CoordStr($coord)
   Return "[" & $coord[0] & ", " & $coord[1] & "]"
EndFunc

Func TimeStr($ms)
   Local Const $SECOND = 1000
   LOCAL CONST $MINUTE = $SECOND * 60

   Local $min = 0
   Local $sec = 0

   If $ms >= $MINUTE Then
      $min = Floor($ms/$MINUTE)
      $ms -= $min * $MINUTE
   EndIf

   If $ms >= $SECOND Then
      $sec = Floor($ms/$SECOND)
      $ms -= $sec * $SECOND
   EndIf

   Return StrPad($min, 2, "0", true) & ":" & StrPad($sec, 2, "0", true) & "." & StrPad(Int($ms), 3, "0")
EndFunc

Func StrPad($str, $pad, $char, $left=False)
   $str = String($str)
   While StringLen($str) < $pad
      If $left Then
         $str = $char & $str
      Else
         $str = $str & $char
      EndIf
   WEnd
   Return $str
EndFunc