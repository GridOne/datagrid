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
	import com.brokenfunction.json.encodeJson;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.KeyboardEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileReference;
	import flash.ui.Keyboard;
	import flash.ui.KeyboardType;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import flashx.textLayout.formats.Float;
	
	import kr.co.actsone.controls.ExAdvancedDataGrid;
	import kr.co.actsone.controls.ExAdvancedDataGridBaseEx;
	import kr.co.actsone.controls.advancedDataGridClasses.ExAdvancedDataGridColumn;
	import kr.co.actsone.controls.advancedDataGridClasses.ExAdvancedDataGridColumnGroup;
	import kr.co.actsone.controls.advancedDataGridClasses.ExAdvancedDataGridHeaderRenderer;
	import kr.co.actsone.events.ExAdvancedDataGridEventReason;
	import kr.co.actsone.events.SAEvent;
	import kr.co.actsone.export.ExcelExportInfo;
	import kr.co.actsone.export.ExcelFileType;
	import kr.co.actsone.export.StyleFooter;
	import kr.co.actsone.export.StyleHeader;
	import kr.co.actsone.filters.FilterDataWithRowHide;
	import kr.co.actsone.importcsv.FileManager;
	import kr.co.actsone.itemRenderers.SubTotalRenderer;
	import kr.co.actsone.itemRenderers.TotalRenderer;
	import kr.co.actsone.summarybar.SummaryBar;
	import kr.co.actsone.summarybar.SummaryBarConstant;
	import kr.co.actsone.summarybar.SummaryBarManager;
	import kr.co.actsone.utils.ConvertProperty;
	import kr.co.actsone.utils.ErrorMessages;
	
	import mx.collections.ArrayCollection;
	import mx.collections.CursorBookmark;
	import mx.collections.HierarchicalCollectionView;
	import mx.collections.IViewCursor;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.collections.XMLListCollection;
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.core.ClassFactory;
	import mx.core.FlexGlobals;
	import mx.core.INavigatorContent;
	import mx.events.CloseEvent;
	import mx.managers.CursorManager;
	import mx.managers.PopUpManager;
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	import mx.utils.UIDUtil;
	
	public class GridOneImpl
	{
		protected var gridone:GridOne;
		public var tempCols:ArrayCollection=new ArrayCollection();
		private var err:ErrorMessages=new ErrorMessages();
		public var isDrawUpdate:Boolean=true;
		public var _columnCount:int=0;
		public var waitingLogo:Image=new Image();
	 
		public var rowStatus:RowStatus =new RowStatus(); 
		public var currentpage:int=0;
		public var pageNum:int=1;
		
	    public var excelFileName:String="datagrid";
		//public var params:Object=null;							
		
		public function GridOneImpl(app:Object)
		{
			gridone=app as GridOne;
		}

		public function get datagrid():ExAdvancedDataGrid
		{
			return gridone.datagrid;
		}							
		
		public function get dgManager():DataGridManager
		{
			return gridone.dgManager;
		}	
		
		public function get gridoneManager():GridOneManager
		{
			return gridone.gridoneManager;
		}	
		
		 
		/*************************************************************
		 * add header for grid
		 * @param columnKey column dataField 
		 * @param columnText header text
		 * @param columnType column type: combo, text, calendar...
		 * @param maxLength length of text in a cell, or length of a number
		 * @param columnWidth column width
		 * @param editable indicate whether column is editable or not
		 * @return ExAdvancedDataGridColumn
		 * ***********************************************************/
		public function createHeader(columnKey:String="", columnText:String="", columnType:String="", maxLength:String="", columnwidth:String="", editable:Boolean=true,property:String=""):ExAdvancedDataGridColumn
		{
			var col:ExAdvancedDataGridColumn=new ExAdvancedDataGridColumn();
			
			col.subTotalRenderer=new ClassFactory(SubTotalRenderer);
			col.totalRenderer=new ClassFactory(TotalRenderer);
			
			col.minWidth=0;
			col.dataField=columnKey;
			col.headerText=columnText;				
			col.editable = editable;
			if (editable)
				col.cellActivation=Global.ACTIVATE_EDIT;
			else
				col.cellActivation=Global.ACTIVATE_ONLY;
						
			if (columnwidth.charAt(columnwidth.length - 1) == "%")
			{
				col.percentWidth=columnwidth;
			}
			else
			{
				col.width=parseInt(columnwidth);
			}
			
			datagrid.totalVisibleColumnWidth += parseInt(columnwidth);
			
			col.orginalMaxLength=maxLength;		
			
			if (Number(maxLength) < 0 ) //Process for using big number
			{
				if(columnType.toUpperCase() == ColumnType.NUMBER)
				{
					var arr:Array = maxLength.toString().split(".");
					var precLength: int = -1;
					if (arr.length > 1)
						precLength = parseInt(arr[1]);
					col.precision = precLength;
					col.checkPrecision = precLength;
					col.maxValue = Number.MAX_VALUE;	
				}
			}
			else if (parseInt(maxLength) >= 0)
			{
				if(columnType.toUpperCase() == ColumnType.NUMBER)
				{
					var precisionLength:int=parseInt(maxLength.toString().split(".")[1]);
					var numberLength:int=parseInt(maxLength.toString().split(".")[0]);
					if(numberLength==0)
					col.maxValue = Math.pow(10, numberLength) - Math.pow(0.1, precisionLength+1);
					col.precision = precisionLength;
					col.checkPrecision=precisionLength;
				}
				else
				{
					col.maxLength=parseInt(maxLength);
					col.editorMaxChars=parseInt(maxLength);	
				}
			}
			
			if (property !="")
			{
			    var params:Object= new Object();
			    params.textAlign=property;
			}
			
			if (params !=null)
			{
				var objectInfo:Object=ObjectUtil.getClassInfo(params);
				for each (var qname:QName in objectInfo.properties)
				{
					var propertyName:String=qname.localName;
					var propertyValue:String=params[qname.localName];
					if (col.hasOwnProperty(propertyName))
						this.dgManager.setColumnProperty(col, propertyName, propertyValue);
					else
						this.dgManager.setStyleForObject(col, propertyName, propertyValue);
				}
			}
			
			col.type=columnType.toUpperCase();
			this.gridone.setItemRenderer(col,col.type,false);	
			
			tempCols.addItem(col);
			_columnCount += 1;
//			tempCols.push(col);
			return col;						
		}
		
		/*************************************************************
		 * Bound header after adding headers
		 * ***********************************************************/
		public function boundHeader():void
		{			
			for (var i:int=0; i< tempCols.length; i++)
			{
				if(tempCols[i] is ExAdvancedDataGridColumnGroup && (tempCols[i] as ExAdvancedDataGridColumnGroup).isGroup)
				{
					this.datagrid._isGroupedColumn = true;
					break;
				}
			}
			if(this.datagrid._isGroupedColumn)
			{
				this.datagrid.groupedColumns = tempCols.toArray();
				var cols:Array = new Array(); 
				cols = convertGroupColumn(tempCols.toArray() , cols)
				this.datagrid.columns = cols;
				this.dgManager.setColumnDataFieldIndex(cols);
			}
			else
			{
				this.datagrid.columns = tempCols.toArray();
				this.dgManager.setColumnDataFieldIndex(tempCols.toArray());
			}			
			this.datagrid.visible=true;
			datagrid.selectedIndex=0;
			setTimeout(dispatchBoundHeaderEvent,200);
//			else
//				this.gridone.activity.closeBusyBar();
			
			//verify which horizontal scroll bar and vertical scroll bar is used
			dgManager.updateExternalScrollBar();
		}

		/*************************************************************
		 * dispatch bound header complete
		 * ***********************************************************/
		private function dispatchBoundHeaderEvent():void
		{
//			this.gridone.activity.closeBusyBar();
			
			//update Application height when data is changed
			gridoneManager.updateGridHeight();
			
			this.datagrid.dispatchEvent(new SAEvent(SAEvent.BOUND_HEADER_COMPLETE));
		}
		
		/*************************************************************
		 * set property or style for datagrid
		 * ***********************************************************/
		public function setDataGridProperty(name:String, value:Object):void
		{
			if (ConvertProperty.proObj.hasOwnProperty(name))
			{
				name = ConvertProperty.proObj[name];
			}
			if (this.datagrid.hasOwnProperty(name) && ConvertProperty.headerStyleObj[name] == null)
				this.dgManager.setDataGridProperty(name, value);
			else
				this.dgManager.setStyleForObject(this.datagrid, name, value);
		}
		
		/*************************************************************
		 * set column property
		 * author: Toan Nguyen
		 * ***********************************************************/
		public function setColumnProperty(dataField:String, name:String, value:Object):void
		{
			try
			{
				var selectedCol:Object;
				selectedCol = this.gridone.getColumnByDataField(dataField);
				if(selectedCol==null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (selectedCol.hasOwnProperty(name))
					this.dgManager.setColumnProperty(selectedCol, name, value);
				else
					this.dgManager.setStyleForObject(selectedCol, name, value);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColumnProperty");
			}
		}

		
		/*************************************************************
		 * set column header checkbox visible
		 * author: Duong Pham
		 * ***********************************************************/
		public function setColHDCheckBoxVisible(strColKey:String, bVisible:Boolean, bChangeCellEvent:Boolean=false):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(strColKey) as ExAdvancedDataGridColumn;
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (bVisible)
				{
					this.gridone.setItemRenderer(col, ColumnType.CHECKBOX, true);
				}
				else
				{
					col.headerRenderer=new ClassFactory(ExAdvancedDataGridHeaderRenderer);
					col.isCheckBoxHeaderRenderer=false;
				}
				col.bChangeCellEvent=bChangeCellEvent;
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColHDCheckBoxVisible");
			}
		}
		
		/*************************************************************
		 * add group column for grid		 
		 * ***********************************************************/
		public function createGroup(groupKey:String, groupName:String):ExAdvancedDataGridColumnGroup
		{
			var col:ExAdvancedDataGridColumnGroup=new ExAdvancedDataGridColumnGroup();			
			col._dataFieldGroupCol=groupKey;
			col.headerText=groupName;
			col.isGroup=true;
			this.tempCols.addItem(col);
//			this.tempCols.push(col);
			return col;
		}
		
		/*************************************************************
		 * append header into group column		 
		 * ***********************************************************/
		public function appendHeader(groupKey:String, columnKey:String):void
		{
			try
			{
				var groupObj:Object=getTempCol(groupKey);				
				if (groupObj == null)				
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(groupObj.addedColumn is ExAdvancedDataGridColumnGroup && (groupObj.addedColumn as ExAdvancedDataGridColumnGroup).isGroup)
				{
					var colObj:Object=getTempCol(columnKey);
					if (colObj == null)
						err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
					if(colObj.addedColumn is ExAdvancedDataGridColumn)
					{
						(colObj.addedColumn as ExAdvancedDataGridColumn).parent=groupKey;						
						//tempCols.splice(colObj.index,1);						
						(groupObj.addedColumn as ExAdvancedDataGridColumnGroup).children.push(colObj.addedColumn as ExAdvancedDataGridColumn);
					}
					else if(colObj.addedColumn is ExAdvancedDataGridColumnGroup)
					{
						(colObj.addedColumn as ExAdvancedDataGridColumnGroup).parent = groupKey;
//						tempCols.splice(colObj.index,1);						
						(groupObj.addedColumn as ExAdvancedDataGridColumnGroup).children.push(colObj.addedColumn as ExAdvancedDataGridColumnGroup);
					}
				}
				if(groupObj.index > colObj.index)
				{
					tempCols.removeItemAt(groupObj.index);
					tempCols.removeItemAt(colObj.index);
					tempCols.addItemAt(groupObj.addedColumn,colObj.index);
				}
				else
				{
					tempCols.removeItemAt(colObj.index);					
				}
				
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"appendHeader");
			}
		}
		
		/*************************************************************
		 * get column from tempCol	 
		 * ***********************************************************/
		private function getTempCol(dataField:String):Object
		{			
			var result:Object = null;
			var index:int = -1;
			for each (var col:Object in tempCols)
			{
				index++;
				if(col is ExAdvancedDataGridColumnGroup)
				{
					if ((col as ExAdvancedDataGridColumnGroup)._dataFieldGroupCol == dataField)
					{
						result = new Object();
						result["addedColumn"] = col;
						result["index"] = index;
						break;
					}
				}
				else if(col is ExAdvancedDataGridColumn)
				{
					if (col.dataField == dataField)
					{
						result = new Object();
						result["addedColumn"] = col;
						result["index"] = index;
						break;
					}
				}					
			}
			return result;
		}
		
		/*************************************************************
		 * get column from tempCol	 
		 * ***********************************************************/
		public function convertGroupColumn(groupCol:Array , result:Array):Array
		{
			for each (var item:Object in groupCol)
			{				
				if(item is ExAdvancedDataGridColumnGroup && (item as ExAdvancedDataGridColumnGroup).children.length > 0)
				{
					convertGroupColumn((item as ExAdvancedDataGridColumnGroup).children , result);
				}
				else
					result.push(item);
			}
			return result;
		}
				
		/*************************************************************
		 * set text for group header		 
		 * ***********************************************************/
		public function setGroupHDText(strGroupKey:String, strText:String):void
		{
			try
			{				
				var groupCol:ExAdvancedDataGridColumnGroup= this.gridone.getColumnByDataField(strGroupKey,true) as ExAdvancedDataGridColumnGroup;;
				if (groupCol == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				groupCol.headerText=strText;
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setGroupHDText");
			}
		}
		

		
		/*************************************************************
		 * set Column header align
		 * ***********************************************************/	
		public function setColHDAlign(strColumnKey:String, strAlign:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn;
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.setColumnProperty(strColumnKey, "headerTextAlign", strAlign);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColHDAlign");
			}
		}

		
		/*************************************************************
		 * Set the col fix: Keep column(s) is visible while using horizontal scrolls
		 * @param columnKey The name of dataField column
		 * @author Thuan 
		 * @modified by Duong Pham
		 * ***********************************************************/		
		public function setColFix(columnKey:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = ExAdvancedDataGridColumn(this.gridone.getColumnByDataField(columnKey));
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				
				var index:int=-1;
				var listParentKey:String = "";
				var arrParent:Array; 
				var parentCol:ExAdvancedDataGridColumnGroup;
				var childColumn:ExAdvancedDataGridColumn;
				var lockColumnIndex:int=0;
				if(this.datagrid._isGroupedColumn)
				{
					if(col.parent == "" || col.parent == null)
					{
						for (index=0 ; index<this.datagrid.groupedColumns.length; index++)
						{
							if(this.datagrid.groupedColumns[index] is ExAdvancedDataGridColumn && (this.datagrid.groupedColumns[index] as ExAdvancedDataGridColumn).dataField == columnKey)
								break;
						}
						lockColumnIndex = index + 1;
						this.setDataGridProperty("lockedColumnCount", lockColumnIndex);
						return;
					}
					else if(col.parent != null && col.parent != "")
					{
						listParentKey += col.parent + "%%";
						listParentKey = getListParentKey(ExAdvancedDataGridColumn(col).parent,listParentKey);
						if(listParentKey != "")
						{
							listParentKey = listParentKey.slice(0,listParentKey.length-2);
							arrParent = listParentKey.split("%%");
							parentCol = gridone.getColumnByDataField(arrParent[arrParent.length-1]) as ExAdvancedDataGridColumnGroup;
						}
					}
					else		//ExAdvancedDataGridColumnGroup
					{
						
						if(ExAdvancedDataGridColumnGroup(col).parent != "")
						{
							listParentKey = ExAdvancedDataGridColumnGroup(col).parent + "%%" ;
							listParentKey = getListParentKey(ExAdvancedDataGridColumnGroup(col).parent,listParentKey);
						}
						if(listParentKey != "")
						{
							listParentKey = listParentKey.slice(0,listParentKey.length-2);
							arrParent = listParentKey.split("%%");
							parentCol = gridone.getColumnByDataField(arrParent[arrParent.length-1]) as ExAdvancedDataGridColumnGroup;						
						}
					}
					for (var i:int=0 ; i<this.datagrid.groupedColumns.length; i++)
					{
						var tmpCol:Object = this.datagrid.groupedColumns[i];
						if(tmpCol.visible)
							index ++;
						if((tmpCol is ExAdvancedDataGridColumnGroup) && ExAdvancedDataGridColumnGroup(tmpCol).isGroup == true
							&& parentCol && ExAdvancedDataGridColumnGroup(tmpCol)._dataFieldGroupCol == parentCol._dataFieldGroupCol)
							break;
					}
					lockColumnIndex = index + 1;
				}
				else
				{
					var cols:Array;
					if(tempCols.length > 0)
						cols = tempCols.toArray();
					else if(this.datagrid.columns.length > 0)
						cols = this.datagrid.columns;
					for each (var column:ExAdvancedDataGridColumn in cols)
					{
						if(column.visible)
						{
							index ++;
							if(column.dataField == columnKey)
								break;
						}
					}			
					lockColumnIndex = index + 1;
				}	
				this.setDataGridProperty("lockedColumnCount", lockColumnIndex);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColFix");
			}
		}		
		
		/*************************************************************
		 * Reset the col fix: column unfix
		 * @param strColumnKey The name of dataField column
		 * @author Thuan 
		 * ***********************************************************/		
		public function resetColFix():void
		{
			try
			{
				this.setDataGridProperty("lockedColumnCount", 0);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"resetColFix");
			}
		}
		
		/*************************************************************
		 * Set the row fix: Keep row(s) is visible while using vertical scrolls
		 * @param strColumnKey The name of dataField column
		 * @author Thuan
		 * ***********************************************************/		
		public function setRowFix(rowIndex:int):void
		{ 					
			//Associated with this.setDataGridProperty("lockedRowCount", rowIndex);
			try
			{
				if(rowIndex > this.datagrid.rowCount ||  rowIndex < 1)
				{
					err.throwError(ErrorMessages.ERROR_ROWINDEX_INVALID, Global.DEFAULT_LANG);
				}
				this.datagrid.lockedRowCount = rowIndex;
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setRowFix");
			}
		}	
		
		/*************************************************************
		 * Set the row fix: Row unfix
		 * @param strColumnKey The name of dataField column
		 * @author Thuan
		 * ***********************************************************/		
		public function resetRowFix():void
		{					
			//Associated with this.setDataGridProperty("lockedRowCount", 0);
			try
			{
				this.datagrid.lockedRowCount = 0;
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"resetRowFix");
			}
		}	
 	
		
		/*************************************************************
		 * setColCellAlign: Set alignment of a column text
		 * @param columnKey The name of dataField column
		 * @param strAlign Left/Center/Right/Justify
		 * @author Thuan
		 * ***********************************************************/				
		public function setColCellAlign(columnKey:String, strAlign:String):void
		{
			try
			{	
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.public::setStyle("textAlign", strAlign);
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellAlign");
			}					
		}		
		
//		/*************************************************************
//		 * getColType: Get Type of Column
//		 * @param columnKey The name of dataField column
//		 * @author Thuan
//		 * @modified by Duong Pham 
//		 * @reason: duplicate function in datagridmanager ( dgManager.getColumnType(columnKey) ) 
//		 * ***********************************************************/			
//		public function getColType(columnKey:String):String
//		{
//			var colType:String = '';
//			try
//			{
//				colType = dgManager.getColumnType(columnKey);
//			}
//			catch(error:Error)
//			{
//				err.throwMsgError(error.message,"getColType");
//			}
//			return colType;
//		}
				
		/*************************************************************
		 * setColCellBgColor: Set background color to column
		 * @param columnKey The name of dataField column
		 * @author Thuan
		 * ***********************************************************/			
		public function setColCellBgColor(columnKey:String, color:String):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				col.public::setStyle("backgroundColor", color);
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellBgColor");
			}
		}		
		
		/*************************************************************
		 * setColCellFgColor: Set foreground color to column
		 * @param columnKey The name of dataField column
		 * @author Thuan
		 * ***********************************************************/			
		public function setColCellFgColor(columnKey:String, color:String):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				col.public::setStyle("color", color);
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellFgColor");
			}
		}	
		
		/*************************************************************
		 * set column cell font
		 * @param columnKey The name of dataField column
		 * @param fontName Font nam
		 * @param bBold Whether font bold
		 * @param bItalic Whether font italic
		 * @param bUnderLine Whether font underline
		 * @param bCenterLine Whether font strikethrough
		 * @param nSize Font size
		 * @author Thuan
		 * ***********************************************************/
		public function setColCellFont(columnKey:String, fontName:String, nSize:Number, bBold:Boolean, bItalic:Boolean, bUnderLine:Boolean, bCenterLine:Boolean):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn= gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				col.public::setStyle("fontFamily", fontName);
				if (!isNaN(nSize))
				{
					col.public::setStyle("fontSize",nSize);
				}
				if(bBold)
				{
					col.public::setStyle("fontWeight","bold");
				}
				else
				{
					col.public::setStyle("fontWeight","normal");
				}
				if(bItalic)
				{
					col.public::setStyle("fontStyle","italic");
				}
				else
				{
					col.public::setStyle("fontStyle","normal");
				}
				if(bUnderLine)
				{
					col.public::setStyle("textDecoration","underline");
				}
				else
				{
					col.public::setStyle("textDecoration","none");
				}
				col.bCellFontCLine=bCenterLine;
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellFont");					
			}
		}		
		
		/*************************************************************
		 * set column cell font bold
		 * @param columnKey Name of datafield
		 * @param bBold Whether font is bold
		 * @author Thuan
		 * ***********************************************************/
		public function setColCellFontBold(columnKey:String, bBold:Boolean):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.public::setStyle("fontWeight",bBold?"bold":"normal");
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellFontBold");					
			}
		}		
		
		/*************************************************************
		 * set column cell font italic
		 * @param columnKey Name of datafield
		 * @param bItalic Whether font is italic
		 * @author Thuan
		 * ***********************************************************/
		public function setColCellFontItalic(columnKey:String, bItalic:Boolean):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				col.public::setStyle("fontStyle",bItalic?"italic":"normal");
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellFontItalic");	
			}
		}		
		
		/*************************************************************
		 * set column cell font name
		 * @param columnKey Name of datafield
		 * @param fontName Font name in column
		 * @author Thuan
		 * ***********************************************************/
		public function setColCellFontName(columnKey:String, fontName:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				if (fontName != null && fontName != "")
				{
					col.public::setStyle("fontFamily",fontName);
				}
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellFontName");	
			}
		}	
		
		/*************************************************************
		 * set column cell font size
		 * @param columnKey Name of datafield
		 * @param nSize Font size in column
		 * @author Thuan
		 * ***********************************************************/
		public function setColCellFontSize(columnKey:String, nSize:Number):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if(col == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				if (isNaN(nSize))
				{
					err.throwError(ErrorMessages.ERROR_NUMBER, Global.DEFAULT_LANG);
				}
				col.public::setStyle("fontSize",nSize);
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellFontSize");	
			}
		}		
		
		/*************************************************************
		 * set column cell font underline
		 * @param columnKey Name of datafield
		 * @param bUnderLine Whether font is underline
		 * @author Thuan
		 * ***********************************************************/
		public function setColCellFontULine(columnKey:String, bUnderLine:Boolean):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.public::setStyle("textDecoration",bUnderLine?"underline":"none");
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message, "setColCellFontULine");	
			}
		}
		
		/*************************************************************
		 * set column cell font center line
		 * @param columnKey Name of datafield
		 * @param bCenterLine Whether font is center line
		 * @author Duong Pham
		 * ***********************************************************/
		public function setColCellFontCLine(columnKey:String, bCenterLine:Boolean):void
		{
			try
			{
				if (this.datagrid.dataFieldIndex[columnKey] == null)					
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);									
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				col.bCellFontCLine = bCenterLine;
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellFontCLine");	
			}
		}
		
		/*************************************************************
		 * set column cell merge
		 * @param columnKey Name of datafield
		 * @param bMerge Whether font is merge
		 * @author Duong Pham
		 * ***********************************************************/
		public function setColCellMerge(columnKey:String, bMerge:Boolean):void
		{
			try
			{
				if (this.datagrid.dataFieldIndex[columnKey] == null)					
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);									
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				col.merge = bMerge;
				this.datagrid.getGroupMergeInfo();
				if(this.datagrid.draggableColumns)
					this.datagrid.draggableColumns = !bMerge;
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellMerge");	
			}
		}

		
	
		
		/*************************************************************
		 * get column header visible key
		 * ***********************************************************/
		public function getColHDVisibleKey(index:int):String
		{
			try
			{
				var result:String = "";
				var col:ExAdvancedDataGridColumn = this.datagrid.columns[index];
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				result = col.dataField;			
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"getColHDVisibleKey");
			}
			return result;			
		}
		

		
		/*************************************************************
		 * set column header text
		 * @param strColumnKey string of data filed 
		 * @param strText string of text
		 * ***********************************************************/
		public function setColHDText(strColumnKey:String, strText:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.headerText = strText;
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColHDText");
			}			
		}
 
		/*************************************************************
		 * Get column header background color
		 * @param columnKey:String
		 * ***********************************************************/
		public function setColHDBgColor(columnKey:String, strColor:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.public::setStyle("headerBackgroundColor", strColor);
				this.datagrid.invalidateList();
//				gridoneManager.setTempColumnProperty(columnKey, "headerBackgroundColor", strColor);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColHDBgColor");
			}
		}
		
		/*************************************************************
		 * set color of column header
		 * @param columnKey:String 
		 * @param color:String
		 * ***********************************************************/
		public function setColHDFgColor(columnKey:String, color:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.public::setStyle("headerColor", color);
				this.datagrid.invalidateList();
//				gridoneManager.setTempColumnProperty(columnKey, "headerColor", color);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColHDFgColor");
			}
		}
		
		/*************************************************************
		 * set group header font color and background color
		 * @param columnKey:String ,strFgColor:String,strBgColor:String
		 * author: Duong Pham
		 * ***********************************************************/
		public function setGroupHDColor(strGroupKey:String, strFgColor:String, strBgColor:String):void
		{
			try
			{
				var groupCol:ExAdvancedDataGridColumnGroup=this.gridone.getColumnByDataField(strGroupKey,true) as ExAdvancedDataGridColumnGroup;
				if (groupCol == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (groupCol.isGroup)
				{
					var strColor:String="";
					
					if (strFgColor != null && strFgColor != "")
					{
						if (strFgColor.search("#") == 0)
							strColor=strFgColor.toString().replace("#", "0x");
						else
							strColor=strFgColor;
						groupCol.public::setStyle("headerColor", strFgColor);
//						gridoneManager.setDefaultColumnProperty(strGroupKey, "headerColor", strFgColor);
					}
					if (strBgColor != null && strBgColor != "")
					{
						if (strBgColor.search("#") == 0)
							strColor=strBgColor.toString().replace("#", "0x");
						else
							strColor=strBgColor;
						groupCol.public::setStyle("headerBackgroundColor", strBgColor);
//						gridoneManager.setDefaultColumnProperty(strGroupKey, "headerBackgroundColor", strBgColor);
					}
					this.datagrid.invalidateList();
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setGroupHDColor");					
			}
		}
		
		/*************************************************************
		 * set group header font		  
		 * ***********************************************************/
		public function setGroupHDFont(strGroupKey:String, strFontName:String, nSize:Number, bBold:Boolean, bItalic:Boolean, bUnderLine:Boolean, bCenterLine:Boolean):void
		{
			try
			{
				var groupCol:ExAdvancedDataGridColumnGroup = this.gridone.getColumnByDataField(strGroupKey,true) as ExAdvancedDataGridColumnGroup;
				if (groupCol == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (isNaN(nSize))
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				if (strFontName != "" && strFontName != null)
				{
					groupCol.public::setStyle("fontFamily", strFontName);
				}
				groupCol.public::setStyle("fontSize", nSize);
				if (bBold)
				{
					groupCol.public::setStyle("fontWeight", "bold");
				}
				else
				{
					groupCol.public::setStyle("fontWeight", "normal");
				}
				if (bItalic)
				{
					groupCol.public::setStyle("fontStyle", "italic");
				}
				else
				{
					groupCol.public::setStyle("fontStyle", "normal");
				}
				if (bUnderLine)
				{
					groupCol.public::setStyle("textDecoration", "underline");
				}
				else
				{
					groupCol.public::setStyle("textDecoration", "none");
				}
				datagrid.bHDFontCLine=bCenterLine;
				groupCol.bHDFontCLine=bCenterLine;					
				this.datagrid.invalidateList();				
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setGroupHDFont");					
			}
		}
		
		/*************************************************************
		 * set tree mode	  
		 * ***********************************************************/
		public function setTreeMode(strTreeColumnKey:String, strRootKey:String, strDelimiter:String):void
		{
			try
			{
				datagrid.summaryBar.clearSort();
				if(this.datagrid.dataFieldIndex[strTreeColumnKey] == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.treeInfo=[strRootKey,strDelimiter];
				var currentCols:Array;				
				if(this.datagrid.columns.length > 0)
					currentCols = this.datagrid.columns;
				else
					currentCols = this.tempCols.toArray();
				var itemCol:Object;
				for each(itemCol in currentCols)
				{
					if(itemCol is ExAdvancedDataGridColumn && (itemCol as ExAdvancedDataGridColumn).dataField == strTreeColumnKey)
					{
						(itemCol as ExAdvancedDataGridColumn).type = ColumnType.TREE;
						break;
					}
					if(itemCol is ExAdvancedDataGridColumnGroup)
					{
						var groupCol:ExAdvancedDataGridColumnGroup = itemCol as ExAdvancedDataGridColumnGroup;
						itemCol = dgManager.getChildrenColByGroupCol(strTreeColumnKey, groupCol);	
						if(itemCol)
							break;
					}
				}
				datagrid.isTree=true;
				datagrid.treeDataField=strTreeColumnKey;	
				datagrid.treeColumn = itemCol as ExAdvancedDataGridColumn;				
				this.gridone.setItemRenderer(itemCol as ExAdvancedDataGridColumn, ColumnType.TREE,false);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setTreeMode");					
			}
		}
		
		/*************************************************************
		 * add a object or text row.
		 * @param object will be added.
		 * ***********************************************************/
		public function addRow(row:Object=null):void
		{
			
		  if (this.datagrid.dataProvider as ArrayCollection)
		  {
			  if(datagrid.summaryBar && this.datagrid.summaryBar.hasSummaryBar())
			  {
				  this.datagrid.summaryBar.clearSort();
				  this.datagrid.summaryBar.resetSummaryBar();
			  }
			  if(this.datagrid.columns==null || this.datagrid.columns.length==0)
				  return;
			  if (row == null)
			  {
				  row = this.gridone.gridoneManager.createEmptyRow();		
			  } 
			  else
			  {
				  row[Global.ACTSONE_INTERNAL]= UIDUtil.createUID(); //Update for SetActivation: disable Cell
			  }
			  setCRUDRowValue(row, this.datagrid.strInsertRowText, Global.CRUD_INSERT);
			  if (datagrid.dataProvider == null)
				  datagrid.dataProvider=new ArrayCollection([]);			
			  
			  if (datagrid._bkDP == null)
				  datagrid._bkDP=new ArrayCollection([]);
			  
			  datagrid.dataProvider.addItem(row);
			  datagrid._bkDP.addItem(row);
			  var index:int=(datagrid.dataProvider as ArrayCollection).getItemIndex(row);
			  rowStatus._arrRAdd.push(index);
			   
		  }
 
			this.datagrid.selectedItem=row;
			
			//update Application height when data is changed
			gridoneManager.updateGridHeight();
			
			if(this.datagrid.bExternalScroll)
			{
				gridoneManager.updateExternalVerticalScroll(this.datagrid.getLength());
			}
			if (this.datagrid.dataProvider.length > this.datagrid.rowCount)
			{
				this.gridone.vScroll.scrollPosition=this.datagrid.maxVerticalScrollPosition=this.datagrid.maxVerticalScrollPosition + 1;
				this.datagrid.verticalScrollPosition=this.datagrid.maxVerticalScrollPosition;
			}
			else
			{
				this.gridone.vScroll.maxScrollPosition=this.datagrid.maxVerticalScrollPosition=0;
			}
			
			if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
			{
				this.datagrid.summaryBar.reCreateSummaryBar(true);
				this.datagrid.summaryBar.clearSort();
			}
				
			//update group mergeCells of datagrid
			if(hasGroupMerge())
			{
				this.datagrid.getGroupMergeInfo();
			}
			
			if(isDrawUpdate)
				this.datagrid.invalidateList();
//			this.datagrid.numberOfRow = this.datagrid._bkDP.length; 
			
		}
				
		/*************************************************************
		 * add a object or text row at an index.
		 * @param row object or text row will be added.
		 * @param index index of row will be added.
		 * ***********************************************************/
		public function addRowAt(row:Object, index:int):void
		{
			if(this.datagrid.summaryBar && this.datagrid.summaryBar.hasSummaryBar())
			{
				this.datagrid.summaryBar.resetSummaryBar();
			}
			
			this.datagrid.setStyle("verticalGridLines", true);	
			this.datagrid.summaryBar.clearSort();
			if (row == null)
			{
				row=this.gridone.gridoneManager.createEmptyRow();				
			}
			setCRUDRowValue(row, this.datagrid.strInsertRowText , Global.CRUD_INSERT);
			if (datagrid.dataProvider == null)
				datagrid.dataProvider=new ArrayCollection([]);
			
			if (datagrid._bkDP == null)
				datagrid._bkDP=new ArrayCollection([]);
			
			if (index < 0)
				index=0;
			else if (index >= datagrid._bkDP.length)
				index=datagrid._bkDP.length;
			var insertedIndex:int;	
			if(index==datagrid._bkDP.length)
				insertedIndex = this.datagrid.getLength();
			else				
				insertedIndex= index;				
			
			datagrid.dataProvider.addItemAt(row, insertedIndex);
			datagrid._bkDP.addItemAt(row,index);
			rowStatus._arrRAdd.push(index);
			//update Application height when data is changed
			gridoneManager.updateGridHeight();
			if(this.datagrid.bExternalScroll)
			{
				gridoneManager.updateExternalVerticalScroll(this.datagrid.getLength());
			}
			
			this.scrollToIndex(index); 
			
			if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
			{
				this.datagrid.summaryBar.reCreateSummaryBar(true);
			}
			//update group mergeCells of datagrid
			if(hasGroupMerge())
			{
				this.datagrid.getGroupMergeInfo();
			}
			if(isDrawUpdate)
				this.datagrid.invalidateList();
			
//			this.datagrid.numberOfRow = this.datagrid._bkDP.length; 
			
//			this.datagrid.summaryBarManager.resetSort();
//			this.datagrid.numberOfRow = this.datagrid._bkDP.length;
		}
		
		/*************************************************************
		 * set focus and scroll to a row.
		 * @param row row index of the cell.
		 * ***********************************************************/
		public function scrollToIndex(rowIndex:int):void
		{
			if (datagrid.dataProvider == null)
				return;
			
			if (datagrid._bkDP == null)
				datagrid._bkDP=new ArrayCollection([]);
			
			if (rowIndex < 0)
				rowIndex=0;
			if (rowIndex >= datagrid._bkDP.length)
				rowIndex=datagrid._bkDP.length - 1;
			var activeItem:Object=this.datagrid.getBackupItem(rowIndex);
			rowIndex=this.datagrid.getItemIndex(activeItem);	
			
			if(!this.datagrid.selectCell)
			{						
				datagrid.selectedIndex=rowIndex;		//select row						
			}			
			if(this.datagrid.dataProvider.length>this.datagrid.rowCount)
			{					
				this.datagrid.maxVerticalScrollPosition=this.datagrid.dataProvider.length-this.datagrid.rowCount+1;	
			}
			if (rowIndex > this.datagrid.rowCount - 2)
			{
				var index:int = rowIndex - datagrid.rowCount + 3;
				if(index >=this.datagrid.maxVerticalScrollPosition)
					gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=this.datagrid.maxVerticalScrollPosition;
				else
					gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=index;
//				gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=(rowIndex - this.datagrid.rowCount + 3) >=this.datagrid.maxVerticalScrollPosition?this.datagrid.maxVerticalScrollPosition:(rowIndex - this.datagrid.rowCount + 3) ;					
			}
			else
				gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=0;
			
			if(this.datagrid.eventArr.hasOwnProperty(SAEvent.ON_ROW_ACTIVATE))
			{
				setTimeout(dispatchRowActivateEvent, 1000, rowIndex);
			}
		}
		
		/*************************************************************
		 * dispatch row active event
		 * ***********************************************************/
		private function dispatchRowActivateEvent(rowIndex:int):void
		{
			var saEvent:SAEvent=new SAEvent(SAEvent.ON_ROW_ACTIVATE, true);
			saEvent.nRow=rowIndex;
			this.datagrid.dispatchEvent(saEvent);
		}
		
		/*************************************************************
		 * delete a row at an pre-defined index or selected index.
		 * @param index index of row will be deleted. If not declare then current selected index will be used.
		 * ***********************************************************/
		public function deleteRow(index:int=-1):void
		{
			try
			{
				if (!datagrid.isTree)
				{
					if (datagrid.dataProvider == null)
						err.throwError(ErrorMessages.ERROR_DATAPROVIDER_NULL, Global.DEFAULT_LANG);
					if(index >= datagrid._bkDP.length)
					 	err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
					if(index >= datagrid.dataProvider.length)
						return;
					if (index < 0)
					{
						if (datagrid.selectedIndex < 0 || datagrid.selectedIndex >= datagrid.dataProvider.length)
							return;
						index=datagrid.selectedIndex;
					}
					
					if(this.datagrid.summaryBar && this.datagrid.summaryBar.hasSummaryBar())
					{
						this.datagrid.summaryBar.resetSummaryBar();
					}
				//	var item:Object=datagrid._bkDP.getItemAt(index);
					var item:Object=datagrid.getItemAt(index);
					 
					if(!this.datagrid.bViewDelRowCRUD)
					{
						if(item[this.datagrid.crudColumnKey] == this.datagrid.strInsertRowText)
							datagrid._bkDP.removeItemAt(index);
						else
							setCRUDRowValue(item, this.datagrid.strDeleteRowText , Global.CRUD_DELETE);
					}
					else
					{
						if (setCRUDRowValue(item, this.datagrid.strDeleteRowText , Global.CRUD_DELETE) && item[this.datagrid.crudColumnKey] != this.datagrid.strInsertRowText)
							return;
						 datagrid._bkDP.removeItemAt(index);
					}
					
					var rowStatus:RowStatus=dgManager.getRowKey(item) as RowStatus;
					if (rowStatus != null)
							rowStatus.currentStatus=RowStatus.STATUS_DEL;
					
					if (datagrid.dataProvider as ArrayCollection)
					{
						var removeIndex : int = (datagrid.dataProvider as ArrayCollection).getItemIndex(item);
						(datagrid.dataProvider as ArrayCollection).removeItemAt(removeIndex);
					}
					else
					{
						var removeIndexNode : int = (datagrid.dataProvider as XMLListCollection).getItemIndex(item);
						(datagrid.dataProvider as XMLListCollection).removeItemAt(removeIndexNode);
					}
					
					for each(var col:ExAdvancedDataGridColumn in datagrid.columns)
					{
						if(col.type==ColumnType.CHECKBOX) 
						{
							if(col.arrSelectedCheckbox.getItemIndex(item)!=-1)
								col.arrSelectedCheckbox.removeItemAt(col.arrSelectedCheckbox.getItemIndex(item));
						}
					}
					//update Application height when data is changed
					gridoneManager.updateGridHeight();
					
					//update vertical in case bExternalScroll = false 
					gridoneManager.updateExternalVerticalScroll(this.datagrid.getLength());
					
					if (this.datagrid.dataProvider.length < this.datagrid.rowCount)
					{						
						this.gridone.vScroll.maxScrollPosition=this.datagrid.maxVerticalScrollPosition=0;
					}
					//re-create summary bar.
					if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
						this.datagrid.summaryBar.reCreateSummaryBar(true);	
					//update group mergeCells of datagrid
					if(hasGroupMerge())
						this.datagrid.getGroupMergeInfo();
					//validate grid 
					if(isDrawUpdate)
						this.datagrid.invalidateList();
//					this.datagrid.numberOfRow = this.datagrid._bkDP.length;
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"deleteRow");					
			}
import kr.co.actsone.common.Global;

		}
		

		
		/*************************************************************
		 * set active for row index
		 * ***********************************************************/
		public function setActiveRowIndex(rowIndex:int):void
		{
			if (datagrid.dataProvider == null)
				return;
			
			if (rowIndex < 0)
				rowIndex=0;
			if (rowIndex >= datagrid._bkDP.length)
				rowIndex=datagrid._bkDP.length - 1;
			var activeItem:Object=this.datagrid.getBackupItem(rowIndex);
			if(activeItem==this.datagrid.selectedItem)
				return;
			rowIndex=this.datagrid.getItemIndex(activeItem);
			datagrid.selectedIndex=rowIndex;
			if (rowIndex > this.datagrid.rowCount - 1)
			{
				var index:int = rowIndex - this.datagrid.rowCount + 3;
				if(index > this.datagrid.maxVerticalScrollPosition)
					gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=this.datagrid.maxVerticalScrollPosition
				else
					gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=index;
//				gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=(rowIndex - this.datagrid.rowCount + 3) > this.datagrid.maxVerticalScrollPosition?this.datagrid.maxVerticalScrollPosition:(rowIndex - this.datagrid.rowCount + 3) ;
			}
			else
				gridone.vScroll.scrollPosition=this.datagrid.verticalScrollPosition=0;
			if(this.datagrid.eventArr.hasOwnProperty(SAEvent.ON_ROW_ACTIVATE))
			{
				setTimeout(dispatchRowActivateEvent, 1000, rowIndex);
			}
			//this.datagrid.invalidateList();		
		}

		/*************************************************************
		 * set number format
		 * ***********************************************************/
		public function setNumberFormat(columnKey:String, value:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				//var expression:RegExp=/[^0-9,.#]/g;
				var expression:RegExp=/[#0][#0,.]*[0#]/g;
				var currencyArr:Array=value.split(expression);
				col.strCurrencyBefore=currencyArr[0];
				col.strCurrencyAfter=currencyArr[1];
				var strFormat:Array=value.match(expression);
				var arrPrecision:Array=strFormat[0].split(".");
				col.precision=0;
				if (arrPrecision.length == 2 && arrPrecision[1].toString() != "")
				{
					col.precision=arrPrecision[1].toString().length;
					col.symbolPrecision=arrPrecision[1].toString().charAt(0);
				}
				//updated by Thuan: add conditional col.checkPrecision > -1
				//2013April01
				if (col.precision > col.checkPrecision && col.checkPrecision > -1)  
					col.precision=col.checkPrecision;
				/* var useCurrency:Boolean=false;
				for (var i:int=0; i < value.length; i++)
				{
				if (value.charAt(i) == '$')
				{
				useCurrency=true;
				break;
				}
				}
				col.useCurrency=useCurrency; */
				col.formatString = value;
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setNumberFormat");					
			}
		}
//		public function addComboList(columnKey:String, listKey:String):void
//		{
//			try
//			{
//				var col:ExAdvancedDataGridColumn=dgManager.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
//				if (col == null)
//					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);					
//				col.listCombo[listKey]=new Array();
//				col.indexComboKeyArr.push(listKey);
//				col.comboKey=col.indexComboKeyArr[0];
//			}
//			catch(error:Error)
//			{
//				err.throwMsgError(error.message,"addComboList");	
//			}
//		}		
		
		/*************************************************************
		 * set row activation
		 * ***********************************************************/
		public function setRowActivation(nRow:int, strActivation:String):void
		{
			try
			{
				if(nRow < 0 || nRow > this.datagrid.getLength())
					err.throwError(ErrorMessages.ERROR_ROWINDEX_INVALID, Global.DEFAULT_LANG);
				for (var itemKey:String in this.datagrid.dataFieldIndex)
				{
					if (itemKey != null || itemKey != "")
						this.setActivation(itemKey, nRow, strActivation);
				}
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setRowActivation");
			}
		}
		
		public function setActivation(strColumnKey:String, nRow:int, strActivation:String, isSettingsCell:Boolean = false):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(col.merge)					
					err.throwError(ErrorMessages.ERROR_ACTIVATION_COLKEY_INVALID, Global.DEFAULT_LANG);					
				if (strActivation != Global.ACTIVATE_EDIT && strActivation != Global.ACTIVATE_DISABLE && strActivation != Global.ACTIVATE_ONLY)
					err.throwError(ErrorMessages.ERROR_ACTIVATION_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(strColumnKey,nRow,strActivation,'activation');
				if(isSettingsCell)
					this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				throw new Error(error.message);
			}
		}
		

		
		/*************************************************************
		 * set row background color
		 * @param row int
		 * @param color String
		 * ***********************************************************/
		public function setRowBgColor(row:int, color:String):void
		{
			try
			{
				if(row < 0 || row >= this.datagrid.dataProvider.length)
					err.throwError(ErrorMessages.ERROR_ROWINDEX_INVALID, Global.DEFAULT_LANG);
				if (datagrid.dataProvider == null)
					err.throwError(ErrorMessages.ERROR_DATAPROVIDER_NULL, Global.DEFAULT_LANG);
				this.datagrid.setRowStyle(row,"backgroundColor",color);
				if (isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setRowBgColor");
			}
		}
		
		/*************************************************************
		 * set row font color
		 * @param row int
		 * @param color String
		 * ***********************************************************/
		public function setRowFgColor(row:int, color:String):void
		{
			try
			{
				if(row < 0 || row >= this.datagrid.dataProvider.length)
					err.throwError(ErrorMessages.ERROR_ROWINDEX_INVALID, Global.DEFAULT_LANG);
				if (datagrid.dataProvider == null)
					err.throwError(ErrorMessages.ERROR_DATAPROVIDER_NULL, Global.DEFAULT_LANG);
				this.datagrid.setRowStyle(row,"color",color);
				if (isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setRowFgColor");
			}
		}
		
		/*************************************************************
		 * set row hide
		 * ***********************************************************/
		public function setRowHide(nRow:int, bHide:Boolean,isHandleBkDp:Boolean=true):void
		{
			try
			{
				var indexBk:int=-1;
				var tmpArr:Array=new Array();
				if(this.datagrid.itemEditorInstance)
					this.datagrid.destroyItemEditor();
				if (!this.datagrid.isTree)
				{
					if(datagrid.invisibleIndexOrder == null)
						datagrid.invisibleIndexOrder = new Array();
					var item:Object;
					if(isHandleBkDp)
					{
						if(nRow < 0 || nRow >= this.datagrid._bkDP.length)
							err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
						item = this.datagrid._bkDP.getItemAt(nRow);
						indexBk = nRow;
					}
					else
					{
						//if bHide =true ,nRow will be followed index of dataProvider
						if(bHide)
						{
							if(nRow < 0 || nRow >= this.datagrid.dataProvider.length)
								err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
							item = this.datagrid.getItemAt(nRow);
							indexBk = this.datagrid._bkDP.getItemIndex(item);
						}
						else
						{
							if(nRow < 0 || nRow >= this.datagrid._bkDP.length)
								err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
							//ifbHide = false, nRow will be followed index of dataProviderBackup
							item = this.datagrid._bkDP.getItemAt(nRow);
							indexBk = nRow;
						}
					}
					//save indexBk to apply in case setRowVisible
					var position:Object = getPositionOfIndexInArr(indexBk,datagrid.invisibleIndexOrder);
					if(bHide)
					{
						if(position == null)
						{
							if(datagrid.invisibleIndexOrder.length == datagrid.nRowHideBuffer)
							{
								//remove the first element of array
								datagrid.invisibleIndexOrder.splice(0,1);
							
							}
							//add new element into array
							tmpArr.push(indexBk);
							datagrid.invisibleIndexOrder.push(tmpArr);
						}
					}
					else
					{
						if(position && position['row'] > -1)
						{
							//remove element is not invisible any more
							var detailItemArr:Array = this.datagrid.invisibleIndexOrder[position['row']];
							detailItemArr.splice(position['column'],1);
							if(detailItemArr.length == 0)
							{
								this.datagrid.invisibleIndexOrder.splice(position['row'],1);
							}
								
						}
					}
					
					item[Global.ROW_HIDE] = bHide;					
					setCRUDRowValue(item, this.datagrid.strDeleteRowText, Global.CRUD_DELETE);
					this.datagrid.filter = new FilterDataWithRowHide(this.datagrid.filter,null);
					if (this.datagrid.dataProvider as XMLListCollection)
					{
//					 	(this.datagrid.dataProvider as XMLListCollection).filterFunction=this.datagrid.filter.apply;
//						(this.datagrid.dataProvider as XMLListCollection).refresh();
					}
					else
					{
						(this.datagrid.dataProvider as ArrayCollection).filterFunction = this.datagrid.filter.apply;
						(this.datagrid.dataProvider as ArrayCollection).refresh();
					}
				
					if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
					{
						this.datagrid.summaryBar.reCreateSummaryBar();
					}
					//update Application height when data is changed
					gridoneManager.updateGridHeight();
					
					gridoneManager.updateExternalVerticalScroll(datagrid.getLength());
					//update group mergeCells of datagrid
					if(hasGroupMerge())
					{
						this.datagrid.getGroupMergeInfo();
					}
					
					if(isDrawUpdate)
						this.datagrid.invalidateList();
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setRowHide");			
			}
		}
		
		/*************************************************************
		 * check that value is existed inside array or not
		 * @author Duong Pham
		 * ***********************************************************/
		public function getPositionOfIndexInArr(value:int, arr:Array):Object
		{
			var row:int =-1, column:int=-1;
			var i:int = 0;
			var j:int=0;
			var isExisted:Boolean = false;
			var arrItem:Array;
			for(i=0; i<arr.length; i++)
			{
				if(arr[i] != null)
				{
					if(arr[i].length > 0)
					{
						arrItem = arr[i] as Array;
						for(j=0; j<arrItem.length; j++)
						{
							if(arrItem[j] == value)
							{
								isExisted = true;
								column = j;
								break;
							}
						}
					}
					if(isExisted)
					{
						row = i;
						break;
					}
				}
			}
			if(row > -1 && column > -1 )
				return {row:row,column:column};
			return null;
		}
		

		/*************************************************************
		 * set CRUD row value
		 * ***********************************************************/
		public function setCRUDRowValue(row:Object, value:String , crudKey:String):Boolean
		{
			if (this.datagrid.crudMode)
			{
				if (row[this.datagrid.crudColumnKey] != this.datagrid.strInsertRowText && row[this.datagrid.crudColumnKey] != value)
				{
					row[this.datagrid.crudColumnKey]=value;
					row[this.datagrid.crudColumnKey + Global.CRUD_KEY]= crudKey;
					//(this.datagrid.dataProvider as ArrayCollection).itemUpdated(row);
					this.datagrid.invalidateList();
				}
				return true;
			}
			return false;
		}
 
		/*************************************************************
		 * set a cell value index.		 
		 * ***********************************************************/
		public function setCellValueIndex(nColumnIndex:int, nRow:int, strValue:String):void
		{
			if (nColumnIndex < 0 || nColumnIndex >= this.datagrid.columns.length)
				err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
			
			if (nRow < 0 || nRow >= this.datagrid.dataProvider.length)
				err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
			
			var fieldName:String=(this.datagrid.columns[nColumnIndex] as ExAdvancedDataGridColumn).dataField;
			this.setCellHelper(fieldName, nRow, strValue , "setCellValueIndex",true);					
		}
		
		/*************************************************************
		 * set a cell value.		 
		 * ***********************************************************/
		public function setCellHelper(columnKey:String, rowIndex:int, value:Object , functionName:String,belongVisibleCol:Boolean):void
		{
			try
			{
				var item:Object=datagrid.getBackupItem(rowIndex);
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if(col == null && !belongVisibleCol)
				{
					item[columnKey] = value;
					setCRUDRowValue(item, this.datagrid.strUpdateRowText, Global.CRUD_UPDATE);
					this.datagrid.invalidateList();
					return;
				}
				if (!gridone.gridoneManager.checkValueEntered(col, value, Global.SET_CELL_FUNCTION))
				{
					err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
				}
				if (rowIndex < 0 || rowIndex >= datagrid._bkDP.length)
				{
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				}
				//if(hasSummaryBar())
				////dispatch onCellChange event
				
				/* var saEvent:SAEvent=new SAEvent(SAEvent.ON_CELL_CHANGE, true);
				saEvent.columnKey=fieldName;
				saEvent.nRow=rowIndex;
				saEvent.strOldValue=item[fieldName];
				saEvent.strNewValue=value.toString();
				this.datagrid.dispatchEvent(saEvent); */
				///
				if(item[columnKey]!=value)
				{
					item[columnKey]=value;	
					if(datagrid.columns[datagrid.dataFieldIndex[columnKey]].type == ColumnType.CHECKBOX)
					{
						if(value.toString() == "1")
							datagrid.columns[datagrid.dataFieldIndex[columnKey]].arrSelectedCheckbox.addItem(item);
						else if((datagrid.columns[datagrid.dataFieldIndex[columnKey]] as ExAdvancedDataGridColumn).arrSelectedCheckbox.getItemIndex(item)!=-1)
							(datagrid.columns[datagrid.dataFieldIndex[columnKey]] as ExAdvancedDataGridColumn).arrSelectedCheckbox.removeItemAt((datagrid.columns[datagrid.dataFieldIndex[columnKey]] as ExAdvancedDataGridColumn).arrSelectedCheckbox.getItemIndex(item));
					}
					setCRUDRowValue(item, this.datagrid.strUpdateRowText, Global.CRUD_UPDATE);
					if (isDrawUpdate == true)
						this.datagrid.invalidateList();
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,functionName);		
			}
		}
	
		
		public function setCellHiddenValueIndex(nColumnIndex:int, nRow:int, strValue:String):void
		{
			if (nColumnIndex < 0 || nColumnIndex >= this.datagrid.columns.length)
				err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
			
			if (nRow < 0 || nRow >= this.datagrid._bkDP.length)
				err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
			
			var colField:String=(this.datagrid.columns[nColumnIndex] as ExAdvancedDataGridColumn).dataField;
			setCellHiddenValueHelper(colField, nRow, strValue ,"setCellHiddenValueIndex");
		}
		
		public function setCellHiddenValueHelper(strColumnKey:String, nRow:int, strValue:String , strFuncName:String):void
		{
			try
			{
				if (!datagrid.isTree)
				{
					if (!this.datagrid.dataFieldIndex.hasOwnProperty(strColumnKey))
						err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
					
					if (nRow < 0 || nRow >= this.datagrid._bkDP.length)
						err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
					
					var obj:Object=this.datagrid.getBackupItem(nRow);
					obj[strColumnKey + "_hidden"]=strValue;
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,strFuncName);					
			}
		}
		
		public function setCellValue(columnKey:String, nRow:int, value:String, belongVisibleCol:Boolean):void
		{				
			try
			{
				
				if (value == null)
					value="";
				if(nRow <= -1)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				
				var item:Object = this.datagrid.getItemAt(nRow);
				
				
				if(item[SummaryBarConstant.SUB_TOTAL]!= null || item[SummaryBarConstant.TOTAL]!= null)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_VALUE, Global.DEFAULT_LANG);
				this.setCellHelper(columnKey,nRow,value , "setCellValue",belongVisibleCol);
				if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
				{
					this.datagrid.summaryBar.reCreateSummaryBar();
				} 
				
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellValue");					
			}
		}
		
		
		public function setCellArray(valueArray:Array, rowIndexArray:Array, fieldName:String):void
		{
			
			if (this.datagrid.dataProvider == null || valueArray == null || rowIndexArray == null)
				return;
			
			for (var i:int=0; i < rowIndexArray.length; i++)
			{
				var rowIndex:int=int(rowIndexArray[i]);
				
				if (rowIndex < 0 || rowIndex >=this.datagrid._bkDP.length)
					continue;
				
				var item:Object = this.datagrid.getItemAt(rowIndex);
				
				item[fieldName]=valueArray[i];
				
				var rowStatus:RowStatus=dgManager.getRowKey(item) as RowStatus;
				if (rowStatus != null)
					rowStatus.currentStatus=RowStatus.STATUS_EDIT;
				
			}
			this.datagrid.invalidateList();
		}

		
		public function setCellImage(strColKey:String, nRow:int, nImageIndex:int):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(strColKey) as ExAdvancedDataGridColumn;
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(col.type!=ColumnType.IMAGETEXT)
					err.throwError(ErrorMessages.ERROR_WRONG_COLUMN_TYPE, Global.DEFAULT_LANG);
				if (nRow < 0 || nRow >= this.datagrid._bkDP.length)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				if(nImageIndex>col.imageList.length-1)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				var obj:Object=this.datagrid.getBackupItem(nRow);
				obj[strColKey + "_index"]=nImageIndex;
				this.datagrid.invalidateList();
				this.datagrid.scrollToIndex(nRow);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellImage");					
			}
		}
		

		
		public function setCellBgColor(columnKey:String, nRow:int, color:String):void
		{				
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(columnKey, nRow, color , "backgroundColor");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellBgColor");					
			}
		}
		
		public function setCellFgColor(columnKey:String, nRow:int, color:String):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(columnKey, nRow, color , "color");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellFgColor");					
			}			
		}
		
		public function setCellPaddingLeft(columnKey:String,nRow:int,padding:Number):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(columnKey, nRow, padding, "paddingLeft");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellPaddingLeft");					
			}	
		}
		
		public function setCellFont(columnKey:String, nRow:int, fontName:String, nSize:Number, bBold:Boolean, bItalic:Boolean, bUnderLine:Boolean, bCenterLine:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(columnKey, nRow, fontName, "fontFamily" );
				if (bBold)
					this.datagrid.setCellProperty(columnKey, nRow, "bold" , "fontWeight");
				else
					this.datagrid.setCellProperty(columnKey, nRow, "normal" , "fontWeight");
				if (bItalic)
					this.datagrid.setCellProperty(columnKey, nRow, "italic" , "fontStyle");
				else
					this.datagrid.setCellProperty(columnKey, nRow, "normal" , "fontStyle");
				if (bUnderLine)
					this.datagrid.setCellProperty(columnKey, nRow, "underline", "textDecoration");
				else
					this.datagrid.setCellProperty(columnKey, nRow, "none", "textDecoration");
				if (bCenterLine)			
					this.datagrid.setCellProperty(columnKey, nRow, true, "fontCLine");
				else
					this.datagrid.setCellProperty(columnKey, nRow, false, "fontCLine");
				if (!isNaN(nSize))
					this.datagrid.setCellProperty(columnKey, nRow, nSize, "fontSize");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellFont");					
			}
		}
		
		public function setCellFontBold(columnKey:String, nRow:int, bBold:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (bBold)
					this.datagrid.setCellProperty(columnKey, nRow, "bold" , "fontWeight");
				else
					this.datagrid.setCellProperty(columnKey, nRow, "normal" , "fontWeight");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellFontBold");					
			}
		}
		
		public function setCellFontCLine(columnKey:String, nRow:int, bCenterLine:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(columnKey, nRow, bCenterLine , "fontCLine");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setCellFontCLine");					
			}
		}
		
		public function setCellFontItalic(columnKey:String, nRow:int, bItalic:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(bItalic)
					this.datagrid.setCellProperty(columnKey, nRow, "italic", "fontStyle");
				else
					this.datagrid.setCellProperty(columnKey, nRow, "normal", "fontStyle");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setCellFontItalic");	
			}
		}
		
		public function setCellFontName(columnKey:String, nRow:int, value:String):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(columnKey, nRow, value , "fontFamily");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setCellFontName");	
			}
		}
		
		public function setCellFontSize(columnKey:String, nRow:int, value:Number):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				this.datagrid.setCellProperty(columnKey, nRow, value, "fontSize");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setCellFontSize");	
			}
		}
		
		public function setCellFontULine(columnKey:String, nRow:int, bUnderLine:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (bUnderLine)
					this.datagrid.setCellProperty(columnKey, nRow, "underline", "textDecoration");
				else
					this.datagrid.setCellProperty(columnKey, nRow, "none", "textDecoration");
				if (this.isDrawUpdate == true)
					this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setCellFontULine");	
			}
		}
		
		public function allowDrawUpdate(boolDraw:Boolean):void
		{
			if (boolDraw == true || boolDraw == false)
				isDrawUpdate=boolDraw;
			
			if (boolDraw == true)
				this.datagrid.invalidateList();
		}
		
		public function addComboList(columnKey:String, value:Object):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn= gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(value is String) //case for combo or multicombo column type
				{
					if(value == null)
						value = 'default';
					col.listCombo[value]=new Array();
					col.indexComboKeyArr.push(value);
					col.comboKey=col.indexComboKeyArr[0];
					this.datagrid.invalidateList();
				}
				else if(value is Array) //in case for MultiCombobox column type
				{
					col.multiComboArr=value as Array; //connect to multiComboRender class, by register in dgManager=>setItemRender	
				}
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"addComboList");	
			}
		}
		
		public function addComboListValue(columnKey:String, strText:String, strValue:String, listKey:String="default"):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (strValue == null)
					err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
				var obj:Object=new Object();
				obj["label"]=strText;
				obj["value"]=strValue; 
				if (col.listCombo[listKey] == null)
					col.listCombo[listKey]=new Array();
				//verify that value is existed or not in listKey of listCombo of column
				if(!col.checkComboValueWithListKey(strValue,listKey))
				{
					(col.listCombo[listKey] as Array).push(obj);
					this.datagrid.invalidateList();
				}
				
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"addComboListValue");						
			}
		}



		
	
		
		public function addComboHeaderValue(columnKey:String,label:String,value:String):void
		{
			var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
			var item:Object=new Object();
			item["label"]= label;
			item["value"]=value;
			col.comboHeaderProvider.addItem(item);
		}
		
		public function setComboSelectedIndex(columnKey:String, rowIndex:int, comboIndex:int, listKey:String=Global.DEFAULT_COMBO_KEY):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (rowIndex >= this.datagrid._bkDP.length || rowIndex < 0)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				
				if (listKey != null)
				{
					if(col.type==ColumnType.COMBOBOX)
					{
						if(!col.listCombo.hasOwnProperty(listKey))
							err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
						col.comboKey=listKey;
					}
					else
					{
						for(var i:int=0;i<col.indexComboKeyArr.length;i++)
						{
							if(listKey==col.indexComboKeyArr[i])
								break;
						}
						
						this.datagrid.getBackupItem(rowIndex)[col.dataField+Global.COMBO_KEY_CELL]=i;
					}
					if(comboIndex!=-1)
					{
						this.datagrid.getBackupItem(rowIndex)[col.dataField]=col.listCombo[listKey][comboIndex]["value"];
						this.datagrid.getBackupItem(rowIndex)[col.dataField+Global.SELECTED_COMBO_INDEX]=comboIndex;
					}
					else
					{
						this.datagrid.getBackupItem(rowIndex)[col.dataField]="";
						this.datagrid.getBackupItem(rowIndex)[col.dataField+Global.SELECTED_COMBO_INDEX]=-1;
					}
				}
				/* else
				this.datagrid.dataProvider[rowIndex][col.dataField]=col.comboData[comboIndex]["value"]; */
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setComboSelectedIndex");					
			}
		}
		
		public function setComboSelectedHiddenValue(columnKey:String, rowIndex:int, hiddenValue:String, listKey:String=Global.DEFAULT_COMBO_KEY):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (rowIndex < 0 || rowIndex >= this.datagrid.dataProvider.length)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				
				if (listKey != null)
				{
					this.datagrid.getBackupItem(rowIndex)[col.dataField]=hiddenValue;
					var flag:Boolean=false;
					var index:int=0;
					for each(var item:Object in col.listCombo[listKey])
					{
						if(item["value"]==hiddenValue)
						{
							flag=true;
							this.datagrid.getBackupItem(rowIndex)[col.dataField+Global.SELECTED_COMBO_INDEX]=index;
							break;
							
						}
						index++;
					}
					if(!flag)
						err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
				}
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setComboSelectedHiddenValue");					
			}
		}
		

		
		public function hasComboList(columnKey:String, listKey:String=Global.DEFAULT_COMBO_KEY):Boolean
		{
			try
			{
				var result:Boolean = false;
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (listKey != null)
				{
					if (col.listCombo[listKey] != null)
						result = true;
				}					
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"hasComboList");					
			}
			return result;
		}
		
		public function clearComboList(columnKey:String, listKey:String=Global.DEFAULT_COMBO_KEY):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (listKey != null)
				{
					if (col.listCombo[listKey] != null)
						col.listCombo[listKey] = null;
				}
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"clearComboList");					
			}
		}
		
		public function setComboRowCount(columnKey:String, rowCount:int):void{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(col.type.toUpperCase() != ColumnType.COMBOBOX)
					err.throwError(ErrorMessages.ERROR_COMBOBOX_COLUMN_TYPE,Global.DEFAULT_LANG);
				if(rowCount < -1)	
					err.throwError(ErrorMessages.ERROR_COMBO_ROWCOUNT_INVALID,Global.DEFAULT_LANG);
				col.comboRowCount = rowCount;
				
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setComboRowCount");						
			}				
		}
		

		
		public function addImageList(columnKey:String, strUrl:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (col.imageList == null)
					col.imageList=new Array();
				col.imageList.push(strUrl);
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"addImageList");
			}
		}
		
	
	
		
		public function setImageListSize(columnKey:String, iwidth:int, iHeight:int):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(iwidth < 0 || iHeight <0 )
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);	
				col.imageHeight=iHeight;
				col.imageWidth=iwidth;
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setImageListSize");
			}
		}
		
		public function clearImageList(columnKey:String):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.imageList=[];
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"clearImageList");
			}
		}
		

		public function addGridImageList(url:String):void
		{
			this.datagrid.imageList.push(url);			
		}
		
		public function setColCellGridImageList(columnKey:String, bValue:Boolean):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				col.isUseGridImage=bValue;
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellGridImageList");
			}
		}
		
		public function clearGridImageList():void
		{
			this.datagrid.imageList=[];
			this.datagrid.invalidateList();
		}
		
		public function setGridImageListSize(nWidth:int, nHeight:int):void
		{
			for each (var col:ExAdvancedDataGridColumn in this.datagrid.columns)
			{
				if (col.type == ColumnType.IMAGETEXT)
					setImageListSize(col.dataField, nWidth, nHeight);
			}
		}
		
		public function setColCellActivation(strColumnKey:String, strValue:String):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);				
				if(col.merge)
				{
					err.throwError(ErrorMessages.ERROR_ACTIVATION_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				if (strValue != Global.ACTIVATE_EDIT && strValue != Global.ACTIVATE_DISABLE && strValue != Global.ACTIVATE_ONLY)
					err.throwError(ErrorMessages.ERROR_ACTIVATION_INVALID, Global.DEFAULT_LANG);
				col.cellActivation=strValue;							
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellActivation");					
			}
		}
		

		public function setColHDCheckBoxValue(strColumnKey:String, bValue:Boolean):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn;
				if(col==null || col.type != ColumnType.CHECKBOX)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				datagrid.setHeaderCheckBoxValue(col,bValue);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColHDCheckBoxValue");	
			}
		}
		
		public function setColCellSort(strColumnKey:String, strSort:String):void
		{
			try
			{
				if (this.datagrid.dataFieldIndex[strColumnKey] == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn;
				if(col.type == ColumnType.CHECKBOX)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (strSort == "none")
				{
					col.sortable=false;
				}
				else if (col.type != ColumnType.CHECKBOX)
				{
					col.sortable=true;		
					if(strSort == "descending")
						col.sortDescending = true;
					else
						col.sortDescending = false;
					var nameSort:Sort = new Sort();
					if(col.type == ColumnType.NUMBER)
						nameSort.fields = [new SortField(strColumnKey, false, col.sortDescending, true)];
					else
						nameSort.fields = [new SortField(strColumnKey, false, col.sortDescending)];
					this.datagrid.dataProvider.sort = nameSort;
				}
				this.datagrid.dataProvider.refresh();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setColCellSort");	
			}
		}
		
		/*************************************************************
		 * set column cell radio
		 * @param columnKey:String; bRadio :Boolean.
		 * author: Duong Pham
		 * Modifier:Toan Nguyen
		 * ***********************************************************/
		public function setColCellRadio(columnKey:String, bRadio:Boolean):void
		{
			try
			{
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if(col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (col.type == ColumnType.CHECKBOX)
				{
					col.isSelectSingleCheckbox=bRadio;
					for each (var item:Object in this.datagrid.dataProvider)
					{
						item[columnKey]="0";
					}
					col.arrSelectedCheckbox.removeAll();
					this.datagrid.invalidateList();
				}
				else
				{
					err.throwError(ErrorMessages.ERROR_CHECKBOX_COLUMN_TYPE, Global.DEFAULT_LANG);
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellRadio");					
			}
		}
		
		/*************************************************************
		 * check column is visible or not
		 * ***********************************************************/
		public function isColHide(columnKey:String):Boolean
		{
			try
			{					
				var result:Boolean = false;
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				result = !col.visible;
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"isColHide");
			}
			return result;
		}		
		
		/*************************************************************
		 * set column is visible or not
		 * ***********************************************************/
		public function setColHide(dataField:String, isHide: Boolean):void
		{
			try
			{
				var datagridWidth:int=this.gridone.applicationWidth;
				var hiddenColumn:ExAdvancedDataGridColumn = ExAdvancedDataGridColumn(gridone.getColumnByDataField(dataField,false));
				if(hiddenColumn == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(hiddenColumn.visible != !isHide)
				{
					if(this.datagrid.bExternalScroll)
					{
						if(isHide == false)
							this.datagrid.width = this.datagrid.totalVisibleColumnWidth = this.datagrid.totalVisibleColumnWidth + hiddenColumn.width;
						else
							this.datagrid.width = this.datagrid.totalVisibleColumnWidth = this.datagrid.totalVisibleColumnWidth - hiddenColumn.width;
					}
					hiddenColumn.visible = !isHide;
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColHide");
			}
		}
		
		/*************************************************************
		 * move column to index position
		 * ***********************************************************/
		public function setColIndex(columnKey:String, index:int):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if(index < 0 && index >= this.datagrid.columns.length)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				var realIndex:int = getRealIndexByVisibleIndex(index);
				if(!this.datagrid._isGroupedColumn)
				{
					var columns:Array = this.datagrid.columns;
					var columnCollection:ArrayCollection=new ArrayCollection(columns);
					columnCollection.removeItemAt(this.datagrid.dataFieldIndex[columnKey]);
					columnCollection.addItemAt(col, realIndex);					
					for (var i:int=0; i < columnCollection.toArray().length; i++)
					{
						var updatedCol:ExAdvancedDataGridColumn = columnCollection.toArray()[i]; 
						this.datagrid.dataFieldIndex[updatedCol.dataField]=i;
					}
					this.datagrid.columns=columnCollection.toArray();
				}
				else
				{
					var sourceCol:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
					updateColumnPositionInGroupColumn(sourceCol, realIndex,true);
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColIndex");
			}
		}
		
		private function updateColumnPositionInGroupColumn(sourceCol:ExAdvancedDataGridColumn, index:int,isMoveCol:Boolean=true):void
		{
			try
			{
				var sourceIndex:int;
				var remainCols:ArrayCollection;
				if(isMoveCol)
				{
					sourceIndex = this.datagrid.dataFieldIndex[sourceCol.dataField]; 
					remainCols =deleteColumnByDataField(sourceCol.dataField);
				}
				else
				{
					sourceIndex = index;
					remainCols = new ArrayCollection(this.datagrid.groupedColumns);
				}
				var prevCol:ExAdvancedDataGridColumn;
				var nextCol:ExAdvancedDataGridColumn;
				var prevListParentKey:String;
				var nextListParentKey:String;
				var sourceListParentKey:String;
				if(sourceCol.parent != "")
				{
					sourceListParentKey = sourceCol.parent + "%%"; 
					sourceListParentKey = getListParentKey(sourceCol.parent,sourceListParentKey);
					sourceListParentKey = sourceListParentKey.slice(0,sourceListParentKey.length-2);
				}
				if(index == 0)
				{
					nextCol = this.datagrid.columns[0];
				}
				else if(index == this.datagrid.columns.length)
				{
					prevCol = this.datagrid.columns[this.datagrid.columns.length];
				}
				else
				{
					if(sourceIndex < index)
					{
						// preCol: index ; nextCol: index +1
						prevCol = this.datagrid.columns[index];
						nextCol = this.datagrid.columns[index + 1];
					}
					else
					{
						// preCol: index - 1;  nextCol: index
						prevCol = this.datagrid.columns[index - 1];
						nextCol = this.datagrid.columns[index];
					}
				}
				if(prevCol && prevCol.parent != "")
				{
					prevListParentKey = prevCol.parent + "%%"; 
					prevListParentKey = getListParentKey(prevCol.parent,prevListParentKey);
					prevListParentKey = prevListParentKey.slice(0,prevListParentKey.length-2);
				}
				if(nextCol && nextCol.parent != "")
				{
					nextListParentKey = nextCol.parent + "%%"; 
					nextListParentKey = getListParentKey(nextCol.parent,nextListParentKey);
					nextListParentKey = nextListParentKey.slice(0,nextListParentKey.length-2);
				}
				if(sourceCol.parent == "")
				{					
					if( (prevCol == null && nextCol.parent == "") || (prevCol == null && nextCol.parent != "") ||
						(prevCol.parent == "" && nextCol == null) || (prevCol.parent != "" && nextCol == null) ||
						(prevCol && nextCol && (    (prevCol.parent == "" && nextCol.parent == "") || 
													(prevCol.parent == "" && nextCol.parent != "") ||
													(prevCol.parent != "" && nextCol.parent == "")
											   )
						))
					{
						remainCols = addColumnAtIndex(remainCols,sourceCol,index,false);
					}
					else
					{				
						if(prevListParentKey == nextListParentKey)
						{
							// belong one group column
							err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
						}
						else
						{
							// next and previous column belong two different group columns => allow insert
							remainCols = addColumnAtIndex(remainCols,sourceCol,index,false);
						}
					}
				}
				else
				{					
					if( (prevCol == null && nextCol.parent == "") ||
						(prevCol.parent == "" && nextCol == null) ||
						(prevCol && nextCol && ((prevCol.parent == "" && nextCol.parent == "")))
					  )
					{
						err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
					}
					else
					{
						if(prevCol.parent == "" && nextCol.parent != "")
						{
							if(isNotBelongOneColumnGroups(sourceListParentKey,nextListParentKey))
								err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
							else
								remainCols = addColumnAtIndex(remainCols,sourceCol,index,false);
						}
						else if(prevCol.parent != "" && nextCol.parent == "")
						{
							if(isNotBelongOneColumnGroups(prevListParentKey, sourceListParentKey))
								err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
							else
								remainCols = addColumnAtIndex(remainCols,sourceCol,index,true);
						}
						else if(prevCol.parent != "" && nextCol.parent != "")
						{
							var isSourceNotBelongPreviousCol:Boolean = isNotBelongOneColumnGroups(prevListParentKey,sourceListParentKey);
							var isSourceNotBelongNextCol:Boolean = isNotBelongOneColumnGroups(sourceListParentKey,nextListParentKey);
							if(isSourceNotBelongPreviousCol && isSourceNotBelongNextCol)
								err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
							else if(!isSourceNotBelongPreviousCol && isSourceNotBelongNextCol) 
								remainCols = addColumnAtIndex(remainCols,sourceCol,index,true);
							else if (isSourceNotBelongPreviousCol && !isSourceNotBelongNextCol)
								remainCols = addColumnAtIndex(remainCols,sourceCol,index,false);
							else if (!isSourceNotBelongPreviousCol && !isSourceNotBelongNextCol)
								remainCols = addColumnAtIndex(remainCols,sourceCol,index,false);							
						}
					}
				}
				//update grouped column in datagrid
				this.datagrid.groupedColumns = remainCols.toArray();
				var updatedCols:Array = new Array(); 
				updatedCols = convertGroupColumn(remainCols.toArray() , updatedCols)
				this.datagrid.columns = updatedCols;
				for (var i:int=0; i < updatedCols.length; i++)
				{
					this.datagrid.dataFieldIndex[updatedCols[i].dataField]=i;
				}	
			}
			catch (error:Error)
			{
				throw new Error(error.message);
			}
		}
				
		private function deleteColumnByDataField(dataField:String):ArrayCollection
		{
			var remainCols:ArrayCollection;
			var groupedColumns:Array = this.datagrid.groupedColumns;
			remainCols=new ArrayCollection(groupedColumns);
			for (var i:int=0; i< remainCols.length; i++)
			{
				if(remainCols[i] is ExAdvancedDataGridColumn && ExAdvancedDataGridColumn(remainCols[i]).dataField != null && (remainCols[i] as ExAdvancedDataGridColumn).dataField == dataField)
				{
					remainCols.removeItemAt(i);
					break;
				}
				else if(remainCols[i] is ExAdvancedDataGridColumnGroup && ExAdvancedDataGridColumn(remainCols[i]).dataField == null)
				{
					if(deleteChildrenColByDataField(dataField, remainCols[i]))	
						break;
				}
			}
			var deletedColIndex:int = this.datagrid.dataFieldIndex[dataField];
			this.datagrid.dataFieldIndex = new Object();
			//update index column in datafieldIndex
			for (var j:int=0; j < this.datagrid.columns.length; j++)
			{
				if(j < deletedColIndex)
					this.datagrid.dataFieldIndex[this.datagrid.columns[j].dataField]=j;
				else if(j > deletedColIndex)
				{
					var index:int = j;
					this.datagrid.dataFieldIndex[this.datagrid.columns[j].dataField]=--index;
				}
			}
			return remainCols;		
		}
		
		private function deleteChildrenColByDataField(dataField:String, groupCol:ExAdvancedDataGridColumnGroup):Boolean
		{			
			var isBreak:Boolean = false;
			for(var i:int=0; i<groupCol.children.length; i++)
			{
				if(groupCol.children[i] is ExAdvancedDataGridColumn && (groupCol.children[i] as ExAdvancedDataGridColumn).dataField == dataField)
				{
					groupCol.children.splice(i,1);
					isBreak = true;
					break;
				}
				else if(groupCol.children[i] is ExAdvancedDataGridColumnGroup && groupCol.children[i].dataField == "")
				{					
					isBreak = deleteChildrenColByDataField(dataField, groupCol.children[i]);
					if(isBreak)
						break;
				}
			}
			return isBreak;
		}
		
		private function isNotBelongOneColumnGroups(prevListParentKey:String, nextListParentKey:String):Boolean
		{
			var result:Boolean = false;
			var arrPrevParent:Array = prevListParentKey.split("%%");
			var arrNextParent:Array = nextListParentKey.split("%%");
			var i:int = 0;
			var end:int;
			if(arrNextParent.length > arrPrevParent.length)
				end = arrNextParent.length;
			else if(arrNextParent.length < arrPrevParent.length)
				end = arrPrevParent.length;
			else
				end = arrPrevParent.length;
					
			for(i = 0 ; i< end; i++)
			{
				if(arrNextParent[i] && arrPrevParent[i] && arrNextParent[i] != arrPrevParent[i])
				{
					result = true;
					break;
				}
			}
			return result;			
		}
		
		private function addColumnAtIndex(allColumns:ArrayCollection, insertedCol:ExAdvancedDataGridColumn, index:int, isUsePreviousCol:Boolean):ArrayCollection
		{
			var destDataField:String;
			var curColIndex:int;
			var col:ExAdvancedDataGridColumn;
			var isInsertAfterColAtIndex:Boolean = false; 
			if(isUsePreviousCol)
			{
				//get previous column
				isInsertAfterColAtIndex = true;
				var tmp:int = index - 1;
				destDataField = dgManager.getDataFieldByIndex(tmp);
				col=ExAdvancedDataGridColumn(gridone.getColumnByDataField(destDataField,true));
			}
			else
			{
				destDataField = dgManager.getDataFieldByIndex(index);
				col=ExAdvancedDataGridColumn(gridone.getColumnByDataField(destDataField,true));
			}
			
			var j:int = 0;
			var i:int = 0;
			var listParentKey:String;
			var parentKey:Array;
			var parentGroupCol:ExAdvancedDataGridColumnGroup;
			if(insertedCol.parent == "")
			{
				if(col.parent == "")
				{
					for (i =0 ; i < allColumns.length; i++)
					{
						if(allColumns[i] is ExAdvancedDataGridColumn && allColumns[i].dataField == col.dataField)
						{
							allColumns.addItemAt(insertedCol,i);
							break;
						}
					}
				}
				else
				{
					listParentKey = col.parent + "%%"; 
					listParentKey = getListParentKey(col.parent,listParentKey);
					listParentKey = listParentKey.slice(0,listParentKey.length-2);
					parentKey = listParentKey.split("%%");
					for (i =0 ; i < allColumns.length; i++)
					{
						if(allColumns[i] is ExAdvancedDataGridColumnGroup && allColumns[i]._dataFieldGroupCol == parentKey[parentKey.length-1])
						{
							allColumns.addItemAt(insertedCol,i);
							break;
						}
					}
				}
			}
			else 
			{
				if(col.parent == "")
				{
					parentGroupCol = ExAdvancedDataGridColumnGroup(gridone.getColumnByDataField(insertedCol.parent,true));
					parentGroupCol.children.push(insertedCol);
				}
				else
				{
					parentGroupCol = ExAdvancedDataGridColumnGroup(gridone.getColumnByDataField(insertedCol.parent));
					if(parentGroupCol)
					{
						for(i = 0; i<parentGroupCol.children.length; i++)
						{
							if(parentGroupCol.children[i] is ExAdvancedDataGridColumn && (parentGroupCol.children[i] as ExAdvancedDataGridColumn).dataField == col.dataField)
							{
								if(i == parentGroupCol.children.length-1)
								{
									if(!isInsertAfterColAtIndex)
										parentGroupCol.children.splice(i,0,insertedCol);
									else
										parentGroupCol.children.push(insertedCol);
								}
								else					
								{
									parentGroupCol.children.splice(i,0,insertedCol);
								}
								break;
							}				
						}
						
							
					}
				}
			}
			return allColumns;
		}
		
		private function addColumnToChidrenOfGroup(groupCol:ExAdvancedDataGridColumnGroup , col:ExAdvancedDataGridColumn, previousCol:ExAdvancedDataGridColumn,isInsertedInsideGroupCol:Boolean):Boolean
		{			
			var isStop:Boolean = false;
			for(var i:int=0; i<groupCol.children.length; i++)
			{
				if(groupCol.children[i] is ExAdvancedDataGridColumn && (groupCol.children[i] as ExAdvancedDataGridColumn).dataField == previousCol.dataField)
				{
					if(i == groupCol.children.length - 1)
						groupCol.children.push(col);
					else					
					{
						groupCol.children.splice(i,0,col);
					}
					isStop = true;
					break;
				}				
			}
			return isStop;
		}
		
		public function getListParentKey(parentKey:String, result:String):String
		{			
			var groupCol:ExAdvancedDataGridColumnGroup = this.gridone.getColumnByDataField(parentKey,true) as ExAdvancedDataGridColumnGroup;
			if(groupCol.parent != "")
			{
				result = result + groupCol.parent + "%%";
				getListParentKey(groupCol.parent , result);
			}
			return result;
		}
		
	
		
		/*************************************************************
		 * set date format
		 * ***********************************************************/
		public function setDateFormat(columnKey:String, value:String):void
		{
			var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
			if(col != null)
			{
				col.dateOutputFormatString=value;
				this.datagrid.invalidateList();
			}
		}
		
		/*************************************************************
		 * Expand directly children node or all children node of tree 
		 * @param strTreeKey Key of tree
		 * @param bAll Is true if expand all children, Is false if expand only directly children
		 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function expandAtNode(strTreeKey:String, bAll:Boolean, strFuncName:String):void
		{
			try
			{  
				(((this.datagrid.dataProvider as HierarchicalCollectionView).source as ExIHierarchicalData).source as ArrayCollection).refresh();
				var hd: ExIHierarchicalData = this.dgManager.getTreeDataInHier();
				var cursor:IViewCursor = this.dgManager.getTreeDataInFlatCursor();
				cursor.seek(CursorBookmark.FIRST);
				do
				{
					if (cursor.current[this.datagrid.treeIDField] == strTreeKey)
					{
						if (bAll)
						{
							this.datagrid.expandChildrenOf(cursor.current, true);
						}
						else
						{
							this.datagrid.expandItem(cursor.current, true);
						}
						
						//expand all parent of current node:
						var parent:Object = hd.getParent(cursor.current);
						while (parent)
						{
							this.datagrid.expandItem(parent, true);
							parent = hd.getParent(parent);
						}	
						break;
					}
				}while (cursor.moveNext());
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,strFuncName);
			}
		}
		
		/*************************************************************
		 * Collapse tree node
		 * @param strTreeKey Key of tree
 		 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function collapseAtNode(strTreeKey:String, strFuncName: String):void
		{
			try
			{
				var cursor:IViewCursor = this.dgManager.getTreeDataInFlatCursor();
				cursor.seek(CursorBookmark.FIRST);
				do
				{
					if (cursor.current[this.datagrid.treeIDField] == strTreeKey)
					{
						this.datagrid.expandItem(cursor.current, false);
					}
				}while (cursor.moveNext());
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
		}
		
		/*************************************************************
		 * Delete tree node and all children of that
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function deleteTreeNode(strTreeKey: String, strFuncName: String):void
		{
			try
			{
				var cursor:IViewCursor = this.dgManager.getTreeDataInFlatCursor();
				do
				{
					if (cursor.current[this.datagrid.treeIDField] == strTreeKey)
					{
						var children:Object = this.dgManager.getChildren(cursor.current);
						setCRUDRowValue(cursor.current,this.datagrid.strDeleteRowText,Global.CRUD_DELETE);
						//delete all child node:
						this.dgManager.deleteChild(cursor.current, children);
						//delete current node:
						var parent:Object = this.dgManager.getNodeByKey(cursor.current[this.datagrid.treePIDField]);
						(this.datagrid.dataProvider as HierarchicalCollectionView).removeChild(parent,cursor.current);
						break;
					}
				}while (cursor.moveNext());
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
		}
		
		/*************************************************************
		 * Get row index from tree key
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function getRowIndexFromTreeKey(strTreeKey: String, strFuncName: String): int
		{
			try
			{
				var cursor:IViewCursor = this.dgManager.getTreeDataInFlatCursor();
				var rowIndex:int = -1;
				do
				{
					rowIndex = rowIndex + 1;
					if (cursor.current[this.datagrid.treeIDField] == strTreeKey)
					{
						break;
					}
				} while(cursor.moveNext());
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return rowIndex;
		}
		
		/*************************************************************
		 * Return the number of child node of the corresponding tree node if true is inputted as bAll value.
		 * @param strTreeKey Key of tree
		 * @param bAll Is true if count all children, Is false if count only directly children
		 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeChildNodeCount(strTreeKey:String, bAll:Boolean, strFuncName: String): int
		{
			try
			{
				var node:Object = this.dgManager.getNodeByKey(strTreeKey);
				if (bAll)
				{
					var arrCollection: ArrayCollection;
					var children:Object = this.dgManager.getChildren(node);
					var arrChildren:ArrayCollection = new ArrayCollection();
					arrCollection = this.dgManager.getAllChildren(node, children, arrChildren);
					return arrCollection.length;
				}
				else
				{
					var arr: Array = (this.dgManager.getChildren(node) as Array);
					return arr.length;
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return 0;			
		}
		
		/*************************************************************
		 * Return child node key of the corresponding tree node
		 * @param strTreeKey Key of tree
 	 	 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeChildNodeKey(strTreeKey:String, strFuncName: String): Object
		{
			try
			{
				return this.dgManager.getNodeByKey(strTreeKey);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return null;
		}		

		/*************************************************************
		 * Return the first node of tree
		 * @param strFuncName Name of called function
		 * @return The first node of tree
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeFirstNodeKey(strFuncName: String): String
		{
			try
			{
				var firstNode:Object = this.dgManager.getFirstNodeInTree();
				return firstNode[this.datagrid.treeIDField];
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return null;
		}
		
		/*************************************************************
		 * Get tree key from row index
 		 * @param strFuncName Name of called function 
		 * @return String of tree key from row index
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeKeyFromRowIndex(rowIndex: int, strFuncName: String): String
		{
			var strTreeKey: String = "";
			try
			{
				if (this.datagrid.dataProvider == null)
				{
					err.throwError(ErrorMessages.ERROR_DATAPROVIDER_NULL, Global.DEFAULT_LANG);
				}
				if(rowIndex < 0 || rowIndex >= this.datagrid._bkDP.length)
				{
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
				}
				var flatData: ArrayCollection = this.dgManager.getTreeDataInFlat();
				strTreeKey = flatData.getItemAt(rowIndex)[this.datagrid.treeIDField];
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return strTreeKey;
		}
		
		/*************************************************************
		 * Get next key
		 * @param strTreeKey Key of tree
 		 * @param strFuncName Name of called function
		 * @param isInBranch True: Next key is in branch with strTreeKey; False: Next key can be key of next branch
		 * @return The next key of strTreeKey
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeNextNodeKey(strTreeKey:String, strFuncName: String, isInBranch:Boolean):String
		{
			var nextKey: String = "";
			try
			{
				nextKey = this.dgManager.getNextNodeByKey(strTreeKey, isInBranch);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return nextKey;
		}
		
		/*************************************************************
		 * Get previous key
		 * @param strTreeKey Key of tree
 		 * @param strFuncName Name of called function
		 * @param isInBranch True: Previous key is in branch with strTreeKey; False: Previous key can be key of next branch
		 * @return The previous key of strTreeKey
		 * @author Thuan
		 * ***********************************************************/
		public function getTreePrevNodeKey(strTreeKey:String, strFuncName: String, isInBranch:Boolean):String
		{
			var previousKey: String = "";
			try
			{
				previousKey = this.dgManager.getPreviousNodeByKey(strTreeKey, isInBranch);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return previousKey;
		}
		
		/*************************************************************
		 * Get depth of tree node
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return The depth of strTreeKey
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeNodeDepth(strTreeKey:String, strFuncName: String):int
		{
			var depth:int = 0;
//			Case 2: Not tested
//			var hData: HierarchicalCollectionView = (this.datagrid.dataProvider as HierarchicalCollectionView);
//			var node:Object = this.dgManager.getNodeByKey(strTreeKey);
//			var d:int = hData.getNodeDepth(node);
			
			try
			{
				var flatData: ArrayCollection = this.dgManager.getTreeDataInFlat();
				var hierData: ExIHierarchicalData = this.dgManager.getTreeDataInHier();
				var cur:IViewCursor = flatData.createCursor();
				
				if (cur.current == null)
					return 0;
				do
				{
					if (cur.current[this.datagrid.treeIDField] == strTreeKey)
					{
						var curNode: Object = cur.current;
						while (curNode)
						{	
							depth++;
							curNode = hierData.getParent(curNode);	
						}
						break;
					}
				}
				while (cur.moveNext());
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			
			return depth;
		}

		/*************************************************************
		 * Get parent key of key
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return The parent key of strTreeKey
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeParentNodeKey(strTreeKey:String, strFuncName: String):String
		{
			var parenNodeKey: String = "";
			try
			{
				var node: Object = this.dgManager.getNodeByKey(strTreeKey);
				if (node)
				{
					parenNodeKey = node[this.datagrid.treePIDField];
					if (parenNodeKey == Global.TREE_ROOT_CHAR)
						return Global.TREE_ROOT_STRING;
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}			
			return parenNodeKey;
		}
		
		/*************************************************************
		 * Return the summary of child node of the corresponding tree node
		 * @param strTreeKey Key of tree
		 * @param strSummaryColumnKey Summary applied ColumnKey
		 * @param strFunc Function [ sum | count | avarage ] 
 		 * @param strFuncName Name of called function
		 * @param bAll Whether to apply all subordinate node
		 * @return The Summary of child node of the corresponding tree node
		 * @author Thuan
		 * ***********************************************************/
		public function getTreeSummaryValue(strTreeKey:String, strSummaryColumnKey:String, strFunc:String, strFuncName:String, bAll:Boolean):int
		{
			var result: int = 0;
			try
			{
				if(this.datagrid.dataFieldIndex[strSummaryColumnKey] == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
					return result;
				}
				if (bAll)
				{
					result = this.dgManager.getTreeSummaryValueOfAllSubNode(strTreeKey, strSummaryColumnKey, strFunc);
				}
				else
				{
					result = this.dgManager.getTreeSummaryValueOfSubNode(strTreeKey, strSummaryColumnKey, strFunc);
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return result;
		}
		
		/*************************************************************
		 * Check if the corresponding tree node has child node or not
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return Indicates whether node of strTreeKey has child 
		 * @author Thuan
		 * ***********************************************************/
		public function hasTreeChildNode(strTreeKey: String, strFuncName:String):Boolean
		{
			var hasChild:Boolean = false;

			try
			{
				var cursor:IViewCursor = this.dgManager.getTreeDataInFlatCursor();
				do
				{
					if (cursor.current[this.datagrid.treePIDField] == strTreeKey)
					{
						hasChild = true;
						break;
					}
				}
				while (cursor.moveNext());
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return hasChild;
		}
		
		/*************************************************************
		 * Check if the corresponding tree node has next node or not
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return Indicates whether node of strTreeKey has next node
		 * @author Thuan
		 * ***********************************************************/
		public function hasTreeNextNode(strTreeKey: String, strFuncName:String):Boolean
		{
			var hasNextNode:Boolean = false;
			
			try
			{
				var nextKey:String = this.dgManager.getNextNodeByKey(strTreeKey, true);
				hasNextNode = (nextKey != "");
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return hasNextNode;
		}
		
		/*************************************************************
		 * Check if the corresponding tree node has previous node or not
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return Indicates whether node of strTreeKey has previous node
		 * @author Thuan
		 * ***********************************************************/
		public function hasTreePrevNode(strTreeKey: String, strFuncName:String):Boolean
		{
			var hasPreviousNode:Boolean = false;
			
			try
			{
				var previousKey:String = this.dgManager.getPreviousNodeByKey(strTreeKey, true);
				hasPreviousNode = (previousKey != "");
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
			return hasPreviousNode;		
		}
		
		/*************************************************************
		 * Check if the corresponding tree node has parent node or not
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return Indicates whether node of strTreeKey has parent node
		 * @author Thuan
		 * ***********************************************************/
		public function hasTreeParentNode(strTreeKey: String, strFuncName:String):Boolean
		{
			var parenNodeKey: String = "";
			var hasParent:Boolean = false;

			try
			{
				var node: Object = this.dgManager.getNodeByKey(strTreeKey);
				if (node)
				{
					parenNodeKey = node[this.datagrid.treePIDField];
					hasParent = (parenNodeKey != Global.TREE_ROOT_CHAR && parenNodeKey != "");
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}			
			return hasParent;		
		}
		
		/*************************************************************
		 * Check whether tree node is collapsed
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return True: tree node is collapsed; False: tree node is not collapsed 
		 * @author Thuan
		 * ***********************************************************/
		public function isTreeNodeCollapse(strTreeKey: String, strFuncName: String):Boolean
		{
			try
			{
				var h:HierarchicalCollectionView = (this.datagrid.dataProvider as HierarchicalCollectionView);
				var node: Object = this.dgManager.getNodeByKey(strTreeKey);
				var uid:String = UIDUtil.getUID(node);
				if (h.openNodes[uid] == null)
					return true;			
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}	
			return false;
		}
		
		/*************************************************************
		 * Check whether tree node is expanded
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return True: tree node is expanded; False: tree node is not expanded  
		 * @author Thuan
		 * ***********************************************************/
		public function isTreeNodeExpand(strTreeKey: String, strFuncName: String):Boolean
		{
			try
			{
				var hcv:HierarchicalCollectionView = (this.datagrid.dataProvider as HierarchicalCollectionView);
				var node: Object = this.dgManager.getNodeByKey(strTreeKey);
				var uid:String = UIDUtil.getUID(node);
				if (hcv.openNodes[uid] != null)
					return true;			
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}	
			return false;			
		}
		
		/*************************************************************
		 * Check whether tree key is of tree node
		 * @param strTreeKey Key of tree
		 * @param strFuncName Name of called function
		 * @return True: key is of tree node; False: key is not of tree node 
		 * @author Thuan
		 * ***********************************************************/
		public function isTreeNodeKey(strTreeKey: String, strFuncName: String):Boolean
		{
			try
			{
				var node: Object = this.dgManager.getNodeByKey(strTreeKey);
				return (node != null);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}	
			return false;
		}
		
		/*************************************************************
		 * Insert tree node at last child node of parent node
		 * @param strParentTreeKey Parent key of inserted key
		 * @param strTreeKey Inserted key of tree
		 * @param strText Value of tree data field
		 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function insertTreeNode(strParentTreeKey: String, strTreeKey: String, strText: String, strFuncName: String):void
		{
			try
			{
				var isExistedKey:Boolean = this.dgManager.isExistedKey(strTreeKey);
				if (isExistedKey == true)
				{
					err.throwError(ErrorMessages.ERROR_TREE_EXISTED_KEY, Global.DEFAULT_LANG);
					return;
				}
				
				//Get all children of strParentTreeKey:
				var arrAllChildren: ArrayCollection = new ArrayCollection(); 
				arrAllChildren = this.dgManager.getAllChildrenByParentKey(strParentTreeKey);
				
				//Get lastChild of strParentTreeKey:
				var lastChild: Object = arrAllChildren.getItemAt(arrAllChildren.length - 1);
				
				//Get insertIndex of last child:
				var insertIndex: int = this.getRowIndexFromTreeKey(lastChild[this.datagrid.treeIDField], strFuncName) + 1;
				
				//Create node to insert:
				var node:Object=new Object();
				node[this.datagrid.treePIDField] = strParentTreeKey;
				node[this.datagrid.treeIDField] = strTreeKey;
				node[this.datagrid.treeDataField] = strText;
				
				//update CRUD mode
				setCRUDRowValue(node, this.datagrid.strInsertRowText, Global.CRUD_INSERT);
				
				//Insert item:
				var hierData:ExIHierarchicalData = this.dgManager.getTreeDataInHier();
				hierData.insertNodeAt(node, insertIndex);
				
				//Update dataProvider:
				var treeData:ExIHierarchicalData = this.dgManager.getTreeData();
				this.datagrid.dataProvider = treeData;
				
				//Expand to see inserted item:
				this.expandAtNode(strParentTreeKey, false, strFuncName);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
		}
		
		/*************************************************************
		 * Move tree node to other parent
		 * @param strParentTreeKey Parent key of moved key
		 * @param strTreeKey Moved key of tree
		 * @param strFuncName Name of called function
		 * @author Thuan
		 * ***********************************************************/
		public function moveTreeNode(strParentTreeKey:String, strTreeKey:String, strFuncName: String):void
		{
			try
			{
				var isParentChild:Boolean = this.dgManager.isParentOf(strParentTreeKey, strTreeKey);
				if (isParentChild == true)
				{
					err.throwError(ErrorMessages.ERROR_TREE_IS_PARENT_CHILD_KEY, Global.DEFAULT_LANG);
					return;
				}
//				Get all nodes:
				var hcvData:ArrayCollection = this.dgManager.getTreeDataInFlat();
//				Get moved node:
				var moveNode:Object = this.dgManager.getNodeByKey(strTreeKey);
				
//				Backup children:
//				-----------------------------------------------------------------------------
//				Backup strTreeKey and children:
				var allChildren:ArrayCollection = new ArrayCollection; 
				allChildren = this.dgManager.getAllChildrenByParentKey(strTreeKey);
				allChildren.addItemAt(moveNode, 0);

//				Change parent of moved node:
				moveNode[this.datagrid.treePIDField] = strParentTreeKey;
				
//				Delete branch of strTreeKey:
//				-----------------------------------------------------------------------------
//				hcvData = this.dgManager.deleteAllChildrenByList(hcvData, allChildren);
				var hier:ExIHierarchicalData = this.dgManager.getTreeDataInHier();
				hier.removeNodes(allChildren);
				
//				Get index to insert:
//				-----------------------------------------------------------------------------
//				Get parent node:
				var parentNode:Object = this.dgManager.getNodeByKey(strParentTreeKey);
				
//				Get all children of parent:
				var allChildrenOfParent:ArrayCollection = this.dgManager.getAllChildrenByParentKey(strParentTreeKey);
//
//				Get lastChild of strParentTreeKey:
				var lastChild: Object = allChildrenOfParent.getItemAt(allChildrenOfParent.length - 1);

//				Get insertIndex of last child:
				var insertIndex: int = this.getRowIndexFromTreeKey(lastChild[this.datagrid.treeIDField], strFuncName) + 1;

//				Add all children:
//				-----------------------------------------------------------------------------
				hier = this.dgManager.getTreeDataInHier();
				hier.insertNodesAt(allChildren, insertIndex);

//				Update dataProvider:
//				-----------------------------------------------------------------------------
				var treeData:ExIHierarchicalData = this.dgManager.getTreeData();
				this.datagrid.dataProvider = treeData;
				
//				Expand to display result:
//				-----------------------------------------------------------------------------				
				this.expandAtNode(strParentTreeKey, false, strFuncName);
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message, strFuncName);
			}
		}
		
		/*************************************************************
		 * Export AdvancedDataGrid to Excel
		 * param bColHideVisible=true allow hidden column include in excel export, bColHideVisible=false not allow hidden column include in excel export.
		 * @author Thuan
		 * ***********************************************************/
		public function excelExport(strPath:String, strListColumnKey:String, bHeaderVisible:Boolean, bDataFormat:Boolean, bHeaderOrdering:Boolean=true,bColHideVisible:Boolean=true,strExcelFileName:String="", bCharset:Boolean=true):void
		{
			try
			{
				var isError:Boolean=false;
				var listCol:String=strListColumnKey;
				
				if (strExcelFileName !="")
				{
					this.datagrid.strDefaultExportFileName=strExcelFileName;
				}
				
				if(listCol != ""  && bColHideVisible==true)
				{
					var colArr:Array = listCol.split(",");	
					for(var i:int=0;i<colArr.length;i++)
					{
						if (this.datagrid.dataFieldIndex[colArr[i]] == null)
						{
							isError = true;
							break;
						}
					}
				}
				
				if(listCol == ""  && bColHideVisible==false)
				{
					var countCol:int=this.datagrid.columnCount;
					 
					for (var j:int;j<countCol;j++)
					{
						var visibleCol:String=this.getColHDVisibleKey(j);
						if(!this.isColHide(visibleCol))
						{
							listCol +=visibleCol + ","; 	
						}
						
					}
				}
				
				if(isError)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				
				//save condition to export data
				if(this.gridoneManager.excelExportInfo)
					this.gridoneManager.excelExportInfo = null;
				
				this.gridoneManager.excelExportInfo = new ExcelExportInfo(strPath,listCol,bHeaderVisible,bDataFormat,bHeaderOrdering,bCharset);
				//export
				exportExcel();
				
//				this.datagrid.excelExport(strPath, strListColumnKey, bHeaderVisible, bDataFormat, bHeaderOrdering, bCharset);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"excelExport");
			}
		}
		
		/*************************************************************
		 * open popup to export excel
		 * @author Thuan
		 * @modify Duong Pham
		 * ***********************************************************/
		private function exportExcel():void
		{  
			Alert.show(Global.getMessageLang(Global.EXPORT_EXCEL_MESSAGE,Global.DEFAULT_LANG), Global.getMessageLang(Global.EXPORT_EXCEL_MESSAGE,Global.DEFAULT_LANG), (Alert.OK | Alert.CANCEL), null, chooseFileType, null, Alert.OK);
		}
		
		/*************************************************************
		 * Select kind of file type to export
		 * support CSV and XLS file
		 * @author Thuan
		 * @author Duong Pham
		 * ***********************************************************/
		private function chooseFileType(event:CloseEvent):void
		{
			if (event.detail == Alert.OK)
			{
				var filePopup:ExcelFileType=new ExcelFileType();
				filePopup.strDefaultExportFileFilter = datagrid.strDefaultExportFileFilter;
				PopUpManager.addPopUp(filePopup, datagrid);
				PopUpManager.centerPopUp(filePopup);
				filePopup.addEventListener(SAEvent.SELECT_FILE_TYPE, exportExcelHandler);
			}
		}
		
		/*************************************************************
		 * Select a file type
		 * support CSV and XLS file
		 * @author Thuan
		 * @author Duong Pham
		 * ***********************************************************/
		public function exportExcelHandler(event:SAEvent):void 
		{
			if (datagrid.strDefaultExportFileName != "")
			{
				if (datagrid.strDefaultExportFileName.search(/[~\\\/:\*\?"<>\|]/g) < 0)
					excelFileName=datagrid.strDefaultExportFileName;
			}
			//format number
			var file:FileReference=new FileReference();
			file.addEventListener(Event.COMPLETE, saveFileCompleteHandler)
			file.addEventListener(Event.SELECT, selectSaveFileHandler);
			file.addEventListener(IOErrorEvent.IO_ERROR, errorSaveFileHandler);
			var _txtByte:ByteArray = new ByteArray();
			if (event.fileType == "xls")
			{
				var xlsStr:String= this.gridoneManager.convertDGToHTMLTable();
				var strFileName:String = excelFileName + ".xls"; 
				file.save(xlsStr, strFileName);		
			}
			else //csv
			{
				var str:String=this.gridoneManager.makeCSVData();					
				if(this.gridoneManager.excelExportInfo.bCharset)
				{
					_txtByte.writeUTFBytes(str);
					//_txtByte.writeMultiByte(str,"utf8");  //euc-kr  for korean
					file.save(_txtByte, excelFileName + ".csv");
				}
				else
					file.save(str, excelFileName + ".csv");
			}
		}
		
		/*************************************************************
		 * Select to save that file
		 * support CSV and XLS file
		 * @author Thuan
		 * @author Duong Pham
		 * ***********************************************************/
		private function selectSaveFileHandler(event:Event):void
		{
			//this.showBusyBar("waiting");
			CursorManager.setBusyCursor();
		}
		
		/*************************************************************
		 * Save file completed
		 * support CSV and XLS file
		 * @author Thuan
		 * @author Duong Pham
		 * ***********************************************************/
		private function saveFileCompleteHandler(event:Event):void
		{
			//this.closeBusyBar(); 
			CursorManager.removeBusyCursor();
			//			Alert.show("Export successfully.", "Information", Alert.OK);
			if(datagrid.eventArr.hasOwnProperty(SAEvent.ON_END_FILE_EXPORT))
			{
				datagrid.dispatchEvent(new SAEvent(SAEvent.ON_END_FILE_EXPORT, true));
			}
		}
		
		/*************************************************************
		 * save file to see some problems
		 * support CSV and XLS file
		 * @author Thuan
		 * @author Duong Pham
		 * ***********************************************************/
		private function errorSaveFileHandler(event:IOErrorEvent):void
		{
			//this.closeBusyBar();
			CursorManager.removeBusyCursor();
		}
		
		/*************************************************************
		 * Import AdvancedDataGrid to Excel
		 * @author Thuan
		 * ***********************************************************/
		public function excelImport(strPath:String, strColumnKeyList:String, strImportValidate:String, bIgnoreHeader:Boolean, bTrimBottom:Boolean, bCharset:Boolean = true, dateInputFormat:String=""):void
		{
			try
			{
				//save condition to export data
				this.datagrid.strImportColumnKeyList=strColumnKeyList;
				this.datagrid.bTrimBottom=bTrimBottom;
				this.datagrid.bIgnoreHeaderImport=bIgnoreHeader;
				this.datagrid.bCharset = bCharset;
				this.datagrid.dateExcelImportFormat=dateInputFormat;
				//show popup to select file for importting
				Alert.show(Global.getMessageLang(Global.IMPORT_EXCEL_MESSAGE,Global.DEFAULT_LANG), Global.getMessageLang(Global.IMPORT_EXCEL_TITLE,Global.DEFAULT_LANG), Alert.OK | Alert.CANCEL, this.datagrid, selectFileToImport, null, Alert.OK);
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"excelImport");
			}
		}
		
		public function selectFileToImport(e:CloseEvent):void
		{
			if (e.detail == Alert.OK)
			{
				var fileManager:FileManager=new FileManager(this.datagrid);
				fileManager.strColumnKeyList=this.datagrid.strImportColumnKeyList;
				fileManager.bIgnoreHeader=datagrid.bIgnoreHeaderImport;
				fileManager.bTrimBottom=datagrid.bTrimBottom;
				fileManager.bCharset = this.datagrid.bCharset;
				fileManager.dateImportFormat=this.datagrid.dateExcelImportFormat;
				fileManager.importFile();
			}
		}
		
		/*************************************************************
		 * set text align of image in image text 
		 * @author Duong Pham
		 * ***********************************************************/
		public function setImagetextAlign(strColumnKey:String, strAlign:String):void
		{
			try
			{
				if (this.datagrid.dataFieldIndex[strColumnKey] == null)
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				var col:ExAdvancedDataGridColumn=gridone.getColumnByDataField(strColumnKey) as ExAdvancedDataGridColumn;
				col.public::setStyle("imageTextAlign", strAlign);					
				this.datagrid.invalidateList();					
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setImagetextAlign");
			}
		}
		
		/*************************************************************
		 * set focus for specified cell
		 * @author Duong Pham
		 * ***********************************************************/
		public function setCellFocus(strColumnKey:String,nRow:int,bEditmode:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(strColumnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				
				if (nRow < 0 || nRow >= this.datagrid._bkDP.length)
					err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);								
				
				// change selection mode to selectCell
				if(!this.datagrid.selectCell)
				{
					this.datagrid.selectCell = true;
					datagrid.selectionMode = "multipleCells";
				}
				
				this.scrollToIndex(nRow);
				this.datagrid.endEditCell(ExAdvancedDataGridEventReason.OTHER);
				
				var item:Object=this.datagrid.getBackupItem(nRow);
				nRow = this.datagrid.getItemIndex(item);	
				var colIndex:int = this.datagrid.dataFieldIndex[strColumnKey];
				var col:ExAdvancedDataGridColumn = this.datagrid.columns[colIndex] as ExAdvancedDataGridColumn;
				this.datagrid._selectedColIndex = colIndex;
				this.datagrid._selectedRowIndex = nRow;
				ExternalInterface.call("setFocusCell");
				if(bEditmode)
				{								
					if(col.editable)
					{
						if(!this.datagrid.isEditable)
						{
							this.datagrid.isEditable = true;
							this.datagrid.editable = "all";
						}
						this.datagrid.editedItemPosition = {columnIndex:colIndex,rowIndex:nRow};
						this.datagrid.setSelectCell(colIndex,nRow);
					}
					else
					{
						this.datagrid.setSelectCell(colIndex,nRow);							
					}
				}
				else
				{					
					this.datagrid.setSelectCell(colIndex,nRow);						
				}
				updateHorizontalScroll(colIndex);
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"setCellFocus");					
			}
		}
		
		/*************************************************************
		 * update horiziontal scroll bar when changing column index
		 * @author Duong Pham
		 * ***********************************************************/
		private function updateHorizontalScroll(colIndex:int):void
		{	
			var numCol:int = 0;
			for each(var col:ExAdvancedDataGridColumn in this.datagrid.columns)
			{
				if(col.visible)
					numCol ++;
			}				 
			var displayNumCol:int = numCol - this.datagrid.maxHorizontalScrollPosition;
			var position:int = colIndex - displayNumCol + 1;				
			if(position > 0)
				this.datagrid.horizontalScrollPosition=position;
			else
				this.datagrid.horizontalScrollPosition=0;				
		}
		
		/*************************************************************
		 * set group merge
		 * @param strColumnKeyList String
		 * @ author Duong Pham
		 * ***********************************************************/
		public function setGroupMerge(strColumnKeyList:String):void
		{
			try
			{
				if(this.datagrid.summaryBar.hasSummaryBar()) 
					this.datagrid.summaryBar.clearSummaryBar();
				if (!datagrid.isTree)
				{
					if (strColumnKeyList == null || strColumnKeyList == "")
						err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
					
					//save old value before setting group merge 
					
					this.datagrid.isDraggableCol = datagrid.draggableColumns;
					this.datagrid.orignalStrHDClickAction = datagrid.strHDClickAction;
					
					//require condition:
					this.datagrid.draggableColumns = false; 
					this.datagrid.strHDClickAction = "select";
					//set group merge
					var columnKeyList:Array=strColumnKeyList.split(',');	
					var col:ExAdvancedDataGridColumn;
					for each (var columnKey:String in columnKeyList)
					{
						if (StringUtil.trim(columnKey).length > 0)
						{
							col = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
							col.editable = false;//remove icon for combobox when set group merge
							//this.setColCellMerge(columnKey, true);
							col.merge = true;
						}
					}
					//add to list
					this.datagrid.summaryBar.columnMergeList=strColumnKeyList;
					this.datagrid.getGroupMergeInfo();
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setGroupMerge");		
			}
		}
		
		/*******************************************************6******
		 * check column is merged or not
		 * @author: Duong Pham
		 * ***********************************************************/
		public function isGroupMergeColumn(columnKey:String): Boolean
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(columnKey))
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);	
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				return col.merge;					
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"isGroupMergeColumn");					
			}
			return false;
		}
		

		
		/*******************************************************6******
		 * check grid that has group merge or not
		 * @author Duong Pham
		 * ***********************************************************/
		public function hasGroupMerge(): Boolean
		{
			var result : Boolean = false;
			for each (var col:ExAdvancedDataGridColumn in this.datagrid.columns)
			{
				if (col.merge)
				{
					result =true;
					break;
				}
			}
			return result;
		}
		
		/*******************************************************6******
		 * clear group merge
		 * @author Duong Pham
		 * ***********************************************************/
		public function clearGroupMerge():void  
		{
			try
			{
				if(this.datagrid.summaryBar && this.datagrid.summaryBar.hasSummaryBar())
				{
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_EXIST, Global.DEFAULT_LANG);
				}
				for each (var col:ExAdvancedDataGridColumn in this.datagrid.columns)
				{
					if (col.merge)
						col.merge = false;
				}	
//				clearSummaryBar();
				datagrid.mergeCells = null;
				datagrid.lstMergeColumn = null;
				this.datagrid.draggableColumns = this.datagrid.isDraggableCol;
				this.datagrid.strHDClickAction = this.datagrid.orignalStrHDClickAction;
				this.datagrid.invalidateList();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"clearGroupMerge");					
			}
		}
		
		/*************************************************************
		 * add summary bar
		 * author Duong Pham
		 * ***********************************************************/
		public function addSummaryBar(strSummaryBarKey:String, strText:String, strMergeColumn:String, strFunc:String, strColumnList:String,position:String="bottom"):void
		{
			try 
			{
				if(datagrid.dataProvider == null)
					err.throwError(ErrorMessages.ERROR_DATAPROVIDER_NULL, Global.DEFAULT_LANG);
				if(strColumnList== null || strColumnList.length == 0)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID,Global.DEFAULT_LANG);
				if(strSummaryBarKey.length ==0 ) 
					err.throwError(ErrorMessages.ERROR_SUMMARY_KEY_INVALID,Global.DEFAULT_LANG); 
				
				if(this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar))
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_HAS_EXIST,Global.DEFAULT_LANG); 
				
				var listColumn:Array = strColumnList.split(',');
				var t:int;
				if(position == "right")
				{
					if(strMergeColumn  != SummaryBarConstant.SUMMARYALL)
						err.throwError(ErrorMessages.ERROR_MERGE_INVALID,Global.DEFAULT_LANG);
					
					for (t = 0; t < listColumn.length; t++) 
					{
						if(this.datagrid.dataFieldIndex[listColumn[t]] <= -1)
						{
							err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
							break;
						}
						if(this.datagrid.columns[this.datagrid.dataFieldIndex[listColumn[t]]].type != ColumnType.NUMBER)
						{
							err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
							break;
						}
					}
					
					this.datagrid.summaryBar.addSummaryBar(strSummaryBarKey, strText, strMergeColumn, strFunc, strColumnList,position);
				}
				else
				{
					//build list column merge
					this.datagrid.summaryBar.buildListColMerge();
					
					//check if col merge is valid
					if(strMergeColumn  != SummaryBarConstant.SUMMARYALL)
					{
						if(!this.datagrid.summaryBar.isValidColMerge(strMergeColumn,datagrid.lstMergeColumn))
						{
							err.throwError(ErrorMessages.ERROR_MERGE_INVALID,Global.DEFAULT_LANG);
						}
					}
					
					if(strMergeColumn != SummaryBarConstant.SUMMARYALL && datagrid.dataFieldIndex[strMergeColumn]==null)
						err.throwError(ErrorMessages.ERROR_MERGE_INVALID,Global.DEFAULT_LANG);
					
					for (t = 0; t < listColumn.length; t++) 
					{
						if(this.datagrid.dataFieldIndex[listColumn[t]] <= -1)
						{
							err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
							break;
						}
						if(listColumn[t] == strMergeColumn)
						{
							err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
							break;
						}
//						//prevent merge column in colkey list
//						if(strMergeColumn  != SummaryBarConstant.SUMMARYALL && listColumn[t] == strMergeColumn)
//						{
//							err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
//							break;
//						}
						
						//prevent merge column in colkey list
						if(strMergeColumn  != SummaryBarConstant.SUMMARYALL)
						{
							for(var j:int=0; j<this.datagrid.lstMergeColumn.length; j ++)
							{
								if(this.datagrid.lstMergeColumn[j] == listColumn[t])
								{									
									var indexOfMergedColOfSummary:int = this.datagrid.lstMergeColumn.getItemIndex(strMergeColumn);
									if(j <= indexOfMergedColOfSummary)
									{
										err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
										break;
									}
								}
							}
						}
						
					}
					//check if column merge of summary bar key has been exist, if yes replace and remove old
					if(strMergeColumn != SummaryBarConstant.SUMMARYALL) 
					{
						this.datagrid.summaryBar.removeOldSummarBar(strMergeColumn);
					}
					this.datagrid.summaryBar.clearSort();
					this.datagrid.summaryBar.addSummaryBar(strSummaryBarKey, strText, strMergeColumn, strFunc, strColumnList,position);
					this.datagrid.summaryBar.resetSort();
					if(this.datagrid.hasSubTotal)
					{
						this.datagrid.getGroupMergeInfo();
						this.datagrid.invalidateList();
					}
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"addSummaryBar");					
				return;
			}
		}
		
		/*************************************************************
		 * clear summary bar
		 * @author Duong Pham
		 * ***********************************************************/
		public function clearSummaryBar():void
		{
			if(this.datagrid.summaryBar.hasSummaryBar())
				this.datagrid.summaryBar.clearSummaryBar();	
		}
		
		/*************************************************************
		 * get summary bar value		 
		 * @author: Duong Pham
		 * ***********************************************************/
		public function getSummaryBarValue(strSummaryBarKey:String, strColumnKey:String, nMergeIndex:Number, bDataFormat:Boolean=true):String
		{
			try
			{
				var returnValue : String ;
				var item : Object;
				if(this.datagrid.lstSummaryBar == null)
					err.throwError(ErrorMessages.ERROR_NO_SUMMARY_BAR, Global.DEFAULT_LANG);
				
				var isExistedSummaryBar : Boolean = this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar);
				
				//check if this is a total, subtotal
				if(!isExistedSummaryBar)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_NOT_EXIST,Global.DEFAULT_LANG);
				
				if(!this.datagrid.summaryBar.isInvalidColumnKey(this.datagrid.lstSummaryBar[strSummaryBarKey],strColumnKey))
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				
				var summaryBarType:String = this.datagrid.summaryBar.getSummaryBarType(strSummaryBarKey);
				
				var index : int;
				var count : int = -1;
				var column : ExAdvancedDataGridColumn;
				if(summaryBarType == "total")		//total
				{
					returnValue = this.datagrid.summaryBar.getSummaryBarValueForTotal(strSummaryBarKey, strColumnKey, nMergeIndex,bDataFormat);
				}
				else if(summaryBarType == "subtotal")		//subtotal
				{
					returnValue = this.datagrid.summaryBar.getSummaryBarValueForSubTotal(strSummaryBarKey, strColumnKey, nMergeIndex,bDataFormat);
				}
				else		//total column
				{
					returnValue = this.datagrid.summaryBar.getSummaryBarValueForTotalColumn(strSummaryBarKey, strColumnKey, nMergeIndex,bDataFormat);
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"getSummaryBarValue");
			}
			return returnValue;
		}
		
		/*************************************************************
		 * set summary bar color
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarColor(strSummaryBarKey:String, strFgColor:String, strBgColor:String):void
		{
			try 
			{
				if(this.datagrid.lstSummaryBar == null)
					err.throwError(ErrorMessages.ERROR_NO_SUMMARY_BAR, Global.DEFAULT_LANG);
				
				//check if this is a total, subtotal
				var isExistedSummaryBar : Boolean = this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar);
				
				//check if this is a total, subtotal
				if(!isExistedSummaryBar)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_NOT_EXIST,Global.DEFAULT_LANG);
				
				var summaryBarType:String = this.datagrid.summaryBar.getSummaryBarType(strSummaryBarKey);
				
				if(summaryBarType == "total") // total
				{
					this.datagrid.summaryBar.setSummaryBarColor(strSummaryBarKey, strFgColor, strBgColor, true);
				}
				else if(summaryBarType == "subtotal")   //sub total
				{
					this.datagrid.summaryBar.setSummaryBarColor(strSummaryBarKey, strFgColor, strBgColor , false);
				}
				else
				{
					var summaryBar:SummaryBar = this.datagrid.lstSummaryBar[strSummaryBarKey];
					setColCellBgColor(summaryBar.totalColDataField,strBgColor);
					setColCellFgColor(summaryBar.totalColDataField,strFgColor);
				}
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setSummaryBarColor");					
			}
		}
		
		/*************************************************************
		 * set summary bar font
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarFont(strSummaryBarKey:String, strName:String, nSize:Number, bBold:Boolean, bItalic:Boolean, bUnderLine:Boolean, bCenterLine:Boolean, columnKey : String=null):void
		{
			try
			{
				if(this.datagrid.lstSummaryBar == null && this.datagrid.lstSummaryBar == null)
					err.throwError(ErrorMessages.ERROR_NO_SUMMARY_BAR, Global.DEFAULT_LANG);
				
				//check if this is a total, subtotal
				var isExistedSummaryBar : Boolean = this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar);
				
				//check if this is a total, subtotal
				if(!isExistedSummaryBar)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_NOT_EXIST,Global.DEFAULT_LANG);
				
				if(isNaN(nSize))
					err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA,Global.DEFAULT_LANG);
				
				var summaryBarType:String = this.datagrid.summaryBar.getSummaryBarType(strSummaryBarKey);
				
				var fontFamily : String;
				var fontSize : String;
				var fontWeight : String;
				var fontStyle : String ;
				var fontULine : String;
				
				if (strName != null || strName != "")
					fontFamily = strName;
				if (!isNaN(nSize))
					fontSize = nSize.toString();
				if (bBold) 
					fontWeight = "bold";
				else
					fontWeight = "normal";
				if (bItalic)
					fontStyle = "italic";
				else
					fontStyle =  "normal";
				
				if (bUnderLine)
					fontULine = "underline"; 
				else
					fontULine = "none";
												
				if(summaryBarType == "total") // total
				{
					this.datagrid.summaryBar.setSummaryBarFont(strSummaryBarKey, fontFamily,fontSize,fontWeight,fontStyle,fontULine,bCenterLine , true, columnKey);
				}
				else if(summaryBarType == "subtotal")  //sub total
				{
					this.datagrid.summaryBar.setSummaryBarFont(strSummaryBarKey, fontFamily,fontSize,fontWeight,fontStyle,fontULine,bCenterLine ,false, columnKey);
				}
				else
				{
					var summaryBar:SummaryBar = this.datagrid.lstSummaryBar[strSummaryBarKey];
					setColCellFont(summaryBar.totalColDataField,fontFamily,nSize,bBold,bItalic,bUnderLine,bCenterLine);
				}
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setSummaryBarFont");					
			}
		}
		
		/*************************************************************
		 * set summary bar format
		 * @author: Duong Pham
		 * ***********************************************************/
		public function setSummaryBarFormat(strSummaryBarKey:String, strColumnKey:String, strFormat:String):void
		{
			try
			{
				if(this.datagrid.lstSummaryBar == null)
					err.throwError(ErrorMessages.ERROR_NO_SUMMARY_BAR, Global.DEFAULT_LANG);
				
				//check if this is a total, subtotal
				var isExistedSummaryBar : Boolean = this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar);
				
				//check if this is a total, subtotal
				if(!isExistedSummaryBar)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_NOT_EXIST,Global.DEFAULT_LANG);
				
				var summaryBarType:String = this.datagrid.summaryBar.getSummaryBarType(strSummaryBarKey);
				
				if(summaryBarType == "total")	//total
					this.datagrid.summaryBar.setSummaryBarFormat(strSummaryBarKey, strColumnKey, strFormat);
				else if(summaryBarType == "subtotal")		 //sub total
					this.datagrid.summaryBar.setSummaryBarFormat(strSummaryBarKey, strColumnKey, strFormat);
				else
				{
					var summaryBar:SummaryBar = this.datagrid.lstSummaryBar[strSummaryBarKey];
					 this.datagrid.summaryBar.setSummaryBarFormat(strSummaryBarKey, summaryBar.totalColDataField, strFormat);
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setSummaryBarFormat");					
			} 
		}
		
		/*************************************************************
		 * set summary bar function
		 * @param strSummaryBarKey String
		 * @param strColumnKey String
		 * @param strFormat String
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarFunction(strSummaryBarKey:String, strFunc:String, strColumnKey:String):void
		{
			try
			{
				if(this.datagrid.lstSummaryBar == null)
					err.throwError(ErrorMessages.ERROR_NO_SUMMARY_BAR, Global.DEFAULT_LANG);
				//check if this is a total, subtotal, total column
				var isExistedSummaryBar : Boolean = this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar);
				//check if this is a total, subtotal, total column
				if(!isExistedSummaryBar)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_NOT_EXIST,Global.DEFAULT_LANG);
				
				if(!(strFunc.toUpperCase() == "SUMMARRYALL" || strFunc.toUpperCase() == "COUNT" || strFunc.toUpperCase() == "SUM" || strFunc.toUpperCase() == "AVERAGE"))
					err.throwError(ErrorMessages.ERROR_INVALID_SUMMARY_BAR_FUNCTION,Global.DEFAULT_LANG);
				
				var summaryBarType:String = this.datagrid.summaryBar.getSummaryBarType(strSummaryBarKey);
				
				if(!((this.datagrid.lstSummaryBar[strSummaryBarKey] as SummaryBar).strFunction == 'custom'))
				{
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_VALUE, Global.DEFAULT_LANG);
				}
				if((this.datagrid.lstSummaryBar[strSummaryBarKey] as SummaryBar).functionList[strColumnKey] == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				
				var summaryBar:SummaryBar = this.datagrid.lstSummaryBar[strSummaryBarKey] as SummaryBar;
				var positionTotalChange : Dictionary;
				if(summaryBar.position == "right")
				{
					summaryBar.strFunction = strFunc;
					positionTotalChange = (datagrid.columns[datagrid.dataFieldIndex[summaryBar.totalColDataField]] as ExAdvancedDataGridColumn).positionTotalChange;
				}
				else
				{
					if(summaryBar.functionList == null)
						summaryBar.functionList = new Dictionary();
					var column:ExAdvancedDataGridColumn =  (datagrid.columns[datagrid.dataFieldIndex[strColumnKey]] as ExAdvancedDataGridColumn);
					if(column.type != ColumnType.NUMBER)
					{
						strFunc = SummaryBarConstant.FUNC_COUNT;
					}
					summaryBar.functionList[strColumnKey] = strFunc;
					positionTotalChange = column.positionTotalChange;
				}
				this.datagrid.summaryBar.removeCustomSummaryBarValue(strSummaryBarKey,positionTotalChange);
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setSummaryBarFunction");					
			}
		}
		
		/*************************************************************
		 * set summary bar text
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarText(strSummaryBarKey:String, strText:String):void
		{
			try
			{
				if(this.datagrid.lstSummaryBar == null)
					err.throwError(ErrorMessages.ERROR_NO_SUMMARY_BAR, Global.DEFAULT_LANG);
				
				//check if this is a total, subtotal
				var isExistedSummaryBar : Boolean = this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar);
				
				//check if this is a total, subtotal
				if(!isExistedSummaryBar)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_NOT_EXIST,Global.DEFAULT_LANG);
				
				var summaryBarType:String = this.datagrid.summaryBar.getSummaryBarType(strSummaryBarKey);
				
				this.datagrid.summaryBar.setSummaryBarText(strSummaryBarKey, strText,summaryBarType);
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setSummaryBarText");					
				return;
			}			
		}
		
		/*************************************************************
		 * set summary bar function
		 * @author Duong Pham
		 * ***********************************************************/
		public function setSummaryBarValue(strSummaryBarKey:String, strColumnKey:String, nMergeIndex:Number, strValue:String):void
		{
			try
			{
				if(this.datagrid.lstSummaryBar == null)
					err.throwError(ErrorMessages.ERROR_NO_SUMMARY_BAR, Global.DEFAULT_LANG);
				
				//check if this is a total, subtotal
				var isExistedSummaryBar : Boolean = this.datagrid.summaryBar.isExistSummaryKey(strSummaryBarKey,this.datagrid.lstSummaryBar);
				
				//check if this is a total, subtotal
				if(!isExistedSummaryBar)
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_NOT_EXIST,Global.DEFAULT_LANG);
				
				if(!this.datagrid.summaryBar.isInvalidColumnKey(this.datagrid.lstSummaryBar[strSummaryBarKey],strColumnKey))
				{
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				if(!((this.datagrid.lstSummaryBar[strSummaryBarKey] as SummaryBar).strFunction == 'custom'))
				{
					err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_VALUE, Global.DEFAULT_LANG);
				}
				
				var summaryBarType:String = this.datagrid.summaryBar.getSummaryBarType(strSummaryBarKey);
				
				if(summaryBarType == "subtotal")		//sub total
				{
					if(isNaN(Number(nMergeIndex)))
					{
						err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_INDEX_INVALID, Global.DEFAULT_LANG);
					} 
					if(nMergeIndex < -1)
					{
						err.throwError(ErrorMessages.ERROR_SUMMARY_BAR_INDEX_INVALID, Global.DEFAULT_LANG);
					}
				}
				this.datagrid.summaryBar.setSummaryBarValue(strSummaryBarKey, strColumnKey, nMergeIndex, strValue, summaryBarType);
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setSummaryBarValue");					
			}			
		}
		
		/*************************************************************
		 * set column excel with asterisk character file function
		 * @param strColumnKey : String, nStartIndex : int, nCount : int
		 * author: Hoang Pham
		 * ***********************************************************/
		public function setColCellExcelAsterisk(strColumnKey:String, nStartIndex:int, nCount:int):void
		{
			this.setColumnProperty(strColumnKey, "replacedStartIndex", nStartIndex);
			this.setColumnProperty(strColumnKey, "replacedLength", nCount);
		}
		
		/*************************************************************
		 * set header excel file function
		 * @param strTitle : String ,nHeigh : int, nFontSize : int, strAlign : String
		 * author Thuan
		 * ***********************************************************/
		public function setExcelHeader(strTitle:String, nHeigh:int, nFontSize:int, strAlign:String, strBottom:String=''):void
		{
			this.gridoneManager.styleHeader = new StyleHeader();
			this.gridoneManager.styleHeader.data = strTitle;
			this.gridoneManager.styleHeader.row_height = nHeigh;
			this.gridoneManager.styleHeader.font_size = nFontSize;
			this.gridoneManager.styleHeader.text_align = strAlign;
			if (strBottom.length > 0)
			{
				var data:Array = strBottom.split('%%');
				this.datagrid.subHeaderStyle = new Array();
				for (var i:int=0; i < data.length; i++)
				{
					var temp:StyleHeader = new StyleHeader();
					temp.data = data[i].toString();
					this.datagrid.subHeaderStyle[i] = temp;
				}
			}
		}
		
		/*************************************************************
		 * set footer excel file function
		 * @param strTitle : String ,nHeigh : int, nFontSize : int, strAlign : String
		 * author Thuan
		 * ***********************************************************/
		public function setExcelFooter(strTitle:String, nHeigh:int, nFontSize:int, strAlign:String):void
		{
			this.gridoneManager.styleFooter = new StyleFooter();
			this.gridoneManager.styleFooter.data = strTitle;
			this.gridoneManager.styleFooter.row_height = nHeigh;
			this.gridoneManager.styleFooter.font_size = nFontSize;
			this.gridoneManager.styleFooter.text_align = strAlign;
		}
		
		/*************************************************************
		 * clear excel file info function
		 * author Thuan
		 * ***********************************************************/
		public function clearExcelInfo():void
		{
			this.gridoneManager.styleHeader=null;
			this.gridoneManager.styleFooter=null;
		}
		/*************************************************************
		 * lose focus
		 * @author Duong Pham
		 * ***********************************************************/
		public function loseFocus():void
		{
			this.datagrid.endEditCell(ExAdvancedDataGridEventReason.OTHER);
			this.datagrid.focusManager.deactivate();
			this.datagrid.selectedIndex = -1;
			
			//Thuan leaved on 2012Dec24
//			if(!this.datagrid.selectCell)
//				this.datagrid.selectedIndex = -1;
		}
		
		
		/*************************************************************
		 * get datafield by visible column index
		 * @author Duong Pham
		 * ***********************************************************/
		public function getDataFieldVisibleByIndex(visibleIndex:int):String
		{
			var dataField:String = "";
			var index:int = -1;
			if(this.datagrid.columns.length > 0)
			{
				for each(var col:ExAdvancedDataGridColumn in this. datagrid.columns)
				{
					if(col.visible)
					{
						index++;
						if(index == visibleIndex)
						{
							dataField = col.dataField;
							break;
						}
					}
				}
			}
			return dataField;
		}
		
		/*************************************************************
		 * create row data to test performance
		 * @author Duong Pham
		 * ***********************************************************/
		public function generateTestData(numRows:int,numCols:int,isNormal:Boolean=true):void
		{
			CursorManager.setBusyCursor();
			if(datagrid.dataProvider && datagrid.dataProvider.length > 0)
				datagrid.dataProvider = null;
			//create data
			var rowData:String="";
			var i:int;
			var j:int;
			var index:int=0;
			var provider:ArrayCollection = new ArrayCollection();
			var obj:Object;
			if(isNormal)
			{
				for ( i=0; i < numRows; i++)
				{		
					obj = new Object();
					obj['col0'] = "0";				
					obj['col1'] = "(" + i + ",1)";
					obj['col1_index']= 0;
					obj['col2'] = (i+1)+"000";
					obj['col3'] = (i+1) * 2;
					obj['col4'] = (i+1) * 3;
					for (j = 5; j < numCols; j++)
					{	
						obj['col'+j] = "(" + i + "," + j + ")";
					}
					provider.addItem(obj);
				}
			}
			else
			{
				for ( i=0; i < numRows; i++)
				{		
					obj = new Object();
					obj['col0'] = "0";				
					obj['col1'] = (i+1)*4 +"000";
					obj['col2'] = (i+1)+"000";
					obj['col3'] = (i+1) * 2;
					obj['col4'] = (i+1) * 3;
					for (j = 5; j < numCols; j++)
					{	
						obj['col'+j] = "(" + i + "," + j + ")";
					}
					provider.addItem(obj);
				}
			}
			datagrid.dataProvider = provider;
			gridoneManager.bkDataProvider(provider);
			gridoneManager.updateExternalVerticalScroll(provider.length);
//			this.gridone.activity.closeBusyBar();
			CursorManager.removeBusyCursor();
		}
		
		/*************************************************************
		 * get real index (include visible index and invisible index) from the visible index
		 * @param visibleIndex int
		 * @return int
		 * @author Duong Pham
		 * ***********************************************************/
		public function getRealIndexByVisibleIndex(visibleIndex:int):int
		{
			var realIndex:int = -1;
			for each(var col:ExAdvancedDataGridColumn in this.datagrid.columns)
			{
				if(col.visible)
					realIndex ++;
				if(realIndex == visibleIndex)
					break;
			}
			return this.datagrid.dataFieldIndex[col.dataField];
		}
		
		/*************************************************************
		 * insert a specified column for grid
		 * @param columnKey column dataField 
		 * @param columnText header text
		 * @param columnType column type: combo, text, calendar...
		 * @param maxLength length of text in a cell, or length of a number
		 * @param columnWidth column width
		 * @param editable indicate whether column is editable or not
		 * @return ExAdvancedDataGridColumn
		 * ***********************************************************/
		public function insertColumn(columnKey:String, columnText:String, columnType:String, maxLength:String, columnwidth:String, editable:Boolean,parentDataField:String,insertAt:String):ExAdvancedDataGridColumn
		{		
			try
			{
				if(this.datagrid.dataFieldIndex[columnKey])
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				var insertedCol:ExAdvancedDataGridColumn=new ExAdvancedDataGridColumn();
				insertedCol.minWidth=0;
				insertedCol.dataField=columnKey;
				insertedCol.headerText=columnText;				
				insertedCol.editable = editable;			
				insertedCol.parent=parentDataField;
				if (editable)
					insertedCol.cellActivation=Global.ACTIVATE_EDIT;
				else
					insertedCol.cellActivation=Global.ACTIVATE_ONLY;
				
				if (columnwidth.charAt(columnwidth.length - 1) == "%")
				{
					insertedCol.percentWidth=columnwidth;
				}
				else
				{
					insertedCol.width=parseInt(columnwidth);
				}
				
				datagrid.totalVisibleColumnWidth += parseInt(columnwidth);
				
				insertedCol.orginalMaxLength=maxLength;		
				
				if (Number(maxLength) < 0 ) //Process for using big number
				{
					if(columnType.toUpperCase() == ColumnType.NUMBER)
					{
						var arr:Array = maxLength.toString().split(".");
						var precLength: int = -1;
						if (arr.length > 1)
							precLength = parseInt(arr[1]);
						insertedCol.precision = precLength;
						insertedCol.checkPrecision = precLength;
						insertedCol.maxValue = Number.MAX_VALUE;	
					}
				}
				else if (parseInt(maxLength) >= 0)
				{
					if(columnType.toUpperCase() == ColumnType.NUMBER)
					{
						var precisionLength:int=parseInt(maxLength.toString().split(".")[1]);
						var numberLength:int=parseInt(maxLength.toString().split(".")[0]);
						if(numberLength==0)
							insertedCol.maxValue = Math.pow(10, numberLength) - Math.pow(0.1, precisionLength+1);
						insertedCol.precision = precisionLength;
						insertedCol.checkPrecision=precisionLength;
					}
					else
					{
						insertedCol.maxLength=parseInt(maxLength);
						insertedCol.editorMaxChars=parseInt(maxLength);	
					}
				}
				insertedCol.type=columnType.toUpperCase();
				this.gridone.setItemRenderer(insertedCol,insertedCol.type,false);	
				_columnCount += 1;
				var col:ExAdvancedDataGridColumn;
				var listColumns:ArrayCollection;
				var insertAtPosition:int;
				if(!isNaN(parseInt(insertAt)))
				{
					insertAtPosition = parseInt(insertAt);
				}
				else
				{
					insertAtPosition = this.datagrid.dataFieldIndex[insertAt];
				}
				var realIndex:int = getRealIndexByVisibleIndex(insertAtPosition);
				col = this.datagrid.columns[realIndex];
				var i:int=0;
				//insert column into datagrid
				if(datagrid._isGroupedColumn)
				{
					updateColumnPositionInGroupColumn(insertedCol,realIndex,false);
				}
				else
				{
					listColumns = new ArrayCollection( this.datagrid.columns);
					listColumns.addItemAt(insertedCol,insertAtPosition);
					this.datagrid.columns = listColumns.toArray();
					//update dataFieldIndex
					this.datagrid.dataFieldIndex = new Object();
					for (i=0; i < listColumns.length; i++)
					{
						this.datagrid.dataFieldIndex[listColumns[i].dataField]=i;
					}	
				}
				gridoneManager.updateExternalHorizontalScroll();
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"insertColumn");	
			}
			return insertedCol;	
		}
		
 
		/*************************************************************
		 * export excel by active X
		 * @author Duong Pham
		 * ***********************************************************/
		public function exportExcelByActiveX():String
		{
			if(this.gridoneManager.excelExportInfo)
				this.gridoneManager.excelExportInfo = null;
			
			this.gridoneManager.excelExportInfo = new ExcelExportInfo("","",true,false,true,true);
			return this.gridoneManager.convertDGToHTMLTable();			
		}
		
		/*************************************************************
		 * import excel by active X
		 * @author Duong Pham
		 * ***********************************************************/
		public function importExcelByActiveX(str:String):void
		{
			var columnSep:String = DataGridManager.columnSeparator;
			var rowSep:String = DataGridManager.rowSeparator;
			
			DataGridManager.columnSeparator = "|";
			DataGridManager.rowSeparator = "\n";
			
			gridone.setTextData(str,true,true,false);
			
			DataGridManager.columnSeparator = columnSep;
			DataGridManager.rowSeparator = rowSep;
		}
		
		/*************************************************************
		 * set visible row according to order of setRowHide is reverted
		 * @author Duong Pham
		 * ***********************************************************/
		public function undoRowHide():void
		{
			var i:int;
			if(this.datagrid.invisibleIndexOrder == null || this.datagrid.invisibleIndexOrder.length == 0)
				return;
			if(datagrid.invisibleIndexOrder == null || datagrid.invisibleIndexOrder.length == 0)
				return;
			if(this.datagrid.itemEditorInstance)
				this.datagrid.destroyItemEditor();
			
			if(this.datagrid.nRowHideBuffer < this.datagrid.invisibleIndexOrder.length)
			{
				//remove these element which does not need to undo	
				var index:int=0;
				for(i=this.datagrid.invisibleIndexOrder.length-1; i>=0; i--)
				{
					index ++;
					if(index > this.datagrid.nRowHideBuffer)
					{
						this.datagrid.invisibleIndexOrder.splice(i,1);
					}
				}
			}
			
			var itemArr:Array = this.datagrid.invisibleIndexOrder[this.datagrid.invisibleIndexOrder.length-1];
			var position:Object;
			var item:Object;
			for(i=itemArr.length-1; i>=0; i--)
			{
				item = this.datagrid._bkDP.getItemAt(itemArr[i]);
				position = getPositionOfIndexInArr(itemArr[i],datagrid.invisibleIndexOrder);
				if(position)
				{
					//remove element is not invisible any more
					var detailItemArr:Array = this.datagrid.invisibleIndexOrder[position['row']];
					detailItemArr.splice(position['column'],1);
					if(detailItemArr.length == 0)
					{
						this.datagrid.invisibleIndexOrder.splice(position['row'],1);
					}
				}
				item[Global.ROW_HIDE] = false;					
				setCRUDRowValue(item, this.datagrid.strDeleteRowText, Global.CRUD_DELETE);
			}
			this.datagrid.filter = new FilterDataWithRowHide(this.datagrid.filter,null);	
			(this.datagrid.dataProvider as ArrayCollection).filterFunction = this.datagrid.filter.apply;
			(this.datagrid.dataProvider as ArrayCollection).refresh();
			if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
			{
				this.datagrid.summaryBar.reCreateSummaryBar();
			}
			//update Application height when data is changed
			gridoneManager.updateGridHeight();
			
			gridoneManager.updateExternalVerticalScroll(datagrid.getLength());
			//update group mergeCells of datagrid
			if(hasGroupMerge())
			{
				this.datagrid.getGroupMergeInfo();
			}
			
			if(isDrawUpdate)
				this.datagrid.invalidateList();
		}
		
		/*************************************************************
		 * set multi rows is hidden
		 * @param strListHideIndex String contain list of index to be set invisible rows
		 * @param bHide Boolean
		 * @author Duong Pham
		 * ***********************************************************/
		public function setMultiRowsHide(strListHideIndex:String,bHide:Boolean,isHandleBkDp:Boolean=true):void
		{
			try
			{
				if(strListHideIndex == "" || strListHideIndex == null || strListHideIndex.indexOf(",") == -1)
					err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
				
				var arrListHideIndex:Array = strListHideIndex.split(",");
				var i:int=0;
				for(i=0; i<arrListHideIndex.length; i++)
				{
					if(arrListHideIndex[i] < 0 || arrListHideIndex[i] >= this.datagrid.getLength())
					{
						err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
						break;
					}
				}
				
				var indexBk:int=-1;
				var hiddenIndexArr:Array=new Array();
				if(this.datagrid.itemEditorInstance)
					this.datagrid.destroyItemEditor();
				if (!this.datagrid.isTree)
				{
					if(datagrid.invisibleIndexOrder == null)
						datagrid.invisibleIndexOrder = new Array();
					var item:Object;
					var nRow:int = -1;
					for(i=0; i<arrListHideIndex.length; i++)
					{
						nRow = arrListHideIndex[i];
						if(isHandleBkDp)
						{
							if(nRow < 0 || nRow >= this.datagrid._bkDP.length)
								err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
							item = this.datagrid._bkDP.getItemAt(nRow);
							indexBk = nRow;
						}
						else
						{
							//if bHide =true ,nRow will be followed index of dataProvider
							if(bHide)
							{
								if(nRow < 0 || nRow >= this.datagrid.dataProvider.length)
									err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
								item = this.datagrid.getItemAt(nRow);
								indexBk = this.datagrid._bkDP.getItemIndex(item);
							}
							else
							{
								if(nRow < 0 || nRow >= this.datagrid._bkDP.length)
									err.throwError(ErrorMessages.ERROR_INDEX_INVALID, Global.DEFAULT_LANG);
								//ifbHide = false, nRow will be followed index of dataProviderBackup
								item = this.datagrid._bkDP.getItemAt(nRow);
								indexBk = nRow;
							}
						}
						//check indexBk has existed or not in datagrid.invisibleIndexOrder
						var position:Object = getPositionOfIndexInArr(indexBk,datagrid.invisibleIndexOrder);
						if(bHide)
						{
							if(position == null)
							{
								if(datagrid.invisibleIndexOrder.length == datagrid.nRowHideBuffer)
								{
									//remove the first element of array
									datagrid.invisibleIndexOrder.splice(0,1);
								}
								hiddenIndexArr.push(indexBk);
							}
						}
						else
						{
							if(position && position['row'] > -1)
							{
								//remove element is not invisible any more
								var detailItemArr:Array = this.datagrid.invisibleIndexOrder[position['row']];
								detailItemArr.splice(position['column'],1);
								if(detailItemArr.length == 0)
								{
									this.datagrid.invisibleIndexOrder.splice(position['row'],1);
								}
							}
						}
						item[Global.ROW_HIDE] = bHide;					
						setCRUDRowValue(item, this.datagrid.strDeleteRowText, Global.CRUD_DELETE);
					}
					
					if(bHide && hiddenIndexArr.length > 0)
					{
						//add new element into array
						datagrid.invisibleIndexOrder.push(hiddenIndexArr);
					}
					
					//apply filter in rowHide
					this.datagrid.filter = new FilterDataWithRowHide(this.datagrid.filter,null);	
					(this.datagrid.dataProvider as ArrayCollection).filterFunction = this.datagrid.filter.apply;
					(this.datagrid.dataProvider as ArrayCollection).refresh();
					if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
					{
						this.datagrid.summaryBar.reCreateSummaryBar();
					}
					//update Application height when data is changed
					gridoneManager.updateGridHeight();
					
					gridoneManager.updateExternalVerticalScroll(datagrid.getLength());
					//update group mergeCells of datagrid
					if(hasGroupMerge())
					{
						this.datagrid.getGroupMergeInfo();
					}
					
					if(isDrawUpdate)
						this.datagrid.invalidateList();
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setMultiRowsHide");					
			}
		}
		
		/*************************************************************
		 * import array data into datagrid
		 * @author Chheav Hun
		 * ***********************************************************/
		public function setArrayData(arrData:Array,bValidate:Boolean):void
		{
			gridoneManager.checkDataProvider(arrData, bValidate,"setArrayData");	
		}
		
		/*************************************************************
		 *get all data from datagrid as Object
		 * @author Chheav Hun
		 * ***********************************************************/
		public function getAllData():Object
		{
			return this.datagrid.dataProvider;
		}
		

		
		/*************************************************************
		 * add json data into comboList
		 * @author Chheav Hun
		 * ***********************************************************/
		public function addComboListJson(columnKey:String,strText:String,strValue:String,jsonData:Object):void
		{
			var arrCol:ArrayCollection=new ArrayCollection(jsonData as Array);
			
			for each(var item:Object in arrCol){				
				addComboListValue(columnKey,item[strText],item[strValue],"default");
			}
		}
		
		/*************************************************************
		 * add json data into dynamic comboList. The comboList will clear all the time call this function. 
		 * @author Chheav Hun
		 * ***********************************************************/
		public function addComboDynamicListJson(columnKey:String,strText:String,strValue:String,jsonData:Object):void
		{
			try
			{
				var arrCol:ArrayCollection=new ArrayCollection(jsonData as Array);
				var col:ExAdvancedDataGridColumn = gridone.getColumnByDataField(columnKey) as ExAdvancedDataGridColumn;
				var listKey:String="default";
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				if (strValue == null)
					err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
				col.listCombo[listKey]=new Array();
				for each(var item:Object in arrCol){
					
					var obj:Object=new Object();
					obj["label"]=item[strText];
					obj["value"]=item[strValue]; 
					if (col.listCombo[listKey] == null)
						col.listCombo[listKey]=new Array();
					//verify that value is existed or not in listKey of listCombo of column
					if(!col.checkComboValueWithListKey(strValue,listKey))
					{
						(col.listCombo[listKey] as Array).push(obj);
						this.datagrid.invalidateList();
					}
				}
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"addComboListValue");						
			}
			
		}
		

	 
		/*************************************************************
		 * insert headers for DataGrid.
		 * @param params object that is defined with multiple properties to create columns likes headerText,dataField.
		 * ***********************************************************/
		public function insertHeader(params:Object):void
		{
			this.datagrid.visible=true;
			var col:ExAdvancedDataGridColumn=new ExAdvancedDataGridColumn();
			var colArr:Array;
			var colgroup:Array;
			if (this.datagrid._isGroupedColumn)
			{
				colArr = new Array();
				colgroup= this.datagrid.groupedColumns;
				colgroup.push(col);
				this.datagrid.groupedColumns=colgroup;
			}
			else
			{
				colArr=this.datagrid.columns;
				colArr.push(col);
				this.datagrid.columns=colArr;
			}	
			
			var objectInfo:Object=ObjectUtil.getClassInfo(params);
			for each (var qname:QName in objectInfo.properties)
			{
				var propertyName:String=qname.localName;
				var propertyValue:String=params[qname.localName];
				if (col.hasOwnProperty(propertyName))
					this.dgManager.setColumnProperty(col, propertyName, propertyValue);
				else
					this.dgManager.setStyleForObject(col, propertyName, propertyValue);
			}	
			if(this.datagrid._isGroupedColumn)
			{
				colArr = convertGroupColumn(colgroup , colArr)
				this.datagrid.columns = colArr;
			}
			this.dgManager.setColumnDataFieldIndex(colArr);
			this.datagrid.invalidateList(); 
		}
		
		/*************************************************************
		 * set logo waiting image  
		 * @author Chheav Hun
		 * ***********************************************************/
		public function setWaitingLogoValue(logoUrl:String, logoWidth:Number=200, logoHeight:Number=50):void
		{
			 this.waitingLogo.source=logoUrl;
			 this.waitingLogo.width=logoWidth;
			 this.waitingLogo.height=logoHeight;
		}
		
		/*************************************************************
		 * show image waiting logo   
		 * @author Chheav Hun
		 * ***********************************************************/
		public function showWaitingLogo():void
		{
		 	PopUpManager.addPopUp(waitingLogo,this.datagrid,true);
			PopUpManager.centerPopUp(waitingLogo);
		}
		
		/*************************************************************
		 * hide image waiting logo  
		 * @author Chheav Hun
		 * ***********************************************************/
		public function hideWaitingLogo():void
		{
		   PopUpManager.removePopUp(waitingLogo);	
		}
		
		/************************************************************* 
		 * set data for commbo box renderer of a given name column.
	 	 * @param colname column fied name.
		 * @param sComboData data for setting combo box in format value1|name1%%value2|name2
		 * @author Chheav Hun
		 * ***********************************************************/
		public function addComboDataAtColumn(colKey:String, sComboData:String):void
		{
	   		 if (this.datagrid.dataFieldIndex[colKey]==null)
			 {
				 err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
			 }
			 else
			 {
				 for(var i:int=0 ; i<=this.datagrid.columns.length;i++)
				 {
					 if (colKey==this.datagrid.columns[i].dataField)
					 {
						 addComboDataAtColumnIndex(i, sComboData);
						 break;
					 }
						 
				 }
			 }
		}
		
		/*************************************************************
		 * set data for commbo box renderer of a given index column.
		 * @param colname column fied name.
		 * @param sComboData data for setting combo box in format value1|name1%%value2|name2
		 * ***********************************************************/
		public function addComboDataAtColumnIndex(colIndex:int, sComboData:String):void
		{
			try
			{
				if (colIndex < 0 || colIndex >= datagrid.columns.length || sComboData == null || sComboData == "")
					err.throwError(ErrorMessages.ERROR_INVALID_INPUT_DATA, Global.DEFAULT_LANG);
				
				var cbArr:Array= parseComboData(sComboData);
				
				var col:ExAdvancedDataGridColumn=datagrid.columns[colIndex];
				
				col.listCombo[Global.DEFAULT_COMBO_KEY]=cbArr;
				
				this.datagrid.invalidateList();
			 
			}
			catch(error:Error)
			{
				err.throwMsgError(error.message,"addComboDataAtColumnIndex");	
			}
		}
		
		/*************************************************************
		 * set image for column imagetext 
		 * @columnKey : dataField 
		 * @index: index of image
		 * @athor: Chheav Hun
		 * ***********************************************************/
		public function setColCellImage(columnKey:String, index:int):void
		{
			try
			{					
				var col:ExAdvancedDataGridColumn=this.datagrid.columns[this.datagrid.dataFieldIndex[columnKey]];
				if (col == null)
					err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				for each (var item:Object in this.datagrid._bkDP)
				{
					item[columnKey + "_index"]=index;
				}
				this.datagrid.invalidateList();
			}
			catch (error:Error)
			{
				err.throwMsgError(error.message,"setColCellImage");
			}
		}
		
		/*************************************************************
		 * add comboData for column.
		 * ***********************************************************/
		public function parseComboData(sComboData:String):Array
		{
			var itemArr:Array=sComboData.split("%%");
			if (itemArr.length == 1)
				itemArr=sComboData.split(",");
			var cbArr:Array=[];
			for (var i:int=0; i < itemArr.length; i++)
			{
				var pair:Array=String(itemArr[i]).split("|");
				var obj:Object=new Object();
				
				if (pair.length > 1)
				{
					obj.value=pair[0];
					obj.label=pair[1];
				}
				else if (pair.length == 1)
				{
					obj.label=pair[0];
				}
				cbArr[i]=obj;
			}
			return cbArr;
		}
		
		/*************************************************************
		 * delete multi rows which selected or (shift + selected) in DataGrid's row.
		 * Before call this function, must set "selectCell=false", "strCellClickAction=rowselect", and "allowMultipleSelection=true".
		 * @columnKey : dataField 
		 * @index: index of image
		 * @athor: Chheav Hun
		 * ***********************************************************/
		public function deleteRows():void
		{
			if (datagrid.dataProvider == null)
				return;
			
			if (!datagrid.isTree)
			{
				var index:int;
				var item:Object;
				if (datagrid.allowMultipleSelection)
				{
					for (var i:int=(datagrid.selectedItems.length - 1); i >= 0; i--)
					{
						item=datagrid.selectedItems[i];
						index=(datagrid.dataProvider).getItemIndex(item);
						if (rowStatus !=null)
							rowStatus.currentStatus=RowStatus.STATUS_DEL;
						rowStatus._arrRDelete.push(index);
						(datagrid.dataProvider).removeItemAt(index);
					}
				}
				else
				{
					index=datagrid.selectedIndex;
					item=datagrid.dataProvider.getItemAt(index);
					if (rowStatus !=null)
						rowStatus.currentStatus=RowStatus.STATUS_DEL;
					rowStatus._arrRDelete.push(index);
					(datagrid.dataProvider).removeItemAt(index);
				}
				if (this.datagrid.dataProvider.length < this.datagrid.rowCount)
				{
					//this.vScroll.scrollPosition=0;
					//this.datagrid.verticalScrollPosition=0;
					this.gridone.vScroll.maxScrollPosition=this.datagrid.maxVerticalScrollPosition=0;
					
				}
				if(this.datagrid.summaryBar.hasSummaryBar() && datagrid.rowCount >0)
					 this.datagrid.summaryBar.reCreateSummaryBar(true);
				this.datagrid.invalidateList();
				
			}	 
		}
		
		/*************************************************************
		 * It will be called before getting data from server			 
		 * Return true: without getting data from server or otherwise
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function doStartQuery(useLoadingBar:Boolean=true):Boolean
		{
			if(useLoadingBar)
			{
				this.gridone.activity.showBusyBar();
			}
			else
			{
				this.gridone.activity.closeBusyBar();				
			}
			this.datagrid.isDoQuery= true;
			var saEvent:SAEvent = new SAEvent(SAEvent.ON_START_QUERY, true);
			this.datagrid.dispatchEvent(saEvent);				
			if(this.datagrid.isGettingData)
				return false;
			else
				return true;
		}
		

		/*************************************************************
		 * set button column in a specific row to visible or not visible. 
		 * @param  strColKey ColumnKey
		 * @param  nRow  The row index 
		 * @param bVisible true=visible or not visible=false
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function setButtonVisible(strColKey:String, nRow:int, bVisible:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(strColKey))
				{
					this.err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				if (this.datagrid.columns[this.datagrid.dataFieldIndex[strColKey]].type !=ColumnType.BUTTON)
				{
					err.throwError(ErrorMessages.ERROR_WRONG_COLUMN_TYPE, Global.DEFAULT_LANG);
				}
				if (nRow < 0 || nRow >= this.datagrid._bkDP.length)
				{
					this.err.throwError(ErrorMessages.ERROR_ROWINDEX_INVALID, Global.DEFAULT_LANG);
				}
				var row:Object=this.datagrid.getBackupItem(nRow);
				row[strColKey + Global.SELECTED_BUTTON_INDEX]=bVisible;
				this.datagrid.invalidateList();
			}catch(e:Error)
			{
				throw new Error(e.message);
			}
		}
		
		
		/*************************************************************
		 * set checkbox column in a specific row to visible or not visible. 
		 * @param  strColKey ColumnKey
		 * @param  nRow  The row index 
		 * @param bVisible true=visible or not visible=false
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function setCheckBoxVisible(strColKey:String, nRow:int, bVisible:Boolean):void
		{
			try
			{
				if (!this.datagrid.dataFieldIndex.hasOwnProperty(strColKey))
				{
					this.err.throwError(ErrorMessages.ERROR_COLKEY_INVALID, Global.DEFAULT_LANG);
				}
				if (this.datagrid.columns[this.datagrid.dataFieldIndex[strColKey]].type !=ColumnType.CHECKBOX)
				{
					err.throwError(ErrorMessages.ERROR_WRONG_COLUMN_TYPE, Global.DEFAULT_LANG);
				}
				if (nRow < 0 || nRow >= this.datagrid._bkDP.length)
				{
					this.err.throwError(ErrorMessages.ERROR_ROWINDEX_INVALID, Global.DEFAULT_LANG);
				}
		 
				var row:Object=this.datagrid.getBackupItem(nRow);
				row[strColKey + Global.SELECTED_CHECKBOX_INDEX]=bVisible;
				this.datagrid.invalidateList();
			}catch(e:Error)
			{
				throw new Error(e.message);
			}
		}
		

		
		/*************************************************************
		 * get cell font color of specific row and col. 
		 * @param  col Column index
		 * @param  row  The row index 
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function getCellFontColor(col:int, row:int):String
		{
			try
			{
				if(this.datagrid._bkDP==null)
				{
					this.err.throwError(ErrorMessages.ERROR_DATAPROVIDER_NULL, Global.DEFAULT_LANG);
				}
				if (row <0 ||row >= this.datagrid._bkDP.length)
				{
					this.err.throwError(ErrorMessages.ERROR_ROWINDEX_INVALID, Global.DEFAULT_LANG);
				}
				var uid:String = ""; 
				var rowItem:Object = datagrid.getItemAt(row);
				uid = rowItem[Global.ACTSONE_INTERNAL];
				var dataField:String = "";
				dataField=ExAdvancedDataGridColumn(this.datagrid.columns[col]).dataField;
				var strFgCol:String = this.datagrid.getCellProperty("color",uid,dataField);
				if(strFgCol == null)
					strFgCol = "";
			}catch(e:Error)
			{
				throw new Error(e.message);
			}
			return strFgCol;	
		}
		/*************************************************************
		 * set hide column in specific column index; 
		 * @param  colIndex  column index
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function hideColumnIndex(colIndex:int):void
		{
			var col:ExAdvancedDataGridColumn=this.datagrid.columns[colIndex] as ExAdvancedDataGridColumn;
			if (col !=null)
			{
				col.visible=false;
				this.datagrid.invalidateList();
			}
		}



		
		/*************************************************************
		 * get data of datagrid in HTML format.
		 * @return string of data in HTML format.
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function getDataGridString():String
		{
			this.gridoneManager.excelExportInfo = new ExcelExportInfo("","",true,false,true,true);
			return this.gridoneManager.convertDGToHTMLTable();
		}
		


		

		
	
		 
		public function getCurrentPage():int
		{
//			var fistVisibelRow:Array=this.datagrid.getVisibleListItem();
//		    var res:int=fistVisibelRow["firstRow"];
//		//	this.datagrid.getVisibleListItem().length;
 			return  currentpage;
		}
		
		/*************************************************************
		 * get page total  
		 * @return  number of row
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function getPageTotal():int
		{
		    return this.datagrid.getVisibleListItem().length;
		}
		/*************************************************************
		 * get page total  count
		 * @return  number of pages
		 * @Author:Chheav Hun
		 * ***********************************************************/
		public function getPagingCount():int
		{
			if (this.datagrid._bkDP.length > this.datagrid.getVisibleListItem().length)
			{
				pageNum= Math.ceil(this.datagrid._bkDP.length/this.datagrid.getVisibleListItem().length);
			}
			else 
				pageNum=1;
			return pageNum;
		}
		
		public function  dispatchCustomEvent(funcName:String):void
		{
			var keyBoardEvent:KeyboardEvent;
			if(funcName == "mouseDown")
			{
				keyBoardEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN,true,false,0,40,0,false,false,false);
				this.datagrid.dispatchEvent(keyBoardEvent);
			}
			
			else if(funcName == "mouseUp")
			{
				keyBoardEvent = new KeyboardEvent(KeyboardEvent.KEY_UP,true,false,0,38,0,false,false,false);
				this.datagrid.dispatchEvent(keyBoardEvent);
			}
		}
		
		private var funList: Array =[];
		 
		public function registerFunc(arrfun:Array,fun:String=""):void
		{
			var invilid :Boolean = false;
			var bFirst :Boolean =false;
			if (funList.length ==0)
			{
				funList.push(fun);
				bFirst=true;
			}
			
			if (funList.length >=1)
			{
				  if (bFirst ==false)
				  {
						for (var i:int=0;i<funList.length ;i++)
						{
							if (funList[i]==fun)
							{
								invilid=true;
							}
						}
				  }
			 }
			
			if (invilid==false)
			{
				funList.push(fun);
				
				if (this.hasOwnProperty(fun))
				{
					ExternalInterface.addCallback(fun,this[fun]); 	
				}
				else if (this.dgManager.hasOwnProperty(fun))
				{
					ExternalInterface.addCallback(fun,this.dgManager[fun]); 	
				}
				else if (this.gridoneManager.hasOwnProperty(fun))
				{
					ExternalInterface.addCallback(fun,this.gridoneManager[fun]); 	
				}
//				else if (this.gridone.hasOwnProperty(fun))
//				{
//					ExternalInterface.addCallback(fun,this.datagrid[fun]); 
//				}
				else{ExternalInterface.addCallback(fun,this.gridone[fun]); }
			}
			
//			if (arrfun.length >0)
//			{ 
//				for (var i:int=0;i< arrfun.length;i++)
//				{
//					if (this.gridone.hasOwnProperty(arrfun[i]))
//					{
//						ExternalInterface.addCallback(arrfun[i],this.gridone[arrfun[i]]); 
//					}
//					if (this.hasOwnProperty(arrfun[i]))
//					{
//						ExternalInterface.addCallback(arrfun[i],this[arrfun[i]]); 
//					}
//				}
//				
//			}
  
		}
		
		public function setXMLRowAt(row:String, rowIndex:int):void
		{
		 
		}
	}
}