package napalm.framework.net
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	
	import napalm.framework.log.BugReporter;
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.FunctionUtil;
	
	/**
	 * ResourceLoader.
	 * 
	 * Use to load *.swf files.
	 * 
	 * Note: name used only in logs for debug to distinguish one instance from another.
	 * @author alex.panoptik@gmail.com
	 */
	public class ResourceLoader
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		public var name:String;
		
		protected var log:Log;
		private var domain:ApplicationDomain;

		private var onComplete:Function;
		private var onProgress:Function;

		// Properties

		private var _url:String;
		public function get url():String
		{
			return _url;
		}

		protected var _loader:Loader;
		public function get loader():Loader
		{
			return _loader;
		}

		public function get bytesTotal():uint
		{
			return _loader ? _loader.contentLoaderInfo.bytesTotal : 0;
		}

		public function get bytesLoaded():uint
		{
			return _loader ? _loader.contentLoaderInfo.bytesLoaded : 0;
		}

		public function get loadingRatio():Number
		{
			return _loader && _loader.contentLoaderInfo.bytesTotal ? _loader.contentLoaderInfo.bytesLoaded / _loader.contentLoaderInfo.bytesTotal : 0;
		}

		private var _isLoading:Boolean = false;
		public function get isLoading():Boolean
		{
			return _isLoading;
		}

//?
		public function get content():DisplayObject
		{
			return _loader ? _loader.content : null;
		}

		// Constructor

		public function ResourceLoader(domain:ApplicationDomain = null)
		{
			this.domain = domain || ApplicationDomain.currentDomain;//new ApplicationDomain(ApplicationDomain.currentDomain);
			log = Log.instance;
		}

		// Methods

		public function dispose():void
		{
			log.info(Channel.NET_LOADER, this, "(dispose) name:", name);
			clear();

			if (_loader)
			{
				BugReporter.unlistenUncaughtErrors(_loader.contentLoaderInfo);
				if (_loader.parent)
				{
					_loader.parent.removeChild(_loader);
				}
				
				// Free memory!
				_loader.unloadAndStop();
			}
			_loader = null;
			_url = null;
			
			domain = null;
			
			log = null;
		}

		public function clear():void
		{
			//log.info(Channel.NET_LOADER, "  (dispose) url:", url, "loader:", loader, "onComplete:", onComplete, "onProgress:", onProgress);
			if (_loader)
			{
				// Listeners
				_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, contentLoaderInfo_completeHandler);
				_loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, contentLoaderInfo_ioErrorHandler);
				_loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, contentLoaderInfo_securityErrorHandler);
				_loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, contentLoaderInfo_progressHandler);
				//??? 20151206 maybe this will cause uncatchable crashes (don't unlisten?)
				//?- was uncommented 20160221 BugReporter.unlistenUncaughtErrors(loader.contentLoaderInfo);

				if (_isLoading)
				{
//					loader.close();
				}

				//?- was uncommented 20160221
//				loader = null;
			}

			onComplete = null;
			onProgress = null;

			//?- was uncommented 20160221
//			_url = null;
			_isLoading = false;
		}

		/**
		 * Load URL and call onComplete when success or fail.
		 *
		 * @param url
		 * @param onComplete function onComplete(result:Object):void
		 *                    success result is LoaderInfo. Use its properties: 
		 *                    		result.content:DisplayObject or 
		 *                    		result.applicationDomain.getDefinition():Class
		 *                    fail result is Error|IOErrorEvent|SecurityErrorEvent
		 * @param onProgress function onProgress(loadRatio:Number):void
		 */
		public function load(url:String, onComplete:Function, onProgress:Function = null):void//++?, params:Object = null, isPost:Boolean = false
		{
			if (_isLoading)//was 20160221 if (loader)
			{
				log.warn(Channel.NET_LOADER, "Previous request is loading! This request will be skipped! (Maybe use URLRequestQueue) " + "current-url:", _url, "new-url:", url);
				return;
			}

			log.info(Channel.NET_LOADER, "(load) url:", url, "onComplete:", Boolean(onComplete), "onProgress:", Boolean(onProgress), "name:", name);//, params ? "params: " + params : "", isPost ? "isPost: " + isPost : ""

			_url = url;
			this.onComplete = onComplete;
			this.onProgress = onProgress;
			
			if (!url)
			{
				log.warn(Channel.NET_LOADER, "No URL given! current-url:", _url, "new-url:", url);
				doComplete(null);
				return;
			}

			//was 20160221 loader = new Loader();
			if (!_loader)
			{
				_loader = new Loader();
			}

			// Listeners
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaderInfo_completeHandler);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, contentLoaderInfo_ioErrorHandler);
			_loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, contentLoaderInfo_securityErrorHandler);
			if (onProgress != null)
			{
				_loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, contentLoaderInfo_progressHandler);
			}
			BugReporter.listenUncaughtErrors(_loader.contentLoaderInfo);

			var urlRequest:URLRequest = new URLRequest(_url);
			//++?
			//urlRequest.method = isPost ? URLRequestMethod.POST : URLRequestMethod.GET;
			//urlRequest.data = processParams(params);

			var securityDomain:SecurityDomain = Security.sandboxType == Security.REMOTE ? SecurityDomain.currentDomain : null;
			var loaderContext:LoaderContext = new LoaderContext(true, domain, securityDomain);

			_isLoading = true;
			_loader.load(urlRequest, loaderContext);
		}

		//todo
		public function loadEmbedded(embeddedSWFClass:Class):void
		{
			
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

		private function doComplete(result:Object):void
		{
			if (onProgress != null)
			{
				onProgress(1);
			}
			if (onComplete != null)
			{
				FunctionUtil.call(onComplete, [result, this]);//was onComplete(result);
			}
		}

		// Event handlers

		private function contentLoaderInfo_completeHandler(event:Event):void
		{
			log.info(Channel.NET_LOADER, this, " (contentLoaderInfo_completeHandler) Request Success url:", _url);
			log.info(Channel.NET_LOADER, this, "  (contentLoaderInfo_completeHandler) event.target(LoaderInfo):", event.target);
			_isLoading = false;

			doComplete(event.target);

			clear();
		}

		private function contentLoaderInfo_ioErrorHandler(event:IOErrorEvent):void
		{
			log.info(Channel.NET_LOADER, " (contentLoaderInfo_ioErrorHandler) Request FAIL url:", _url, "event:", event.toString());//, "errorID:",event.errorID, event.text
			_isLoading = false;

			doComplete(event);
			log.error(Channel.NET_LOADER, this, "  (contentLoaderInfo_ioErrorHandler) event,_url:", event, _url);
			//-BugReporter.reportError(LOG + " contentLoaderInfo_ioErrorHandler - ", _url);

			clear();
		}

		private function contentLoaderInfo_securityErrorHandler(event:SecurityErrorEvent):void
		{
			log.info(Channel.NET_LOADER, " (contentLoaderInfo_securityErrorHandler) Request FAIL url:", _url, "errorID:", event.errorID, event.text, event.toString());
			_isLoading = false;

			doComplete(event);

			log.error(Channel.NET_LOADER, this, "  (contentLoaderInfo_ioErrorHandler) event, _url:", event, _url);
			//-BugReporter.reportError(LOG + " contentLoaderInfo_ioErrorHandler - ", _url);
			
			clear();
		}

		private function contentLoaderInfo_progressHandler(event:ProgressEvent):void
		{
			if (onProgress != null)
			{
				//var loaderInfo:LoaderInfo = loader.contentLoaderInfo;
				//var loadingRatio:Number = loaderInfo.bytesTotal ? loaderInfo.bytesLoaded / loaderInfo.bytesTotal : 0;
				//log.info(Channel.NET_LOADER, " (contentLoaderInfo_progressHandler) loadingRatio:", loadingRatio);
				onProgress(loadingRatio);
			}
		}

	}
}
