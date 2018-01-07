package napalm.framework.managers
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.SimpleButton;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	import napalm.framework.config.Device;
	import napalm.framework.config.Preferences;
	import napalm.framework.config.constants.LanguageCode;
	import napalm.framework.log.Channel;
	import napalm.framework.net.air.URLUpdaterQueue;
	import napalm.framework.utils.ObjectUtil;
	import napalm.framework.utils.StringUtil;
	
	[Event(name="languageUpdate", type="starling.events.Event")]
	[Event(name="languageChange", type="starling.events.Event")]

	/**
	 * LanguageManager.
	 * 
	 * Set availableLanguageCodeArray - a list of languages to be loaded.
	 * Set getRemoteLanguageURLByCode or languageDirURL to enable remote loading of language data.
	 * Set getMobileLanguagePathByCode or mobileLanguageDirPath to enable local loading of language data.
	 * Call loadLanguages(onComplete) - to load all JSONs with translations. When onComplete called 
	 * the manager is ready to translate.
	 * 
	 * isLoadAllAvailableLanguages=true - load all available languages at start.
	 * isLoadAllAvailableLanguages=false - load each new language on demand - when currentLanguageCode changed.
	 * 
	 * Using:
	 * 	languageManager.availableLanguageCodeArray = appConfig.availableLanguageCodeArray;
	 * 	languageManager.getRemoteLanguageURLByCode = urlConfig.getRemoteLanguageURLByCode;
	 * 	languageManager.getMobileLanguagePathByCode = urlConfig.getMobileLanguagePathByCode;
	 * 	languageManager.socialNetwork = appConfig.socialNetwork;
	 * 	// Set currentLanguageCode after availableLanguageCodeArray
	 * 	languageManager.currentLanguageCode = appConfig.languageCode;
	 * 	languageManager.loadLanguages(onLanguagesLoaded);
	 * 	...
	 * 	private function onLanguagesLoaded():void
	 * 	{
	 * 		// Since now we can get translations
	 * 		trace(languageManager.get("some_key"));
	 * 	}
	 * 
	 * (If function is set then dirURL/Path will be ignored.)
	 * @author alex.panoptik@gmail.com
	 */
	public class LanguageManager extends BaseManager
	{

		// Class constants


		// Use to update GUI which choose a language
		public static const LANGUAGE_CHANGE:String = "languageChange";
		// Use this event to update texts
		public static const LANGUAGE_UPDATE:String = "languageUpdate";

		private static const GENDER_MALE_SUFFIX:String = "m";
		private static const GENDER_FEMALE_SUFFIX:String = "f";
		
		private static const ASIAN_LANGUAGE_CODE_ARRAY:Array = ["ja", "ko", "kk", "th", "zh", "tc"];
		
		// Class variables
		
		// Class methods
		
		// Variables

		public var defaultLanguageCode:String = LanguageCode.EN;
		public var availableLanguageCodeArray:Array;

		public var isLoadAllAvailableLanguages:Boolean = false;
		public var getRemoteLanguageURLByCode:Function;
		public var getMobileLanguagePathByCode:Function;
		public var languageDirURL:String;
		public var mobileLanguageDirPath:String;

		public var globalSubstituteDictionary:Object = {};
		public var socialNetwork:String;
		public var isUserGenderMale:Boolean = true;

		public var isKeepAsianFontsForFlash:Boolean = false;
		public var defaultFontName:String;
		public var asianFontNameByLanguageCodeLookup:Object = {"ko": "_sans", "ja": "_sans", "zh": "_sans", "tc": "_sans"}; // Microsoft YaHei UI";// "Microsoft JhengHei UI";// "Meiryo UI";
//?-		private function loadAsianFonts():void
//		{
//			asianFontNameByLanguageCodeLookup["ja"] = asianFontNameByLanguageCodeLookup["zh"] = asianFontNameByLanguageCodeLookup["tc"] = "Microsoft YaHei UI";
//			asianFontNameByLanguageCodeLookup["ko"] = "Gulim";
//		}
		
		private var preferences:Preferences;
		
		private var languageUpdaterQueue:URLUpdaterQueue;
		private var onUpdaterComplete:Function;
		private var loadingLanguageCodeArray:Array = [];
		
		private var languageDataByCodeDic:Dictionary = new Dictionary();
		private var currentLanguageData:Object;

		// Properties

		/**
		 * Set after availableLanguageCodeArray.
		 */
		private var _currentLanguageCode:String;
		public function get currentLanguageCode():String
		{
			return _currentLanguageCode;
		}
		public function set currentLanguageCode(value:String):void
		{
			if (_currentLanguageCode === value)
			{
				return;
			}
			
			if (!checkLanguageAllowed(value))
			{
				log.error(Channel.LANGUAGE, this, "(set-currentLanguageCode) <return> Trying to set not available language! " +
						"Default language will be used!", "value:", value, "prev-currentLanguageCode:", 
						_currentLanguageCode, "availableLanguageCodeArray:", availableLanguageCodeArray, 
						"defaultLanguageCode:", defaultLanguageCode);
				return;
			}
			
//			if (availableLanguageCodeArray.length && !languageDataByCodeDic[value])
//			{
//				log.error(Channel.LANGUAGE, this, "(set-currentLanguageCode) Trying to set language which wasn't loaded! " +
//						"Default language will be used!", "value:", value, "prev-currentLanguageCode:", _currentLanguageCode, 
//						"languageData:", languageDataByCodeDic[value], "availableLanguageCodeArray:", 
//						availableLanguageCodeArray, "defaultLanguageCode:", defaultLanguageCode);
//			}

			log.log(Channel.LANGUAGE, this, "(set-currentLanguageCode)", "value:", value, "prev-currentLanguageCode:", _currentLanguageCode);
			var isInitialized:Boolean = _currentLanguageCode != null;
			_currentLanguageCode = value;
			preferences.setSetting("currentLanguageCode", value);
			
			var prevIsAsian:Boolean = _isAsian;
			_isAsian = ASIAN_LANGUAGE_CODE_ARRAY.indexOf(_currentLanguageCode) != -1;
			
			// Used only for Flash!
			if (isKeepAsianFontsForFlash && prevIsAsian != _isAsian)
			{
				changeKeepAsianFontsForFlash(_isAsian);
			}
			
			if (isInitialized)
			{
				if (languageDataByCodeDic.hasOwnProperty(_currentLanguageCode))
				{
					refreshData();
				}
				else
				{
					loadLanguages(refreshData);
				}
			}

			// Dispatch
			dispatchEventWith(LANGUAGE_CHANGE);
		}

		private var _isAsian:Boolean;
		public function get isAsian():Boolean
		{
			return _isAsian;
		}

		// Constructor

		public function LanguageManager()
		{
		}

		// Methods

		override public function initialize(systemManager:SystemManager):void
		{
			super.initialize(systemManager);

			preferences = systemManager.preferences;
			
			// Set currentLanguageCode automatically
			var preferencesLanguageCode:String = preferences.getSetting("currentLanguageCode");
			log.log(Channel.LANGUAGE, this, "(initialize)", "preferencesLanguageCode:", preferencesLanguageCode,
					"Device.language:", Device.language, "defaultLanguageCode:", defaultLanguageCode);
			currentLanguageCode = preferencesLanguageCode || Device.language || defaultLanguageCode;
		}

		override public function dispose():void
		{
			if (languageUpdaterQueue)
			{
				languageUpdaterQueue.dispose();
				languageUpdaterQueue = null;
			}

			//defaultLanguageCode = LanguageCode.EN;
			availableLanguageCodeArray = null;
			
			getRemoteLanguageURLByCode = null;
			getMobileLanguagePathByCode = null;
			languageDirURL = null;
			mobileLanguageDirPath = null;

			//globalSubstituteDictionary = {};
			//socialNetwork = null;
			//isUserGenderMale = true;

			isKeepAsianFontsForFlash = false;
			defaultFontName = null;
			_isAsian = false;
			changeKeepAsianFontsForFlash(false);

			loadingLanguageCodeArray.length = 0;
			onUpdaterComplete = null;
			
			languageDataByCodeDic = new Dictionary();
			currentLanguageData = null;
			_currentLanguageCode = null;

			preferences = null;
			
			super.dispose();
		}

		public function getFontName(defaultFontName:String = null):String
		{
			var result:String = defaultFontName || this.defaultFontName;
			if (isAsian)
			{
				if (Device.isIOS)
				{
					result = "_sans";//ios, _sans - no problem
				}
				else
				{
					//android wants embedded fonts (4Mb+)
					if (asianFontNameByLanguageCodeLookup[currentLanguageCode])
					{
						result = asianFontNameByLanguageCodeLookup[currentLanguageCode];
					}
				}
			}
			//log.info(Channel.LANGUAGE, this, "(getFontName)", "result:", result, "defaultFontName:", defaultFontName);
			return result;
		}

		public function checkLanguageAllowed(languageCode:String):Boolean
		{
			return !availableLanguageCodeArray || !availableLanguageCodeArray.length || availableLanguageCodeArray.indexOf(languageCode) != -1;
		}
		
		public function hasLanguage(languageCode:String = null):Boolean
		{
			return (languageCode ? languageDataByCodeDic[languageCode] : currentLanguageData) != null;
		}

		public function hasTranslation(key:String, languageCode:String = null):Boolean
		{
			if (!languageCode)
			{
				if (!currentLanguageData)
				{
					return false;
				}
				return key in currentLanguageData;
			}
			else
			{
				var languageData:Object = languageDataByCodeDic[languageCode];
				if (languageData)
				{
					return key in languageData;
				}
			}
			
			return false;
		}
		
		/**
		 * Get translation by key. Some values could be injected into translation from replaces.
		 * If there is no translation for currentLanguageCode, then defaultLanguageCode would be used.
		 * 
		 * Translation is finding in following order:
		 * 	1. soc_key_gender
		 * 	2. key_soc_gender
		 * 	3. soc_key
		 * 	4. key_soc
		 * 	5. key_gender
		 * 	6. gender_key
		 * 	7. key
		 * Here:
		 *  soc = fb|vk|ok|mm|...
		 *	gender = m|f
		 * For this socialNetwork and isUserGenderMale must be properly set.
		 * 
		 * Example:
		 * 	var piecesCount:int = 5;
		 * 	var piecesForms:String = languageManager.get("pieces_forms")
		 * 	// "Buy {0} {1}" -> "Buy 5 pieces"
		 * 	textField.text = languageManager.get("buy_pieces_text", piecesCount, 
		 * 			languageManager.getPluralForm(piecesCount, piecesForms));
		 * 
		 * @param key		key to find translation
		 * @param replaces	values by which "{0}","{1}",... would be replaced
		 * @return			translation or "{key}" string
		 */
		public function get(key:String, ...replaces):String
		{
			// Try translate
			var text:String = getTranslation(currentLanguageData, key);

			// Try translate on default language
			if (!text && defaultLanguageCode != currentLanguageCode)
			{
				var defaultLanguageData:Object = languageDataByCodeDic[defaultLanguageCode];
				text = getTranslation(defaultLanguageData, key);
			}
			
			// Substitutions
			if (text)
			{
				while (text.indexOf("\\n") != -1)
				{
					text = text.replace("\\n", "\n");
				}

				text = StringUtil.substituteByLookup(text, globalSubstituteDictionary);

				if (replaces && replaces.length)
				{
					text = StringUtil.substitute(text, replaces);
				}
			}
			
			if (!text)
			{
				log.warn(Channel.LANGUAGE, this, "(get) There is no token with such a key in current language JSON! key:", key, 
						"key===null:", key === null, "text:", text, "currentLanguageCode:", currentLanguageCode);
			}
			//log.info(Channel.LANGUAGE, this, "(get)", "key:", key, "text:", text);
			
			// Return translation or key
			return text || "{" + key + "}";
		}
		
		private function getTranslation(languageData:Object, key:String):String
		{
			var text:String;

			var genderCode:String = isUserGenderMale ? GENDER_MALE_SUFFIX : GENDER_FEMALE_SUFFIX;
			if (socialNetwork)
			{
				// By key + socialNetwork + genderCode
				if (genderCode)
				{
					text = languageData[socialNetwork + "_" + key + "_" + genderCode];
					text ||= languageData[key + "_" + socialNetwork + "_" + genderCode];
				}

				// By key + socialNetwork
				text ||= languageData[socialNetwork + "_" + key];
				text ||= languageData[key + "_" + socialNetwork];
			}

			// By key + genderCode
			if (!text && genderCode)
			{
				text = languageData[key + "_" + genderCode];
			}

			// By key
			if (!text)
			{
				text = languageData[key];
			}

			return text;
		}

		/**
		 * To add support of more languages see:
		 * http://localization-guide.readthedocs.org/en/latest/l10n/pluralforms.html
		 *
		 * @param number
		 * @param forms must be an comma-separated list of plural forms for current language.
		 * 				for en: "turn,turns", for ru: "ход,хода,ходов"
		 * @return
		 */
		public function getPluralForm(number:int, forms:String):String
		{
			var formIndex:int;
			switch (currentLanguageCode)
			{
				case "ru":
				{
					formIndex = (number % 10 == 1 && number % 100 != 11 ? 0 : number % 10 >= 2 && 
							number % 10 <= 4 && (number % 100 < 10 || number % 100 >= 20) ? 1 : 2);
					break;
				}
				case "en":
				{
					formIndex = number < 2 ? 0 : 1;
					break;
				}
				case "de":
				case "it":
				case "mn":
				{
					formIndex = int(number != 1);
					break;
				}
				case "ja":
				case "zh":
				case "ko":
				case "kk":
				case "th":
				{
					formIndex = 0;
					break;
				}
			}

			var formsArray:Array = forms.split(",");
			if (formsArray[formIndex])
			{
				return formsArray[formIndex];
			}
			return null;//"Unknown Plural Form!";
		}
		
		// Load

	//todo test immediate changing language several times when isLoadAllAvailableLanguages=false
		/**
		 * Set params before:
		 *  - availableLanguageCodeArray;
		 *  - getRemoteLanguageURLByCode or languageDirURL;
		 *  - getMobileLanguagePathByCode or mobileLanguageDirPath.
		 * 
		 * @param onComplete called on language JSONs are loaded and manager is ready to be used
		 */
		public function loadLanguages(onComplete:Function):void
		{
			log.log(Channel.LANGUAGE, this, "(loadLanguages) Start loading. languageUpdaterQueue:", languageUpdaterQueue);
//			// Check is loading now
//			if (languageUpdaterQueue)
//			{
//				return;
//			}
			
			this.onUpdaterComplete = onComplete;
			
			// Get URLs/paths
			var languageURLArray:Array = [];
			var mobileLanguagePathArray:Array = [];
			for (var languageCode:String in availableLanguageCodeArray)
			{
				// Check for isLoadAllAvailableLanguages
				if ((!isLoadAllAvailableLanguages && languageCode != currentLanguageCode) ||
						loadingLanguageCodeArray.indexOf(languageCode) != -1)
				{
					continue;
				}
				
				var languageURL:String = getRemoteLanguageURLByCode != null ?
						getRemoteLanguageURLByCode(languageCode) : getRemoteLanguageURLByCodeDefault(languageCode);
				var mobileLanguagePath:String = getMobileLanguagePathByCode != null ?
						getMobileLanguagePathByCode(languageCode) : getMobileLanguagePathByCodeDefault(languageCode);
				
				languageURLArray[languageURLArray.length] = languageURL;
				mobileLanguagePathArray[mobileLanguagePathArray.length] = mobileLanguagePath;
				loadingLanguageCodeArray[loadingLanguageCodeArray.length] = languageCode;
			}
			
			log.log(Channel.LANGUAGE, this, " (loadLanguages) load loadingLanguageCodeArray:", loadingLanguageCodeArray, 
					"languageURLArray:", languageURLArray, "mobileLanguagePathArray:", mobileLanguagePathArray,
					"availableLanguageCodeArray:", availableLanguageCodeArray);
			
			// Load
			languageUpdaterQueue = new URLUpdaterQueue();
			languageUpdaterQueue.name = "languageUpdaterQueue";
			languageUpdaterQueue.isParseJSON = true;
			languageUpdaterQueue.loadAndUpdateArray(languageURLArray, mobileLanguagePathArray, languageUpdaterQueue_onComplete);
		}

		private function getRemoteLanguageURLByCodeDefault(languageCode:String):String
		{
			return languageDirURL && languageCode ? languageDirURL + languageCode + ".json" : null;
		}

		private function getMobileLanguagePathByCodeDefault(languageCode:String):String
		{
			return mobileLanguageDirPath && languageCode ? mobileLanguageDirPath + languageCode + ".json" : null;
		}
		
		private function refreshData():void
		{
			currentLanguageData = languageDataByCodeDic[currentLanguageCode] || languageDataByCodeDic[defaultLanguageCode];

			// Dispatch
			dispatchEventWith(LANGUAGE_UPDATE);
		}

		// Fix Asian fonts for Flash (not used because only Starling is usually used)
		
		private function changeKeepAsianFontsForFlash(isAsian:Boolean):void
		{
			log.log(Channel.LANGUAGE, this, "(changeKeepAsianFontsForFlash) Should be used only if there are some Flash TextFields in App!", 
					"isKeepAsianFontsForFlash:", isKeepAsianFontsForFlash, "isAsian:", isAsian);
			var stage:Stage = systemManager.stage;
			if (isAsian && isKeepAsianFontsForFlash)
			{
				stage.addEventListener(Event.ENTER_FRAME, stage_enterFrameHandler);
			}
			else
			{
				stage.removeEventListener(Event.ENTER_FRAME, stage_enterFrameHandler);
			}
		}

		private function fixAsianFontsInFlashTextFields(target:Object):void
		{
			var displayContainer:DisplayObjectContainer = target as DisplayObjectContainer;
			var textField:TextField = target as TextField;
			var simpleButton:SimpleButton = target as SimpleButton;
			var displayObject:DisplayObject;

			if (displayContainer && displayContainer.visible)
			{
				for (var i:int = displayContainer.numChildren - 1; i > -1; --i)
				{
					displayObject = displayContainer.getChildAt(i);
					if (displayObject && displayObject.visible)
					{
						fixAsianFontsInFlashTextFields(displayObject);
					}
				}
			}
			else if (simpleButton && simpleButton.visible && simpleButton.alpha)
			{
				fixAsianFontsInFlashTextFields(simpleButton.upState);
				fixAsianFontsInFlashTextFields(simpleButton.downState);
				fixAsianFontsInFlashTextFields(simpleButton.overState);
			}
			else if (textField && textField.visible && textField.alpha)
			{
				fixFlashTextFieldForAsianFonts(textField);
			}
		}

		public function fixFlashTextFieldForAsianFonts(textField:TextField):void
		{
			if (isAsian)
			{
				textField.embedFonts = false;

				var format:TextFormat = textField.getTextFormat();
				format.font = getFontName(format.font);

				textField.styleSheet = null;
				textField.defaultTextFormat = format;
				textField.setTextFormat(format);
			}
		}
		
		// Event handlers
		
		private function languageUpdaterQueue_onComplete(dataArray:Array):void
		{
			log.info(Channel.LANGUAGE, this, "(languageUpdaterQueue_onComplete)", "availableLanguageCodeArray:", availableLanguageCodeArray, 
					"dataArray.length:", dataArray.length);
			// Save loaded data
			for (var i:int = 0; i < loadingLanguageCodeArray.length; i++)
			{
				// Register loaded language dictionaries!
				var languageCode:String = loadingLanguageCodeArray[i];
				var languageData:Object = dataArray[i];
				var isError:Boolean = languageData is Event || languageData is Error;
				languageDataByCodeDic[languageCode] = isError ? languageData : null;
				
				log.info(Channel.LANGUAGE, this, " (languageUpdaterQueue_onComplete)", "languageCode:", languageCode, 
						"languageData:", languageData ? ObjectUtil.stringify(languageData, 300) : null);
			}
			// Dispose
			if (languageUpdaterQueue)
			{
				languageUpdaterQueue.dispose();
				languageUpdaterQueue = null;
			}
			loadingLanguageCodeArray.length = 0;
			
			// Refresh
			refreshData();

			// onComplete
			if (onUpdaterComplete != null)
			{
				onUpdaterComplete();
				onUpdaterComplete = null;
			}
		}

		private function stage_enterFrameHandler(event:Event):void
		{
			//todo? add check time interval?
			//One Run Approx 0.00015 ms
			//var start:int = getTimer();
			if (isKeepAsianFontsForFlash)
			{
				fixAsianFontsInFlashTextFields(event.target);
			}
			//log.log('Sensei', getTimer() - start);
		}
		
	}
}
