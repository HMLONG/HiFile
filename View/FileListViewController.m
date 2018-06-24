//
//  HistoryPopOverViewController.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "FileListViewController.h"
#import "HistoryPopOverViewController.h"
#import "WDMessage.h"
#import "NSImage+QuickLook.h"
//#import "AppDelegate.h"
#import "TransparentTableView.h"
#import "WDBubble.h"
#import "MyPopover.h"
#import "NSPopover+MISSINGBackgroundView.h"
#import "FLController.h"
#import "FLView.h"
//#import "RoundWindowFrameView.h"

@implementation FileListViewController
@synthesize historyPopOver = _historyPopOver;
@synthesize fileHistoryArray = _fileHistoryArray;
@synthesize filehistoryTableView = _fileHistoryTableView;
@synthesize bubbles = _bubbles;

#pragma mark - Private Methods

- (void)showItPreview
{
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        WDMessage *message = (WDMessage *)[_fileHistoryArray objectAtIndex:[_fileHistoryTableView selectedRow]];
        FLController *del = (FLController *)[NSApp delegate];
        if (![del.array containsObject:message.fileURL]) {
            del.array = [NSArray arrayWithObject:message.fileURL];
        }
        [del showPreviewInHistory];
    }
}

- (void)showItFinder:(NSURL *)aFileURL
{
    // Wu:Use NSWorkspace to open Finder with specific NSURL and show the selected status 
    [[NSWorkspace sharedWorkspace]selectFile:[aFileURL path] inFileViewerRootedAtPath:nil];
}

- (void)enterSelectedRowIfFLDirectoryItem:(NSNotification *)note
{
    NSLog(@"Selced row %ld,~~",(long)[_fileHistoryTableView selectedRow]);
    
    //获取WDMessage
    WDMessage *message = [_fileHistoryArray objectAtIndex:[_fileHistoryTableView selectedRow]];
    NSLog(@"message item path is %@, jugde FLD is %d",[[message getFLDItem] path],[message isFLDirectoryType]);
    
    //获取item
    if ([_fileHistoryTableView selectedRow]>-1) {
        if ([message isFLDirectoryType]) {
            FLDirectory* fldItem=[message getFLDItem];
            //更新饼图
            [flController setRootDir: fldItem];
            //更新面包屑导航
            [flController updateBreadcrumbNavigationByFLDirectoryItem:fldItem WithMode:true];
            //更新列表
            [flView addRootAndCurrentItemChildrenToFileList];
        }else{//如非目录则为文件，quickLook之
            [self showItPreview];
        }
    }
    
}

- (void)deleteSelectedRow
{
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        WDMessage *message = [_fileHistoryArray objectAtIndex:[_fileHistoryTableView selectedRow]];
        
        NSLog(@"message state is %@",message.state);
        
//        // Wu :Terminate 
//        if (!(([message.state isEqualToString:kWDMessageStateFile])
//              ||([message.state isEqualToString:kWDMessageStateText]))) {
//            [_bubbles terminateTransfer];
//            
//            // Wu:Remove all unstable 
//            NSArray *originalArray = [NSArray arrayWithArray:_fileHistoryArray];
//            for (WDMessage *m in originalArray) {
//                if (![m.state isEqualToString:kWDMessageStateFile] && ![m.state isEqualToString:kWDMessageStateText]) {
//                    [self deleteMessageFromHistory:m];
//                }
//            }
//        }
//        
//        // Wu:Delete
//        else {
//            [_fileHistoryArray removeObjectAtIndex:[_fileHistoryTableView selectedRow]];
//        }
        [[_historyPopOverViewController getFileHistoryArray] addObject:message];
        [[_historyPopOverViewController getFileHistoryTableView] reloadData];

        NSLog(@"Selected row is %ld",(long)[_fileHistoryTableView selectedRow]);
        [_fileHistoryArray removeObjectAtIndex:[_fileHistoryTableView selectedRow]];
        
    }
    
    if ([_fileHistoryArray count] == 0) {
        [_removeButton setHidden:YES];
        [_historyPopOver close];
    }
    [_fileHistoryTableView reloadData];
}

- (void)previewSelectedRowInSelf
{
    NSLog(@"In previw f");
    if (0 <= [_fileHistoryTableView selectedRow] && [_fileHistoryTableView selectedRow] < [_fileHistoryArray count]) {
        WDMessage *message = (WDMessage *)[_fileHistoryArray objectAtIndex:[_fileHistoryTableView selectedRow]];
        [self showItFinder:message.fileURL];
    }
}

#pragma mark - LifeCycle

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        //_fileHistoryArray = [[NSMutableArray alloc]init];
//    }
//    
//    return self;
//}

- (void)dealloc
{
//    [_imageAndTextCell release];
//    [_fileHistoryTableView release];
//    [_fileHistoryArray release];
//    [_historyPopOver release];
//    [super dealloc];
}

- (void)awakeFromNib
{
    _fileHistoryArray = [[NSMutableArray alloc]init];
    
    // Wu:Set the customize the cell for the  only one column
    _imageAndTextCell = [[ImageAndTextCell alloc] init];
    _imageAndTextCell.delegate = self;
    //[_imageAndTextCell setAction:@selector(enterSelectedRowIfFLDirectoryItem:)];
    //[_imageAndTextCell setTarget:self];
    NSTableColumn *column = [[_fileHistoryTableView tableColumns] objectAtIndex:0];
    [column setDataCell:_imageAndTextCell];
    
    //增加消息服务，当点击ImageAndTextCell，则执行enterSelectedRowIfFLDirectoryItem语句
    NSNotificationCenter *nc =
    [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(enterSelectedRowIfFLDirectoryItem:)
               name:@"ImageAndTextCellClicked"
             object:nil];
    NSLog(@"Registered with notification center");
    
    //[_fileHistoryTableView setSelectionHighlightStyle:<#(NSTableViewSelectionHighlightStyle)#>];
    
    //设定第二列和第三列cell的图标和按钮对应的响应函数
    NSButtonCell *previewCell = [[NSButtonCell alloc]init];//[[[NSButtonCell alloc]init]autorelease];
    [previewCell setBordered:NO];
    [previewCell setImage:[NSImage imageNamed:@"NSRevealFreestandingTemplate"]];
    [previewCell setImageScaling:NSImageScaleProportionallyDown];
    [previewCell setAction:@selector(previewSelectedRowInSelf)];
    [previewCell setTarget:self];
    [previewCell setTitle:@""];
    previewCell.highlightsBy = NSContentsCellMask;
    NSTableColumn *columnThree = [[_fileHistoryTableView tableColumns] objectAtIndex:kPreviewColumn];
    [columnThree setDataCell:previewCell];
    
    NSButtonCell *deleteCell = [[NSButtonCell alloc]init];//[[[NSButtonCell alloc]init]autorelease];
    [deleteCell setBordered:NO];
    [deleteCell setImage:[NSImage imageNamed:@"NSTrashEmpty"]];//NSStopProgressFreestandingTemplate
    [deleteCell setImageScaling:NSImageScaleProportionallyDown];
    [deleteCell setAction:@selector(deleteSelectedRow)];
    [deleteCell setTarget:self];
    deleteCell.highlightsBy = NSContentsCellMask;
    NSTableColumn *columnTwo = [[_fileHistoryTableView tableColumns] objectAtIndex:kDeleteColumn];
    [columnTwo setDataCell:deleteCell];
    
    NSButtonCell *quickLookCell = [[NSButtonCell alloc]init];//[[[NSButtonCell alloc]init]autorelease];
    [quickLookCell setBordered:NO];
    [quickLookCell setImage:[NSImage imageNamed:@"NSQuickLookTemplate"]];//NSStopProgressFreestandingTemplate
    [quickLookCell setImageScaling:NSImageScaleProportionallyDown];
    [quickLookCell setAction:@selector(showItPreview)];
    [quickLookCell setTarget:self];
    quickLookCell.highlightsBy = NSContentsCellMask;
    NSTableColumn *columnFour = [[_fileHistoryTableView tableColumns] objectAtIndex:kQuickLookColumn];
    [columnFour setDataCell:quickLookCell];
    
    //NSView* viewT;
    //viewT.backgroundColor=;
//    [self view].wantsLayer = YES;
//    [self view].layer.backgroundColor = [NSColor colorWithCalibratedRed:0.227f
//                                                      green:0.251f
//                                                       blue:0.337
//                                                      alpha:0.9].CGColor;
    
    // Wu:Set the tableview can accept being dragged from
    [_fileHistoryTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType,NSFilenamesPboardType,NSTIFFPboardType,nil]];
    
	// Wu:Tell NSTableView we want to drag and drop accross applications the default is YES means can be only interact with current application
	[_fileHistoryTableView setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
    
    //记录鼠标的位置
    lastMouseOverRow=-2;
    
    NSLog(@"awake from nib in filelistviewcontroller");
}

#pragma mark - Public Method

- (void)refreshButton
{
    if ([_fileHistoryArray count] != 0) {
        
        [_removeButton setHidden:NO];
    } else
    {
        [_removeButton setHidden:YES];
    }
}

- (void)reloadTableView
{
    [_fileHistoryTableView reloadData];
}

- (void)showHistoryPopOver:(NSView *)attachedView
{
    // Wu: init the popOver
    if (_historyPopOver == nil) {
        // Create and setup our window
        _historyPopOver = [[NSPopover alloc] init];
        // The popover retains us and we retain the popover. We drop the popover whenever it is closed to avoid a cycle.
        _historyPopOver.contentViewController = self;
        _historyPopOver.behavior = NSPopoverBehaviorTransient;
        _historyPopOver.delegate = self;
        _historyPopOver.backgroundColor=[NSColor colorWithDeviceCyan:0.3 magenta:0.3 yellow:0.3 black:0.3 alpha:0.5];
        //[_historyPopOver.backgroundView se];
        //_historyPopOver.appearance = NSPopoverAppearanceHUD;
    }
    
    // Wu:CGRectMaxXEdge means appear in the right of button
    
    [_historyPopOver showRelativeToRect:[attachedView bounds] ofView:attachedView preferredEdge:CGRectMinYEdge];
    [self refreshButton];
}

- (void)deleteMessageFromHistory:(WDMessage *)aMessage
{
    NSArray *originArray = [NSArray arrayWithArray:_fileHistoryArray];
    for (WDMessage *m in originArray) {
        if ([m.fileURL.path.lastPathComponent isEqualToString:aMessage.fileURL.path.lastPathComponent]) {
            [_fileHistoryArray removeObject:m];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kRestoreLabelAndImage object:nil];
    [self refreshButton];
    [_fileHistoryTableView reloadData];
}

#pragma mark - IBAction

- (IBAction)removeAllHistory:(id)sender
{
    if ([_fileHistoryArray count] == 0) {
        return ;
    } else {
        BOOL willTerminate = FALSE;
        
        // Wu:Remove all unstable at first
        NSArray *originalArray = [NSArray arrayWithArray:_fileHistoryArray];
        for (WDMessage *m in originalArray) {
            if (![m.state isEqualToString:kWDMessageStateFile] && ![m.state isEqualToString:kWDMessageStateText]) {
                NSLog(@"gosh");
                willTerminate = TRUE;
                [self deleteMessageFromHistory:m];
            }
        }
        
        if (willTerminate) {
            [_bubbles terminateTransfer];
        }
        
        // Wu:Remove other files;
        if ([_fileHistoryArray count] != 0) {
            [_fileHistoryArray removeAllObjects];
            [_fileHistoryTableView noteNumberOfRowsChanged];
            [_fileHistoryTableView reloadData];
        }
    }
    
    // Wu:Force it to close
    [_historyPopOver close];
    
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_fileHistoryArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [_fileHistoryArray objectAtIndex:rowIndex];
}

- (BOOL)   tableView:(NSTableView *)pTableView 
writeRowsWithIndexes:(NSIndexSet *)pIndexSetOfRows 
		toPasteboard:(NSPasteboard*)pboard
{
	// Wu:This is to allow us to drag files to save
	// We don't do this if more than one row is selected
	if ([pIndexSetOfRows count] > 1 ) {
		return NO;
	} 
	NSInteger zIndex	= [pIndexSetOfRows firstIndex];
	WDMessage *message	= [_fileHistoryArray objectAtIndex:zIndex];
    
    if ([message.state isEqualToString:kWDMessageStateText]) {
        return YES;
    }
    
    [pboard declareTypes:[NSArray arrayWithObjects:NSFilesPromisePboardType, nil] owner:self];
    NSArray *propertyArray = [NSArray arrayWithObject:message.fileURL.pathExtension];
    [pboard setPropertyList:propertyArray
                    forType:NSFilesPromisePboardType];
    return YES;
}

- (NSArray *)tableView:(NSTableView *)aTableView
namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
forDraggedRowsWithIndexes:(NSIndexSet *)indexSet {
    NSInteger zIndex = [indexSet firstIndex];
    WDMessage *message = [_fileHistoryArray objectAtIndex:zIndex];
    NSLog(@"dropDes is %@",dropDestination);
    if ([message.state isEqualToString:kWDMessageStateText]) {
        return nil;
    }
    NSURL *newURL = [[NSURL URLWithString:[message.fileURL.lastPathComponent stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
                            relativeToURL:dropDestination] URLWithoutNameConflict];
    [[NSFileManager defaultManager] copyItemAtURL:message.fileURL toURL:newURL error:nil];
    return [NSArray arrayWithObjects:newURL.lastPathComponent, nil];
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes NS_AVAILABLE_MAC(10_7)
{
    //[self removeAllHistory:self];
    NSLog(@"haha dragbegin");
}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation NS_AVAILABLE_MAC(10_7)
{
    NSLog(@"haha dragend");
}

//- (void)mouseMoved:(NSEvent*)theEvent{
//    NSLog(@"haha mouse moved");
//}
-(void)refreshLastMouseOverRowAfterMouseExitTable{
    lastMouseOverRow=-2;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    WDMessage *message = [_fileHistoryArray objectAtIndex:row];
    if ([message.state isEqualToString: kWDMessageStateText] && tableColumn == [[_fileHistoryTableView tableColumns]objectAtIndex:kPreviewColumn]) {
        NSButtonCell *buttonCell = (NSButtonCell *)cell;
        [buttonCell setImagePosition:NSNoImage];
    } else if ([message.state isEqualToString:kWDMessageStateFile] && tableColumn == [[_fileHistoryTableView tableColumns]objectAtIndex:kPreviewColumn]) {
        NSButtonCell *buttonCell = (NSButtonCell *)cell;
        [buttonCell setImagePosition:NSImageOverlaps];
    }
    
    
    
//    int mouseOverRow = [_fileHistoryTableView rowAtPoint:[_fileHistoryTableView convertPoint:[NSEvent mouseLocation] fromView:nil]];
//    NSLog(@"mouse at row %d",mouseOverRow);
    //获取当前鼠标所在列
    int mouseOverRow=[_fileHistoryTableView getMouseOverRow];
    if (row==mouseOverRow){
         //NSLog(@"mouse moved in FileListViewController");
        //High Light效果
        if (row>-1) {
            //列表高亮
            NSRect rowRect = [tableView rectOfRow:row];
            [tableView lockFocusIfCanDraw];
            NSGradient* aGradient =
            [[NSGradient alloc]
             initWithColorsAndLocations:
             [NSColor colorWithDeviceRed:0.416 green:0.529 blue:0.961 alpha:0.2], (CGFloat)0.0,
             [NSColor colorWithDeviceRed:0.212 green:0.365 blue:0.949 alpha:0.2], (CGFloat)1.0,
             nil];
            NSRect rectToDraw = rowRect;
            rectToDraw.size.height = rowRect.size.height - 1;
            rectToDraw.origin.y = rectToDraw.origin.y + 1;
            [aGradient drawInRect:rectToDraw angle:90];
            
            NSRect upperLineRect = [tableView rectOfRow:row];
            upperLineRect.origin.y = upperLineRect.origin.y + 1;
            upperLineRect.size.height = 1.0;
            [[NSColor colorWithDeviceRed:0.376 green:0.498 blue:0.925 alpha:0.2] set];
            NSRectFill(upperLineRect);
            
            NSRect lowerLineRect = [tableView rectOfRow:row];
            lowerLineRect.origin.y = NSMaxY(lowerLineRect) - 1;
            lowerLineRect.size.height = 1.0;
            [[NSColor colorWithDeviceRed:0.169 green:0.318 blue:0.914 alpha:0.2] set];
            NSRectFill(lowerLineRect);
            
            [tableView unlockFocus];
            
            //饼图高亮
            //鼠标处在不同行才更新
            if (row!=lastMouseOverRow) {
                [flView needHightlightChildRadialItemAtIndex:row];
                //保存鼠标位置
                lastMouseOverRow=row;
            }
            
        }

    }
   
    
    
//    //High Light效果
//    if (row==0) {
//        NSRect rowRect = [tableView rectOfRow:0];
//        [tableView lockFocusIfCanDraw];
//        NSGradient* aGradient =
//        [[NSGradient alloc]
//         initWithColorsAndLocations:
//         [NSColor colorWithDeviceRed:0.416 green:0.529 blue:0.961 alpha:0.2], (CGFloat)0.0,
//         [NSColor colorWithDeviceRed:0.212 green:0.365 blue:0.949 alpha:0.2], (CGFloat)1.0,
//         nil];
//        NSRect rectToDraw = rowRect;
//        rectToDraw.size.height = rowRect.size.height - 1;
//        rectToDraw.origin.y = rectToDraw.origin.y + 1;
//        [aGradient drawInRect:rectToDraw angle:90];
//        
//        NSRect upperLineRect = [tableView rectOfRow:0];
//        upperLineRect.origin.y = upperLineRect.origin.y + 1;
//        upperLineRect.size.height = 1.0;
//        [[NSColor colorWithDeviceRed:0.376 green:0.498 blue:0.925 alpha:0.2] set];
//        NSRectFill(upperLineRect);
//        
//        NSRect lowerLineRect = [tableView rectOfRow:0];
//        lowerLineRect.origin.y = NSMaxY(lowerLineRect) - 1;
//        lowerLineRect.size.height = 1.0;
//        [[NSColor colorWithDeviceRed:0.169 green:0.318 blue:0.914 alpha:0.2] set];
//        NSRectFill(lowerLineRect);
//        
//        [tableView unlockFocus];
//    }
    
}


#pragma mark - ImageAndTextCellDelegate

- (NSImage *)previewIconForCell:(NSObject *)data
{
    //DLog(@"previewIconForCell");
    WDMessage *message = (WDMessage *)data;
    if ([message.state isEqualToString: kWDMessageStateText]){
        return [NSImage imageNamed:@"text"];
    } else if ([message.state isEqualToString:kWDMessageStateFile]){
        NSImage *icon = [NSImage imageWithPreviewOfFileAtPath:[message.fileURL path] asIcon:YES];
        return icon;
    }
    
//    NSURL *t=message.fileURL;
//    if([t hasDirectoryPath]){
//        
//    }
    //NSLog(@"%@",[message getFileExtension]);
    if ([[message getFileExtension] isEqual:@""]) {
        return [NSImage imageNamed:@"NSFolder"];
    }else if ([self isCodeExtension:[message getFileExtension]]){
        return [NSImage imageNamed:@"code"];
    }else if ([self isCompressExtension:[message getFileExtension]]){
        return [NSImage imageNamed:@"compress"];
    }else if ([self isMusicExtension:[message getFileExtension]]){
        return [NSImage imageNamed:@"music"];
    }else if ([self isImageExtension:[message getFileExtension]]){
        return [NSImage imageNamed:@"image"];
    }else if ([self isVideoExtension:[message getFileExtension]]){
        return [NSImage imageNamed:@"video"];
    }else if ([self isDocumentExtension:[message getFileExtension]]){
        return [NSImage imageNamed:@"document"];
    }
    
    //return [NSImage imageNamed:@"NSFolder"];
    
    return [NSImage imageNamed:@"file"];
}

- (bool)isCodeExtension:(NSString*) extension
{
    if([extension isEqual:@"cpp"])return true;
    if([extension isEqual:@"h"])return true;
    if([extension isEqual:@"m"])return true;
    if([extension isEqual:@"mm"])return true;
    if([extension isEqual:@"c"])return true;
    if([extension isEqual:@"py"])return true;
    if([extension isEqual:@"nib"])return true;
    if([extension isEqual:@"xib"])return true;
    if([extension isEqual:@"s"])return true;
    if([extension isEqual:@"fo"])return true;
    if([extension isEqual:@"java"])return true;
    if([extension isEqual:@"cu"])return true;
    if([extension isEqual:@"r"])return true;
    if([extension isEqual:@"rb"])return true;
    if([extension isEqual:@"cc"])return true;
    if([extension isEqual:@"cmake"])return true;
    if([extension isEqual:@"css"])return true;
    if([extension isEqual:@"json"])return true;
    if([extension isEqual:@"html"])return true;
    if([extension isEqual:@"cs"])return true;
    if([extension isEqual:@"ads"])return true;
    if([extension isEqual:@"adb"])return true;
    if([extension isEqual:@"cxx"])return true;
    if([extension isEqual:@"hpp"])return true;
    if([extension isEqual:@"ml"])return true;
    if([extension isEqual:@"mli"])return true;
    if([extension isEqual:@"make"])return true;
    if([extension isEqual:@"mips"])return true;
    
    return false;
}

- (bool)isCompressExtension:(NSString*) extension
{
    if([extension isEqual:@"rar"])return true;
    if([extension isEqual:@"zip"])return true;
    if([extension isEqual:@"7z"])return true;
    if([extension isEqual:@"cab"])return true;
    if([extension isEqual:@"iso"])return true;
    if([extension isEqual:@"jar"])return true;
    if([extension isEqual:@"ace"])return true;
    if([extension isEqual:@"tar"])return true;
    if([extension isEqual:@"gz"])return true;
    if([extension isEqual:@"arj"])return true;
    if([extension isEqual:@"lzh"])return true;
    if([extension isEqual:@"uue"])return true;
    if([extension isEqual:@"bz2"])return true;
    if([extension isEqual:@"z"])return true;
    if([extension isEqual:@"pkg"])return true;
    
    return false;
}

- (bool)isMusicExtension:(NSString*) extension
{
    if([extension isEqual:@"mp3"])return true;
    if([extension isEqual:@"ogg"])return true;
    if([extension isEqual:@"ape"])return true;
    if([extension isEqual:@"flac"])return true;
    if([extension isEqual:@"wav"])return true;
    if([extension isEqual:@"wma"])return true;
    if([extension isEqual:@"wv"])return true;
    if([extension isEqual:@"aac"])return true;
    if([extension isEqual:@"mpc"])return true;
    if([extension isEqual:@"pac"])return true;
    if([extension isEqual:@"m4a"])return true;
    if([extension isEqual:@"ac3"])return true;
    if([extension isEqual:@"caf"])return true;
    if([extension isEqual:@"mid"])return true;
    
    return false;
}

- (bool)isImageExtension:(NSString*) extension
{
    if([extension isEqual:@"jpg"])return true;
    if([extension isEqual:@"tiff"])return true;
    if([extension isEqual:@"png"])return true;
    if([extension isEqual:@"bmp"])return true;
    if([extension isEqual:@"gif"])return true;
    
    return false;
}

- (bool)isVideoExtension:(NSString*) extension
{
    if([extension isEqual:@"rm"])return true;
    if([extension isEqual:@"rvmb"])return true;
    if([extension isEqual:@"mp4"])return true;
    if([extension isEqual:@"avi"])return true;
    if([extension isEqual:@"mkv"])return true;
    if([extension isEqual:@"webm"])return true;
    if([extension isEqual:@"flv"])return true;
    if([extension isEqual:@"mpg"])return true;
    if([extension isEqual:@"mov"])return true;
    if([extension isEqual:@"m4v"])return true;
    if([extension isEqual:@"wmv"])return true;
    if([extension isEqual:@"dv"])return true;
    if([extension isEqual:@"ts"])return true;
    
    return false;
}

- (bool)isDocumentExtension:(NSString*) extension
{
    if([extension isEqual:@"doc"])return true;
    if([extension isEqual:@"docx"])return true;
    if([extension isEqual:@"txt"])return true;
    if([extension isEqual:@"csv"])return true;
    if([extension isEqual:@"ppt"])return true;
    if([extension isEqual:@"pdf"])return true;
    if([extension isEqual:@"rtf"])return true;
    if([extension isEqual:@"md"])return true;
    if([extension isEqual:@"markdown"])return true;
    if([extension isEqual:@"rst"])return true;
    if([extension isEqual:@"pot"])return true;
    if([extension isEqual:@"log"])return true;
    if([extension isEqual:@"cfg"])return true;
    if([extension isEqual:@"htm"])return true;
    
    return false;
}


- (void)reserveCompressedFiles{
    NSLog(@"reserve");
    //枚举
    NSMutableArray *discardedItems = [NSMutableArray array];
    WDMessage *item;
    for (item in _fileHistoryArray) {
        if (![self isCompressExtension:[item getFileExtension]])
            [discardedItems addObject:item];
    }
    [_fileHistoryArray removeObjectsInArray:discardedItems];
    
    //刷新列表
    [_fileHistoryTableView reloadData];
}

- (NSString *)primaryTextForCell:(NSObject *)data
{
    //DLog(@"primaryTextForCell");
    WDMessage *message = (WDMessage *)data;
    
    return [[message getFileURLofNStringPointerFormat] lastPathComponent];
    
    if ([message.state isEqualToString: kWDMessageStateText]){
        NSString *string = [[NSString alloc]initWithData:message.content encoding:NSUTF8StringEncoding];//[[[NSString alloc]initWithData:message.content encoding:NSUTF8StringEncoding] autorelease];
        string = [string stringByReplacingOccurrencesOfString:@"\n" withString:@"."];
        if ([string length] >= 25) {
            NSString *temp = [string substringWithRange:NSMakeRange([string length] - 6 , 5)];
            string = [string substringWithRange:NSMakeRange(0,15)];
            string = [string stringByAppendingString:@"..."];
            string = [string stringByAppendingString:temp];
        }
        return string;
    } else if ([message.state isEqualToString:kWDMessageStateFile]){
        if ([[message.fileURL lastPathComponent] length] >= 20) {
            NSInteger length = [[message.fileURL lastPathComponent] length];
            NSString *string = [[message.fileURL lastPathComponent] substringWithRange:NSMakeRange(0, 8)];
            string = [string stringByAppendingString:@"......"];
            string = [string stringByAppendingString:[[message.fileURL lastPathComponent] substringWithRange:NSMakeRange(length - 4, 3)]];
            return string;
        }  else {
            return [message.fileURL lastPathComponent];
        }
    } else if (([message.state isEqualToString:kWDMessageStateReadyToSend])
               ||([message.state isEqualToString:kWDMessageStateSending]))
    {
        return [NSString stringWithFormat:@"%.0f%% %@ sent", 
                [self.bubbles percentTransfered]*100, 
                [NSURL formattedFileSize:[self.bubbles bytesTransfered]]];
    } else if ([message.state isEqualToString:kWDMessageStateReadyToReceive] || [message.state isEqualToString:kWDMessageStateReceiving]){
        return [NSString stringWithFormat:@"%.0f%% %@ received", 
                [self.bubbles percentTransfered]*100, 
                [NSURL formattedFileSize:[self.bubbles bytesTransfered]]];
    }
    
    return nil;
}

- (NSString *)auxiliaryTextForCell:(NSObject *)data
{
    WDMessage *message = (WDMessage *)data;
    //NSString *fileSize = [NSString stringWithFormat:@"%lu",(unsigned long)[message fileSize]]; ;
    return [message state];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];//[[[NSDateFormatter alloc] init] autorelease];
    df.dateFormat = @"hh:mm:ss";
    return  [message.sender stringByAppendingFormat:@" %@", [df stringFromDate:message.time]];
}

- (NSURL *)URLForCell:(NSObject *)data
{
    WDMessage *message = (WDMessage *)data;
    return  message.fileURL;
}

- (NSInteger)indexForCell:(NSObject *)data
{
    WDMessage *message = (WDMessage *)data;
    NSLog(@"index is %lu",[_fileHistoryArray indexOfObject:message]);
    return [_fileHistoryArray indexOfObject:message];
}

#pragma mark - ContextMenuDelegate

- (NSMenu*)tableView:(NSTableView*)aTableView menuForRows:(NSIndexSet*)rows
{
    NSMenu *menu = [[NSMenu alloc] init];//[[[NSMenu alloc] init] autorelease];
    NSInteger selectedRow = [rows firstIndex];
    WDMessage *message = [_fileHistoryArray objectAtIndex:selectedRow];
    //右键出现菜单，如文本，菜单项为DELETE
    if ([message.state isEqualToString: kWDMessageStateText]) {
        NSMenuItem *deleteItem = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"DELETE", @"Delete") action:@selector(deleteSelectedRow) keyEquivalent:@""];
        [menu addItem:deleteItem];
//        [deleteItem release];
    } else {//右键出现菜单，如文件，菜单项为SHOW_IN_FINDER、DELETE、QUICKLOOK
        NSLog(@"Right Click now, row is %d",selectedRow);
        
        NSMenuItem *previewItem = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"SHOW_IN_FINDER", @"Show in Finder") action:@selector(previewSelectedRowInSelf) keyEquivalent:@""];
        [previewItem setTarget:self];
        [menu addItem:previewItem];
//        [previewItem release];
        
        NSMenuItem *deleteItem = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"DELETE", @"Delete") action:@selector(deleteSelectedRow) keyEquivalent:@""];
        [deleteItem setTarget:self];
        [menu addItem:deleteItem];
//        [deleteItem release];
        
        NSMenuItem *quicklookItem = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"QUICKLOOK", @"Quicklook") action:@selector(showItPreview) keyEquivalent:@""];//
        [quicklookItem setTarget:self];
        [menu addItem:quicklookItem];
//        [quicklookItem release];
    }
    return menu;
}

- (void)setHistoryPopOverViewController:(HistoryPopOverViewController *)historyPopOverViewController{
    _historyPopOverViewController=historyPopOverViewController;
}

@end
