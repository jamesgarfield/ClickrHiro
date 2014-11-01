#include-once

#include <Utils.au3>
#include <ClickrConstants.au3>

Global Const $PROFILE_BOT_ENGINE = False

Func StartBotEngine()
   WinActivate($WINDOW)
   
   Pipeline(NextPipeline())
   
   While RunBot() And Not Paused()
      Local $tick = Tick()

      If $PROFILE_BOT_ENGINE Then
         TickTimer($tick)
      EndIf
      
      Local $pipeline = Pipeline()
      For $step in $pipeline
         RunStep($step, $tick)  
      Next
   WEnd
EndFunc

Func Tick($reset=False)
   Static Local $tick = -1
   If $reset Then
      $tick = -1
   EndIf

   $tick += 1

   Return $tick
EndFunc

Func RunStep($step, $tick)
   If $PROFILE_BOT_ENGINE Then
      StepTimer($step, $tick)
   Else
      $step($tick)
   EndIf
EndFunc

Func PipelineChain($c = Null)
   Static Local $chain
   If $c <> Null Then
      $chain = $c
   EndIf
   Return $chain
EndFunc

; Get/Set the current action pipeline
; @param {Array<Function(Int)>} [$p]
; @return {Array<Function(Int)>}
Func Pipeline($p=Null)
   Static Local $pipeline
   If $p <> Null Then
      Tick(true)
      $pipeline = $p
   EndIf

   Return $pipeline
EndFunc

; Get the next pipeline in the current pipeline chain
; @param {Boolean} [$restart] Resets the pipeline chain to the start
; @return {Array<Function(Int)>}
Func NextPipeline($restart = False)
   Static Local $index = 0
   If $restart Then
      $index = 0
   EndIf
   $p = $PIPELINE_CHAIN[$index]
   $index += 1
   Return $p
EndFunc

; Set the Paused state of the Bot Engine
Func Paused($pause=Null)
   Static Local $is_paused = False

   If $pause == Null Then
      Return $is_paused
   EndIf

   $is_paused = $pause
   Return $is_paused
EndFunc

; Set the Bot Engine to on or off
Func RunBot($run=Null)
   Static Local $is_running = True

   If $run == Null Then
      Return $is_running
   EndIf

   $is_running = $run
   Return $is_running
EndFunc

Func TickTimer($tick)
   Static Local $timer = TimerInit()
   Static Local $total = 0

   If $tick == 0 Then
      Return
   EndIf

   Local $diff = TimerDiff($timer)
   $total += $diff
   Local $tps = Round($tick / Floor($total/1000))
   Dbg("Tick: " & StrPad($tick, 25, " ") & " Time: " & TimeStr($diff) & ", t/sec: " & $tps)
   Dbg("----------------------------------------------------------------")
   $timer = TimerInit()
EndFunc

Func StepTimer($step, $tick)
   Local $timer = TimerInit()
   $step($tick)
   Local $diff = TimerDiff($timer)
   Dbg("Step: " & StrPad(FuncName($step), 25, " ") & " Time: " & TimeStr(TimerDiff($timer)))
EndFunc