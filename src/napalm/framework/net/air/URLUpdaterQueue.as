package napalm.framework.net.air
{
	import napalm.framework.log.Channel;
	import napalm.framework.utils.FunctionUtil;
	import napalm.framework.utils.StringUtil;
	
	/**
	 * URLUpdaterQueue.
	 * 
	 * Process URLUpdater as a queue. When calling loadAndUpdate() while 
	 * the previous one is loading, URLUpdater will ignore new request, and 
	 * URLUpdaterQueue will add it to the queue.
	 * 
	 * Each URL will be started updating when previous is loaded.
	 *
	 * loadAndUpdateArray() acts like loadAndUpdate() but enqueues more
	 * than one request at a time.
	 * @author alex.panoptik@gmail.com
	 */
	public class URLUpdaterQueue extends URLUpdater
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		private var updateObjectQueue:Array = [];
		private var onComplete:Function;
		private var onProgress:Function;
		private var resultDataArray:Array = [];

		// Properties

		public function get updatedCount():int
		{
			var updatedCount:int = _totalCount && updateObjectQueue ?
					(_totalCount - updateObjectQueue.length) : 0;
			return updatedCount;
		}

		private var _totalCount:int = 0;
		public function get totalCount():int
		{
			return _totalCount;
		}

		// Constructor

		public function URLUpdaterQueue()
		{
		}

		// Methods

		override public function dispose():void
		{
			updateObjectQueue = [];
			_totalCount = 0;
			onComplete = null;
			onProgress = null;
			resultDataArray = [];

			super.dispose();
		}

		override public function clear():void
		{
			super.clear();

			// (Remove from queue just loaded object)
			updateObjectQueue.shift();
			updateProgress();
			
			checkNext();
		}

		override public function loadAndUpdate(url:String, filePath:String = "", onComplete:Function = null):void
		{
			if (urlRequester && urlRequester.isLoading)
			{
				log.info(Channel.NET_LOADER, this, "(loadAndUpdate) <add-to-queue> url:",url, "filePath:",filePath, "onComplete:",onComplete);
				updateObjectQueue[updateObjectQueue.length] = {url: url, filePath: filePath, onComplete: onComplete};
				return;
			}

			super.loadAndUpdate(url, filePath, onComplete);
		}
		
		public function loadAndUpdateArray(urlArray:Array, filePathArray:Array = null, onComplete:Function = null, onProgress:Function = null):void
		{
			log.info(Channel.NET_LOADER, this, "(loadAndUpdateArray) name:", name, "urlArray:", StringUtil.cutStringInMiddle(String(urlArray), 100), 
					"filePathArray:", StringUtil.cutStringInMiddle(String(filePathArray), 100), 
					"onComplete:", Boolean(onComplete), "onProgress:", Boolean(onProgress));

			this.onComplete = onComplete;
			this.onProgress = onProgress;
			
			if ((!urlArray || !urlArray.length) && !urlRequester.isLoading)
			{
				doComplete();
				return;
			}

			for (var i:int = 0; i < urlArray.length; i++)
			{
				var url:String = urlArray[i];
				var filePath:String = filePathArray ? filePathArray[i] : null;
				var isLastURL:Boolean = i == (urlArray.length - 1);
				updateObjectQueue[updateObjectQueue.length] = {url: url, filePath: filePath, 
					onComplete: isLastURL ? onCompleteQueue : onCompleteItem};
			}
			_totalCount = _totalCount ? _totalCount + urlArray.length : updateObjectQueue.length;
			updateProgress();
			
			if (!urlRequester.isLoading)
			{
				checkNext();
			}
		}

		private function onCompleteItem(data:Object):void
		{
			resultDataArray[resultDataArray.length] = data;
		}

		private function onCompleteQueue(data:Object):void
		{
			onCompleteItem(data);
			doComplete();
		}

		private function doComplete():void
		{
			//log.info(Channel.NET_LOADER, this, "(doComplete) resultDataArray.length:", resultDataArray.length);
			//clear();//new //needed here to call clear() before dispose() - triggered by onComplete
			FunctionUtil.call(onComplete, [resultDataArray, this]);
			
			resultDataArray = [];
			//was_here- 
			clear();
		}

		private function checkNext():void
		{
			//log.info(Channel.NET_LOADER, this, "(checkNext)", "queue-length:", updateObjectQueue.length, "totalCount:", _totalCount);
			if (updateObjectQueue.length)
			{
				var updateObject:Object = updateObjectQueue[0];
				loadAndUpdate(updateObject.url, updateObject.filePath, updateObject.onComplete);
			}
		}

		private function updateProgress():void
		{
			if (onProgress != null)
			{
				var progressRatio:Number = _totalCount ? updatedCount / _totalCount : 1;
				log.info(Channel.NET_LOADER, this, "(updateProgress)", "progressRatio:", progressRatio, 
						"queue-length:", updateObjectQueue && updateObjectQueue.length, "totalCount:", _totalCount);
				FunctionUtil.call(onProgress, [progressRatio]);
			}
		}
		
		// Event handlers
		
	}
}
