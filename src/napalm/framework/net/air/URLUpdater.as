package napalm.framework.net.air
{
//CONFIG::mobile
//{
//	import com.freshplanet.ane.AirAlert.AirAlert;
//}
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import napalm.framework.config.Device;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.net.InternetChecker;
	import napalm.framework.net.URLRequester;
	import napalm.framework.utils.FileUtil;
	import napalm.framework.utils.StringUtil;
	
	/**
	 * URLUpdater.
	 * 
	 * Load some resource by URL, save it on mobile's local storage 
	 * by filePath, and return it with onComplete. 
	 * 
	 * If mobile and no Internet or URL didn't return result, 
	 * file will be got from local storage (by filePath).
	 * 
	 * Using:
	 * 	configUpdater = new URLUpdater();
	 * 	configUpdater.isAsyncWrite = true;
	 * 	configUpdater.loadAndUpdate(URLUtil.forceCacheFor(configURL), configFilePath, onConfigLoaded);
	 * 	...
	 * 	//configObject:Object if error, configObject:String if result
	 * 	private function onConfigLoaded(configObject:Object, flashVarsObject:Object = null):void
	 * 	{
	 * 		var isError:Boolean = configObject is Event || configObject is Error;
	 * 		// (Set configUpdater.isParseJSON=true to get already parsed configObject)	
	 * 		if (configObject is String)
	 * 		{
	 * 			configObject = JSON.parse(configObject as String);
	 * 		}
	 * 		AppConfig.initialize(configObject, flashVarsObject);
	 * 	}
	 * 
	 * Note: name used only in logs for debug to distinguish one instance from another.
	 * @author alex.panoptik@gmail.com
	 */
	public class URLUpdater
	{
		
		// Class constants
		
		// Class variables
		
//		private static var isAlertedNetworkError:Boolean = false;
		
		// Class methods
		
		// Variables

		public var name:String;

		public var isParseJSON:Boolean = false;//??for images??
		public var isAsyncWrite:Boolean = true;
		public var maxTryLaterCount:int = 3;
		
		protected var log:Log;
		protected var urlRequester:URLRequester;
		private var onComplete:Function;
		
		// (Temp for writing file)
		private var data:ByteArray;
		private var tryLaterCount:int = 0;
		
		// Properties
		
		private var _url:String;
		/**
		 * URL to load from Internet.
		 */
		public function get url():String
		{
			return _url;
		}

		private var _filePath:String;
		/**
		 * Path to write in local starage (for AIR).
		 */
		public function get filePath():String
		{
			return _filePath;
		}
		
		// Constructor

		public function URLUpdater()
		{
			log = Log.instance;
			//log.info(Channel.NET_LOADER, this, "(constructor)");
			urlRequester = new URLRequester();
		}

		// Methods

		public function dispose():void
		{
			log.info(Channel.NET_LOADER, this, "(dispose) name:", name, "url:", url);
			clear();

			if (urlRequester)
			{
				urlRequester.dispose();
			}

			urlRequester = null;
			isAsyncWrite = true;//?
			log = null;
		}
		
		public function clear():void
		{
			_clear();
		}
		
		private function _clear(): void
		{
			//log.info(Channel.NET_LOADER, this, "(clear) name:", name, "urlRequester:", urlRequester, "url:", url);
			if (urlRequester)
			{
				urlRequester.clear();
			}
			
			onComplete = null;
			data = null;
			_url = null;
			_filePath = null;
		}

		public function loadAndUpdate(url:String, filePath:String = "", onComplete:Function = null):void
		{
			log.info(Channel.NET_LOADER, this, "(loadAndUpdate) url:", url, "filePath:", filePath, "onComplete:", Boolean(onComplete), 
					"name:", name, "isMobile:", Device.isMobile);
			if (urlRequester && urlRequester.isLoading)
			{
				log.warn(Channel.NET_LOADER, this, " (loadAndUpdate) Another file is loading. SKIP! url:", url, 
						"filePath:", filePath, "current-url:", this.url, "name:", name);
				return;
			}
			
			_url = url;
			_filePath = filePath;
			this.onComplete = onComplete;
			
			if (Device.isMobile && !InternetChecker.isInternetAvailable)
			{
				// Load from local storage
				loadFromLocalStorage(filePath);
			}
			else
			{
				// Load from Internet and save to local storage
				urlRequester.name = (name || "updater") + "-requester";
				urlRequester.load(url, urlRequester_onComplete, null, false, true);
			}
		}

		/**
		 * Load only files that should be in local storage if user have played app at least once. 
		 * If no file the "No internet connection" alert will be shown. 
		 * 
		 * @param filePath
		 * @return ByteArray do String(data) to get JSON string
		 */
		public function loadFromLocalStorage(filePath:String):Object//, onComplete:Function = null
		{
			log.info(Channel.NET_LOADER, this, " (loadFromLocalStorage) filePath:", filePath, "url:", url, "name:", name);//, "onComplete:", onComplete
			
			// Load
			var data:Object = FileUtil.read(filePath);
			return data;
		}

		private function doComplete(data:Object):void//, onComplete:Function = null
		{
			log.info(Channel.NET_LOADER, this, "(doComplete) onComplete:", Boolean(onComplete), "name:", name);//, "data:", data

			if (onComplete != null)
			{
				var onCompleteArguments:Array = [prepareResultData(data), this];
				onCompleteArguments.length = onComplete.length;
				onComplete.apply(null, onCompleteArguments);
			}
			
			clear();
		}

		private function prepareResultData(data:Object):Object
		{
			data = data is ByteArray ? String(data) : data;
			
			if (isParseJSON && data is String)// && data is String
			{
	//??for images??
				try
				{
					data = JSON.parse(String(data));
				}
				catch (error:Error)
				{
					log.fatal(Channel.NET_LOADER, this, "URLUpdater. Cannot parse result from url: " + url + "! isParseJSON(t): " + isParseJSON + " Error:", error);
				}
			}
			
			return data;
		}

		private function tryLater(delayMsec:int = 3000):void
		{
			if (tryLaterCount >= maxTryLaterCount)
			{
				doComplete(null);
				return;
			}
			tryLaterCount++;
			
			//todo dispatch instead alert!
			// No internet & no file in local storage
//			try
//			{
				log.warn(Channel.NET_LOADER, this, "  (tryLater) failed checkExists:", FileUtil.checkExists(filePath), "name:", name);
//?						if (AirAlert.isSupported && !isAlertedNetworkError) {
//							isAlertedNetworkError = true;
//							log.error(Channel.NET_LOADER, this, "  (loadFromLocalStorage) <AirAlert.showAlert:no-internet>");
//							AirAlert.getInstance().showAlert("No internet connection for load updates",
//									"Need internet connection", "OK", /*NativeApplication.nativeApplication.exit*/ null);
//						}
				//?
				//clear();//?_clear();
				setTimeout(loadAndUpdate, delayMsec, _url, _filePath, this.onComplete);
//			}
//			catch (error:Error)
//			{
//				log.fatal(Channel.NET_LOADER, "Error:", error);
//			}
		}
		
		// Event handlers

		private function urlRequester_onComplete(data:Object):void
		{
			log.info(Channel.NET_LOADER, this, "  (urlRequester_onComplete) name:", name, "data:", StringUtil.cutStringInMiddle(String(data), 200),
					"is-bytearray:", data is ByteArray, "isMobile:", Device.isMobile, "url:", url);
			//log.info(Channel.NET_LOADER, this, "  temp(urlRequester_onComplete) data:", data,data as String, data as ByteArray, getQualifiedClassName(data));
//			isAlertedNetworkError = false;

			var dataByteArray:ByteArray = data as ByteArray;
			if (Device.isMobile && filePath)
			{
				if (!dataByteArray)
				{
					// Load from local storage
					dataByteArray = loadFromLocalStorage(filePath) as ByteArray;
				}
				if (!dataByteArray)
				{
					// Check loaded data
					tryLater();
					return;
				}

				this.data = dataByteArray;
				// Write to local storage
				if (isAsyncWrite)
				{
					FileUtil.writeAsync(filePath, dataByteArray, doComplete);
				}
				else
				{
					FileUtil.write(filePath, dataByteArray);
					doComplete(data);
				}
			}
			else
			{
				doComplete(data);
			}
		}

	}
}
