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

HotKeySet("+!I", "CursorInfo")            ;Alt+Shift+I Shows information about the pixel under your cursor

Global Const $CLICK_DELAY = 2
Global Const $MOUSE_SPEED = 1

Global Const $DEFAULT_LEVELING_HEROS[] = [$BRITTANY, $IVAN, $TREEBEAST]


Global Const $CLICKSTARTER_PIPELINE[] = [AlwaysProgress, AlwaysWithTheClicking, StartBuying]
Global Const $FAB_FOUR_PIPELINE[] = [FabulousFourLeveling, CollectGold]
Global Const $LADDER_PIPELINE[] = [LadderLeveling, CollectGold]
Global Const $IDLE_PIPELINE[] = [LateGameLeveling, EnhancedDarkRitual, DynamicIdle]
Global Const $ACTIVE_PIPELINE[] = [AlwaysWithTheClicking, LateGameLeveling, EnhancedDarkRitual, DynamicAscend]
Global Const $DEEP_PIPELINE[] = [AlwaysWithTheClicking, LateGameLeveling, EnhancedDarkRitual]
Global Const $APOCOLYPSE_NOW_PIPELINE[] = [ApocolypseNow]

Global Const $PIPELINE_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $ACTIVE_PIPELINE]
;Global Const $PIPELINE_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $DEEP_PIPELINE]
;Global Const $PIPELINE_CHAIN[] = [$CLICKSTARTER_PIPELINE, $FAB_FOUR_PIPELINE, $LADDER_PIPELINE, $IDLE_PIPELINE, $APOCOLYPSE_NOW_PIPELINE]

Func Main()
   PipelineChain($PIPELINE_CHAIN)
   ActivateBoard()
   StartBotEngine()
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
   Ascend()
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