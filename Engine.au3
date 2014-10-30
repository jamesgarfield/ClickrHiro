#include-once

#include <Utils.au3>
#include <Constants.au3>


Func StartBotEngine()
   WinActivate($WINDOW)
   
   Pipeline(NextPipeline())
   
   Local $tick = 0
   While RunBot() And Not Paused()
      Local $pipeline = Pipeline()
      For $step in $pipeline
         $step($tick)
      Next
      $tick += 1
   WEnd
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


