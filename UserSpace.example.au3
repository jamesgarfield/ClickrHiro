#include <BoardState.au3>
#include <ClickrConstants.au3>
#include <Controls.au3>
#include <Engine.au3>
#include <Leveling.au3>
#include <Strategies.au3>
#include <Utils.au3>

Global Const $DEBUG = False

HotKeySet("^{PAUSE}", "Toggle_Pause")     ;Ctrl+Pause
HotKeySet("+!{END}", "Shut_Down")         ;Alt+Shift+End

Global Const $CLICK_DELAY = 2
Global Const $MOUSE_SPEED = 1

Global Const $DEFAULT_LEVELING_HEROS[] = [$BRITTANY, $IVAN, $TREEBEAST]


Global Const $CLICKSTARTER_PIPELINE[] = [AlwaysProgress, StartBuying, AlwaysWithTheClicking]
Global Const $FAB_FOUR_PIPELINE[] = [FabulousFourLeveling]
Global Const $LADDER_PIPELINE[] = [LadderLeveling]
Global Const $IDLE_PIPELINE[] = [LateGameLeveling, EnhancedDarkRitual, TransitionPipelineAtIdleCutoff]
Global Const $ACTIVE_PIPELINE[] = [AlwaysWithTheClicking, LateGameLeveling, EnhancedDarkRitual, AscendAtInflection]


Global Const $PIPELINE_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $ACTIVE_PIPELINE]

Global Const $INFLECTION_LEVEL = 1050

Global Const $IDLE_CUTOFF_LEVEL = 725

Func Main()
   PipelineChain($PIPELINE_CHAIN)
   ActivateBoard()
   StartBotEngine()
EndFunc


Func AscendAtInflection($tick)
   Static Local $ascensions = 0

   If GetZone() >= $INFLECTION_LEVEL Then
      $ascensions += 1
      Dbg("Ascension " & $ascensions)
      Dbg(HeroLevel())
      Ascend()
   EndIf
EndFunc

Func StartBuying($tick)
   If CanLevelBy10($TREEBEAST) Then
      Local $zone = GetZone()
      Dbg("Start buying @ zone " & $zone)
      LevelUp($TREEBEAST, 10)
      Pipeline(NextPipeline())
   EndIf
EndFunc

Func TransitionPipelineAtIdleCutoff($tick)
   If GetZone() >= $IDLE_CUTOFF_LEVEL Then
      Pipeline(NextPipeline())
   EndIf
EndFunc

Func Toggle_Pause()
   Paused(Not Paused())
   While Paused() And RunBot()
      Sleep(100)
      ToolTip("Paused", 0, 0)
   WEnd
   ActivateBoard()
   ToolTip("")
EndFunc

Func Shut_Down()
    RunBot(false)
    ToolTip("Shutting Down")
EndFunc