package {
	import fl.controls.listClasses.CellRenderer;
	import fl.controls.listClasses.ICellRenderer;
	
	public class CustomRowColors extends CellRenderer implements ICellRenderer {
		public function CustomRowColors():void {
			super();
		}
		public static function getStyleDefinition():Object {
			return CellRenderer.getStyleDefinition();
		}
		override protected function drawBackground():void {
			switch (data.rowColor) {
				case "w":
					setStyle("upSkin", CellRenderer_upSkin);
					break;
				case "r":
					setStyle("upSkin", CellRenderer_upSkinRed);
					break;
				default:
					break;
			}
			super.drawBackground();
		}
	}
}