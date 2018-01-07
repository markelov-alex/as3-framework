package napalm.framework.net
{
	/**
	 * URLRequesterQueue.
	 * 
	 * When load() called while previous request is still processing, 
	 * new request enqueued. (URLRequester ignores such a request.)
	 * 
	 * (not tested)
	 * @author alex.panoptik@gmail.com
	 */
	public class URLRequesterQueue extends URLRequester
	{

		// Class constants
		// Class variables
		// Class methods

		// Variables

		private var requestObjectQueue:Array = [];
		
		// Properties

		// Constructor

		public function URLRequesterQueue()
		{
		}

		// Methods

		/**
		 * Called on request complete (success or error).
		 * So here we can start next request.
		 */
		override public function clear():void
		{
			super.clear();

			checkNext();
		}

		override public function load(url:String, onComplete:Function, params:Object = null, isPost:Boolean = false, 
		                              isBinary:Boolean = false, headers:Array = null):void
		{
			if (isLoading)
			{
				requestObjectQueue[requestObjectQueue.length] = {url: url, onComplete: onComplete, params: params, 
					isPost: isPost, isBinary: isBinary, headers: headers};
				return;
			}
			
			super.load(url, onComplete, params, isPost, isBinary, headers);
		}

		private function checkNext():void
		{
			if (requestObjectQueue.length)
			{
				var requestObject:Object = requestObjectQueue.shift();
				load(requestObject.url, requestObject.onComplete, requestObject.params, 
						requestObject.isPost, requestObject.isBinary, requestObject.headers);
			}
		}

		// Event handlers

	}
}
