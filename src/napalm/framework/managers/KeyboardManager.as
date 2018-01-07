package napalm.framework.managers
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import napalm.framework.log.Channel;
	
	/**
	 * KeyboardManager.
	 *
	 * Combinations.
	 *    Good: "m+7", "ctrl+m+7", "shift+m", "ctrl+shift+m", "ctrl+shift+alt+m", "ctrl+alt+m".
	 *  Bad:  "+", "m+", "shift+m+7", "ctrl+shift+m+7", "", "ctrl+shift+alt+m+7", "alt+m",
	 *            "alt+m+n+7", "ctrl+alt+m+7", "alt+shift+m".
	 * Note: "alt+" combinations work only after "ctrl+".
	 * @author alex.panoptik@gmail.com
	 */
	public class KeyboardManager extends BaseManager
	{

		// Class constants

		public static const KEY_DOWN:String = "keyDown";
		public static const KEY_UP:String = "keyUp";
		public static const PRE_KEY_UP:String = "preKeyUp";

		// Class variables

		private static var keyDownNum:int = 0;
		//private static var keyDownAccumNum:int = 0;
		private static var keyCombinationParsedCache:Dictionary = new Dictionary();

		// Class methods

		public static function getKeyCodeByName(keyName:String):int
		{
			if (!keyName)
			{
				return 0;
			}

			keyName = keyName.toUpperCase();
			return keyCodeByName[keyName] || keyCodeByName[keyNameByAlias[keyName]] || 0;
		}

		public static function getKeyNameByCode(keyCode:int):String
		{
			return keyNameByCode[keyCode] || "";
		}

		// Used by InputManager
		public static function isKeyCombination(keyCombination:String, keyNameCheckFunction:Function, 
		                                        keyNameDownCheckFunction:Function = null, 
		                                        isStrictMode:Boolean = true):Boolean
		{
			if (!keyCombination || keyNameCheckFunction == null)
			{
				return false;
			}

			if (keyNameDownCheckFunction == keyNameCheckFunction)
			{
				keyNameDownCheckFunction = null;
			}

			// Cache
			var keyComboArray:Array = keyCombinationParsedCache[keyCombination];
			// Parse
			if (!keyComboArray)
			{
				keyComboArray = keyCombination.split("|");
				for (var i:int = 0; i < keyComboArray.length; i++)
				{
					keyComboArray[i] = keyComboArray[i].split("+");
				}
				keyCombinationParsedCache[keyCombination] = keyComboArray;
			}

			// Check
			var result:Boolean;
			for each (var keyNameArray:Array in keyComboArray)
			{
				result = true;
				var checkedNum:int = 0;
				for each (var keyName:String in keyNameArray)
				{
					var isKeyNameChecked:Boolean = keyNameCheckFunction(keyName);
					if (isKeyNameChecked)
					{
						checkedNum++;
					}
					if (!isKeyNameChecked && (keyNameDownCheckFunction == null || !keyNameDownCheckFunction(keyName)))
					{
						result = false;
						break;
					}
				}

				if (result && checkedNum > 0)
				{
					break;
				}
			}

			if (!result || !checkedNum)
			{
				return false;
			}

			return !isStrictMode || keyNameArray.length == keyDownNum;//? || keyNameArray.length == keyDownAccumNum;//???was || keyNameArray.length == 1;
			//?-var areOnlyCombinationKeysDown:Boolean = keyNameArray.length == keyDownNum || keyNameArray.length == 1;
			//return isStrictMode ? areOnlyCombinationKeysDown : true;
		}

		// Variables

		private var stage:Stage;

		private var keyDownMap:Dictionary = new Dictionary();

		// Properties

		// Constructor

		public function KeyboardManager()
		{
		}

		// Methods

		override public function initialize(systemManager:SystemManager):void
		{
			if (isInitialized)
			{
				return;
			}

			super.initialize(systemManager);

			stage = systemManager.stage;

			// Listeners
			stage.addEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler, false, 0, true);
			stage.addEventListener(Event.DEACTIVATE, stage_deactivateHandler, false, 0, true);
		}

		override public function dispose():void
		{
			// Listeners
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, stage_keyDownHandler);
			stage.removeEventListener(KeyboardEvent.KEY_UP, stage_keyUpHandler);
			stage.removeEventListener(Event.DEACTIVATE, stage_deactivateHandler);

			clearInput();
			keyCombinationParsedCache = new Dictionary();

			stage = null;

			super.dispose();
		}

		public function clearInput():void
		{
			keyDownMap = new Dictionary();
			keyDownNum = 0;
			//keyDownAccumNum = 0;
		}

		public function isDown(keyCode:int):Boolean
		{
			if (!isInitialized)
			{
				log.warn(Channel.KEYBOARD, this, "(isDown) WARNING! KeyboardManager isn't initialized! stage:", stage, new Error().getStackTrace());
				return false;
			}

			return keyDownMap[keyCode];
		}

		public function isDownByName(keyName:String):Boolean
		{
			if (!isInitialized)
			{
				log.warn(Channel.KEYBOARD, this, "(isDownByName) WARNING! KeyboardManager isn't initialized! stage:", stage, new Error().getStackTrace());
				return false;
			}

			//?keyName = StringUtil.trim(keyName);
			keyName = keyName.toUpperCase();

			var keyCode:int = getKeyCodeByName(keyName);// || getKeyCodeByName(keyNameByAlias[keyName]);
			return keyDownMap[keyCode];
		}

		public function isDownCombination(keyCombination:String, isStrictMode:Boolean = true):Boolean
		{
			return isKeyCombination(keyCombination, isDownByName, null, isStrictMode);
		}

		// Event handlers

		private function stage_keyDownHandler(event:KeyboardEvent):void
		{
			if (event.keyCode in keyDownMap)
			{
				return;
			}

			//trace("KEY  +DOWN", event.keyCode, getKeyNameByCode(event.keyCode), "			alt ctrl shift:", event.altKey, event.ctrlKey, event.shiftKey);
			keyDownMap[event.keyCode] = true;
			keyDownNum++;
			//keyDownAccumNum++;

			// Dispatch
			dispatchEventWith(KEY_DOWN);

			//var hotkey0:String = "ctrl+alt+m+7";
			//var hotkey1:String = "alt+shift+m";
			//var hotkey2:String = "alt+ctrl+m";
			//var hotkey3:String = "alt+m+n+7";
			//var hotkey4:String = "alt+m";
			//trace("HOTKEY", hotkey0, isDownCombination(hotkey0), "	", hotkey1, isDownCombination(hotkey1), "	|",
			//hotkey2,isDownCombination(hotkey2, true),"	",hotkey3,isDownCombination(hotkey3),"	",hotkey4,isDownCombination(hotkey4));
		}

		private function stage_keyUpHandler(event:KeyboardEvent):void
		{
			//trace("KEY     -up (", event.keyCode, getKeyNameByCode(event.keyCode), ")	",event.keyCode in keyDownMap,"		alt ctrl shift:", event.altKey, event.ctrlKey, event.shiftKey);
			if (event.keyCode in keyDownMap)
			{
				// Dispatch
				dispatchEventWith(PRE_KEY_UP);

				delete keyDownMap[event.keyCode];
				keyDownNum--;
				//keyDownAccumNum = 0;

				// Dispatch
				dispatchEventWith(KEY_UP);
			}
		}

		private function stage_deactivateHandler(event:Event):void
		{
			//trace("!!!!!!!!!!!!!deactivate!!!!!!!!!!!! (KeyboardManager)");
			clearInput();
		}

		// Class constants (continue)

		private static const keyCodeByName:Dictionary = new Dictionary();

		keyCodeByName["BACKSPACE"] = Keyboard.BACKSPACE;// 8
		keyCodeByName["TAB"] = Keyboard.TAB;// 9
		keyCodeByName["ENTER"] = Keyboard.ENTER;// 13
		keyCodeByName["SHIFT"] = Keyboard.SHIFT;// 16
		keyCodeByName["CONTROL"] = Keyboard.CONTROL;// 17
		keyCodeByName["ALT"] = Keyboard.ALTERNATE;// 18
		keyCodeByName["CAPS LOCK"] = Keyboard.CAPS_LOCK;// 20
		keyCodeByName["ESC"] = Keyboard.ESCAPE;// 27
		keyCodeByName["SPACE"] = Keyboard.SPACE;// 32
		keyCodeByName["PAGE UP"] = Keyboard.PAGE_UP;// 33
		keyCodeByName["PAGE DOWN"] = Keyboard.PAGE_DOWN;// 34
		keyCodeByName["END"] = Keyboard.END;// 35
		keyCodeByName["HOME"] = Keyboard.HOME;// 36
		keyCodeByName["LEFT"] = Keyboard.LEFT;// 37
		keyCodeByName["UP"] = Keyboard.UP;// 38
		keyCodeByName["RIGHT"] = Keyboard.RIGHT;// 39
		keyCodeByName["DOWN"] = Keyboard.DOWN;// 40
		keyCodeByName["INSERT"] = Keyboard.INSERT;// 45
		keyCodeByName["DELETE"] = Keyboard.DELETE;// 46
		keyCodeByName["0"] = Keyboard.NUMBER_0;// 48
		keyCodeByName["1"] = Keyboard.NUMBER_1;// 49
		keyCodeByName["2"] = Keyboard.NUMBER_2;// 50
		keyCodeByName["3"] = Keyboard.NUMBER_3;// 51
		keyCodeByName["4"] = Keyboard.NUMBER_4;// 52
		keyCodeByName["5"] = Keyboard.NUMBER_5;// 53
		keyCodeByName["6"] = Keyboard.NUMBER_6;// 54
		keyCodeByName["7"] = Keyboard.NUMBER_7;// 55
		keyCodeByName["8"] = Keyboard.NUMBER_8;// 56
		keyCodeByName["9"] = Keyboard.NUMBER_9;// 57
		keyCodeByName["A"] = Keyboard.A;// 65
		keyCodeByName["B"] = Keyboard.B;// 66
		keyCodeByName["C"] = Keyboard.C;// 67
		keyCodeByName["D"] = Keyboard.D;// 68
		keyCodeByName["E"] = Keyboard.E;// 69
		keyCodeByName["F"] = Keyboard.F;// 70
		keyCodeByName["G"] = Keyboard.G;// 71
		keyCodeByName["H"] = Keyboard.H;// 72
		keyCodeByName["I"] = Keyboard.I;// 73
		keyCodeByName["J"] = Keyboard.J;// 74
		keyCodeByName["K"] = Keyboard.K;// 75
		keyCodeByName["L"] = Keyboard.L;// 76
		keyCodeByName["M"] = Keyboard.M;// 77
		keyCodeByName["N"] = Keyboard.N;// 78
		keyCodeByName["O"] = Keyboard.O;// 79
		keyCodeByName["P"] = Keyboard.P;// 80
		keyCodeByName["Q"] = Keyboard.Q;// 81
		keyCodeByName["R"] = Keyboard.R;// 82
		keyCodeByName["S"] = Keyboard.S;// 83
		keyCodeByName["T"] = Keyboard.T;// 84
		keyCodeByName["U"] = Keyboard.U;// 85
		keyCodeByName["V"] = Keyboard.V;// 86
		keyCodeByName["W"] = Keyboard.W;// 87
		keyCodeByName["X"] = Keyboard.X;// 88
		keyCodeByName["Y"] = Keyboard.Y;// 89
		keyCodeByName["Z"] = Keyboard.Z;// 90
		keyCodeByName["NUMPAD 0"] = Keyboard.NUMPAD_0;// 96
		keyCodeByName["NUMPAD 1"] = Keyboard.NUMPAD_1;// 97
		keyCodeByName["NUMPAD 2"] = Keyboard.NUMPAD_2;// 98
		keyCodeByName["NUMPAD 3"] = Keyboard.NUMPAD_3;// 99
		keyCodeByName["NUMPAD 4"] = Keyboard.NUMPAD_4;// 100
		keyCodeByName["NUMPAD 5"] = Keyboard.NUMPAD_5;// 101
		keyCodeByName["NUMPAD 6"] = Keyboard.NUMPAD_6;// 102
		keyCodeByName["NUMPAD 7"] = Keyboard.NUMPAD_7;// 103
		keyCodeByName["NUMPAD 8"] = Keyboard.NUMPAD_8;// 104
		keyCodeByName["NUMPAD 9"] = Keyboard.NUMPAD_9;// 105
		keyCodeByName["NUMPAD *"] = Keyboard.NUMPAD_MULTIPLY;// 106
		keyCodeByName["NUMPAD +"] = Keyboard.NUMPAD_ADD;// 107
		keyCodeByName["NUMPAD ENTER"] = Keyboard.NUMPAD_ENTER;// 108
		keyCodeByName["NUMPAD -"] = Keyboard.NUMPAD_SUBTRACT;// 109
		keyCodeByName["NUMPAD ."] = Keyboard.NUMPAD_DECIMAL;// 110
		keyCodeByName["NUMPAD /"] = Keyboard.NUMPAD_DIVIDE;// 111
		keyCodeByName["F1"] = Keyboard.F1;// 112
		keyCodeByName["F2"] = Keyboard.F2;// 113
		keyCodeByName["F3"] = Keyboard.F3;// 114
		keyCodeByName["F4"] = Keyboard.F4;// 115
		keyCodeByName["F5"] = Keyboard.F5;// 116
		keyCodeByName["F6"] = Keyboard.F6;// 117
		keyCodeByName["F7"] = Keyboard.F7;// 118
		keyCodeByName["F8"] = Keyboard.F8;// 119
		keyCodeByName["F9"] = Keyboard.F9;// 120
		keyCodeByName["F10"] = Keyboard.F10;// 121
		keyCodeByName["F11"] = Keyboard.F11;// 122
		keyCodeByName["F12"] = Keyboard.F12;// 123
		keyCodeByName["F13"] = Keyboard.F13;// 124
		keyCodeByName["F14"] = Keyboard.F14;// 125
		keyCodeByName["F15"] = Keyboard.F15;// 126
		keyCodeByName[";"] = Keyboard.SEMICOLON;// 186
		keyCodeByName["="] = Keyboard.EQUAL;// 187
		keyCodeByName[","] = Keyboard.COMMA;// 188
		keyCodeByName["-"] = Keyboard.MINUS;// 189
		keyCodeByName["."] = Keyboard.PERIOD;// 190
		keyCodeByName["/"] = Keyboard.SLASH;// 191
		keyCodeByName["`"] = Keyboard.BACKQUOTE;// 192
		keyCodeByName["["] = Keyboard.LEFTBRACKET;// 219
		keyCodeByName["\\"] = Keyboard.BACKSLASH;// 220
		keyCodeByName["]"] = Keyboard.RIGHTBRACKET;// 221
		keyCodeByName["'"] = Keyboard.QUOTE;// 222

		private static const keyNameByCode:Dictionary = new Dictionary();

		keyNameByCode[Keyboard.BACKSPACE] = "BACKSPACE";//8
		keyNameByCode[Keyboard.TAB] = "TAB";//9
		keyNameByCode[Keyboard.ENTER] = "ENTER";//13
		keyNameByCode[Keyboard.SHIFT] = "SHIFT";//16
		keyNameByCode[Keyboard.CONTROL] = "CONTROL";//17
		keyNameByCode[Keyboard.ALTERNATE] = "ALT";//18
		keyNameByCode[Keyboard.CAPS_LOCK] = "CAPS LOCK";//20
		keyNameByCode[Keyboard.ESCAPE] = "ESC";//27
		keyNameByCode[Keyboard.SPACE] = "SPACE";//32
		keyNameByCode[Keyboard.PAGE_UP] = "PAGE UP";//33
		keyNameByCode[Keyboard.PAGE_DOWN] = "PAGE DOWN";//34
		keyNameByCode[Keyboard.END] = "END";//35
		keyNameByCode[Keyboard.HOME] = "HOME";//36
		keyNameByCode[Keyboard.LEFT] = "LEFT";//37
		keyNameByCode[Keyboard.UP] = "UP";//38
		keyNameByCode[Keyboard.RIGHT] = "RIGHT";//39
		keyNameByCode[Keyboard.DOWN] = "DOWN";//40
		keyNameByCode[Keyboard.INSERT] = "INSERT";//45
		keyNameByCode[Keyboard.DELETE] = "DELETE";//46
		keyNameByCode[Keyboard.NUMBER_0] = "0";//48
		keyNameByCode[Keyboard.NUMBER_1] = "1";//49
		keyNameByCode[Keyboard.NUMBER_2] = "2";//50
		keyNameByCode[Keyboard.NUMBER_3] = "3";//51
		keyNameByCode[Keyboard.NUMBER_4] = "4";//52
		keyNameByCode[Keyboard.NUMBER_5] = "5";//53
		keyNameByCode[Keyboard.NUMBER_6] = "6";//54
		keyNameByCode[Keyboard.NUMBER_7] = "7";//55
		keyNameByCode[Keyboard.NUMBER_8] = "8";//56
		keyNameByCode[Keyboard.NUMBER_9] = "9";//57
		keyNameByCode[Keyboard.A] = "A";//65
		keyNameByCode[Keyboard.B] = "B";//66
		keyNameByCode[Keyboard.C] = "C";//67
		keyNameByCode[Keyboard.D] = "D";//68
		keyNameByCode[Keyboard.E] = "E";//69
		keyNameByCode[Keyboard.F] = "F";//70
		keyNameByCode[Keyboard.G] = "G";//71
		keyNameByCode[Keyboard.H] = "H";//72
		keyNameByCode[Keyboard.I] = "I";//73
		keyNameByCode[Keyboard.J] = "J";//74
		keyNameByCode[Keyboard.K] = "K";//75
		keyNameByCode[Keyboard.L] = "L";//76
		keyNameByCode[Keyboard.M] = "M";//77
		keyNameByCode[Keyboard.N] = "N";//78
		keyNameByCode[Keyboard.O] = "O";//79
		keyNameByCode[Keyboard.P] = "P";//80
		keyNameByCode[Keyboard.Q] = "Q";//81
		keyNameByCode[Keyboard.R] = "R";//82
		keyNameByCode[Keyboard.S] = "S";//83
		keyNameByCode[Keyboard.T] = "T";//84
		keyNameByCode[Keyboard.U] = "U";//85
		keyNameByCode[Keyboard.V] = "V";//86
		keyNameByCode[Keyboard.W] = "W";//87
		keyNameByCode[Keyboard.X] = "X";//88
		keyNameByCode[Keyboard.Y] = "Y";//89
		keyNameByCode[Keyboard.Z] = "Z";//90
		keyNameByCode[Keyboard.NUMPAD_0] = "NUMPAD 0";//96
		keyNameByCode[Keyboard.NUMPAD_1] = "NUMPAD 1";//97
		keyNameByCode[Keyboard.NUMPAD_2] = "NUMPAD 2";//98
		keyNameByCode[Keyboard.NUMPAD_3] = "NUMPAD 3";//99
		keyNameByCode[Keyboard.NUMPAD_4] = "NUMPAD 4";//100
		keyNameByCode[Keyboard.NUMPAD_5] = "NUMPAD 5";//101
		keyNameByCode[Keyboard.NUMPAD_6] = "NUMPAD 6";//102
		keyNameByCode[Keyboard.NUMPAD_7] = "NUMPAD 7";//103
		keyNameByCode[Keyboard.NUMPAD_8] = "NUMPAD 8";//104
		keyNameByCode[Keyboard.NUMPAD_9] = "NUMPAD 9";//105
		keyNameByCode[Keyboard.NUMPAD_MULTIPLY] = "NUMPAD *";//106
		keyNameByCode[Keyboard.NUMPAD_ADD] = "NUMPAD +";//107
		keyNameByCode[Keyboard.NUMPAD_ENTER] = "NUMPAD ENTER";//108
		keyNameByCode[Keyboard.NUMPAD_SUBTRACT] = "NUMPAD -";//109
		keyNameByCode[Keyboard.NUMPAD_DECIMAL] = "NUMPAD .";//110
		keyNameByCode[Keyboard.NUMPAD_DIVIDE] = "NUMPAD /";//111
		keyNameByCode[Keyboard.F1] = "F1";//112
		keyNameByCode[Keyboard.F2] = "F2";//113
		keyNameByCode[Keyboard.F3] = "F3";//114
		keyNameByCode[Keyboard.F4] = "F4";//115
		keyNameByCode[Keyboard.F5] = "F5";//116
		keyNameByCode[Keyboard.F6] = "F6";//117
		keyNameByCode[Keyboard.F7] = "F7";//118
		keyNameByCode[Keyboard.F8] = "F8";//119
		keyNameByCode[Keyboard.F9] = "F9";//120
		keyNameByCode[Keyboard.F10] = "F10";//121
		keyNameByCode[Keyboard.F11] = "F11";//122
		keyNameByCode[Keyboard.F12] = "F12";//123
		keyNameByCode[Keyboard.F13] = "F13";//124
		keyNameByCode[Keyboard.F14] = "F14";//125
		keyNameByCode[Keyboard.F15] = "F15";//126
		keyNameByCode[Keyboard.SEMICOLON] = ";";//186
		keyNameByCode[Keyboard.EQUAL] = "=";//187
		keyNameByCode[Keyboard.COMMA] = ",";//188
		keyNameByCode[Keyboard.MINUS] = "-";//189
		keyNameByCode[Keyboard.PERIOD] = ".";//190
		keyNameByCode[Keyboard.SLASH] = "/";//191
		keyNameByCode[Keyboard.BACKQUOTE] = "`";//192
		keyNameByCode[Keyboard.LEFTBRACKET] = "[";//219
		keyNameByCode[Keyboard.BACKSLASH] = "\\";//220
		keyNameByCode[Keyboard.RIGHTBRACKET] = "]";//221
		keyNameByCode[Keyboard.QUOTE] = "'";//222

		private static const keyNameByAlias:Dictionary = new Dictionary();

		keyNameByAlias["BCKSPCE"] = "BACKSPACE";
		keyNameByAlias["SHFT"] = "SHIFT";
		keyNameByAlias["CNTRL"] = "CONTROL";
		keyNameByAlias["CTRL"] = "CONTROL";
		keyNameByAlias["ALTERNATE"] = "ALT";
		keyNameByAlias["ALTER"] = "ALT";
		keyNameByAlias["CAPS_LOCK"] = "CAPS LOCK";
		keyNameByAlias["CAPS"] = "CAPS LOCK";
		keyNameByAlias["ESCAPE"] = "ESC";
		keyNameByAlias["ESCP"] = "ESC";
		keyNameByAlias["SPACEBAR"] = "SPACE";
		keyNameByAlias["PAGE_UP"] = "PAGE UP";
		keyNameByAlias["PAGEUP"] = "PAGE UP";
		keyNameByAlias["PG UP"] = "PAGE UP";
		keyNameByAlias["PG_UP"] = "PAGE UP";
		keyNameByAlias["PGUP"] = "PAGE UP";
		keyNameByAlias["PAGE_DOWN"] = "PAGE DOWN";
		keyNameByAlias["PAGEDOWN"] = "PAGE DOWN";
		keyNameByAlias["PG DOWN"] = "PAGE DOWN";
		keyNameByAlias["PG_DOWN"] = "PAGE DOWN";
		keyNameByAlias["PGDOWN"] = "PAGE DOWN";
		keyNameByAlias["PG DWN"] = "PAGE DOWN";
		keyNameByAlias["PG_DWN"] = "PAGE DOWN";
		keyNameByAlias["PGDWN"] = "PAGE DOWN";
		keyNameByAlias["PG DN"] = "PAGE DOWN";
		keyNameByAlias["PG_DN"] = "PAGE DOWN";
		keyNameByAlias["PGDN"] = "PAGE DOWN";
		keyNameByAlias["INS"] = "INSERT";
		keyNameByAlias["INSRT"] = "INSERT";
		keyNameByAlias["DEL"] = "DELETE";
		keyNameByAlias["DLT"] = "DELETE";

		keyNameByAlias["NUMBER_0"] = "0";
		keyNameByAlias["NUMBER 0"] = "0";
		keyNameByAlias["NUMBER0"] = "0";
		keyNameByAlias[")"] = "0";
		keyNameByAlias["NUMBER_1"] = "1";
		keyNameByAlias["NUMBER 1"] = "1";
		keyNameByAlias["NUMBER1"] = "1";
		keyNameByAlias["!"] = "1";
		keyNameByAlias["NUMBER_2"] = "2";
		keyNameByAlias["NUMBER 2"] = "2";
		keyNameByAlias["NUMBER2"] = "2";
		keyNameByAlias["@"] = "2";
		keyNameByAlias["NUMBER_3"] = "3";
		keyNameByAlias["NUMBER 3"] = "3";
		keyNameByAlias["NUMBER3"] = "3";
		keyNameByAlias["#"] = "3";
		keyNameByAlias["NUMBER_4"] = "4";
		keyNameByAlias["NUMBER 4"] = "4";
		keyNameByAlias["NUMBER4"] = "4";
		keyNameByAlias["$"] = "4";
		keyNameByAlias["NUMBER_5"] = "5";
		keyNameByAlias["NUMBER 5"] = "5";
		keyNameByAlias["NUMBER5"] = "5";
		keyNameByAlias["%"] = "5";
		keyNameByAlias["NUMBER_6"] = "6";
		keyNameByAlias["NUMBER 6"] = "6";
		keyNameByAlias["NUMBER6"] = "6";
		keyNameByAlias["^"] = "6";
		keyNameByAlias["NUMBER_7"] = "7";
		keyNameByAlias["NUMBER 7"] = "7";
		keyNameByAlias["NUMBER7"] = "7";
		keyNameByAlias["&"] = "7";
		keyNameByAlias["NUMBER_8"] = "8";
		keyNameByAlias["NUMBER 8"] = "8";
		keyNameByAlias["NUMBER8"] = "8";
		keyNameByAlias["*"] = "8";
		keyNameByAlias["NUMBER_9"] = "9";
		keyNameByAlias["NUMBER 9"] = "9";
		keyNameByAlias["NUMBER9"] = "9";
		keyNameByAlias["("] = "9";

		keyNameByAlias["NUMPAD_0"] = "0";
		keyNameByAlias["NUMPAD0"] = "0";
		keyNameByAlias["NUMPAD_1"] = "1";
		keyNameByAlias["NUMPAD1"] = "1";
		keyNameByAlias["NUMPAD_2"] = "2";
		keyNameByAlias["NUMPAD2"] = "2";
		keyNameByAlias["NUMPAD_3"] = "3";
		keyNameByAlias["NUMPAD3"] = "3";
		keyNameByAlias["NUMPAD_4"] = "4";
		keyNameByAlias["NUMPAD4"] = "4";
		keyNameByAlias["NUMPAD_5"] = "5";
		keyNameByAlias["NUMPAD5"] = "5";
		keyNameByAlias["NUMPAD_6"] = "6";
		keyNameByAlias["NUMPAD6"] = "6";
		keyNameByAlias["NUMPAD_7"] = "7";
		keyNameByAlias["NUMPAD7"] = "7";
		keyNameByAlias["NUMPAD_8"] = "8";
		keyNameByAlias["NUMPAD8"] = "8";
		keyNameByAlias["NUMPAD_9"] = "9";
		keyNameByAlias["NUMPAD9"] = "9";

		keyNameByAlias["F 1"] = "F1";
		keyNameByAlias["F 2"] = "F2";
		keyNameByAlias["F 3"] = "F3";
		keyNameByAlias["F 4"] = "F4";
		keyNameByAlias["F 5"] = "F5";
		keyNameByAlias["F 6"] = "F6";
		keyNameByAlias["F 7"] = "F7";
		keyNameByAlias["F 8"] = "F8";
		keyNameByAlias["F 9"] = "F9";
		keyNameByAlias["F 10"] = "F10";
		keyNameByAlias["F 11"] = "F11";
		keyNameByAlias["F 12"] = "F12";
		keyNameByAlias["F 13"] = "F13";
		keyNameByAlias["F 14"] = "F14";
		keyNameByAlias["F 15"] = "F15";

		keyNameByAlias[":"] = ";";
		keyNameByAlias["+"] = "=";
		keyNameByAlias["<"] = ",";
		keyNameByAlias["_"] = "-";
		keyNameByAlias[">"] = ".";
		keyNameByAlias["?"] = "/";
		keyNameByAlias["~"] = "`";
		keyNameByAlias["{"] = "[";
		keyNameByAlias["|"] = "\\";
		keyNameByAlias["}"] = "]";
		keyNameByAlias["\""] = "'";

	}
}
