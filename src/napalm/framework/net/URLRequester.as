package napalm.framework.net
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.FileUtil;
	
	/**
	 * URLRequester.
	 *
	 * Using:
	 * 	// Create
	 * 	private var urlRequester = new URLRequester();
	 * 	
	 * 	// Use
	 * 	urlRequester.load(url, urlRequester_onComplete);
	 * 	//...
	 * 	// success - data:ByteArray
	 * 	// fail - data:Error|IOErrorEvent|SecurityErrorEvent
	 * 	private function urlRequester_onComplete(data:Object):void
	 * 	{
	 * 		log.log("Request result data:", data);
	 * 		var isError:Boolean = data is Event || data is Error;	
	 * 		if (isError)
	 * 		{
	 * 			log.error("Request failed data:", data);
	 * 			return;
	 * 		}
	 * 		
	 * 		var dataObject:Object = JSON.parse(String(data));
	 * 		//...	
	 * 	}
	 * 
	 * Note: name used only in logs for debug to distinguish one instance from another.
	 * @author alex.panoptik@gmail.com
	 */
	public class URLRequester
	{

		// Class constants

		// Class variables
		
		public static var isShowConstructorStackTrace:Boolean = false;
		public static var isShowLoadStackTrace:Boolean = false;
		
		private static var instance:URLRequester;
		
		// Class methods

		public static function load(url:String, onComplete:Function, params:Object = null, isPost:Boolean = false,
		                            isBinary:Boolean = false, headers:Array = null):void
		{
			if (!instance)
			{
				instance = new URLRequesterQueue();
				instance.isParseJSON = true;
			}
			instance.load(url, onComplete, params, isPost, isBinary, headers);
		}
		
		// Variables

		public var name:String;

		public var isParseJSON:Boolean = false;
		
		protected var log:Log;
		protected var urlLoader:URLLoader;
		private var urlRequest:URLRequest;
		private var onComplete:Function;

		private var loadStartTime:int;

		private var constructorStackTrace:String = "";
		private var loadStackTrace:String = "";

		// Properties

		private var _url:String;
		public function get url():String
		{
			return _url;
		}

		private var _isLoading:Boolean;
		public function get isLoading():Boolean
		{
			return _isLoading;
		}

		// Constructor

		public function URLRequester()
		{
			log = Log.instance;
			if (log.checkChannelEnabled(Channel.NET_REQUEST))
			{
				constructorStackTrace = new Error("(constructor stack)").getStackTrace();
			}
			
			init();
		}

		// Methods

		private function init():void
		{
			urlLoader = new URLLoader();
			// Listeners
			urlLoader.addEventListener(Event.COMPLETE, urlLoader_completeHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoader_ioErrorHandler);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoader_securityErrorHandler);
			//urlLoader.addEventListener(ProgressEvent.PROGRESS, urlLoader_progressHandler);

			urlRequest = new URLRequest();
		}
		
		public function dispose():void
		{
			if (urlLoader)
			{
				// Listeners
				urlLoader.removeEventListener(Event.COMPLETE, urlLoader_completeHandler);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoader_ioErrorHandler);
				urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoader_securityErrorHandler);
				//urlLoader.removeEventListener(ProgressEvent.PROGRESS, urlLoader_progressHandler);
			}

			urlLoader = null;
			urlRequest = null;
			
			clear();
			log = null;
		}

		public function clear():void
		{
			//log.info(Channel.NET_REQUEST, this, "  (dispose) url:", url, "name:", name, "urlLoader:", urlLoader, "onComplete:", onComplete);
			if (_isLoading && urlLoader)
			{
				urlLoader.close();
			}
			
			_isLoading = false;
			onComplete = null;
			_url = null;
		}

		/**
		 * Load url and call onComplete when success or fail.
		 *
		 * @param url
		 * @param onComplete function onComplete(data:Object):void
		 *                    success data:String
		 *                    success data:Object if isParseJSON=true
		 *                    success data:ByteArray if isBinary=true
		 *                    fail data:Error|IOErrorEvent|SecurityErrorEvent
		 *                    Use String(data) to get content of ByteArray or to log when fail.
		 * @param isBinary    false - success data is String
		 *                    true - success data is ByteArray
		 */
		public function load(url:String, onComplete:Function, params:Object = null, isPost:Boolean = false, 
		                     isBinary:Boolean = false, headers:Array = null):void
		{
			if (_isLoading)
			{
				log.warn(Channel.NET_REQUEST, this, "Previous request is loading! This request will be skipped! (May be use URLRequestQueue) " + 
						"current-url:", _url, "new-url:", url);
				return;
			}
			
			if (log.checkChannelEnabled(Channel.NET_REQUEST))
			{
				loadStackTrace = new Error("(load() stack)").getStackTrace();
			}

			log.log(Channel.NET_REQUEST, this, "(load) url:", url, params ? "params: " + (params is ByteArray ? params.toString().substr(0, 64) : params) : "", "name:", name);
//			log.info(Channel.NET_REQUEST, this, " (load)", "onComplete:", onComplete,
//				isPost ? "isPost: " + isPost : "", isBinary ? "isBinary: " + isBinary : "");

			_url = url;
			this.onComplete = onComplete;

			if (!url)
			{
				log.warn(Channel.NET_REQUEST, this, "Empty URL! url:", _url);
				doComplete(null);
				return;
			}

			//??
//			CONFIG::mobile
//20151016commented??
// 			{
//				if (url.indexOf("http") != 0 && FileUtil.checkExists(url))
//				{
//					doComplete(String(FileUtil.read(url)));
//					return;
//				}
//			}
			CONFIG::mobile
			{
				if (url.indexOf("http") != 0)//if (url.indexOf(":/") == -1)//
				{
					var fileContent:ByteArray = FileUtil.read(url);
					if (fileContent)
					{
						doComplete(fileContent);
						return;
					}
				}
			}
			
			urlRequest.url = _url;
			urlRequest.method = isPost ? URLRequestMethod.POST : URLRequestMethod.GET;
			urlRequest.data = processParams(params);

			//?+
//			CONFIG::mobile
//			{
//				urlRequest.idleTimeout = 15000;
//			}
			if (headers)
			{
				urlRequest.requestHeaders = headers;
			}
			// to avoid auto-converting POST request to GET
			// http://stackoverflow.com/questions/12774611/urlrequest-urlloader-auto-converting-post-request-to-get
			//if (!params && isPost)
			//{
			//	urlRequest.data = {};
			//}

			urlLoader.dataFormat = isBinary ? URLLoaderDataFormat.BINARY : URLLoaderDataFormat.TEXT;

			// Load
			_isLoading = true;
			loadStartTime = getTimer();
			urlLoader.load(urlRequest);
		}

		private function processParams(params:Object):Object
		{
			if (!params || params is String || params is URLVariables || params is ByteArray)
			{
				return params;
			}

			var urlVariables:URLVariables = new URLVariables();
			for (var key:String in params)
			{
				urlVariables[key] = params[key];
			}

			return urlVariables;
		}

		private function getResultFromLoader(result:Object):Object
		{
			if (isParseJSON && (result is ByteArray || result is String))// && result is String
			{
				try
				{
					var object:Object = JSON.parse(String(result));
					result = object;
				}
				catch (error:Error)
				{
					log.error(Channel.NET_REQUEST, this, "Cannot parse URLRequester result from url:" + url + " ! isParseJSON(t):" + 
							isParseJSON + " Error:", error);
				}
			}

			return result;
		}

		private function doComplete(result:Object):void
		{
			if (onComplete != null)
			{
				onComplete(getResultFromLoader(result));
			}

			clear();
		}

		// Event handlers

		private function urlLoader_completeHandler(event:Event):void
		{
			log.info(Channel.NET_REQUEST, this, " (urlLoader_completeHandler) Request Success url:", _url, "name:", name, "time:", getTimer() - loadStartTime, "msec");
			//log.info(Channel.NET_REQUEST, this, "  (urlLoader_completeHandler) data:", StringUtil.cutStringLeavingEnd(urlLoader.data, 200));//, urlLoader.data ? getQualifiedClassName(urlLoader.data) : "", urlLoader.data);//

			doComplete(urlLoader.data);
		}

		private function urlLoader_ioErrorHandler(event:IOErrorEvent):void
		{
			log.error(Channel.NET_REQUEST, this, " (urlLoader_ioErrorHandler) Request FAIL url:", _url, "name:", name, 
					"time:", getTimer() - loadStartTime, "msec", "event:", event,
					isShowConstructorStackTrace && constructorStackTrace ? "\nconstructed in: " + constructorStackTrace : "",
					isShowLoadStackTrace && loadStackTrace ? "\nload() called in: " + loadStackTrace : "");//, "errorID:",event.errorID, event.text

			doComplete(event);

			InternetChecker.checkInternetConnection();
		}

		private function urlLoader_securityErrorHandler(event:SecurityErrorEvent):void
		{
			log.error(Channel.NET_REQUEST, this, " (urlLoader_securityErrorHandler) Request FAIL url:", _url, "name:", name, 
					"time:", getTimer() - loadStartTime, "msec", "event:", event, 
					"event.errorID:", event.errorID, event.text);

			doComplete(event);
		}

		private function urlLoader_progressHandler(event:ProgressEvent):void
		{
//			//debug
//			if (url.indexOf("some...") != -1)
//			{
//				trace(this,"(urlLoader_progressHandler) url:", url, "bytesLoaded:", event.bytesLoaded, "bytesTotal:", event.bytesTotal);
//			}
		}

	}
}
