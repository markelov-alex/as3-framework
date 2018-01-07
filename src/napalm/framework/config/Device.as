package napalm.framework.config
{
	import flash.display.Stage;
	import flash.external.ExternalInterface;
	import flash.system.Capabilities;
	
	import napalm.framework.config.constants.ArtPlatformType;
	import napalm.framework.config.constants.QualityType;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	
	/**
	 * Device.
	 *
	 * @author alex.panoptik@gmail.com
	 */
	public class Device
	{

		// Class constants

//TEMP!?
	//todo rename DEFAULT_INITIAL_HD_..
		// Initial stage size all art was drawn for
		public static const INITIAL_HD_WIDTH:int = 2048;
		public static const INITIAL_HD_HEIGHT:int = 1536;

		private static const APP_SD_HEIGHT:int = INITIAL_HD_HEIGHT * SD_QUALITY_COEFF * SCALE_COEFF;

		private static const SCALE_COEFF:Number = 1.3;//???

		private static const HD_QUALITY_COEFF:Number = 1;
		private static const SD_QUALITY_COEFF:Number = 0.5;
		private static const SD2_QUALITY_COEFF:Number = 0.25;

		// Class variables

		private static var stage:Stage;
		//-private static var isLocked:Boolean = false;
		private static var isInitialized:Boolean = false;
		private static var isFixedQualityCoeff:Boolean;

		// Class properties

		private static var _DPI:int;
		public static function get DPI():int
		{
			if (_DPI)
			{
				return _DPI;
			}
			if (Capabilities.screenDPI < 161)
			{
				_DPI = 160;
			}
			else if (Capabilities.screenDPI < 241)
			{
				_DPI = 240;
			}
			else if (Capabilities.screenDPI < 321)
			{
				_DPI = 320;
			}
			else if (Capabilities.screenDPI < 481)
			{
				_DPI = 480;
			}
			else
			{
				_DPI = 640;
			}
			return _DPI;
		}

		// 1 or 0.5
		private static var _qualityCoeff:Number;
		public static function get qualityCoeff():Number
		{
			//trace("$$$$$$$$$$$ qualityCoeff isFixedQualityCoeff:",isFixedQualityCoeff,"stage.stageHeight, APP_SD_HEIGHT:",stage.stageHeight, APP_SD_HEIGHT,stage.stageHeight <= APP_SD_HEIGHT ? SD_QUALITY_COEFF : HD_QUALITY_COEFF);
			if (isFixedQualityCoeff)
			{
				return _qualityCoeff;
			}

			//was return stage.stageHeight <= APP_SD_HEIGHT ? SD_QUALITY_COEFF : HD_QUALITY_COEFF;
			//(take min size for different orientations!?)
			return Math.min(stage.stageWidth, stage.stageHeight) <= APP_SD_HEIGHT ? SD_QUALITY_COEFF : HD_QUALITY_COEFF;
		}

		// HD, SD, SD2
		private static var _qualityType:String;
		public static function get qualityType():String
		{
			if (isFixedQualityCoeff)
			{
				return _qualityType;
			}

			return stage.stageHeight <= APP_SD_HEIGHT ? QualityType.SD : QualityType.HD;
		}

		public static function get isHD():Boolean
		{
			return qualityType == QualityType.HD;
		}

		public static function get isSD():Boolean
		{
			return qualityType == QualityType.SD;
		}

		// AND, IOS, EMU, WEB
		private static var _artPlatformType:String;
		public static function get artPlatformType():String
		{
			return _artPlatformType;
		}

		/**
		 * To check isWeb use "if (!Device.isAIR)".
		 */
		public static function get isAIR():Boolean
		{
			return _isMobile || _isDesktop;
		}

		private static var _isMobile:Boolean = false;
		public static function get isMobile():Boolean
		{
			return _isMobile;
		}

		private static var _isDesktop:Boolean = false;
		public static function get isDesktop():Boolean
		{
			return _isDesktop;
		}

//		public static function set isMobile(value:Boolean):void
//		{
//			if (isLocked || _isMobile === value)
//			{
////				if (isLocked)
////				{
////					Log.warn(LOG, Device, "SystemManager is already locked! Cannot set isMobile. " +
////							"cur-isMobile:", isMobile, "value:", value);
////				}
//				return;
//			}
//
//			//Log.info(LOG, Device, "(set-isMobile) prev:",_isMobile, "new:", value);
//			_isMobile = value;
//		}

		/**
		 * Device with low performance capabilities.
		 */
		private static var _isLowDevice:Boolean = false;
		public static function get isLowDevice():Boolean
		{
			return _isLowDevice;
		}

//		public static function set isLowDevice(value:Boolean):void
//		{
//			if (isLocked || _isLowDevice === value)
//			{
//				return;
//			}
//			
//			//Log.info(LOG, Device, "(set-isLowDevice) prev:",_isLowDevice, "new:", value);
//			_isLowDevice = value;
//		}

		private static var _isTablet:Boolean = false;
		public static function get isTablet():Boolean
		{
			return _isTablet;
		}

		//private static var _isMobileEmulator:Boolean = false;
		//public static function get isMobileEmulator():Boolean
		//{
		//	return _isMobileEmulator;
		//}

		public static function get isWindows():Boolean
		{
			return Capabilities.os.toLocaleLowerCase().indexOf("win") > -1;
		}

		public static function get isAndroid():Boolean
		{
			return Capabilities.manufacturer.indexOf("Android") > -1;
		}

		//TODO!
		// Note: If true, isAndroid is also true!
		//private static var _isAmazon:Boolean = false;
		public static function get isAmazon():Boolean
		{
			return false;
			//return _isAmazon;
		}

		public static function get isIOS():Boolean
		{
			return Capabilities.manufacturer.indexOf("iOS") > -1;
		}

		public static function get isIOS5():Boolean
		{
			if (!isIOS)
			{
				return false;
			}
			var version:String = Capabilities.os;
			//version = "iPhone OS 5.1.1 iPad1,1";
			var index:int = version.indexOf("OS");
			if (index == -1)
			{
				return false;
			}
			index += 3;
			return version.slice(index, ++index) == "5";
		}

		public static function get language():String
		{
			var languageCode:String = Capabilities.language;

			//?needed?
			switch (languageCode)
			{
				case "sp"://?
					languageCode = "es"; //Spanish es(sp)
					break;
				case "jp"://?
					languageCode = "ja"; //Japanese ja(jp)
					break;
			}

			return languageCode;
		}

//		/**
//		 * Кодовое название девайса. далеко не совершенное и больше скорей подходит для
//		 * @return "pc" / "ipad3" / "ipad2" / .. / "iphone3" / "iphone4" / .. / "android" / "unknown"
//		 */
//		private static var _deviceName:String;  // название девайса
//		public static function get deviceName():String
//		{
//			if (!_deviceName)
//			{
//				var os:String = deviceOS;
//				if (os.indexOf("ipad4,", 0) >= 0)
//				{
//					_deviceName = "ipad3";
//				}
//				else if (os.indexOf("ipad3,", 0) >= 0)
//				{
//					_deviceName = "ipad3";
//				}
//				else if (os.indexOf("ipad2,", 0) >= 0)
//				{
//					_deviceName = "ipad2";
//				}
//				else if (os.indexOf("ipad1,", 0) >= 0)
//				{
//					_deviceName = "ipad1";
//				}
//				else if (os.indexOf("iphone3,", 0) >= 0)
//				{
//					_deviceName = "iphone3";
//				}
//				else if (os.indexOf("iphone4,", 0) >= 0)
//				{
//					_deviceName = "iphone4";
//				}
//				else if (os.indexOf("ipod4,", 0) >= 0)
//				{
//					_deviceName = "ipod4";
//				}
//				else if (os.indexOf("ipod5,", 0) >= 0)
//				{
//					_deviceName = "ipod5";
//				}
//				else if (os.indexOf("ip", 0) >= 0)
//				{
//					_deviceName = "unknown";
//				}
//				else
//				{
//					_deviceName = "android";
//				}
//			}
//			return _deviceName;
//		}
//
//		/**
//		 * ОС девайса
//		 */
//		public static function get deviceOS():String
//		{
//			return Capabilities.os.toLowerCase();
//		}

		private static var _browserName:String;
		public static function get browserName():String
		{
			if (!_browserName)
			{
				var browserInfoParts:Array = browserInfo.split("/");
				_browserName = browserInfoParts[0];
			}

			return _browserName;
		}

		private static var _browserVersion:String;
		public static function get browserVersion():String
		{
			if (!_browserVersion)
			{
				var browserInfoParts:Array = browserInfo.split("/");
				_browserVersion = browserInfoParts[1];
			}

			return _browserVersion;
		}

		public function get isIE11():Boolean
		{
			return browserInfo ? browserInfo.indexOf("Trident") != -1 : false;
//			//trace1("###########isIE11#FLASHVARS.userAgent#",FLASHVARS.userAgent,FLASHVARS.userAgent&&Config.FLASHVARS.userAgent.indexOf("Trident"));
//			return Config.FLASHVARS.userAgent && Config.FLASHVARS.userAgent.indexOf("Trident") != -1;
//			//var regExpIE11:RegExp = /Trident.*rv[ :]*11\./i;
//			//return Config.FLASHVARS.userAgent && regExpIE11.test(Config.FLASHVARS.userAgent);
		}

		private static var _browserInfo:String;
		private static function get browserInfo():String
		{
			if (!_browserInfo)
			{
				if (ExternalInterface.available)
				{
					var jsCodeString:String = "'\" userAgent: \"' + navigator.userAgent";
					var jsFunctionString:String = "function () { return " + jsCodeString + "; }";
					var jsResponse:String = ExternalInterface.call(jsFunctionString);
					var browserInfoParts:Array = jsResponse.split(" ");

					_browserInfo = browserInfoParts[browserInfoParts.length - 2];
				}
				else
				{
					_browserInfo = "";
				}
			}

			return _browserInfo;
		}

		// Class methods

		public static function initialize(stage:Stage, isMobile:Boolean, isDesktop:Boolean = false, isFixedQualityCoeff:Boolean = true):void
		{
			// Check initialized
			if (isInitialized || !stage)
			{
				return;
			}
			isInitialized = true;

			Device.stage = stage;
			_isMobile = isMobile;
			_isDesktop = isDesktop;
			Device.isFixedQualityCoeff = isFixedQualityCoeff;

			// isTablet
			var minResolution:int = stage ? Math.min(stage.stageWidth, stage.stageHeight) : Capabilities.screenResolutionX;
			_isTablet = isMobile && (minResolution / Capabilities.screenDPI) > 3;

			// qualityCoeff
			//if (stage.fullScreenHeight <= INITIAL_HD_HEIGHT * SD2_QUALITY_COEFF * SCALE_COEFF)
			//{
			//	_qualityCoeff = SD2_QUALITY_COEFF;
			//	_qualityType = SD2_QUALITY;
			//}else
			if (!isMobile || stage.fullScreenHeight <= APP_SD_HEIGHT)
			{
				_qualityCoeff = SD_QUALITY_COEFF;
				_qualityType = QualityType.SD;
			}
			else
			{
				_qualityCoeff = HD_QUALITY_COEFF;
				_qualityType = QualityType.HD;
			}

			// artPlatformType
			if (isMobile)
			{
				if (isAndroid)
				{
					_artPlatformType = ArtPlatformType.ANDROID;
				}
				else if (isIOS)
				{
					_artPlatformType = ArtPlatformType.IOS;
				}
				else
				{
					_artPlatformType = ArtPlatformType.EMULATOR;
				}
			}
			else
			{
				_artPlatformType = ArtPlatformType.WEB;
			}

			Log.log(Channel.CONFIG, Device, "(initialize) stage:", stage, "isMobile:", isMobile, "isTablet:", isTablet,
				"qualityCoeff:", qualityCoeff, "qualityType:", qualityType, "artPlatformType:", artPlatformType);
		}

//-		public static function lock():void
//		{
//			isLocked = true;
//		}
		
	}
}
