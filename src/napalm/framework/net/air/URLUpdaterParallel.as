package napalm.framework.net.air
{
	import flash.utils.Dictionary;
	
	import napalm.framework.log.Channel;
	import napalm.framework.log.Log;
	import napalm.framework.utils.FunctionUtil;
	
	/**
	 * URLUpdaterParallel.
	 * 
	 * You can use it instead of URLUpdaterQueue to update URLs faster.
	 * 
	 * Up to maxQueueCount queues will be loading at a time.
	 * 
	 * Call loadAndUpdateArray() to update an array of URLs. The next call 
	 * available when all previous requests are processed. (While 
	 * previous requests are loading the new ones will be ignored.)
	 * @author alex.panoptik@gmail.com
	 */
	public class URLUpdaterParallel
	{

		// Class constants

		public static const MIN_ITEM_COUNT_PER_QUEUE:int = 6;
		
		// Class variables
		// Class methods

		// Variables

		public var name:String;
		
		public var isParseJSON:Boolean = false;
		public var isAsyncWrite:Boolean = true;
		private var maxQueueCount:int;
		
		protected var log:Log;
		private var urlArray:Array;
		private var onComplete:Function;
		private var onProgress:Function;

		private var urlUpdaterQueueArray:Array = [];
		private var resultDataArrayByUpdater:Dictionary = new Dictionary();
		private var isUpdating:Boolean = false;
		private var queueCount:int = 0;
		private var updaterCompleteCount:int = 0;
		
		// Properties

		// Constructor

		public function URLUpdaterParallel(maxQueueCount:int = 5)
		{
			this.maxQueueCount = maxQueueCount;
			log = Log.instance;
		}

		// Methods

		public function dispose():void
		{
			log.info(Channel.NET_LOADER, this, "(dispose) name:", name);
			clear();

			for (var i:int = 0; i < urlUpdaterQueueArray.length; i++)
			{
				var urlUpdaterQueue:URLUpdaterQueue = urlUpdaterQueueArray[i] as URLUpdaterQueue;
				urlUpdaterQueue.dispose();
			}
			urlUpdaterQueueArray.length = 0;
			
			log = null;
		}

		private function clear():void
		{
			urlArray = null;
			onComplete = null;
			onProgress = null;

			isUpdating = false;
			resultDataArrayByUpdater = new Dictionary();
			queueCount = 0;
			updaterCompleteCount = 0;
		}

		public function loadAndUpdateArray(urlArray:Array, filePathArray:Array = null, 
										   onComplete:Function = null, onProgress:Function = null):void
		{
			log.info(Channel.NET_LOADER, this, "(loadAndUpdateArray) name:", name);// urlArray:", StringUtil.cutStringInMiddle(String(urlArray), 100),
			//		"filePathArray:", StringUtil.cutStringInMiddle(String(filePathArray), 100), "onComplete:", 
			//		onComplete, "onProgress:", onProgress);

			if (isUpdating)
			{
				return;
			}

			this.urlArray = urlArray;
			this.onComplete = onComplete;
			this.onProgress = onProgress;

			if (!urlArray || !urlArray.length)
			{
				doComplete();
				return;
			}

			isUpdating = true;

			var urlCount:int = urlArray.length;
			var itemsPerQueue:int = urlCount > maxQueueCount * MIN_ITEM_COUNT_PER_QUEUE ? 
					Math.ceil(urlCount / maxQueueCount) : MIN_ITEM_COUNT_PER_QUEUE;
			queueCount = Math.ceil(urlCount / itemsPerQueue);
			trace(this, "urlCount:", urlCount, "itemsPerQueue:", itemsPerQueue, "maxQueueCount:", maxQueueCount)
			
			// Create new updaters
			for (var i:int = 0; i < queueCount; i++)
			{
				var startIndex:int = i * itemsPerQueue;
				var endIndex:int = Math.min(startIndex + itemsPerQueue, urlCount);
				trace(this, i, "startIndex:", startIndex, "endIndex:", endIndex)
				
				// Get or create updater
				var urlUpdaterQueue:URLUpdaterQueue = urlUpdaterQueueArray[i] as URLUpdaterQueue || new URLUpdaterQueue();
				urlUpdaterQueue.name = (name || "updaterParallel") + "-updaterQueue";
				urlUpdaterQueueArray[i] = urlUpdaterQueue;
				// Set up updater
				urlUpdaterQueue.isParseJSON = isParseJSON;
				urlUpdaterQueue.isAsyncWrite = isAsyncWrite;
				
				// Update subqueue
				urlUpdaterQueue.loadAndUpdateArray(urlArray.slice(startIndex, endIndex), 
						filePathArray.slice(startIndex, endIndex), onQueueComplete, updateProgress);
			}
			
			updateProgress();
		}

		/**
		 * Called by every URLUpdaterQueue when some URL was updated.
		 */
		private function updateProgress():void
		{
			if (onProgress != null)
			{
				var updatedCount:int = 0;
				for (var i:int = 0; i < urlUpdaterQueueArray.length; i++)
				{
					var urlUpdaterQueue:URLUpdaterQueue = urlUpdaterQueueArray[i] as URLUpdaterQueue;
					updatedCount += urlUpdaterQueue.updatedCount;
				}
				
				var progressRatio:Number = urlArray ? updatedCount / urlArray.length : 1;
				log.info(Channel.NET_LOADER, this, "(updateProgress)", "progressRatio:", progressRatio,
						"updatedCount:", updatedCount, "urlArray-length:", urlArray ? urlArray.length : null);
				
				onProgress(progressRatio);
			}
		}

		private function onQueueComplete(resultDataArray:Array, urlUpdaterQueue:URLUpdaterQueue):void
		{
			updaterCompleteCount++;
			resultDataArrayByUpdater[urlUpdaterQueue] = resultDataArray;
			
			log.info(Channel.NET_LOADER, this, "(onQueueComplete) name:", name, "updaterCompleteCount:", updaterCompleteCount, 
					"queueCount:", queueCount);
			
			if (updaterCompleteCount == queueCount)
			{
				doComplete();
			}
		}

		private function doComplete():void
		{
			// Concat all result to one array
			var resultDataArray:Array = [];
			for (var i:int = 0; i < urlUpdaterQueueArray.length; i++)
			{
				var urlUpdaterQueue:URLUpdaterQueue = urlUpdaterQueueArray[i] as URLUpdaterQueue;
				var subResultDataArray:Array = resultDataArrayByUpdater[urlUpdaterQueue] as Array;
				if (subResultDataArray)
				{
					resultDataArray = resultDataArray.concat(subResultDataArray);
				}
			}

			log.info(Channel.NET_LOADER, this, "(doComplete) name:", name, "urlArray-length:", urlArray.length, 
					"=> resultDataArray-length:", resultDataArray.length);
			if (urlArray.length != resultDataArray.length)
			{
				log.warn(Channel.NET_LOADER, this, " (doComplete) urlArray-length != resultDataArray-length!");
			}

			// onComplete
			FunctionUtil.call(onComplete, [resultDataArray]);
			
			clear();
		}

		// Event handlers

	}
}
