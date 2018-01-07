package napalm.framework.managers
{
	import flash.utils.Dictionary;
	
	import napalm.framework.log.Channel;
	
	/**
	 * ComponentManager.
	 * 
	 * componentType - "component id", base class. For one componentType there can more 
	 * than one componentClass (when we extending base functionality in new projects)
	 * @author alex.panoptik@gmail.com
	 */
	public class ComponentManager extends BaseManager
	{
		
		// Class constants

		// Class variables
		
		// Class methods
		
		// Variables

		// (Set in your overridden Main.initializeManagers)
		//public var ;
		
		private var componentClassByTypeLookup:Dictionary;
		
		// Properties
		
		// Constructor
		
		public function ComponentManager()
		{
		}
		
		// Methods
		
		override public function initialize(systemManager:SystemManager):void
		{
			super.initialize(systemManager);

			log.log(Channel.COMPONENT, this, "(initialize)");
			componentClassByTypeLookup = new Dictionary();
		}
		
		override public function dispose():void
		{
			log.log(Channel.COMPONENT, this, "(dispose)");
			componentClassByTypeLookup = null;
			
			super.dispose();
		}

		/**
		 * Call in your Main.initializeManagers.
		 * 
		 * @param componentType	 the most base Class of component (componentClass extends componentType)
		 * @param componentClass override componentType with custom componentClass
		 * @return
		 */
		public function registerComponentType(componentType:Class, componentClass:Class):void
		{
			if (componentClassByTypeLookup[componentType])
			{
				log.warn(Channel.COMPONENT, this, "Overwrite componentClass in registerComponentType! componentType:",
						componentType,"prev-componentClass:",componentClassByTypeLookup[componentType],"new-componentClass:",componentClass);
			}

			log.log(Channel.COMPONENT, this, "(registerComponentType) componentType:", componentType,"componentClass:", componentClass);
			componentClassByTypeLookup[componentType] = componentClass;
		}

		/**
		 * Create your components by this method. Provides overriding components:
		 * - uses componentType as component class or 
		 * - custom component class, registered by registerComponentType().
		 * 
		 * Use in Dialog and Screen subclasses in their overridden attachSkin() method. 
		 * In some other components you can call from their overridden initialize() method.
		 * 
		 * Important! Don't forget to call initialize() after creation and to set skinObject.
		 * 
		 * Note: skinObject automatically will be created in initialize() in GUIComponent subclasses 
		 * if all needed arguments (skinContainer, assetManager) are given properly.
		 * 
		 * Note: skinObject for any component may be set using parent's skinObject and getSkinChildByPath().
		 * For example:
		 *  private var myComponent:MyComponent;
		 * 	override function attachSkin():void
		 * 	{
		 * 		super.attachSkin();
		 * 		myComponent = componentManager.createComponent(MyComponent);
		 * 		myComponent.initialize(systemManager);
		 * 		myComponent.skinObject = getSkinChildByPath("someSprite.button");
		 * 	}	
		 * 
		 * @param componentType	Used as componentClass or a key to get appropriated 
		 * 						componentClass that overrides the basic one (componentType).
		 * 						Usually componentClass extends componentType.
		 * @return				Component instance to be initialized and only then used.
		 */
		public function createComponent(componentType:Class):Object
		{
			var componentClass:Class = componentClassByTypeLookup[componentType] || componentType;
			if (!componentClass)
			{
				return null;
			}

			var component:Object = new componentClass();
			component.componentType = componentType;
			log.info(Channel.COMPONENT, this, "(createComponent) componentType:", componentType, "component:", component);
			
			return component;
		}

//?--
//		public function createComponentFull(componentType:Class, args:Array = null):Component
//		{
//			var component:Component = createComponent(componentType);
//			if (component)
//			{
//				if (!args)
//				{
//					args = [systemManager];
//				}
//				component.initialize.apply(component, args);
//				component.skinObject = createSkinObject(component);
//			}
//			return component;
//		}
//
//		public function createSkinObject(component:Component):DisplayObject
//		{
//			return null;
//		}
		
		// Event handlers
		
	}
}
