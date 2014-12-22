package  
{
	import adobe.utils.ProductManager;
	import flash.display.DisplayObject;
	import flash.display.Sprite;

	/**
	 * @author Daryl LaRoche
	 * @daryllaroche@gmail.com
	 * 
	 * Protocol Base class. AS3 doesn't
	 * have abstract classes - implement
	 * exception hack in the future.
	 */
	public class Protocol extends Sprite implements IProtocol
	{
		// USER
		private var userId : String = "";
		
		public function Protocol(userId:String):void
		{
			this.userId = userId;
		}
		
		public function SetupProtocolDependencies(userInterface:UserInterface, mediaSettings:MediaSettings):void { }
		public function CreateUserInterface():void { }
		protected function Publish():void { }		
	}

}