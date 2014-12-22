package  
{
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.display.Graphics;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.text.TextFieldAutoSize;


	/**
	 * ...
	 * @author laroche
	 */
	public class UserInterface extends EventDispatcher
	{
		private var uiButtons : Object = new Object();
		
		public function UserInterface() 
		{
			this.SetupCameraUI();
		}
		
		private function SetupCameraUI():void
		{			
			// create initial buttons
			this.uiButtons.cameraButton = this.createButton("", 125, 240);
			this.uiButtons.microphoneButton = this.createButton("", 250, 240);
			this.uiButtons.cameraAndMicrophoneButton = this.createButton("", 0, 240);
			
			// add button mouse events
			this.uiButtons.cameraButton.addEventListener(MouseEvent.ROLL_OVER, CameraMouseOverEventHandler);
			this.uiButtons.cameraButton.addEventListener(MouseEvent.ROLL_OUT, CameraMouseOutEventHandler);
			this.uiButtons.cameraButton.addEventListener(MouseEvent.CLICK, CameraMouseClickEventHandler);
			
			this.uiButtons.microphoneButton.addEventListener(MouseEvent.ROLL_OVER, MicrophoneMouseOverEventHandler);
			this.uiButtons.microphoneButton.addEventListener(MouseEvent.ROLL_OUT, MicrophoneMouseOutEventHandler);
			this.uiButtons.microphoneButton.addEventListener(MouseEvent.CLICK, MicrophoneMouseClickEventHandler);
			
			this.uiButtons.cameraAndMicrophoneButton.addEventListener(MouseEvent.ROLL_OVER, CameraAndMicrophoneMouseOverEventHandler);
			this.uiButtons.cameraAndMicrophoneButton.addEventListener(MouseEvent.ROLL_OUT, CameraAndMicrophoneMouseOutEventHandler);
			this.uiButtons.cameraAndMicrophoneButton.addEventListener(MouseEvent.CLICK, CameraAndMicrophoneMouseClickEventHandler);
		}
		
		public function createButton(buttonText:String, locationX:int, locationY:int):Sprite
		{
			var textField:TextField = new TextField();
			textField.name = "textField";
			textField.mouseEnabled = false;
			
			var rectangleShape:Shape = new Shape();
			rectangleShape.graphics.beginFill(0xCCCCCC);			 
			rectangleShape.graphics.drawRect(0, 0, 50, 40);
			rectangleShape.graphics.endFill();

			var buttonSprite:Sprite = new Sprite();
			buttonSprite.addChild(rectangleShape);
			buttonSprite.addChild(textField);
			buttonSprite.buttonMode = true;
			buttonSprite.x = locationX;
			buttonSprite.y = locationY;

			//button.buttonMode  = true; // so cursor shows up on mouse roll over
			//button.mouseChildren = false; // so no objects inside our sprite will receive the click
			
			var tf:TextField = TextField(buttonSprite.getChildByName("textField"));
			tf.text = buttonText;
			
			return buttonSprite;
		}
		
		public function createLabel(labelText:String, width:int, length:int, locationX:int, locationY:int):Sprite
		{
			var textField:TextField = new TextField();
			textField.name = "textField";
			textField.mouseEnabled = false;
			
			var rectangleShape:Shape = new Shape();
			rectangleShape.graphics.beginFill(0xCCCCCC);			 
			rectangleShape.graphics.drawRect(0, 0, width, length);			 
			rectangleShape.graphics.endFill();
			
			var labelSprite:Sprite = new Sprite();
			labelSprite.addChild(rectangleShape);
			labelSprite.addChild(textField);
			labelSprite.x = locationX;
			labelSprite.y = locationY;

			var tf:TextField = TextField(labelSprite.getChildByName("textField"));
			tf.text = labelText;
			
			return labelSprite;
		}
		
		public function getCameraUserInterface(cameraEnabled:Boolean, microphoneEnabled:Boolean):Object
		{
			var cameraButtonText:String = (cameraEnabled) ? "Stop" : "Start";
			var microphoneButtonText:String = (microphoneEnabled) ? "Stop" : "Start";
			var cameraAndMicrophoneButtonText:String = (cameraEnabled && microphoneEnabled) ? "Stop" : "Start";
			
			var cameraText:TextField = TextField(this.uiButtons.cameraButton.getChildByName("textField"));
			var microphoneText:TextField = TextField(this.uiButtons.microphoneButton.getChildByName("textField"));
			var cameraAndMicrophoneText:TextField = TextField(this.uiButtons.cameraAndMicrophoneButton.getChildByName("textField"));
			cameraText.text = cameraButtonText + " Camera Only";
			microphoneText.text = microphoneButtonText + " Microphone Only";
			cameraAndMicrophoneText.text = cameraAndMicrophoneButtonText + " Camera And Microphone";
			
			//////////////////
			//this.checkIDS();
			//////////////////
	
			return this.uiButtons;
		}
		
		
		private function CameraMouseOverEventHandler(event:MouseEvent):void { }	
		private function CameraMouseOutEventHandler(event:MouseEvent):void { }
		private function CameraMouseClickEventHandler(event:MouseEvent):void
		{
			dispatchEvent(new Event("CameraUserInterfaceEvent"));
		}
		
		private function MicrophoneMouseOverEventHandler(event:MouseEvent):void { }	
		private function MicrophoneMouseOutEventHandler(event:MouseEvent):void { }
		private function MicrophoneMouseClickEventHandler(event:MouseEvent):void
		{ 	
			dispatchEvent(new Event("MicrophoneUserInterfaceEvent"));
		}
		
		private function CameraAndMicrophoneMouseOverEventHandler(event:MouseEvent):void { }	
		private function CameraAndMicrophoneMouseOutEventHandler(event:MouseEvent):void { }
		private function CameraAndMicrophoneMouseClickEventHandler(event:MouseEvent):void
		{
			dispatchEvent(new Event("CameraAndMicrophoneUserInterfaceEvent"));
		}
		
		
////////////////////////////////////////////////////////////////////////////////////////
		private function checkIDS():void
		{
			//////////////////////////////////////////////////////////////////////////////////
			////// testing tracking userids and peerids //////////////////////////////////////
			//var userIdLabel:Sprite = ui.createLabel("userId is: " + this.userId, 50, 50, 0, 50);
			//this.addChild(userIdLabel);
			//////////////////////////////////////////////////////////////////////////////////
		}
		private function randomRange(max:int, min:int = 0):int
		{
			 return Math.random() * (max - min) + min;
		}
////////////////////////////////////////////////////////////////////////////////////////
	}

}