package napalm.framework.core
{

	/**
	 * IAppContainer.
	 * 
	 * Interface for Preloader and Main.
	 * Needed to access one of loaded application in case of multiple loading.
	 */
	public interface IAppContainer
	{

		// Properties

		//function get ():void;
		//function set (value:):void;

		// Methods

		function dispose():void;

		/**
		 * If not -1 values set, application will fit this sizes instead of 
		 * fitting the stage size (RESIZE event will not be listened).
		 * 
		 * @param appWidth -1 to fit stage.stageWidth
		 * @param appHeight -1 to fit stage.stageHeight
		 */
		function setAppSize(appWidth:int, appHeight:int):void;
		
	}
}
