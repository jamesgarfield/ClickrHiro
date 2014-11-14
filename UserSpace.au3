#include <BoardState.au3>
#include <ClickrConstants.au3>
#include <Controls.au3>
#include <Engine.au3>
#include <Leveling.au3>
#include <Strategies.au3>
#include <Utils.au3>

#include <GameDataParser.au3>

Global Const $DEBUG = False
Global Const $PROFILE = True


HotKeySet("^{PAUSE}", "Toggle_Pause")     ;Ctrl+Pause
HotKeySet("+!{END}", "Shut_Down")         ;Alt+Shift+End

HotKeySet("+!I", "CursorInfo")         ;Alt+Shift+I

Global Const $MOUSE_SPEED = 1
Global Const $PAGE_SCROLL_DELAY = 350
Global Const $WITH_KEY_DELAY = 400

Global Const $LATE_GAME_LEVELING_TICK_RATE = 3


Global Const $DEFAULT_LEVELING_HEROS[] = [$TREEBEAST, $BRITTANY, $NATALIA,  $IVAN, $SAMURAI, $APHRODITE, $FROSTLEAF]


Global Const $CLICKSTARTER_PIPELINE[] = [AlwaysProgress, AlwaysWithTheClicking, StartBuying]
Global Const $FAB_FOUR_PIPELINE[] = [FabulousFourLeveling, CollectGold]
Global Const $LADDER_PIPELINE[] = [LadderLeveling, CollectGold]
Global Const $IDLE_PIPELINE[] = [LateGameLeveling, EnhancedDarkRitual, DynamicIdle]
Global Const $ACTIVE_PIPELINE[] = [AlwaysWithTheClicking, LateGameLeveling, EnhancedDarkRitual, DynamicAscend]
Global Const $DEEP_PIPELINE[] = [AlwaysWithTheClicking, LateGameLeveling, EnhancedDarkRitual]
Global Const $APOCOLYPSE_NOW_PIPELINE[] = [ApocolypseNow]

Global Const $PIPELINE_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $ACTIVE_PIPELINE]
Global Const $DEEP_RUN_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $DEEP_PIPELINE]
Global Const $IDLE_ASCEND_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $APOCOLYPSE_NOW_PIPELINE]

Func Main()
   PipelineChain($PIPELINE_CHAIN)
   ActivateBoard()
   StartBotEngine()
EndFunc

Func ShowStats($tick=Null)
   Dbg("       Zone       :   " & GetZone())
   Dbg("       Level Time :   " & TimeStr(TimeInLevel()))
   Dbg("       Boss Time  :   " & TimeStr(TimeToBeatBoss()))
   Dbg("       Fails      :   " & BossFail())
   Dbg("============================================")
EndFunc

Func GottaKeepOnMovin($tick)
   Local $heroes = Range($TREEBEAST, $ALL_HEROES)
   If Any(HeroIsMaxed, $heroes) Then
      Map(SetMaxHeroLevel, $heroes)
   EndIf
EndFunc


Func ForceNext($tick)
   Local $zone = GetZone()
   If $zone > 160 Then
      Dbg("Force next " & $zone)
      ClearStatistics()
      Pipeline(NextPipeline())
   EndIf
EndFunc

Func ForceAscend($tick)
   Local $zone = GetZone()
   If $zone > 200 Then
      Dbg("Force ascend " & $zone)
      ClearStatistics()
      Ascend()
   EndIf
EndFunc

Func StartBuying($tick)
   Local $zone = GetZone()
   If CanLevelBy10($TREEBEAST) And $tick > 4 Then
      Dbg("             Start buying @ zone " & $zone)
      Dbg("============================================")
      LevelUp($TREEBEAST, 10)
      Pipeline(NextPipeline())
   ElseIf $zone > 120 Then
      Dbg("             Skipping ClickStarter")
      Dbg("============================================")
      Pipeline(NextPipeline())
   EndIf
EndFunc

Func ApocolypseNow($tick)
   BossFail(0)
   TimeToBeatBoss(0)
   TimeInLevel(0)
   Ascend()
EndFunc


Func Toggle_Pause()
   Paused(Not Paused())
   
   While Paused() And RunBot()
      Sleep(100)
      ToolTip("Paused", 0, 0)
   WEnd
   
   
   ToolTip("")
EndFunc

Func Shut_Down()
    RunBot(false)
    ToolTip("Shutting Down")
EndFunc
