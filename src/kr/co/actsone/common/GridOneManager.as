/*********************************************************************************
 *
 *  ACTSONE COMPANY
 *  Copyright 2013 Actsone 
 *  All Rights Reserved.
 *
 *	This program is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *************************************************************************************/
package kr.co.actsone.common
{		
	import com.adobe.serialization.json.JSONEncoder;
	import com.brokenfunction.json.encodeJson;
	
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Shape;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	import flash.xml.XMLNode;
	
	import kr.co.actsone.controls.ExAdvancedDataGrid;
	import kr.co.actsone.controls.advancedDataGridClasses.ExAdvancedDataGridColumn;
	import kr.co.actsone.events.ExAdvancedDataGridEventReason;
	import kr.co.actsone.events.SAEvent;
	import kr.co.actsone.export.ColumnInfor;
	import kr.co.actsone.export.ExcelExportInfo;
	import kr.co.actsone.export.ExportUtils;
	import kr.co.actsone.export.StyleFooter;
	import kr.co.actsone.export.StyleHeader;
	import kr.co.actsone.filters.FilterDataWithSearch;
	import kr.co.actsone.footer.FooterBar;
	import kr.co.actsone.protocol.GridProtocol;
	import kr.co.actsone.protocol.ProtocolDelimiter;
	import kr.co.actsone.summarybar.SummaryBarConstant;
	import kr.co.actsone.summarybar.SummaryBarManager;
	import kr.co.actsone.utils.ErrorMessages;
	import kr.co.actsone.utils.MenuConstants;
	import kr.co.actsone.utils.MouseWheelTrap;
	
	import mx.collections.ArrayCollection;
	import mx.collections.HierarchicalCollectionView;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.controls.DateField;
	import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
	import mx.core.FlexGlobals;
	import mx.core.ScrollPolicy;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	import mx.utils.UIDUtil;
	
	use namespace mx_internal; 
	/**
	 *
	 * @author Toan Nguyen
	 */
	public class GridOneManager
	{
		private var gridone:GridOne;
	 
		private var gid:String="";
		private var _isMouseInSWF:Boolean = false;
		private var err:ErrorMessages=new ErrorMessages();
		private var httpService:HTTPService;
		public var gridProtocol:GridProtocol; 
		protected var labelFuncLib:LabelFunctionLib;
		private var bValidate:Boolean; //used in loadGridStringData() function
		private var dataFieldCombo:String; //used in queryComboTextData() function
 
		////////move from ExAdvancedDataGrid//////////
		public var excelExportInfo:ExcelExportInfo;
		public var exportUltis:ExportUtils ;
		public var styleHeader:StyleHeader;
		public var styleFooter:StyleFooter;
		public var subHeaderStyle:Array; 
        /////////////////////////////////////////////
		/**
		 * Parameters for function DoQuery
		 * This variable is object contains array of (key,value)
		 */
		public var params:Object=null;
		public function GridOneManager(app:Object)
		{
			gridone=app as GridOne;
			gridProtocol=new GridProtocol(app);
			labelFuncLib = new LabelFunctionLib(gridone);
			gridone.datagrid.summaryBar=new SummaryBarManager(gridone);
		}
		
		public function get gridoneImpl():GridOneImpl
		{
			return gridone.gridoneImpl;
		}
		
		public function get dgManager():DataGridManager
		{
			return gridone.dgManager;
		}
 
		
		/*************************************************************
		 * javascript function
		 * ***********************************************************/
		public function initJavaFunction():void
		{
			
			
			//			ExternalInterface.call("eval", "if (navigator.appName=='Microsoft Internet Explorer'||navigator.userAgent.toLowerCase().indexOf('chrome') > -1){document.onmousedown=onIEMouse;}else{ window.document.addEventListener('mousedown', onGeckoMouse, true);}" +
			//				"function onIEMouse() {if (event.button > 1) {  document['" + this.gridone.id + "'].rightClickSelectedCell();}}" +
			//				"function onGeckoMouse(ev){ if (ev.button != 0) {var tags = document.getElementsByTagName('embed'); if(tags != null && tags.length > 0){if(ev.target.id == tags[0].id) {document.getElementById(tags[0].id).rightClickSelectedCell();}}}}");
			ExternalInterface.call("eval",
				"function catchError(errorMsg){setTimeout(function(){throw new Error(errorMsg)},500);}"	
				+"function throwErrorMsg(errorMsg){throw new Error(errorMsg);}");
			
			
			//			ExternalInterface.call("eval",
			//				"function checkJS(){try	{var gridone = document.getElementById('" + this.gridone.id + "');gridone.checkFlex();return true;}catch (e){ return false;}}");
			ExternalInterface.call("eval",
				"function setFocusCell(){ var browserName=navigator.appName; if (browserName=='Microsoft Internet Explorer' || navigator.userAgent.toLowerCase().indexOf('chrome') > -1) { document." + this.gridone.id + ".focus();	} else { var tags = document.getElementsByTagName('embed');	 if(tags != null && tags.length > 0) { document.getElementById(tags[0].id).tabIndex = 0; document.getElementById(tags[0].id).focus(); }}}");
			
		
			ExternalInterface.call("eval",   "var browserScrolling"+ this.gridone.id+ ";" +				
				"function allowBrowserScroll"+ this.gridone.id+ "(value){" +
					"if (navigator.userAgent.toLowerCase().indexOf('chrome') != -1 ){" +
						"window.onmousewheel = document.onmousewheel =  wheel"+ this.gridone.id+ ";"+
						"window.DOMMouseScroll = document.DOMMouseScroll =  wheel"+ this.gridone.id+ ";" +
						 
					"}"+ 
				    
					 "browserScrolling"+ this.gridone.id+ "=value;" +
				"}" +				
				"function handle"+ this.gridone.id+ "(delta){if(!browserScrolling"+ this.gridone.id+ "){return false;}return true;}" +
				
				"function  wheel"+ this.gridone.id+ "(event){" +
				"var delta = 0; " +
				"if(!event){event = window.event; }" +
				"var app"+ this.gridone.id+ ";var edelta; var appForChr; var browserName=navigator.appName;" +
				 
				"if (browserName=='Microsoft Internet Explorer') {" +
				
				"app"+ this.gridone.id+ "= document."+ this.gridone.id+ ";" +
			
				"}else if (navigator.userAgent.toLowerCase().indexOf('chrome') != -1 ){" +
 
			 	"app"+ this.gridone.id+ " = document.getElementById('"+ this.gridone.id+ "');" +
			
				"}else{	app"+ this.gridone.id+ "= document."+ this.gridone.id+ ";}" +
				
				"edelta = (navigator.userAgent.indexOf('Firefox') !=-1) ? -event.detail : event.wheelDelta/40;" +
				"var o = {x: event.screenX, y: event.screenY,delta: edelta,ctrlKey: event.ctrlKey, altKey: event.altKey, shiftKey: event.shiftKey};" +
				
				" app"+ this.gridone.id+ ".handleWheel(o); " +	
				// "alert("+ this.gridone.id+ ");"+
				"if(event.wheelDelta){delta = event.wheelDelta/120;if(window.opera){delta =- delta;}" + "}" +
				" else if(event.detail){delta =- event.detail/3;}" +
				"if(delta){handle"+ this.gridone.id+ "(delta);}" +
				
				//for chrome browser
				"if(!browserScrolling"+ this.gridone.id+ "){if(event.preventDefault){event.preventDefault();}event.returnValue=false;}}" +
				
				"if(window.addEventListener){" +
				"window.addEventListener('DOMMouseScroll', wheel"+ this.gridone.id+ ",false);" +
				"}" +
				
				//move scroll bar of page event
				
				"window.attachEvent('onmousewheel', wheel"+ this.gridone.id+ ");"+
				"document.attachEvent('onmousewheel', wheel"+ this.gridone.id+ ");"+
				"window.attachEvent('DOMMouseScroll', wheel"+ this.gridone.id+ ");"+
				"document.attachEvent('DOMMouseScroll', wheel"+ this.gridone.id+ ");"+
				"allowBrowserScroll"+ this.gridone.id+ "(true);" +
				"");
 
			ExternalInterface.call("eval",
				"if (navigator.appName=='Microsoft Internet Explorer'||navigator.userAgent.toLowerCase().indexOf('chrome') != -1){window.DOMMouseScroll = document.DOMMouseScroll =  handleWheel;}else{window.addEventListener('DOMMouseScroll',  handleWheel, false);}"+
				"function  handleWheel(e) {" +
				"var edelta;" +
				"var app = document."+ this.gridone.id + ";" +
				//"alert("+ this.gridone.id+ ");"+
				"var event= window.event || e;" +
				"if (navigator.userAgent.indexOf('Firefox') !=-1) {" +
				" edelta = (navigator.userAgent.indexOf('Firefox') !=-1) ? -e.detail : e.wheelDelta/40;" +
				"}" + 
				"else" +
				"edelta = (navigator.userAgent.toLowerCase().indexOf('chrome') !=-1) ? -event.detail : event.wheelDelta/40;"+
				
				"var o = {x: e.screenX, y: e.screenY, delta: edelta, ctrlKey: e.ctrlKey, altKey: e.altKey,shiftKey: e.shiftKey};" +
				"if (app != null && app != undefined){try{app.handleWheel(o);} catch(e){}}}" +
				"");
			
			
			ExternalInterface.call("eval",
				"if(window.addEventListener){window.addEventListener('onclick',mouseClickBrowserHandler,false);}"+
				//	"document.attachEvent('onclick', mouseClickBrowserHandler);"+
				"window.onclick = document.onclick = mouseClickBrowserHandler;"+			
				"function mouseClickBrowserHandler(e){"+ 
				"var event = window.event || e;" +
				"if(event.clientX > 0 && event.clientY > 0){"+
				"var app = document."+ this.gridone.id + ";"+
				"if(app != null && app != undefined){try{app.handlePressOutOfGridOne();}catch(e){}}}}");
			//apply in case grid's height is changed
			ExternalInterface.call("eval",
				"var _gridOneInside = document."+ this.gridone.id + ";"+
				"var _resizeHeightApp=_gridOneInside.height;"+
				"_gridOneInside.createEvent('onResizeGridHeight','onResizeGridHeightHandler');" +
				"function onResizeGridHeightHandler(e){ _resizeHeightApp = e.nGridHeight;_gridOneInside.style.height =_resizeHeightApp+'px';}");	
			
		}
		
		public function get datagrid():ExAdvancedDataGrid
		{
			return gridone.datagrid;
		}
		
		/*************************************************************
		 * decode text data
		 * author: Toan Nguyen
		 * ***********************************************************/
		 
		public function decodeTextData(dataString:String,isFormatDate:Boolean=false,isFormatDateTime:Boolean=false):Array
		{
			if (dataString == null || dataString == "")
				return [];
			
			//dataString=dataString.replace(/\\r\\n/g, "");
			
			var originArr:Array=dataString.split(DataGridManager.rowSeparator); //default %%
			var dataArr:Array=[];
			var s:String=""; 
			var col:ExAdvancedDataGridColumn;
			if (originArr.length > 1)
			{
				var colArr:Array=String(originArr[0]).split(DataGridManager.columnSeparator); //default |
				if(colArr[colArr.length-1]=="")
					colArr.pop();
				for (var i:int=1; i < originArr.length; i++)
				{
					var dataRow:Array=String(originArr[i]).split(DataGridManager.columnSeparator); //default |
					var x:String=dataRow.toString();
					if(x.length<dataRow.length)
						break;
					//var minColNum:int=Math.min(colArr.length, dataRow.length);
					var obj:Object=new Object();
					
					for (var j:int=0; j < colArr.length; j++)
					{
						//obj[StringUtil.trim(colArr[j])]=StringUtil.trim(dataRow[j]);
						obj[colArr[j]]=dataRow[j];
						if(isFormatDate||isFormatDateTime)
						{
							col=datagrid.columns[datagrid.dataFieldIndex[colArr[j]]];
							if(isFormatDate && col.type==ColumnType.DATE)
							{
								s=StringUtil.trim(dataRow[j]);
								//col=datagrid.columns[j];
								
								s=DateField.dateToString(DateField.stringToDate(s,col.dateOutputFormatString),(col as ExAdvancedDataGridColumn).dateInputFormatString);
								obj[StringUtil.trim(colArr[j])]=s;
							}else if(isFormatDateTime && col.type==ColumnType.DATETIME)
							{
								s=StringUtil.trim(dataRow[j]);
								s=s.substr(0,4)+s.substr(5,2)+s.substr(8,2)+s.substr(11,2)+s.substr(14,2);
								//s=s.replace(" ","");
								obj[StringUtil.trim(colArr[j])]=s;
							}
						}
					}
					
 					dataArr.push(obj);	 
				}
			}
			return dataArr;
		}
		
		/************************************************
		 * Collect all events in GridOne		 
		 ***********************************************/
		public function registerGridOneEvents():void
		{
			this.gridone.systemManager.addEventListener(MouseEvent.RIGHT_CLICK,gridone_rightClickHandler);
			this.gridone.stage.addEventListener(MouseEvent.MOUSE_MOVE,gridone_mouseMoveHandler);
			this.gridone.stage.addEventListener(Event.MOUSE_LEAVE,gridone_mouseLeaveHandler);
			//when import data into grid, update external scroll bar
			this.gridone.systemManager.addEventListener(SAEvent.UPDATE_EXTERNAL_SCROLL, updateExternalScrollHandler,true);
		}
		
		/*************************************************************
		 * handle event update external scroll bar when import data by CSV
		 * ***********************************************************/
		protected function updateExternalScrollHandler(event:Event):void
		{
			//update datagrid width in case external scroll
			updateExternalVerticalScroll(datagrid.dataProvider.length);
			//update Application height when data is changed
			updateGridHeight();
		}
		
		/*************************************************************
		 * update external scroll bar when data is changed
		 * ***********************************************************/
		public function updateExternalVerticalScroll(dataLength:int):void
		{
			if(this.datagrid.bExternalScroll)
			{
				this.gridone.vScroll.pageSize = this.datagrid.getPageSize();
				if(dataLength > this.datagrid.rowCount)
				{
					gridone.vScroll.scrollPosition = datagrid.maxVerticalScrollPosition;
				}
				else
				{
					gridone.vScroll.scrollPosition = datagrid.maxVerticalScrollPosition=0;
				}
				updateExternalHorizontalScroll();
			}
		}
		
		/*************************************************************
		 * Handler of right click event 
		 * 
		 * @param event MouseEvent
		 * ***********************************************************/
		private function gridone_rightClickHandler(event:MouseEvent):void
		{						
			//do nothing to prevent default context menu of Adobe to be displayed.	
		}
		
		/*************************************************************
		 * Handler of mouse move event 
		 * 
		 * @param event MouseEvent
		 * ***********************************************************/
		private function gridone_mouseMoveHandler(event:MouseEvent):void
		{
			if (!_isMouseInSWF) 
			{
				if(this.dgManager.popContextMenu)
				{
					PopUpManager.removePopUp(this.dgManager.popContextMenu);
				}
				_isMouseInSWF = true;
			}
		}
		
		/*************************************************************
		 * Handler of mouse leave event 
		 * 
		 * @param event Event
		 * ***********************************************************/
		private function gridone_mouseLeaveHandler(event:Event):void
		{
			_isMouseInSWF = false;
			if(this.dgManager.popContextMenu)
			{
				PopUpManager.removePopUp(this.dgManager.popContextMenu);
			}
		}
		
		/*************************************************************
		 * Create default context menu
		 * @author Duong Pham
		 * ***********************************************************/
		public function createDefaultContextMenu():void
		{
			/* addDefaultContextMenu(MenuConstants.MENUITEM_CELL_INSERT_ROW);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_DELETE_ROW);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_REMOVE_ALL); 
			gridone.addContextMenuSeparator(MenuConstants.MENU_CELL);*/
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_COPY);
			addDefaultContextMenu(MenuConstants.MENUITEM_ROW_COPY);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_PASTE);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_FONTUP);
			gridone.addContextMenuSeparator(MenuConstants.MENU_CELL);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_FONTDOWN);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_FIND);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_FIND_COLUMN);
			gridone.addContextMenuSeparator(MenuConstants.MENU_CELL);
			addDefaultContextMenu(MenuConstants.MENUITEM_CELL_EXCELEXPORT);
			gridone.addContextMenuSeparator(MenuConstants.MENU_CELL);
			//header context menu//
			addDefaultContextMenu(MenuConstants.MENUITEM_HD_HIDEHEADER);
			addDefaultContextMenu(MenuConstants.MENUITEM_HD_CANCELHIDEHEADER);
			
			addDefaultContextMenu(MenuConstants.MENUITEM_HD_FIXHEADER);
			gridone.addContextMenuSeparator(MenuConstants.MENU_HEADER);
			addDefaultContextMenu(MenuConstants.MENUITEM_HD_CANCELFIXHEADER);
			gridone.addContextMenuSeparator(MenuConstants.MENU_HEADER);
			//row copy
			//addDefaultContextMenu(MenuConstants.MENUITEM_ROW_COPY);
			//gridone.addContextMenuSeparator(MenuConstants.MENU_ROW_SELECTOR);
		}
		
		/*************************************************************
		 * add default context menu 
		 * ***********************************************************/
		public function addDefaultContextMenu(menuItemKey:String):void
		{
			try
			{
				var itemMenuType:String=MenuConstants.getMenuType(menuItemKey);
				if(itemMenuType == "")
				{
					err.throwError(ErrorMessages.ERROR_MENU_COLKEY_INVALID, Global.DEFAULT_LANG);
					return;
				}				
				var item:Object = new Object();
				var _isExisted:Boolean = false;
				if (itemMenuType == MenuConstants.MENU_CELL)
				{	
					_isExisted = validateItem(menuItemKey,this.datagrid.cellContextMenu);				
					if(_isExisted)
						return;			
					switch (menuItemKey)
					{
						case MenuConstants.MENUITEM_CELL_INSERT_ROW:
							item["label"] = MenuConstants.MENU_NAME_INSERT_ROW;
							item["value"] = MenuConstants.MENUITEM_CELL_INSERT_ROW;
							break;
						case MenuConstants.MENUITEM_CELL_DELETE_ROW:
							item["label"] = MenuConstants.MENU_NAME_DELETE_ROW;
							item["value"] = MenuConstants.MENUITEM_CELL_DELETE_ROW;
							break;
						case MenuConstants.MENUITEM_CELL_REMOVE_ALL:
							item["label"] = MenuConstants.MENU_NAME_REMOVE_ALL;
							item["value"] = MenuConstants.MENUITEM_CELL_REMOVE_ALL;
							break;
						case MenuConstants.MENUITEM_CELL_COPY:
							item["label"] = MenuConstants.MENU_NAME_CELL_COPY;
							item["value"] = MenuConstants.MENUITEM_CELL_COPY;
							break;
						case MenuConstants.MENUITEM_CELL_EXCELEXPORT:
							item["label"] = MenuConstants.MENU_NAME_CELL_EXCELEXPORT;
							item["value"] = MenuConstants.MENUITEM_CELL_EXCELEXPORT;
							break;
						case MenuConstants.MENUITEM_CELL_FIND:
							item["label"] = MenuConstants.MENU_NAME_CELL_FIND;
							item["value"] = MenuConstants.MENUITEM_CELL_FIND;
							break;
						case MenuConstants.MENUITEM_CELL_FIND_COLUMN:
							item["label"] = MenuConstants.MENU_NAME_CELL_FIND_COLUMN;
							item["value"] = MenuConstants.MENUITEM_CELL_FIND_COLUMN;
							break;
						case MenuConstants.MENUITEM_CELL_FONTDOWN:
							item["label"] = MenuConstants.MENU_NAME_CELL_FONTDOWN;
							item["value"] = MenuConstants.MENUITEM_CELL_FONTDOWN;
							break;
						case MenuConstants.MENUITEM_CELL_FONTUP:
							item["label"] = MenuConstants.MENU_NAME_CELL_FONTUP;
							item["value"] = MenuConstants.MENUITEM_CELL_FONTUP;
							break;
						case MenuConstants.MENUITEM_CELL_PASTE:
							item["label"] = MenuConstants.MENU_NAME_CELL_PASTE;
							item["value"] = MenuConstants.MENUITEM_CELL_PASTE;							
							break;
					}
					item["seperator"] = false;	
					item["isUserMenu"] = false;
					item["isEnabled"] = true;
					(this.datagrid.cellContextMenu as ArrayCollection).addItem(item);
				}
				else if (itemMenuType == MenuConstants.MENU_HEADER)
				{
					_isExisted = validateItem(menuItemKey,this.datagrid.headerContextMenu);				
					if(_isExisted)
						return;
					switch (menuItemKey)
					{
						case MenuConstants.MENUITEM_HD_CANCELFIXHEADER:
							item["label"] = MenuConstants.MENU_NAME_HD_CANCELFIXHEADER;
							item["value"] = MenuConstants.MENUITEM_HD_CANCELFIXHEADER;							
							break;
						case MenuConstants.MENUITEM_HD_CANCELHIDEHEADER:
							item["label"] = MenuConstants.MENU_NAME_HD_CANCELHIDEHEADER;
							item["value"] = MenuConstants.MENUITEM_HD_CANCELHIDEHEADER;
							break;
						case MenuConstants.MENUITEM_HD_FIXHEADER:
							item["label"] = MenuConstants.MENU_NAME_HD_FIXHEADER;
							item["value"] = MenuConstants.MENUITEM_HD_FIXHEADER;
							break;
						case MenuConstants.MENUITEM_HD_HIDEHEADER:
							item["label"] = MenuConstants.MENU_NAME_HD_HIDEHEADER;
							item["value"] = MenuConstants.MENUITEM_HD_HIDEHEADER;
							break;
					}
					item["seperator"] = false;	
					item["isUserMenu"] = false;
					item["isEnabled"] = true;
					(this.datagrid.headerContextMenu as ArrayCollection).addItem(item);	
				}
				else if (itemMenuType == MenuConstants.MENU_ROW_SELECTOR)
				{
					_isExisted = validateItem(menuItemKey,this.datagrid.cellContextMenu);				
					if(_isExisted)
						return;
					if (menuItemKey == MenuConstants.MENUITEM_ROW_COPY)
					{
						item["label"] = MenuConstants.MENU_NAME_ROW_COPY;
						item["value"] = MenuConstants.MENUITEM_ROW_COPY;
						item["seperator"] = false;
						item["isUserMenu"] = false;
						item["isEnabled"] = true;
					}
					(this.datagrid.cellContextMenu as ArrayCollection).addItem(item);
				}	
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message, "addDefaultContextMenu");	
			}
		}
		
		/*************************************************************
		 * add user context menu 
		 * ***********************************************************/
		private function validateItem(value:String, inputData:ArrayCollection):Boolean
		{
			var _isExisted:Boolean = false;
			var tmpObj:Object;
			if(inputData.length > 0)
			{
				for(var i:int=0 ; i<inputData.length; i++)
				{
					tmpObj = inputData.getItemAt(i);
					if(tmpObj.value == value)
					{
						_isExisted = true;
						break;
					}
				}				
			}
			return _isExisted;
		}
		
		/*************************************************************
		 * add user context menu 
		 * ***********************************************************/
		public function addUserContextMenu(strMenuKey:String, strMenuItemKey:String, strText:String):void
		{
			var _isExisted:Boolean = false;
			//			strText+=MenuConstants.MENU_SPECIAL_CHARACTER;
			var item:Object = new Object();
			item["label"] =  strText;
			item["value"] = strMenuItemKey;
			item["seperator"] = false;
			item["isUserMenu"] = true;
			item["isEnabled"] = true;
			
			if (strMenuKey == MenuConstants.MENU_CELL)
			{
				_isExisted = validateItem(strMenuItemKey,this.datagrid.cellContextMenu);				
				if(_isExisted)
					return;
				this.datagrid.cellContextMenu.addItem(item);
			}
			else if (strMenuKey == MenuConstants.MENU_HEADER)
			{
				_isExisted = validateItem(strMenuItemKey,this.datagrid.headerContextMenu);				
				if(_isExisted)
					return;
				this.datagrid.headerContextMenu.addItem(item);
			}
			else if (strMenuKey == MenuConstants.MENU_ROW_SELECTOR)
			{
				_isExisted = validateItem(strMenuItemKey,this.datagrid.cellContextMenu);				
				if(_isExisted)
					return;
				this.datagrid.cellContextMenu.addItem(item);
			}
		}
		
		/*************************************************************
		 * add user context menu 
		 * ***********************************************************/
		public function removeAllContextMenuItem(strMenuKey:String):void
		{
			try
			{
				if (strMenuKey == MenuConstants.MENU_CELL)
				{
					this.datagrid.cellContextMenu = removeAllContextMenuItemHelper(this.datagrid.cellContextMenu, MenuConstants.MENU_ROW_SELECTOR);				
				}
				else if (strMenuKey == MenuConstants.MENU_ROW_SELECTOR)
				{
					this.datagrid.cellContextMenu = removeAllContextMenuItemHelper(this.datagrid.cellContextMenu, MenuConstants.MENU_CELL);				
				}
				else if (strMenuKey == MenuConstants.MENU_HEADER)
				{
					this.datagrid.headerContextMenu = removeAllContextMenuItemHelper(this.datagrid.headerContextMenu, "");				
				}
				else
				{
					err.throwError(ErrorMessages.ERROR_MENU_KEY_INVALID, Global.DEFAULT_LANG);
				}
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message, "removeAllContextMenuItem");	
			}
		}
		
		/*************************************************************
		 * remove menu items
		 * ***********************************************************/
		private function removeAllContextMenuItemHelper(menuItems:ArrayCollection,strMenuKey:String):ArrayCollection
		{
			var tempArr:ArrayCollection=new ArrayCollection();
			var item:Object;
			var tmpKey:String;
			if (!datagrid.bUseDefaultContextMenu && datagrid.bUserContextMenu)
			{
				for each (item in menuItems)
				{
					if (item.isUserMenu)
					{
						tempArr.addItem(item);
					}
					else
					{
						tmpKey = MenuConstants.getMenuType(item.value);
						if(tmpKey == strMenuKey)
							tempArr.addItem(item);
					}
				}
			}
			else
			{
				for each (item in menuItems)
				{
					tmpKey = MenuConstants.getMenuType(item.value);
					if (!item.isUserMenu && tmpKey == strMenuKey)
					{
						tempArr.addItem(item);						
					}
				}
			}					
			return tempArr;
		}
		
		/*************************************************************
		 * add context menu separator
		 * ***********************************************************/
		public function addContextMenuSeparator(strMenuKey:String):void
		{
			try
			{
				var item:Object;				
				if(strMenuKey == MenuConstants.MENU_CELL || strMenuKey == MenuConstants.MENU_ROW_SELECTOR)
				{
					if(this.datagrid.cellContextMenu.length == 0)
						err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
					item = this.datagrid.cellContextMenu.getItemAt(this.datagrid.cellContextMenu.length - 1);
					item.seperator = true;				
				}
				else if(strMenuKey == MenuConstants.MENU_HEADER)
				{
					if(this.datagrid.headerContextMenu.length == 0)
						err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
					item = this.datagrid.headerContextMenu.getItemAt(this.datagrid.headerContextMenu.length - 1);
					item.seperator = true;
				}	
				else
				{
					err.throwError(ErrorMessages.ERROR_MENU_KEY_INVALID, Global.DEFAULT_LANG);
				}
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message, "addContextMenuSeparator");	
			}
		}
		
		/*************************************************************
		 * check data provider
		 * ***********************************************************/
		public var bAddHeader:Boolean=true;
		public var originData:Array=new Array();
		public var bhaft:Boolean=false;
		public var bFirstLoad:Boolean=false;
		public function checkDataProvider(provider:Object, bValidation:Boolean, parentFunName:String):void
		{
			try
			{
				//				_isGettingData = true;
				//				if(this.datagrid.columns==null || this.datagrid.columns.length==0)
				//					return;
				for each (var exCol:ExAdvancedDataGridColumn in this.datagrid.columns)
				{
					if (exCol.type == ColumnType.CHECKBOX)
						exCol.arrSelectedCheckbox.removeAll();
				}
				
				//set data 2 rows for good performance
				originData=provider as Array;
				var haftArr:Array=new Array();
              
				if (originData.length >30 && this.datagrid.isTree==false)
				{
					for (var i:int=0;i<2;i++)
					{
						haftArr.push(originData[i]);
					}
				    bhaft=true;
				}
 				else
 			    {
				   haftArr=originData;
 				}
				
				this.datagrid.removeSelectedRadio();
				var bInvalid:Boolean=false;
				var columnKey:String="";
				var nRow:int=-1;
				var nColumnIndex:int=-1;
				var col:ExAdvancedDataGridColumn;
				var countRow:int=0;
				var obj:Object;
				var tmpArr:ArrayCollection=new ArrayCollection(haftArr as Array);
				var item:Object;
				var strDelimiter:String = "";
				var s:String;
				var temp:Array = [];
				var bInvalidDelimeter:Boolean = false;
				//var resultArr:ArrayCollection=new ArrayCollection();
				var idIndex:int=0;
				if(this.datagrid.isTree)
				{
					strDelimiter = datagrid.treeInfo[1];
				}
			
				if (bValidation)
				{
					for each (item in tmpArr)
					{
						try
						{
							if (item != null && item != "")
							{
								//create my key
								item[Global.ACTSONE_INTERNAL] = UIDUtil.createUID();
								idIndex++;								
								for each (col in this.datagrid.columns)
								{
									if(col.type == ColumnType.TEXT && item[col.dataField] != null)
									{
										item[col.dataField] = item[col.dataField].toString();
									}
										 
									else if(col.type ==ColumnType.CHECKBOX && item[col.dataField] != null && (item[col.dataField] == datagrid.checkboxTrueValue || item[col.dataField] == datagrid.checkboxFalseValue))
									{
										if(item[col.dataField] == datagrid.checkboxTrueValue)
											item[col.dataField] ="1";
										else
											item[col.dataField] ="0";
									}
									if (item[col.dataField] == null || item[col.dataField] == "")
									{
										if (col.type == ColumnType.CHECKBOX || (col.type == ColumnType.NUMBER && datagrid.bUpdateNullToZero) )
										{
											item[col.dataField]="0";
										}
										else
											item[col.dataField]="";
									}
									else if(item[col.dataField].toString().search('\r\n')>-1)		//remove special characters
									{
										item[col.dataField] = item[col.dataField].replace('\r\n','');
									}
									nRow=countRow;
									nColumnIndex=int(col.colNum);
									columnKey=col.dataField;
									if (this.checkValueEntered(col, item[columnKey], "checkDataProvider"))
									{
										if(col.type==ColumnType.CHECKBOX && item[columnKey] == 1)
										{
											col.arrSelectedCheckbox.addItem(item);
										}
									}
								}
								if(this.datagrid.isTree && item.hasOwnProperty(datagrid.hiddenValue))
								{
									s = item[datagrid.hiddenValue].toString();
									temp = s.split(strDelimiter);
									if (temp.length != 2)
									{
										bInvalidDelimeter = true;
										err.throwError(ErrorMessages.ERROR_DELIMETER_INVALID, Global.DEFAULT_LANG);
									}										
									item[this.datagrid.treePIDField]=temp[0].toString();
									item[this.datagrid.treeIDField]=temp[1].toString();	
									temp = [];
								}
								//resultArr.addItem(item); //remove the item = null
								countRow++;
							}
							else
							{
								tmpArr.removeItemAt(countRow);
							}
						}
						catch (error:Error)
						{
							bInvalid=true;
							break;
						}
					}
					if (bInvalid)
					{							
						var msg:String = err.getStringErrorLang(ErrorMessages.ERROR_COLKEY_ROWINDEX_COLINDEX, Global.DEFAULT_LANG, columnKey, nRow, nColumnIndex);
						if(bInvalidDelimeter)
						{
							msg = err.getStringErrorLang(ErrorMessages.ERROR_DELIMETER_INVALID_ROWINDEX, Global.DEFAULT_LANG, nRow);
						}
						//						_isGettingData = false;
						throw new Error(msg);						
						return;
					}
				}
				else
				{
					for each (item in tmpArr)
					{
						if (item != null && item != "")
						{
							//create my key
							item[Global.ACTSONE_INTERNAL] = UIDUtil.createUID();
							idIndex++;
							for each (col in this.datagrid.columns)
							{
								if(col.type == ColumnType.TEXT && item[col.dataField] != null)
								{
									item[col.dataField] = item[col.dataField].toString();
								}
								else if(col.type ==ColumnType.CHECKBOX && item[col.dataField] != null && (item[col.dataField] == datagrid.checkboxTrueValue || item[col.dataField] == datagrid.checkboxFalseValue))
								{
									if(item[col.dataField] == datagrid.checkboxTrueValue)
										item[col.dataField] ="1";
									else
										item[col.dataField] ="0";
								}
								if (item[col.dataField] == "" || item[col.dataField] == null)
								{
									if (col.type == ColumnType.CHECKBOX || (col.type == ColumnType.NUMBER && datagrid.bUpdateNullToZero))
									{
										item[col.dataField]="0";
									}
									else
										item[col.dataField]="";
								}
								else if (col.type == ColumnType.COMBOBOX)
								{
									if (!col.checkComboValue(item[col.type]))
									{
										obj=new Object();
										obj["label"]=item[col.dataField].toString();
										obj["value"]=item[col.dataField].toString();
										if (col.listCombo[col.comboKey] == null)
											col.listCombo[col.comboKey]=new Array();
										col.listCombo[col.comboKey].push(obj);
									}
								}
								
								else if(col.type==ColumnType.CHECKBOX && item[col.dataField] == 1)
								{
									col.arrSelectedCheckbox.addItem(item);
								}
								else if(item[col.dataField].toString().search('\r\n')>-1)		//remove special characters
								{
									item[col.dataField] = item[col.dataField].replace('\r\n','');
								}
							}
							if(this.datagrid.isTree && item.hasOwnProperty(datagrid.hiddenValue))
							{
								s = item[datagrid.hiddenValue].toString();
								temp = s.split(strDelimiter);
								if (temp.length != 2)
								{
									bInvalidDelimeter = true;
									err.throwError(ErrorMessages.ERROR_DELIMETER_INVALID, Global.DEFAULT_LANG);
									return;
								}										
								item[this.datagrid.treePIDField]=temp[0].toString();
								item[this.datagrid.treeIDField]=temp[1].toString();	
								temp = [];
							}
							countRow++;
							//resultArr.addItem(item); //remove the item = null
						}
						else
						{
							tmpArr.removeItemAt(countRow);
						}
					}
				}
				clearData();
				if(this.datagrid.isTree)
				{
					this.datagrid.dataProvider = parsingTreeData(tmpArr);				
				}
				else
					this.datagrid.dataProvider=tmpArr;
				
				bkDataProvider(tmpArr);
				this.datagrid.crudProvider=new ArrayCollection(ObjectUtil.copy(tmpArr.source) as Array);
				//update invisible index order to be used in setRowHide and undoRowHide
				if(this.datagrid.invisibleIndexOrder)
					this.datagrid.invisibleIndexOrder = null;
				
				
				if (bhaft==true)
				{
					
					for(var k:int=2;k<30;k++)
					{
						setDataSecond(originData[k]);
					}
					
					if(this.datagrid.bExternalScroll)
					{
						updateExternalVerticalScroll(this.datagrid.getLength());
					}
					
					this.gridone.vScroll.maxScrollPosition=this.datagrid.maxVerticalScrollPosition=0;
					
					this.gridone.refresh();
 
				}
				else
				{
					//update Application height when data is changed
					//  	updateGridHeight();
					//update datagrid width in case external scroll
						updateExternalVerticalScroll(tmpArr.length);
					//need to update listContent as soon as datagrid's height is changed
					//	if(this.datagrid.bExternalScroll && this.datagrid.bAllowResizeDgHeight)
					 	this.datagrid.validateNow(); 
				}
				
				updateGridHeight();
				setTimeout(datagrid.dispatchDataCompleted,500);
				this.gridone.activity.closeBusyBar();
			}
			catch(error:Error)
			{
				// _isGettingData = false;
				err.throwMsgError(error.message,parentFunName);	
			}
		}
		
		/*************************************************************
		 * backup data provider
		 * ***********************************************************/
		public function bkDataProvider(source:Object):void
		{
			if(source is ArrayCollection)
			{
				this.datagrid._bkDP = new ArrayCollection(ArrayCollection(source).toArray());
			}
			else if(source is XMLList)
			{
				this.datagrid._bkDP = new XMLListCollection(source as XMLList);
			}
		}
		
		/*************************************************************
		 * check input value
		 * ***********************************************************/
		public function checkValueEntered(col:ExAdvancedDataGridColumn, value:Object, funcName:String):Boolean
		{
			if (value == "" || value == null)
				return true;
			var err:ErrorMessages=new ErrorMessages();
			if (col == null)
			{
				err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				return false;
			}
			switch (col.type)
			{
				case ColumnType.IMAGETEXT:
					if (value != null && value.toString().length > col.maxLength)
					{
						if (funcName == Global.SET_CELL_FUNCTION)
							Alert.show(Global.TEXT_WARNING);
						err.throwError(ErrorMessages.ERROR_TEXT, Global.DEFAULT_LANG);
						return false;
					}
					break;
				case ColumnType.TEXT:
					if (value != null && value.toString().length > col.maxLength)
					{
						if (funcName == Global.SET_CELL_FUNCTION)
							Alert.show(Global.TEXT_WARNING);
						err.throwError(ErrorMessages.ERROR_TEXT, Global.DEFAULT_LANG);
						return false;
					}
					break;
				case ColumnType.CHECKBOX:
					if (value.toString() != "true" && value.toString() != "false" && value.toString() != "1" && value.toString() != "0" && value.toString() != "")
					{
						if (funcName == Global.SET_CELL_FUNCTION)
							Alert.show(Global.CHECKBOX_WARNING);
						err.throwError(ErrorMessages.ERROR_CHECKBOX, Global.DEFAULT_LANG);
						return false;
					}
					break;
				case ColumnType.COMBOBOX:
					if (!col.checkComboValue(value.toString()))
					{
						if (funcName == Global.SET_CELL_FUNCTION)
							Alert.show(Global.COMBOBOX_WARNING);
						if (funcName == "checkDataProvider")
						{
							var obj:Object = new Object();
							obj["label"]=value.toString();
							obj["value"]=value.toString();
							if (col.listCombo[col.comboKey] == null)
								col.listCombo[col.comboKey] =new Array();
							col.listCombo[col.comboKey].push(obj);
							return true;
						} 
						err.throwError(ErrorMessages.ERROR_COMBOBOX, Global.DEFAULT_LANG);
						return false;
					}
					break;
				case ColumnType.DATE:
					var date:Date=DateField.stringToDate(value.toString(), col.dateInputFormatString);
					if (date == null)
					{
						if (funcName == Global.SET_CELL_FUNCTION)
							Alert.show(Global.DATE_WARNING);
						err.throwError(ErrorMessages.ERROR_DATE, Global.DEFAULT_LANG);
						return false;
					}
					break;
				case ColumnType.NUMBER:
					var tmpArray:Array = value.toString().split('.');
					var precision:int = col.precision;
					if(tmpArray.length > 1)
						precision = tmpArray[1].toString().length;
					if (col.precision > -1) ////updated by Thuan: add conditional col.precision > -1; //2013April01
					{
						if (isNaN(Number(value)) || Number(value) > col.maxValue || (!isNaN(Number(precision)) && precision > col.precision))
						{						
							if (funcName == Global.SET_CELL_FUNCTION)
								Alert.show(Global.NUMBER_WARNING);
							err.throwError(ErrorMessages.ERROR_NUMBER, Global.DEFAULT_LANG);
							return false;
						}
					}
					break;
			}
			return true;
		}
		
		/*************************************************************
		 * clear Data
		 * ***********************************************************/
		public function clearData():void
		{
			if( datagrid.summaryBar.hasSummaryBar())
				datagrid.summaryBar.clearSummaryBar();
			gridone.clearGroupMerge();
			this.datagrid.dataProvider = null;
			if(this.datagrid.dataProvider is ArrayCollection)
				this.datagrid.dataProvider=new ArrayCollection();
			else if(this.datagrid.dataProvider is XMLListCollection)
				this.datagrid.dataProvider=new XMLListCollection();
			else if(this.datagrid.dataProvider is ExIHierarchicalData)
				this.datagrid.dataProvider=new ExIHierarchicalData();
			this.datagrid._bkDP=null;
			if(datagrid.bExternalScroll && gridone.vScroll.visible)
			{
				gridone.vScroll.pageSize = 0;
				gridone.vScroll.visible = false;
				datagrid.maxVerticalScrollPosition = 0;
			}
			
			//update height of datagrid
			updateGridHeight();
			
			//clear array to save hidden index to be used in setRowHide and undoRowHide
			this.datagrid.invisibleIndexOrder = null;
			//			gridoneManager.clearTempProperties();
			clearMemory();
			setTimeout(clearMemory, 1000);			
		}
		
		private function clearMemory():void
		{
			flash.system.System.gc();
		}
		
		/*************************************************************
		 * parse flat data to tree data
		 * Thuan updated for moveTreeNode 
		 * 2012 Oct 10
		 * ***********************************************************/
		private function parsingTreeData(dp:ArrayCollection):ExIHierarchicalData
		{
			for each(var item:Object in dp)
			{
				item[this.datagrid.treeTypeField]= hasChildren(dp, item[datagrid.treeIDField]) ? "parent" : "child";
			}
			var exData:ExIHierarchicalData = new ExIHierarchicalData();
			exData.strRootKey = this.datagrid.treeInfo[0];
			exData.treeIDField = this.datagrid.treeIDField;
			exData.treePIDField = this.datagrid.treePIDField;
			exData.treeTypeField = this.datagrid.treeTypeField;
			exData.source = dp;
			return exData;
		}
		
		/*************************************************************
		 * check tree has chidren or not
		 * ***********************************************************/
		private function hasChildren(dp:ArrayCollection , valueTreeIDField:String):Boolean
		{					
			var obj:Object;
			for each( obj in dp )
			{
				if( obj[this.datagrid.treePIDField] == valueTreeIDField )
					return true;
			}
			return false;
		}
		
		/*************************************************************
		 * create empty row
		 * ***********************************************************/
		public function createEmptyRow():Object
		{
			var row:Object=new Object();
			
			for (var i:int=0; i < datagrid.columns.length; i++)
			{
				if (datagrid.columns[i] != null && datagrid.columns[i].dataField != null)
				{
					switch(datagrid.columns[i].type)
					{
						case ColumnType.CHECKBOX:
							row[datagrid.columns[i].dataField]="0";
							break;
						case ColumnType.IMAGETEXT:
							row[datagrid.columns[i].dataField]="";
							row[datagrid.columns[i].dataField+Global.SELECTED_IMAGE_INDEX]="-1";
							break;
						case ColumnType.COMBOBOX:
							var col:ExAdvancedDataGridColumn=datagrid.columns[i];
							row[datagrid.columns[i].dataField+Global.SELECTED_COMBO_INDEX]= -1; //0;
							//	row[datagrid.columns[i].dataField]=(col.listCombo[col.comboKey]!=null && col.listCombo[col.comboKey][0]!=null)?col.listCombo[col.comboKey][0]["value"]:"";
							row[datagrid.columns[i].dataField] = "";
							break;
						case ColumnType.MULTICOMBO:
							row[datagrid.columns[i].dataField+Global.SELECTED_COMBO_INDEX]= -1;
							// row[datagrid.columns[i].dataField+Global.COMBO_KEY_CELL]=(datagrid.columns[i]as ExDataGridColumn).comboKey;
							row[datagrid.columns[i].dataField+Global.COMBO_KEY_CELL] = "";
							break;
						case ColumnType.CRUD:
							row[datagrid.crudColumnKey+Global.CRUD_KEY] = Global.CRUD_INSERT;							
							row[datagrid.columns[i].dataField]="";							
							break;
						case ColumnType.NUMBER:
							if(datagrid.bUpdateNullToZero)
								row[datagrid.columns[i].dataField]="0";
							else
								row[datagrid.columns[i].dataField]="";
							break;
						default:
							row[datagrid.columns[i].dataField]="";
							break;
						
					}
					
				}
			}
			//create my key
			row[Global.ACTSONE_INTERNAL] = UIDUtil.createUID();
			return row;
		}
		
//		/*************************************************************
//		 * search data
//		 * ***********************************************************/				
//		public function searchData(searchStr:String,isDown:String="",columnKey:String=""):void
//		{
//			var rs:Object;
//			var stop:Boolean=false;
//			var index:int=0;
//			var item:Object;
//			var insertIndex:int=0;
//			var col:ExAdvancedDataGridColumn;
//			var firstItem:Object;
//			
//			var itemName:String="";
//			
//			if(searchStr == "")
//				return;
//			
//			if(isDown=="")
//			{
//				while (index < this.datagrid.dataProvider.length)					
//				{
//					if(columnKey != "" && columnKey != null)
//					{
//						itemName=this.datagrid.dataProvider[index][columnKey].toString().toLowerCase();
//						if(itemName.toLocaleLowerCase().indexOf(searchStr.toLowerCase()) > -1)
//						{
//							item=(this.datagrid.dataProvider as ArrayCollection).getItemAt(index);
//							if(firstItem==null)
//								firstItem=item;
//							(this.datagrid.dataProvider as ArrayCollection).removeItemAt(index);
//							(this.datagrid.dataProvider as ArrayCollection).addItemAt(item,insertIndex);
//							insertIndex++;
//						}
//					}
//					else
//					{
//						for each ( col in this.datagrid.columns)
//						{
//							itemName=this.datagrid.dataProvider[index][col.dataField].toString().toLowerCase();
//							if(itemName.toLocaleLowerCase().indexOf(searchStr.toLowerCase()) > -1)
//							{
//								item=this.datagrid.getItemAt(index);
//								if(firstItem==null)
//									firstItem=item;
//								(this.datagrid.dataProvider as ArrayCollection).removeItemAt(index);
//								(this.datagrid.dataProvider as ArrayCollection).addItemAt(item,insertIndex);
//								
//								insertIndex++;
//								break;
//							}						
//						}
//					}
//					index++;
//				}			
//				if(insertIndex>0)
//				{
//					(this.datagrid.dataProvider as ArrayCollection).refresh();
//					this.datagrid.verticalScrollPosition=0;
//					this.datagrid.selectedItem=firstItem;
//				}
//				else
//				{
//					this.datagrid.verticalScrollPosition=0;
//					this.datagrid.selectedItem = null;
//				}
//			}
//			else
//			{
//				//					var direction:String=isDown=="true"?"down":"up"
//				if (isDown=="true")
//				{
//					index=datagrid.selectedIndex;
//					index++;
//					if (index >= this.datagrid.dataProvider.length)
//						index=0;
//				}
//				else
//				{
//					index=datagrid.selectedIndex;
//					index--;
//					if (index <0)
//						index=this.datagrid.dataProvider.length - 1;
//				}
//				
//				while (index < this.datagrid.dataProvider.length)
//				{
//					if(columnKey != "" && columnKey != null)
//					{
//						itemName=this.datagrid.dataProvider[index][columnKey].toString().toLowerCase();
//						if(itemName.toLocaleLowerCase().indexOf(searchStr.toLowerCase()) > -1)
//						{
//							stop=true;
//						}
//					}
//					else
//					{
//						for each ( col in this.datagrid.columns)
//						{
//							itemName=this.datagrid.dataProvider[index][col.dataField].toString().toLowerCase();
//							if(itemName.toLocaleLowerCase().indexOf(searchStr.toLowerCase()) > -1)
//							{
//								stop=true;
//								break;
//							}
//						}
//					}
//					if (stop)
//						break;
//					index++;
//				}
//				
//				if (stop)
//				{				
//					this.datagrid.selectedIndex=index;
//					if(this.datagrid.dataProvider.length>this.datagrid.rowCount)
//					{					
//						this.datagrid.maxVerticalScrollPosition=this.datagrid.dataProvider.length-this.datagrid.rowCount+1;	
//					}
//					if (index > this.datagrid.rowCount - 2)
//					{
//						this.datagrid.verticalScrollPosition=(index - this.datagrid.rowCount + 3) >=this.datagrid.maxVerticalScrollPosition?this.datagrid.maxVerticalScrollPosition:(index - this.datagrid.rowCount + 3) ;					
//					}
//					else
//						this.datagrid.verticalScrollPosition=0;
//				}
//			}		
//		}
		
		public var searchStr:String="";
		public var filterColumnField:String="";
		
		/*************************************************************
		 * filter data
		 * ***********************************************************/	
		public function filter(searchText:String,columnKey:String=""):void
		{
			searchStr = searchText;
			if(columnKey == null)
				columnKey = "";
			filterColumnField = columnKey;
			var searchCondition:Object = new Object();
			searchCondition["searchStr"]=searchStr;
			searchCondition["filterColumnField"]=filterColumnField;
			this.datagrid.filter = new FilterDataWithSearch(this.datagrid.filter,searchCondition);
			(this.datagrid.dataProvider as ArrayCollection).filterFunction = this.datagrid.filter.apply;
			//			(this.datagrid.dataProvider as ArrayCollection).filterFunction = filterMyArrayCollection;
			(this.datagrid.dataProvider as ArrayCollection).refresh();
			updateExternalVerticalScroll(datagrid.getLength());
		}
		
		/*************************************************************
		 * filter array collection
		 * ***********************************************************/
		private function filterMyArrayCollection(item:Object):Boolean 
		{
			var itemName:String;
			if(filterColumnField!="")
			{
				if(item[filterColumnField]==null)
					return false;
				itemName= item[filterColumnField].toString();
				itemName=itemName.toLowerCase();
				return itemName.indexOf(searchStr.toLowerCase()) > -1;
			}else
			{
				for (var dataField:String in item)
				{
					itemName= item[dataField].toString();
					itemName=itemName.toLowerCase();
					if( itemName.indexOf(searchStr.toLowerCase()) > -1 )
						return true;
				}
				return false;
			}
			return false;
		}
		
		/*************************************************************
		 * set Json data
		 * ***********************************************************/
		public function setJsonData(jsonData:Object, bValidation:Boolean=true , nameFunction:String =""):void
		{
			try
			{
				this.gridone.activity.showBusyBar();
				this.datagrid.setStyle("verticalGridLines", true);	
				this.checkDataProvider(jsonData, bValidation, nameFunction);
				//				_isGettingData = false;
				
				if (bFirstLoad==true)
				{
					this.LoadRemainData();
				}
			}
			catch (error:Error)
			{
				throw new Error(error.message);			
			}
		}
		

		
		/*************************************************************
		 * set CRUD mode for datagrid, using CRUD column
		 * author: Toan Nguyen
		 * ***********************************************************/
		public function setCRUDMode(strCRUDColumnKey:String, strInsertRowText:String="C", strUpdateRowText:String="U", strDeleteRowText:String="D"):void
		{
			try
			{
				//				if (this.datagrid.dataFieldIndex[strCRUDColumnKey] == null)
				//					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(this.datagrid.dataProvider!=null && this.datagrid.dataProvider.length>0)
					this.datagrid.crudProvider=new ArrayCollection(ObjectUtil.copy(this.datagrid.dataProvider.source) as Array);
				else
					this.datagrid.crudProvider=new ArrayCollection();
				this.datagrid.crudMode=true;
				if(this.datagrid.dataFieldIndex[strCRUDColumnKey] != null)
				{
					var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(strCRUDColumnKey) as ExAdvancedDataGridColumn;
					col.type = ColumnType.CRUD;
					col.editable = false;
					col.public::setStyle("textAlign", "center");
				}
				this.datagrid.strInsertRowText=strInsertRowText;
				this.datagrid.strUpdateRowText=strUpdateRowText;
				this.datagrid.strDeleteRowText=strDeleteRowText;
				this.datagrid.crudColumnKey=strCRUDColumnKey;
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCRUDMode");					
			}
		}
		
		/*************************************************************
		 * reset value for CRUD column		 
		 * ***********************************************************/
		public function cancelCRUD():void
		{			
			this.datagrid.dataProvider=new ArrayCollection(ObjectUtil.copy((this.datagrid.crudProvider as ArrayCollection).source) as Array);
			this.datagrid.invalidateList();
		}
		
		/*************************************************************
		 * disable CRUD mode
		 * ***********************************************************/
		public function clearCRUDMode():void
		{
			for each(var item:Object in this.datagrid.dataProvider)
			{
				item[this.datagrid.crudColumnKey]="";
				item[this.datagrid.crudColumnKey + Global.CRUD_KEY]="";
			}	
			this.datagrid.crudColumnKey="";
			this.datagrid.crudMode=false;
			this.datagrid.strDeleteRowText=Global.CRUD_DELETE;
			this.datagrid.strUpdateRowText=Global.CRUD_UPDATE;
			this.datagrid.strInsertRowText=Global.CRUD_INSERT;
			this.datagrid.invalidateList();
		}
		
		/*************************************************************
		 * reset value for a specified cell in CRUD column
		 * ***********************************************************/
		public function cancelCRUDRow(rowIndex:int):void
		{
			if(this.datagrid.crudMode)
			{
				if(rowIndex<=this.datagrid.crudProvider.length-1)
				{
					var item:Object=ObjectUtil.copy((this.datagrid.crudProvider as ArrayCollection).getItemAt(rowIndex));
					for(var field:String in item)
					{
						this.datagrid._bkDP[rowIndex][field]=item[field];
					}
					this.datagrid.dataProvider.refresh();
				}
				else if(this.datagrid.dataProvider.length>rowIndex)
				{
					(this.datagrid.dataProvider as ArrayCollection).removeItemAt(rowIndex);
				}
			}
		}
		
		/*************************************************************
		 * clear data inside datagrid
		 * @author Duong Pham
		 * ***********************************************************/
		public function clearGrid():void
		{
			clearData();
			if(this.datagrid.bExternalScroll && gridone.hbDg.horizontalScrollBar.visible)
				gridone.hbDg.horizontalScrollBar.visible=false;
			if(this.datagrid._isGroupedColumn)
				this.datagrid.groupedColumns = new Array();
			this.datagrid.columns=new Array();
			this.datagrid.visible=false;
			this.datagrid.resizableColumns=true;
			datagrid.totalVisibleColumnWidth=0;
		}
		
		/*************************************************************
		 * set data into grid with protocol format
		 * @author Duong Pham
		 * ***********************************************************/
		public function setProtocolData(protocolData:String, funcName:String="protocolData"):void
		{
			try
			{
				this.gridone.activity.showBusyBar();
				if(this.gridoneImpl.tempCols.length > 0)
					this.gridoneImpl.tempCols.removeAll();
				
				var search:String = protocolData.substring(protocolData.length-2,protocolData.length);
				if(search != ProtocolDelimiter.BASE)
					err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
				
				gridProtocol.decode(protocolData);
				if(gridProtocol.drawType==GridProtocol.DRAW_TYPE_A)
				{
					this.gridoneImpl.boundHeader();
				}
				checkDataProvider(gridProtocol.provider,true,funcName);					
				//_isGettingData = false;					
				datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,funcName);			
			}
		}
		
		/*************************************************************
		 * add XML data
		 * @param path string path of xml file from javascript
		 * @author Duong Pham
		 * ***********************************************************/
		public function setXMLData(path:String):void
		{
			this.gridone.activity.showBusyBar();
			httpService=new HTTPService;
			httpService.url=path;
			//httpService.method="post";
			httpService.resultFormat="e4x";
			httpService.showBusyCursor=true;
			httpService.addEventListener(ResultEvent.RESULT,xmlServiceResultHanlder);
			httpService.addEventListener(FaultEvent.FAULT,xmlServiceFaultHanlder);
			httpService.send();
		}
		
		/*************************************************************
		 * handler result event of http service
		 * @author Duong Pham
		 * ***********************************************************/
		private function xmlServiceResultHanlder(event:ResultEvent):void
		{
			var provider:XMLList=event.result.item;
			// add more actsone_internal_uid for each row
			var item:XML;	
			if(datagrid.bUpdateNullToZero)
			{
				var col:ExAdvancedDataGridColumn;
				for (var dataField:String in this.datagrid.dataFieldIndex)
				{
					col = ExAdvancedDataGridColumn(gridone.getColumnByDataField(dataField));
					if(col.type == ColumnType.NUMBER)
					{
						for each (item in provider)
						{
							if(item[col.dataField][0] == null || item[col.dataField][0] == "")
								item[col.dataField][0] = "0"
						}
					}
				}
			}
			for each (var node:XML in provider)
			{
				//create my key
				item = <actsone_internal_uid></actsone_internal_uid>;
				node.appendChild(item);
				node.actsone_internal_uid= UIDUtil.createUID();
			}			
			this.datagrid.dataProvider=provider;
			bkDataProvider(provider);
			//			this.datagrid.crudProvider=new ArrayCollection(ObjectUtil.copy(provider) as Array);
			
			//update invisible index order to be used in setRowHide and undoRowHide
			if(this.datagrid.invisibleIndexOrder)
				this.datagrid.invisibleIndexOrder = null;
			//check external scroll
			updateExternalVerticalScroll(provider.length());	
			//update Application height when data is changed
			updateGridHeight();
			 setTimeout(datagrid.dispatchDataCompleted, 1000);
		
			this.gridone.activity.closeBusyBar();
			
		}
		
		/*************************************************************
		 * handler fault event of http service
		 * @author Duong Pham
		 * ***********************************************************/
		private function xmlServiceFaultHanlder(event:FaultEvent):void
		{
			Alert.show(event.fault.message);
		}
		
		/*************************************************************
		 * handle protocol
		 * @author Duong Pham
		 * ***********************************************************/
		public function getProtocol(selectedField:Object=null):String
		{
			return gridProtocol.getProtocol(selectedField);
		}
		
		/*************************************************************
		 * clear footer bar
		 * @author Duong Pham
		 * ***********************************************************/
		public function clearFooter(strFooterKey:String="all"):void
		{
			if(this.datagrid.hasFooterBar)
			{
				var col:ExAdvancedDataGridColumn;
				for(var i:int=0; i<this.datagrid.columns.length; i++)
				{
					col = ExAdvancedDataGridColumn(this.datagrid.columns[i]);
					//remove footer bar
					if(col.footerColumn)
						col.footerColumn = null;
				}
				if(strFooterKey != "all")
				{
					var hasSpecifiedFooterBar:Boolean = false;
					var index:int=0;
					for(var q:String in this.datagrid.lstComponentBar)
					{						
						if(q == strFooterKey)
						{
							hasSpecifiedFooterBar = true;
							break;
						}
						index++;
					}
					if(hasSpecifiedFooterBar)
					{
						var footerBar:FooterBar = this.datagrid.lstComponentBar[strFooterKey];
						footerBar.functionList = null;
						footerBar = null;
						this.datagrid.lstComponentBar.splice(index,0);
					}
				}
				else
					this.datagrid.lstComponentBar = null;
				this.datagrid.hasFooterBar = false;
				this.datagrid.invalidateList();
			}
		}
		
		/*************************************************************
		 * add footer 
		 * @author Duong Pham
		 * ***********************************************************/
		public function addFooter(strFooterKey:String, strFunc:String, strColumnList:String, isFooter:Boolean=true):void
		{
			try
			{
				if(strColumnList== null || strColumnList.length == 0)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID,Global.DEFAULT_LANG);	
				
				var footerBar : FooterBar = new FooterBar();
				footerBar.strColumnList = strColumnList;
				var colKeyLst : Array = strColumnList.split(',');
				for (var v:int = 0; v < colKeyLst.length; v++) 
				{
					footerBar.functionList[colKeyLst[v]] = strFunc; 
				}
				footerBar.footerBarKey = strFooterKey;
				footerBar.strFunction = strFunc.toLowerCase();
				footerBar.isFooter = isFooter;
				
				if(this.datagrid.lstComponentBar == null)
					this.datagrid.lstComponentBar = new Array(2);
				this.datagrid.lstComponentBar[strFooterKey] = footerBar;
				var col:ExAdvancedDataGridColumn;
				for(var i:int=0; i<this.datagrid.columns.length; i++)
				{
					col = ExAdvancedDataGridColumn(this.datagrid.columns[i]);
					if(isFooter)
					{
						if(col.footerColumn == null)
							col.footerColumn = new ExAdvancedDataGridColumn();
						col.footerColumn.dataField = col.dataField;
						for (var j:int=0; j<colKeyLst.length; j++)
						{
							if(col.dataField == colKeyLst[j])
							{
								//								col.footerBarKey = strFooterKey;
								col.footerBarFunc = strFunc.toLowerCase();
								col.footerColumn.labelFunction = labelFuncLib.footerLabelFunction;
								break;
							}
						}
					}
				}
				this.datagrid.hasFooterBar = true;
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"addFooter");					
				return;
			}
		}
		
		//=============================================================================================
		//Code for DoQuery: Begin
		//=============================================================================================
		/*************************************************************
		 * get a row of data.
		 * @param rowIndex row index of return row.
		 * @return Object represents for the row which we want to get.
		 * author Duong Pham
		 * ***********************************************************/
		public function getRowValues(rowIndex:int):Object
		{
			try
			{					
				var item:Object=new Object();
				if (this.datagrid.dataProvider == null)
					err.throwError(ErrorMessages.ERROR_DATAPROVIDER_NULL, Global.DEFAULT_LANG);
				
				if (rowIndex < 0 || rowIndex >= this.datagrid._bkDP.length)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				
				item = this.datagrid.getBackupItem(rowIndex);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"getRowValues");					
			}
			return item;
		}
		
		private function getDatasFromArray(rows:Array):ArrayCollection
		{
			var arrColl:ArrayCollection = new ArrayCollection;
			for (var i:int=0; i < rows.length; i++)
			{
				var item:Object=new Object;
				item = getRowValues(rows[i]);
				arrColl.addItem(item);
			}
			return arrColl;
		}
		
		private function getCRUDData():Array
		{
			var arr:Array=new Array();
			var rowObj:Object = new Object();
			var column:ExAdvancedDataGridColumn;
			for each (var item:Object in this.datagrid.dataProvider)
			{
				if (item[this.datagrid.crudColumnKey] != "" && item[this.datagrid.crudColumnKey] != null)
				{
					rowObj = new Object();
					for each (column in this.datagrid.columns)
					{
						rowObj[column.dataField]=item[column.dataField];
					}
					arr.push(rowObj); 						
				}
			}
			return arr;
		}
		
		/*************************************************************
		 *Toan Nguyen
		 * ***********************************************************/
		private function validationData(tmpArrColl:ArrayCollection):Boolean
		{
			for each (var item:Object in tmpArrColl)
			{
				for (var itemKey:String in item)
				{
					if (item[itemKey] == null)
						item[itemKey]="";
					var col:ExAdvancedDataGridColumn = this.datagrid.columns[this.datagrid.dataFieldIndex[itemKey]];
					if (col != null)
					{
						if (!checkValueEntered(col, item[itemKey], "httpServiceResult"))
						{
							return false;
						}
					}
				}
			}
			return true;
		}
		
		/*************************************************************
		 *Toan Nguyen
		 * ***********************************************************/
		private function httpServiceResult(event:ResultEvent, requestToken:Object):void
		{
			this.datagrid.isGettingData = false;
			this.datagrid.maxVerticalScrollPosition=0;
			//params=null;
			this.datagrid.logManager.writeLog("Httpservice result: success");
			try
			{
				var dataString:String = event.result as String;
				//var provider:Object=decodeJson(dataString);
				gridProtocol.decode(dataString);
				this.gridoneImpl.boundHeader();
				this.datagrid.logManager.writeLog("boundHeader");
				var provider:Array = gridProtocol.provider;
				if (provider != null)
				{
					if (requestToken != null)
					{
						if (requestToken["validationCheck"])
						{
							var tmpArrColl:ArrayCollection = new ArrayCollection(provider as Array);
							var bValidationCheck:Boolean = validationData(tmpArrColl);
							if (bValidationCheck)
							{
								this.datagrid.dataProvider = tmpArrColl;
							}
						}
						else
							this.datagrid.dataProvider=new ArrayCollection(provider);
						
						if(this.datagrid.eventArr.hasOwnProperty(SAEvent.END_QUERY))
						{
							var endQueryEvent:SAEvent=new SAEvent(SAEvent.END_QUERY);
							this.datagrid.dispatchEvent(endQueryEvent);
						}
						
						var saEvent:SAEvent;
						switch (requestToken[Global.MODE])
						{
							case Global.INSERT_MODE:
								saEvent=new SAEvent(SAEvent.INSERT_SUCCESS);
								break;
							case Global.UPDATE_MODE:
								saEvent=new SAEvent(SAEvent.UPDATE_SUCCESS);
								break;
							case Global.DELETE_MODE:
								saEvent=new SAEvent(SAEvent.DELETE_SUCCESS);
								break;
							default:
							 	saEvent=new SAEvent(SAEvent.LOAD_DATA_COMPLETED);
								break;
						}
						this.datagrid.dispatchEvent(saEvent);
					}
				}
			}
			catch (e:Error)
			{
				this.datagrid.logManager.writeLog("ASFuntion httpServiceResult: " + e.message);
			}				
			this.gridone.closeBusyBar();
		}
		
		private function httpServiceFault(event:FaultEvent, obj:Object):void
		{
			this.datagrid.isGettingData=false;
			this.gridone.closeBusyBar();
			this.datagrid.logManager.writeLog("Httpservice result: Fault");
			this.datagrid.logManager.writeLog("error:" + event.fault.toString());
			//params=null;
			Alert.show(event.fault.toString());
		}
		/*************************************************************
		 * The function sends parameteres to server page using URL parameter and do query based on action parameter.
		 * @param urlStr URL string of server page likes JSP, ASP.
		 * @param objQuery: A string of column key or array of row indexes
		 * @validationCheck indicate whether data is checked or not
		 * ***********************************************************/
		public function doQuery(urlStr:String, objQuery:Object=null, validationCheck:Boolean=true):void
		{
			//service.request = new Object();
			this.datagrid.service.url=urlStr;
			this.datagrid.service.method="post";
			this.datagrid.service.resultFormat="text";
			var queryMode:String="all";
			if (this.datagrid.params == null)
				this.datagrid.params = new Object();
			if (objQuery == null)
			{
				this.datagrid.logManager.writeLog("doQuery:");
				this.datagrid.logManager.writeLog("action:null");
			}
			else
			{
				
				if (objQuery is String)
				{
					var strCondition:String=objQuery as String;
					if (strCondition == Global.WISEGRIDDATA_ALL)
					{
						if (this.datagrid.dataProvider != null)
						{
							this.datagrid.params["data"] = encodeJson((this.datagrid.dataProvider as ArrayCollection).toArray());
							this.datagrid.params["wisegriddata"] = JSONEncoder(strCondition);//JSON.encode(strCondition);
							this.datagrid.logManager.writeLog("doQuery");
							this.datagrid.logManager.writeLog("wisegriddata_all:" + strCondition);
						}
					}
					else
					{
						if (datagrid.crudMode)
							this.datagrid.params["data"] = encodeJson(getCRUDData());
						else
							this.datagrid.params["data"] = encodeJson(this.datagrid.columns[this.datagrid.dataFieldIndex[objQuery]].arrSelectedCheckbox.toArray());
						this.datagrid.params["columnKey"] = objQuery;
						this.datagrid.logManager.writeLog("doQuery");
						this.datagrid.logManager.writeLog("checkbox key:" + objQuery);
						/* switch (params[Global.MODE])
						{
						case Global.INSERT_MODE:
						params["data"]=JSON.encode(this.datagrid.arrSelectedCheckbox.toArray());
						break;
						case Global.DELETE_MODE:
						params["data"]=JSON.encode(this.datagrid.arrSelectedCheckbox.toArray());
						break;
						case Global.UPDATE_MODE:
						params["data"]=JSON.encode(this.datagrid.arrSelectedCheckbox.toArray());
						break;
						case ACTION_APPLYCHANGE:
						params["insertArray"]=JSON.encode(this.datagrid.arrSelectedCheckbox);
						params["deleteArray"]=JSON.encode(this.datagrid.arrSelectedCheckbox);
						params["updateArray"]=JSON.encode(this.datagrid.arrSelectedCheckbox);
						break;
						
						} */
					}
				}
				else if (objQuery is Array)
				{
					var rowDatas:ArrayCollection = this.getDatasFromArray(objQuery as Array);
					this.datagrid.params["data"] = encodeJson(rowDatas.toArray());
					this.datagrid.params["rowArray"] = encodeJson(objQuery);
					this.datagrid.logManager.writeLog("doQuery");
					this.datagrid.logManager.writeLog("action: rows array");
				}
			}
			
			this.datagrid.service.request = this.datagrid.params;
			if (this.datagrid.params.hasOwnProperty(Global.MODE) && (this.datagrid.params[Global.MODE] != null || this.datagrid.params[Global.MODE] != ""))
				queryMode = this.datagrid.params[Global.MODE];
			var objArr:Object = new Object();
			objArr[Global.MODE] = queryMode;
			objArr["validationCheck"] = validationCheck;
			var token:AsyncToken = this.datagrid.service.send();
			var responder:AsyncResponder = new AsyncResponder(httpServiceResult, httpServiceFault, objArr);
			token.addResponder(responder);
			this.datagrid.isGettingData=true;
			this.gridone.showBusyBar();
			//closeBusyBar();
		}
		//=============================================================================================
		//Code for DoQuery: End
		//=============================================================================================
		
		private function isExistedInColumnKeyList(strColumnKeyList:String, strValue:String):Boolean
		{
			var lstColKey : Array = strColumnKeyList.split(',');
			var isExist : Boolean = false;
			for (var i:int = 0; i < lstColKey.length; i++) 
			{
				if(lstColKey[i] == strValue)
				{
					isExist = true;
					break;
				}
			}
			return isExist;
		}
		
		/*************************************************************
		 * set text data by service 
		 * @author Duong Pham
		 * ***********************************************************/
		public function setTextDataByService(path:String):void
		{
			httpService=new HTTPService;
			httpService.url=path;
			//httpService.method="post";
			httpService.resultFormat="text";
			httpService.showBusyCursor=true;
			httpService.addEventListener(ResultEvent.RESULT,textServiceResultHandler);
			httpService.addEventListener(FaultEvent.FAULT,textServiceFaultHandler);
			httpService.send();
		}
		
		/*************************************************************
		 * handle result event handler of HTTP service when calling setTextDataByService method
		 * @author Duong Pham
		 * ***********************************************************/
		private function textServiceResultHandler(event:ResultEvent):void
		{
			gridone.setTextData(event.result.toString(),false);
		}
		
		/*************************************************************
		 * handle fault event handler of HTTP service when calling setTextDataByService method
		 * @author Duong Pham
		 * ***********************************************************/
		private function textServiceFaultHandler(event:FaultEvent):void
		{
			Alert.show(event.fault.message.toString());
		}
		
		/*************************************************************
		 * handle mouse wheel event which is catched from javascript
		 * and find object under point to dispatch MOUSE WHEEL again 
		 * @author Duong Pham
		 * ***********************************************************/
		public function handleMouseWheelHandler(applicationStage:Stage,event:Object):void
		{			
			if (MouseWheelTrap.isMouseOutGrid)
			{
				return;
			}
			
			var obj:InteractiveObject=null;
			
			var mousePoint:Point=new Point(applicationStage.mouseX, applicationStage.mouseY);
			var objects:Array=applicationStage.getObjectsUnderPoint(mousePoint);
			for (var i:int=objects.length - 1; i >= 0; i--)
			{
				if (objects[i] is InteractiveObject)
				{
					obj=objects[i] as InteractiveObject;
					break;
				}
				else
				{
					if (objects[i] is Shape && (objects[i] as Shape).parent)
					{
						obj=(objects[i] as Shape).parent;
						break;
					}
				}
			}
			if (obj)
			{
				var mEvent:MouseEvent=new MouseEvent(MouseEvent.MOUSE_WHEEL, true, false, mousePoint.x, mousePoint.y, obj, event.ctrlKey, event.altKey, event.shiftKey, false, Number(event.delta));
				obj.dispatchEvent(mEvent);
			}
		}
		

		
		/*************************************************************
		 * add footer 
		 * @author Duong Pham
		 * ***********************************************************/
		public function setFooterValue(strFooterKey:String, strColumnKey:String, strValue:String):void
		{
			try
			{
				//				if(!this.datagrid.hasFooterBar)
				//					err.throwError(ErrorMessages.ERROR_FOOTER_INVALID, Global.DEFAULT_LANG);				
				//				if(!isInvalidColumnKey(this.datagrid.summaryBarManager.lstTotal[strSummaryBarKey],strColumnKey))
				//				{
				//					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				//				}
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellSort");	
			}
		}
		
		/*************************************************************
		 * handle mouse click event when user clicks out of GridOne or click another places in browser which is not Flex area.
		 * @author Duong Pham
		 * ***********************************************************/
		public function handlePressOutOfGridOne():void
		{
			//end edit item editor when move is moved out of flex
			if(datagrid.itemEditorInstance)
			{
				datagrid.endEditCell(ExAdvancedDataGridEventReason.OTHER);
			}
		}
		
		/*************************************************************
		 * handle resize event
		 * ***********************************************************/
		public function resizeApplication(event:ResizeEvent):void
		{
			if(gridone.stage && gridone.stage.stageWidth != event.oldWidth)
			{
				this.gridone.applicationWidth = gridone.stage.stageWidth;
				updateExternalVerticalScroll(this.datagrid.getLength());
			}
		}
		
		/*************************************************************
		 * update datagrid width in case bExternalScroll = true
		 * ***********************************************************/
		public function updateExternalHorizontalScroll():void
		{
			if(datagrid.bExternalScroll)
			{
				var originalDataGridWidth:Number = this.datagrid.width;
				var datagridWidth:Number;
				//update the datagrid's width
				datagridWidth = datagrid.totalVisibleColumnWidth;
 
				if(gridone.vScroll.visible)
				{
				if(gridone.applicationWidth <= datagridWidth)
				datagridWidth = datagridWidth - gridone.vScroll.width - 2;
				}
			 
				if(datagridWidth != originalDataGridWidth)
				  	this.datagrid.width = datagridWidth;
				// this.datagrid.width =this.gridone.width-20;
			}
		}
		
		/*************************************************************
		 * update height of application when grid has no data or any datas
		 * @author Thuan Phan
		 * ***********************************************************/
		public function updateGridHeight():void
		{
			if(this.datagrid.eventArr.hasOwnProperty(SAEvent.ON_RESIZE_GRID_HEIGHT))
			{
				var vHeaderHeight:Number = getHeaderHeight();
				var vRowsHeight:Number;
				var vGridHeight:Number;
				var vAppHeight:Number=0;
				var lenGrid:Number = 0;
				if (this.datagrid.data)  // updated by Thuan on April 11, 2013 
					lenGrid = this.datagrid.getLength();
				var oldAppHeight:Number = this.gridone.height;
				var isDispatchEvent:Boolean = false;
				
				
				if(this.datagrid.bAllowResizeDgHeight)
				{
					//allow resize height
					if(this.datagrid.isResizeDgHeightByPixel)
					{
						if(this.datagrid.bResizeHeightByApp)
						{
							//allow resize height of application
							vRowsHeight = datagrid.rowHeight * lenGrid;
							
							if(vRowsHeight < this.datagrid.nMinContentHeight)
								vRowsHeight = this.datagrid.nMinContentHeight;
							
							vGridHeight = vRowsHeight + vHeaderHeight;
							
							//hbDg box
							if(this.datagrid.bExternalScroll && this.gridone.hbDg.horizontalScrollBar)
								vGridHeight += this.gridone.hbDg.horizontalScrollBar.height;
							
							vAppHeight = vGridHeight;
							
							vAppHeight += 2; 	//padding main container hbox
							
							//logo
							if(this.gridone.hBoxLogo.visible)
								vAppHeight += this.gridone.hBoxLogo.height;
							
							
							if(this.datagrid.originalAppHeight >= vAppHeight)
							{
								vAppHeight += 3; //trick: in case of addRow, addRowAt
								if(oldAppHeight != vAppHeight)
								{
									this.gridone.height = vAppHeight;
									isDispatchEvent = true;
								}
							}
							else
							{
								if(this.gridone.height != this.datagrid.originalAppHeight)
								{
									isDispatchEvent = true;
									vAppHeight = this.gridone.height = this.datagrid.originalAppHeight;
								}
							}
							this.datagrid.height = reCalculateDgHeight(this.gridone.height);
						}
						else
						{
							//allow resize height of datagrid
							vRowsHeight = datagrid.rowHeight * lenGrid;		//update height of datagrid according to pixels
							
							if(vRowsHeight < this.datagrid.nMinContentHeight)
								vRowsHeight = this.datagrid.nMinContentHeight;
							
							vGridHeight = vRowsHeight + vHeaderHeight;
							
							if(this.datagrid.originalDgHeight >= vGridHeight)
							{
								if(!this.datagrid.bExternalScroll && this.datagrid.checkHorizontalScollBar())
								{	
									vGridHeight += (this.datagrid.getHorizontalScollBar()).height;
								}
								else if(this.datagrid.bExternalScroll && this.gridone.hbDg.horizontalScrollBar)
								{	
									vGridHeight += this.gridone.hbDg.horizontalScrollBar.height;
								}
								vGridHeight += 3; //trick: in case of clearData for hScrollBar work well
								this.datagrid.height = vGridHeight;	
							}
							else
							{
								this.datagrid.height = this.datagrid.originalDgHeight;
							}
							if(this.gridone.height != this.datagrid.originalAppHeight)
							{
								isDispatchEvent = true;
								this.gridone.height = this.datagrid.originalAppHeight;
							}
						}
					}
				}
				else
				{
					//does not allow resize height
					if(this.datagrid.isResizeDgHeightByPixel)
					{
						if(this.datagrid.bResizeHeightByApp)
						{
							if(this.gridone.height != this.datagrid.originalAppHeight)
							{
								isDispatchEvent = true;
								this.gridone.height = this.datagrid.originalAppHeight;
								this.datagrid.height = reCalculateDgHeight(this.gridone.height);
							}
						}
						else
						{
							//update height of datagrid
							if(this.datagrid.height != this.datagrid.originalDgHeight)
								this.datagrid.height = this.datagrid.originalDgHeight;
							if(this.gridone.height != this.datagrid.originalAppHeight)
							{
								isDispatchEvent = true;
								this.gridone.height = this.datagrid.originalAppHeight;
							}
						}
					}
				}
				if(isDispatchEvent)
				{
					var saEventResize:SAEvent;
					saEventResize = new SAEvent(SAEvent.ON_RESIZE_GRID_HEIGHT, false);
					saEventResize.nGridHeight = this.gridone.height;
					this.datagrid.dispatchEvent(saEventResize);
				}
			}
		}
		
		/*************************************************************
		 * calculate datagrid's height when gridone's height is changed
		 * @author Duong Pham
		 * ***********************************************************/
		public function reCalculateDgHeight(appHeight:Number):Number
		{
			var dgHeight:Number=0;
			//re-calculate height of datagrid
			if(this.gridone.hBoxLogo.visible)
				dgHeight = appHeight - this.gridone.hBoxLogo.height;
			
			dgHeight -= 2;	//padding mainContain hbox
			
			//hbDg box			
			if(this.datagrid.bExternalScroll && this.gridone.hbDg.horizontalScrollBar)
				dgHeight -= this.gridone.hbDg.horizontalScrollBar.height;
			
			return dgHeight;
		}
		
		/*************************************************************
		 * get header height of datagrid
		 * @author Duong Pham
		 * ***********************************************************/
		public function getHeaderHeight():Number
		{
			if(this.datagrid.bAutoWidthColumn)
			{
				if(this.datagrid._isGroupedColumn)
				{
					var nHeaderRows:int = countRowsHeader();
					return nHeaderRows * this.datagrid.headerHeight;
				}
				else
					return  this.datagrid.headerHeight;
			}
			else
				return this.datagrid.headerHeight;
		}
		
		/*************************************************************
		 * Count of row header in case datagrid is grouped columns
		 * @author Duong Pham
		 * ***********************************************************/
		public function countRowsHeader():int
		{
			var maxRowHeader:int=0;
			var tempHeightRow:int=0;
			for(var i:int=0; i<datagrid.columns.length; i++)
			{
				if(ExAdvancedDataGridColumn(datagrid.columns[i]).parent != "")
				{
					tempHeightRow = countRowHeaderGroup(datagrid.columns[i]);
				}
				if(maxRowHeader < tempHeightRow)
					maxRowHeader = tempHeightRow;
			}
			return maxRowHeader;
		}
		
		private function countRowHeaderGroup(column:ExAdvancedDataGridColumn):int
		{
			var count:int=1;
			var listParentKey:String = column.parent + "%%";
			listParentKey = gridoneImpl.getListParentKey(column.parent,listParentKey);
			if(listParentKey != null && listParentKey != "")
				count += listParentKey.split("%%").length - 1;
			return count;
		}
		

		/*	
		public function addXMLDataTest(sData:String):void
		{
		if(this.datagrid.dataProvider && this.datagrid.dataProvider.length > 0)
		this.datagrid.dataProvider = null;
		var xmldata:XML= new XML(sData); 
		var item:XML;
		for each (var node:XML in xmldata)
		{
		//create my key
		item = <actsone_internal_uid></actsone_internal_uid>;
		node.appendChild(item);
		node.actsone_internal_uid= UIDUtil.createUID();
		}
		this.datagrid.dataProvider= new XMLListCollection(xmldata as XMLList);
		bkDataProvider(xmldata);
		
		//update invisible index order to be used in setRowHide and undoRowHide
		if(this.datagrid.invisibleIndexOrder)
		this.datagrid.invisibleIndexOrder = null;
		//check external scroll
		updateExternalVerticalScroll(xmldata.length());	
		//update Application height when data is changed
		updateGridHeight();
		setTimeout(datagrid.dispatchDataCompleted, 1000);
		}
		*/
		
		/*************************************************************
		 * load data text into DataGrid by httpService			 
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function loadGridData(url:String):void
		{
			parentFuncName = "loadGridData";
			getTextDataByService(url);
		}
		
		private var parentFuncName:String = "";
		private function getTextDataByService(url:String):void
		{
			this.gridone.activity.showBusyBar();
			httpService=new HTTPService;
			httpService.url=url;
			httpService.method="post";
			httpService.resultFormat="text";
			httpService.showBusyCursor=true;
			httpService.addEventListener(ResultEvent.RESULT,textServiceResultHanlder);
			httpService.addEventListener(FaultEvent.FAULT,serviceFaultHanlder);
			httpService.send();
		}
		/*************************************************************
		 * Result handler of loadGridData		 
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function textServiceResultHanlder(event:ResultEvent):void
		{
			this.datagrid.setStyle("verticalGridLines", true);
			var data:String=event.result as String;
			var jsonArray:Array=decodeTextData(data,false,false);
			checkDataProvider(jsonArray,false,parentFuncName);
			this.datagrid.validateDisplayList();
		}
		
		/*************************************************************
		 * Fault handler of loadGridData			 
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function serviceFaultHanlder(event:FaultEvent):void
		{
			Alert.show(event.fault.message);
		}
		
		/*************************************************************
		 * The function get data with text format to bind to datagrid
		 * @param urlStr URL string of server page likes JSP, ASP.			 
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function queryTextData(urlStr:String):void
		{
			parentFuncName = "queryTextData";
			getTextDataByService(urlStr);
		}
		
		/*************************************************************
		 * The function get data with text format to bind to combodata
		 * @param urlStr URL string of server page likes JSP, ASP.
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function queryComboTextData(dataField:String, urlStr:String):void
		{
			httpService=new HTTPService;
			httpService.url=urlStr;
			httpService.request=params;
			httpService.showBusyCursor=true;
			httpService.addEventListener(ResultEvent.RESULT,queryComboServiceResultHanlder);
			httpService.addEventListener(FaultEvent.FAULT,serviceFaultHanlder);
			httpService.send(dataField);
			dataFieldCombo=dataField;
		}
		
		/*************************************************************
		 * Result handler of  queryComboTextData	 
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function queryComboServiceResultHanlder(event:ResultEvent):void
		{
			var data:String=event.result as String;
			this.gridoneImpl.addComboDataAtColumn(dataFieldCombo,data);
		}
		
		/*************************************************************
		 * allow GridOne header layout display
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function setGridOneHeaderVisible(bheader:Boolean):void
		{
			this.gridone.hBoxHeader.includeInLayout=bheader; 
			this.gridone.hBoxHeader.visible=bheader;
			this.gridone.lRowNum.text= "0/0 Rows";
		}
		/*************************************************************
		 * set content for GridOne header layout for display
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function  setHeaderContent(imgurl:String,strText:String):void
		{
			 
				this.gridone.imgHeader.source=imgurl;
				this.gridone.lHeadTitle.text=strText;
				this.gridone.lRowNum.text= "0/0 Rows";
		}
		
		public function setGridOneHeaderTitle(strheader:String):void
		{
			 
			   this.gridone.lHeadTitle.text=strheader; 
 
		}
		
		public function setGridOneHeaderImage(url:String):void
		{
			 
			   this.gridone.imgHeader.source=url;
			 
		}
		
		public function app_ClickHandler(event:MouseEvent):void
		{
 
			if(this.datagrid.eventArr.hasOwnProperty(SAEvent.GRIDONE_CLICK))
			{
				var saVEvent:SAEvent=new SAEvent(SAEvent.GRIDONE_CLICK, true);
				saVEvent.bridgeName=this.gridone.bridgeName;
				this.datagrid.dispatchEvent(saVEvent);
			}
			
		}
		
        /****************************************************************
		 *  This event is used to set second data , in case data > 50 rows.
         *  It useful for loading data performance. 
		 * *************************************************************/
		 
		public function dg_MouseMoveHandler(event:MouseEvent):void
		{

		}
 
		public function setDataSecond(data:Object=null):void
		{
			if (data == null)
			{
			   	data = createEmptyRow();		
			} 
			else
			{
				data[Global.ACTSONE_INTERNAL]= UIDUtil.createUID(); //Update for SetActivation: disable Cell
			}
			
			datagrid.dataProvider.addItem(data);
			datagrid._bkDP.addItem(data);
 
		}
		
		public function LoadRemainData():void
		{  
			if (this.bhaft==true)
			{
				
				for(var k:int=30;k<originData.length;k++)
				{
					setDataSecond(originData[k]);
				}
				
				if(this.datagrid.bExternalScroll)
				{
					updateExternalVerticalScroll(this.datagrid.getLength());
				}
				
				this.gridone.vScroll.maxScrollPosition=this.datagrid.maxVerticalScrollPosition=0;
				
				this.gridone.refresh();
				
				bhaft=false;
				bFirstLoad=true;
				setTimeout(datagrid.dispatchDataCompleted,500);
				
			}
		}
		
		/*************************************************************
		 * event data change of dataGrid. this event is work internally for row index status change.
		 * @author Chheav Hun
		 * ***********************************************************/
		public function collectionChange_handler(event:SAEvent):void
		{
			this.gridone.lRowNum.text=(this.datagrid.selectedIndex +1) + "/" + this.datagrid.dataProvider.length + " Rows";
			if(this.datagrid.eventArr.hasOwnProperty(SAEvent.COLLECTION_CHANGE))
			{
				var saVEvent:SAEvent=new SAEvent(SAEvent.COLLECTION_CHANGE, true);
				saVEvent.totalRow=this.datagrid.dataProvider.length;
				this.datagrid.dispatchEvent(saVEvent);
			}	
		}
		
		
		///******************** moved from ExAdvancedDataGrid *********************************************		
		
		/************************************************
		 * Make CSV data
		 * @author Thuan 
		 * @modify Duong Pham
		 ***********************************************/
		public function makeCSVData():String
		{
			var exportedColumns:Array = [];
			if(excelExportInfo.strColumnKeyList==null||StringUtil.trim(excelExportInfo.strColumnKeyList).length==0)
				exportedColumns =this.datagrid.columns;
			else
			{
				var colArr:Array = excelExportInfo.strColumnKeyList.split(",");	
				if(excelExportInfo.bHeaderOrdering)
				{
					for(j=0;j<this.datagrid.columns.length;j++)
					{
						for(i=0;i<colArr.length;i++)
						{
							if(this.datagrid.columns[j].dataField==colArr[i])
							{
								exportedColumns.push(this.datagrid.columns[j]);
								break;
							}
						}
					}
				}
				else
				{
					for(i=0;i<colArr.length;i++)	
					{
						for(j=0;j<this.datagrid.columns.length;j++)
						{
							if(this.datagrid.columns[j].dataField==colArr[i])
							{
								exportedColumns.push(this.datagrid.columns[j]);
								break;
							}
						}	
					}
				}
			}
			
			var sData:String = "";
			if(excelExportInfo.bHeaderVisible)
			{
				for(var j:int=0;j<exportedColumns.length;j++)
				{
					if(exportedColumns[j].export)	
						sData += (exportedColumns[j].headerText?exportedColumns[j].headerText:exportedColumns[j].dataField) +',';		
				}
				if(sData.length>0)
					sData = sData.slice(0,sData.length-1);
				sData += '\r';
			}
			
			if(!this.datagrid.dataProvider)
			{	
				exportedColumns = [];
				return sData;
			}
			
			var s:String = "";
			var tmp:String="";
			var columnArr:Array;
			for(var i:int=0;i<this.datagrid.dataProvider.length;i++)
			{
				for(j=0;j<exportedColumns.length;j++)
				{
					if(exportedColumns[j].export)
					{
						if(excelExportInfo.bDataFormat)
						{
							s ="";
							if(this.datagrid.dataProvider[i][SummaryBarConstant.TOTAL] != null || this.datagrid.dataProvider[i][SummaryBarConstant.SUB_TOTAL] != null)
							{
								if((this.datagrid.dataProvider[i].hasOwnProperty(SummaryBarConstant.TOTAL) || this.datagrid.dataProvider[i].hasOwnProperty(SummaryBarConstant.SUB_TOTAL))
									&& exportedColumns[j].dataField == this.datagrid.dataProvider[i][SummaryBarConstant.SUMMARY_MERGE_COLUMN])
								{
									this.datagrid.dataProvider[i][exportedColumns[j].dataField] = this.datagrid.lstSummaryBar[this.datagrid.dataProvider[i][SummaryBarConstant.SUMMARY_BAR_KEY]].strText;
								}
								else
								{
									columnArr=this.datagrid.lstSummaryBar[this.datagrid.dataProvider[i][SummaryBarConstant.SUMMARY_BAR_KEY]].strColumnList.split(",");
									tmp = "";
									for(var c:int=0; c<columnArr.length; c++)
									{
										if(columnArr[c] == exportedColumns[j].dataField)
										{
											tmp =  exportedColumns[j].itemToLabel(this.datagrid.dataProvider[i]);
											break;
										}
									}
								}
							}
							if(this.datagrid.dataProvider[i][exportedColumns[j].dataField] != null)
								s =  exportedColumns[j].itemToLabel(this.datagrid.dataProvider[i]);							
							
							s = '"'+ this.datagrid.replaceCellValueWithAsterisk(exportedColumns[j],s,"*")+ '",';							
							sData += s;
						}
						else
						{
							s = "";	
							if(this.datagrid.dataProvider[i][SummaryBarConstant.TOTAL] != null || this.datagrid.dataProvider[i][SummaryBarConstant.SUB_TOTAL] != null)
							{
								if((this.datagrid.dataProvider[i].hasOwnProperty(SummaryBarConstant.TOTAL) || this.datagrid.dataProvider[i].hasOwnProperty(SummaryBarConstant.SUB_TOTAL))
									&& exportedColumns[j].dataField == this.datagrid.dataProvider[i][SummaryBarConstant.SUMMARY_MERGE_COLUMN])
								{
									this.datagrid.dataProvider[i][exportedColumns[j].dataField] = this.datagrid.lstSummaryBar[this.datagrid.dataProvider[i][SummaryBarConstant.SUMMARY_BAR_KEY]].strText;
								}
								else
								{
									tmp = "";
									tmp =  exportedColumns[j].itemToLabel(this.datagrid.dataProvider[i]);
								}
							}
							if(this.datagrid.dataProvider[i][exportedColumns[j].dataField] != null)
								s =  this.datagrid.dataProvider[i][exportedColumns[j].dataField].toString();							
							s = '"'+ this.datagrid.replaceCellValueWithAsterisk(exportedColumns[j],s,"*")+ '",';							
							sData += s;
						}
					}	
				}
				
				if(sData.length>0)
					sData = sData.slice(0,sData.length-1);
				
				sData += '\r';	
			}
			
			if(sData.length>0)
				sData = sData.slice(0,sData.length-1);
			
			exportedColumns = [];
			return sData;
		}
		
		
		/************************************************
		 * Get exported column
		 * @author Duong Pham
		 ***********************************************/
		public function getExportedColumns():Array
		{
			var i:int , j:int;
			var exportedColumns:Array = new Array();
			var strKeyList:String = "";
			var columnInfor:ColumnInfor;
			if(excelExportInfo == null)
			{
				for(j=0;j<this.datagrid.columns.length;j++)
				{
					if (this.datagrid.columns[j].export == true)
					{
						exportedColumns.push(this.datagrid.columns[j]);
					}
				}
			}
			else
			{
				if(excelExportInfo.strColumnKeyList==null||StringUtil.trim(excelExportInfo.strColumnKeyList).length==0)
				{
					for (var k:int = 0; k < this.datagrid.columnCount; k++)
					{
						if (this.datagrid.columns[k].export == true)
						{
							exportedColumns.push(this.datagrid.columns[k]);
						}
					}
				}
				else
				{
					var colArr:Array = excelExportInfo.strColumnKeyList.split(",");	
					if(excelExportInfo.bHeaderOrdering)
					{
						for(j=0;j<this.datagrid.columns.length;j++)
						{
							for(i=0;i<colArr.length;i++)
							{
								if(this.datagrid.columns[j].dataField==colArr[i] && this.datagrid.columns[j].export == true)
								{
									exportedColumns.push(this.datagrid.columns[j]);
									break;
								}
							}
						}
					}
					else
					{
						for(i=0;i<colArr.length;i++)	
						{
							for(j=0;j<this.datagrid.columns.length;j++)
							{
								if(this.datagrid.columns[j].dataField==colArr[i] && this.datagrid.columns[j].export == true)
								{
									exportedColumns.push(this.datagrid.columns[j]);
									break;
								}
							}	
						}
					}
				}
			}
			return exportedColumns;
		}
		
		/************************************************
		 * Get data in html format
		 * @author Thuan 
		 * @modify Duong Pham
		 ***********************************************/
		public function convertDGToHTMLTable():String 
		{
			//header
			var header:String="";
			var nHeightHeader:String="";
			var nFontSizeHeader:String="";
			var strAlignHeader:String="";
			var styleHeaderStr:String="";
			var paddingHeader:String="";
			
			//headersub
			var headerSub:String="";
			
			//footer
			var footer:String="";
			var nHeightFooter:String="";
			var nFontSizeFooter:String="";
			var strAlignFooter:String="";
			var styleFooterStr:String="";
			var paddingFooter:String="";
			
			if(exportUltis)
				exportUltis = null;
			
			exportUltis = new ExportUtils(this.datagrid);
			
			var exportedColumns:Array = getExportedColumns();
			var maxColSpan:int = exportedColumns.length;
			
			if (styleHeader != null)
			{
				//header=styleHeader.data;
				nHeightHeader=" height= '" + styleHeader.row_height.toString() + "'";
				nFontSizeHeader="font-size:" + styleHeader.font_size;
				strAlignHeader='text-align:' + styleHeader.text_align;
				paddingHeader="padding : -1 ";
				styleHeaderStr=" style='" + nFontSizeHeader + ";" + strAlignHeader + ";"; //+ paddingHeader + "'";
				if (styleHeader.data != null)
					header = "<tr><td colspan='" + maxColSpan + "'" + styleHeaderStr + nHeightHeader + ">" + styleHeader.data + "</td></tr>";
			}
			if (styleFooter != null)
			{
				//footer=styleFooter.data;
				nHeightFooter=" height= '" + styleFooter.row_height.toString() + "'";
				nFontSizeFooter="font-size:" + styleFooter.font_size;
				strAlignFooter='text-align:' + styleFooter.text_align;
				styleFooterStr=" style='" + nFontSizeFooter + ";" + strAlignFooter + "'";
				if (styleFooter.data != null)
					footer = "<tr><td colspan='" + maxColSpan + "'" + styleFooterStr + nHeightFooter + ">" + styleFooter.data + "</td></tr>";
			}
			if (subHeaderStyle != null)
			{
				for (var m:int=0; m < subHeaderStyle.length; m++)
				{
					if ((subHeaderStyle[m] as StyleHeader).data != null)
						headerSub += "<tr><td colspan='" + maxColSpan + "' style='text-align: right; color : red'>" + (subHeaderStyle[m] as StyleHeader).data + "</td></tr> ";
				}
			}
			
			var headerDepth:int = this.datagrid.headerRowInfor.length;
			var strData:String = "<html xmlns:o='urn:schemas-microsoft-com:office:office' " + 
				"xmlns:x='urn:schemas-microsoft-com:office:excel' " +
				"xmlns='http://www.w3.org/TR/REC-html40'> " + 
				"<head><meta http-equiv='content-type' content='text/html' charset='utf-8'></head><body>";
			var acData:Object;
			
			if (this.datagrid.isTree)
			{
				acData = (((this.datagrid.dataProvider as HierarchicalCollectionView).source as ExIHierarchicalData).source as ArrayCollection);	
			}
			else
			{
				if (this.datagrid.dataProvider is ArrayCollection)
				{
					acData = this.datagrid.dataProvider as ArrayCollection;
				}
				else if (this.datagrid.dataProvider is ListCollectionView)
				{
					acData = this.datagrid.dataProvider as ListCollectionView;
				}
			}
			strData += "<table border='1'><thead>" + header + headerSub;
			
			if (excelExportInfo && excelExportInfo.bHeaderVisible)
			{
				strData += exportUltis.makeHeader(headerDepth,exportedColumns);
			}
			strData += "</thead><tbody>"; 
			if (this.datagrid.isMergeOrderPriority)
				strData += exportUltis.makeDataOrderInMerged(acData, exportedColumns);
			else
				strData += exportUltis.makeDataWithoutOrderInMerged(acData, exportedColumns);
			strData += footer;
			strData += "</tbody></table>"; 
			strData += "</body></html>";
			
			return strData; 
		}
		//*************************************************************************************************************************
	}
	
}