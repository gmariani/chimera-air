package com.coursevector.flex {
	
	import mx.containers.*;
	import mx.controls.Text;
	import mx.controls.ToolTip;
	import mx.core.*;
	
	public class HTMLToolTip extends ToolTip {
		public function HTMLToolTip() {
			super();
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			textField.htmlText = text;
		}
	}
}