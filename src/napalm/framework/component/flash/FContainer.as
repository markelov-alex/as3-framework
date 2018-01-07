package napalm.framework.component.flash
{
	import napalm.framework.log.Channel;
	
	/**
	 * FContainer.
	 *
	 *
	 */
	public class FContainer extends FComponent
	{


		// Class variables
		// Class methods

		// Variables

		protected var children:Array = [];

		// Properties

		// Constructor

		public function FContainer()
		{
		}

		// Methods

//		override public function initialize(args:Array = null):void
//		{
//			super.initialize(args);
//		}

		override public function dispose():void
		{
			// Children
			for each (var component:FComponent in children)
			{
				component.dispose();
			}
			children = [];

			super.dispose();
		}

		protected function addChild(child:FComponent):void
		{
			if (!child)
			{
				return;
			}

			var index:int = children.indexOf(child);
			if (index == -1)
			{
				children[children.length] = child;
				log.info(Channel.COMPONENT, this, "(addChild) children:", children);
			}
		}

		protected function removeChild(child:FComponent):void
		{
			if (!child)
			{
				return;
			}

			var index:int = children.indexOf(child);
			if (index != -1)
			{
				children.splice(index, 1);
				log.info(Channel.COMPONENT, this, "(removeChild) children:", children);
			}
		}

		// Event handlers

	}
}
