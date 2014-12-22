package  
{
	import flash.display.DisplayObject;
	
	/**
	 * ...
	 * @author laroche
	 */
	public interface IProtocol 
	{
		function SetupProtocolDependencies(userInterface:UserInterface, mediaSettings:MediaSettings):void;
		function CreateUserInterface():void;
	}
	
}