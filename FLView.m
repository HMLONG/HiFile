/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLView.h"

#import "FLRadialPainter.h"
#import "FLFile.h"
#import "FLController.h"
#import "FLDirectoryDataSource.h"

#import "FLRadialItem.h"

#import "FileListViewController.h"
#import "WDMessage.h"
//#import "HistoryPopOverViewController.h"
#import "TransparentTableView.h"

@implementation FLView

#pragma mark Tracking


- (void) setTrackingRect
{    
    NSPoint mouse = [[self window] mouseLocationOutsideOfEventStream];
    NSPoint where = [self convertPoint: mouse fromView: nil];
    BOOL inside = ([self hitTest: where] == self);
    
    m_trackingRect = [self addTrackingRect: [self visibleRect]
                                     owner: self
                                  userData: NULL
                              assumeInside: inside];
    if (inside) {
        [self mouseEntered: nil];
    }
}

- (void) clearTrackingRect
{
	[self removeTrackingRect: m_trackingRect];
}

- (BOOL) acceptsFirstResponder
{    
    return YES;
}

- (BOOL) becomeFirstResponder
{
    return YES;
}

- (void) resetCursorRects
{
	[super resetCursorRects];
	[self clearTrackingRect];
	[self setTrackingRect];
}

-(void) viewWillMoveToWindow: (NSWindow *) win
{
	if (!win && [self window]) {
        [self clearTrackingRect];
    }
}

-(void) viewDidMoveToWindow
{
	if ([self window]) {
        [self setTrackingRect];
    }
}

- (void) mouseEntered: (NSEvent *) event
{
    m_wasAcceptingMouseEvents = [[self window] acceptsMouseMovedEvents];
    [[self window] setAcceptsMouseMovedEvents: YES];
    [[self window] makeFirstResponder: self];
}

//- (FLFile *) itemForEvent: (NSEvent *) event
- (FLRadialItem *) itemForEvent: (NSEvent *) event
{
    NSPoint where = [self convertPoint: [event locationInWindow] fromView: nil];
    return [m_painter itemAt: where];
}

- (FLRadialItem *) itemForMousePoint: (NSPoint *) where
{
    //NSPoint where = [self convertPoint: [event locationInWindow] fromView: nil];
    return [m_painter itemAt: *where];
}

- (void) mouseExited: (NSEvent *) event
{
    [[self window] setAcceptsMouseMovedEvents: m_wasAcceptingMouseEvents];
    [locationDisplay setStringValue: @""];
    [sizeDisplay setStringValue: @""];
}

- (void) mouseMoved: (NSEvent *) event
{
    //扫描后rootDir不为nil，这时才进行相应数据的加载
    if ([[self dataSource] rootDir]!=nil) {
        //获取鼠标当前指向的item
        id rItem=[self itemForEvent: event];
        id item = [(FLRadialItem*)rItem item];
        if (item) {
            //指向不同的rItem才进行列表显示刷新
            if (![currentRadialItemString isEqualToString:[[(FLRadialItem*)rItem item]path]]) {
                NSLog(@"pass");
                //[rItem showSelfAndCurrentItemChildren];
                //给文件列表加载自身和子文件
                [self addSelfAndCurrentItemChildrenToFileList:rItem];
                //更新当前鼠标指向的radialItem
                currentRadialItemString=[[(FLRadialItem*)rItem item]path];
            }
            
            //鼠标当前指向的item的路径
            [locationDisplay setStringValue: [item path]];
            //鼠标当前指向的item的大小
            [sizeDisplay setStringValue: [item displaySize]];
            //设置鼠标的显示模式，如item是文件夹则设置鼠标为手指形状
            if ([item isKindOfClass: [FLDirectory class]]) {
                [[NSCursor pointingHandCursor] set];
            } else {
                [[NSCursor arrowCursor] set];
            }
        } else {//找不到item说明当前鼠标指向中央或者空白区域
            [locationDisplay setStringValue: @""];
            [sizeDisplay setStringValue: @""];
            [[NSCursor arrowCursor] set];
            
            //如当前currentRadialItemString已是rootDir对应的string，则说明已经进行过列表的更新，无需再次更新
            if (![currentRadialItemString isEqualToString:[[[self dataSource] rootDir]path]]) {
                NSLog(@"pass addrootand...");
                [self addRootAndCurrentItemChildrenToFileList];
                currentRadialItemString=[[[self dataSource] rootDir]path];
            }
            
        }
    }
    
}

- (void) mouseUp: (NSEvent *) event
{
    //获取鼠标当前位置的item
    id item = [[self itemForEvent: event] item];
    if(isMouseInCenterItem){
        NSLog(@"should exit...");
        [flController enterParentDir];
    }else{
        //获取item成功并且该item为文件夹则设定该item为RootDir
        if (item && [item isKindOfClass: [FLDirectory class]]) {
            [controller setRootDir: item];
            //更新breadcrumb navigation
            [controller updateBreadcrumbNavigationByFLDirectoryItem:item WithMode:true];
        }
    }
    
    //避免点击之后鼠标停留在新内容处不进行列表刷新
    [self mouseMoved:event];
}

- (NSMenu *) menuForEvent: (NSEvent *) event
{
    id item = [self itemForEvent: event];
    if (item) {
        m_context_target = item;
        return (NSMenu *)contextMenu;
    } else {
        return nil;
    }
}

- (void)setIsMouseInCenterItem:(bool)isMouseInCenterItemOrNot
{
    isMouseInCenterItem=isMouseInCenterItemOrNot;
}

- (BOOL) validateMenuItem: (NSMenuItem *) item
{
    if ([item action] == @selector(zoom:)) {
        return [m_context_target isKindOfClass: [FLDirectory class]];
    }
    return YES;
}

- (IBAction) zoom: (id) sender
{
    [controller setRootDir: (FLDirectory *)m_context_target];
}

- (IBAction) open: (id) sender
{
    [[NSWorkspace sharedWorkspace] openFile: [m_context_target path]];
}

- (IBAction) reveal: (id) sender
{
    [[NSWorkspace sharedWorkspace] selectFile: [m_context_target path]
                     inFileViewerRootedAtPath: @""];
}

- (IBAction) trash: (id) sender
{
    int tag;
    BOOL success;
    
    NSString *path = [m_context_target path];
    NSString *basename = [path lastPathComponent];
    
    success = [[NSWorkspace sharedWorkspace]
        performFileOperation: NSWorkspaceRecycleOperation
                      source: [path stringByDeletingLastPathComponent]
                 destination: @""
                       files: [NSArray arrayWithObject: basename]
                         tag: &tag];
    
    if (success) {
        [controller refresh: self];
    } else {
        NSString *msg = [NSString stringWithFormat:
            @"The path %@ could not be deleted.", path];
        NSRunAlertPanel(@"Deletion failed", msg, nil, nil, nil);
    }
}

- (IBAction) copyPath: (id) sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes: [NSArray arrayWithObject: NSStringPboardType]
               owner: self];
    [pb setString: [[m_context_target path] copy]
          forType: NSStringPboardType];
}

#pragma mark Drawing

- (void) drawSize: (NSString *) str;
{
    double rfrac, wantr, haver;
    float pts;
    NSFont *font;
    NSSize size;
    NSDictionary *attrs;
    NSPoint p, center;
    
    rfrac = [m_painter minRadiusFraction] - 0.02;
    wantr = [self maxRadius] * rfrac;
    
    font = [NSFont systemFontOfSize: 0];
    attrs = [NSMutableDictionary dictionary];
    [attrs setValue: font forKey: NSFontAttributeName];
    size = [str sizeWithAttributes: attrs];
    haver = hypot(size.width, size.height) / 2;
    
    pts = [font pointSize] * wantr / haver;
    font = [NSFont systemFontOfSize: pts];
    [attrs setValue: font forKey: NSFontAttributeName];
    size = [str sizeWithAttributes: attrs];
    center = [self center];
    p = NSMakePoint(center.x - size.width / 2,
                    center.y - size.height / 2);
    [str drawAtPoint: p withAttributes: attrs];
}

- (void) updateFileListAfterFirstScanThroughMousePoint:(NSPoint)mousePoint
{
    id rItem=[self itemForMousePoint:&mousePoint];
    id item = [(FLRadialItem*)rItem item];
    if (item) {
        //指向不同的rItem才进行列表显示刷新
        if (![currentRadialItemString isEqualToString:[[(FLRadialItem*)rItem item]path]]) {
            NSLog(@"pass");
            //[rItem showSelfAndCurrentItemChildren];
            [self addSelfAndCurrentItemChildrenToFileList:rItem];
            currentRadialItemString=[[(FLRadialItem*)rItem item]path];
        }
        
        [locationDisplay setStringValue: [item path]];
        [sizeDisplay setStringValue: [item displaySize]];
        if ([item isKindOfClass: [FLDirectory class]]) {
            [[NSCursor pointingHandCursor] set];
        } else {
            [[NSCursor arrowCursor] set];
        }
    } else {
        [locationDisplay setStringValue: @""];
        [sizeDisplay setStringValue: @""];
        [[NSCursor arrowCursor] set];
        
        if (![currentRadialItemString isEqualToString:[[[self dataSource] rootDir]path]]) {
            NSLog(@"pass");
            [self addRootAndCurrentItemChildrenToFileList];
            currentRadialItemString=[[[self dataSource] rootDir]path];
        }
        
    }
}

- (void)hightlightChildRadialItemAtIndex: (int)index{
    //int count=[[[m_painter getRootRadialItem] getChildren] count];
    //NSLog(@"rItem has %d child rItems",count);
    FLRadialItem* itemToHighlight=[[[m_painter getRootRadialItem] getChildren] objectAtIndex:index];
    [m_painter drawItem:itemToHighlight setHighlight:HIGHLIGHT];
    NSLog(@"highlight %d",index);
    
    //hightLight完毕，清除标志
    isNeedHightlight=false;
}

- (void)needHightlightChildRadialItemAtIndex: (int)index{
    isNeedHightlight=true;
    hightlightIndex=index;
    //使高亮立即有效
    [self setNeedsDisplay:YES];
}

- (void)clearRItemHightlight{
    isNeedHightlight=false;
    [self setNeedsDisplay:YES];
}

- (void) drawRect: (NSRect)rect
{
    //向上扫描完毕时会进入drawRect，此时ritem已更新，currentRaialItemString可能会指向野指针，故这里要更新
    //currentRadialItemString=nil;
    
    NSString *size;
    [m_painter drawRect: rect];
    
    //highlight子rItem
    //[self hightlightChildRadialItemAtIndex:0];
    if (isNeedHightlight) {
        [self hightlightChildRadialItemAtIndex:hightlightIndex];
    }
    
    //显示当前饼图的根目录的文件大小
    size = [[[self dataSource] rootDir] displaySize];
    [self drawSize: size];
    
    //NSString *path=[[[self dataSource] rootDir] path];
    NSLog(@"%@",[[[self dataSource] rootDir] path]);
    NSLog(@"drawRect");
    
    //NSLog(@"%@",);
    NSPoint tp=[NSEvent mouseLocation];
    NSLog(@"tp is %f,%f",tp.x,tp.y);
//    if ([[self dataSource] rootDir]!=nil) {
//        [self updateFileListAfterFirstScanThroughMousePoint:&tp];
//    }
    
}

- (id) dataSource
{
    return dataSource;
}

- (void) awakeFromNib
{
    m_painter = [[FLRadialPainter alloc] initWithView: self];
    [m_painter setColorer: self];
    //currentRadialItemString=[NSMutableString stringWithString:@"Hello World"];;
    
    //初始化不hightlight任何rItem
    isNeedHightlight=false;
}

- (NSColor *) colorForItem: (id) item
                 angleFrac: (float) angle
                 levelFrac: (float) level
{
    if ([item isKindOfClass: [FLDirectory class]]) {
        return [m_painter colorForItem: item
                             angleFrac: angle
                             levelFrac: level];
    } else {
        return [NSColor colorWithCalibratedWhite: 0.65 alpha: 1.0];
    }
}

#pragma mark Add file to file list view

- (IBAction)addFile:(id)sender
{
    NSURL *_fileURL = [NSURL fileURLWithPath:@"/Users/HMLONG/Desktop/test.mp3" isDirectory:NO];
    WDMessage *t = [WDMessage messageWithFile:_fileURL andState:kWDMessageStateReadyToSend];//[[WDMessage messageWithFile:_fileURL andState:kWDMessageStateReadyToSend] retain];
    [self storeMessageToFileList:t];
//    [t release];
}

- (void)storeMessageToFileList:(WDMessage *)message
{
    if ([message.state isEqualToString:kWDMessageStateFile]) {
        NSArray *originalMessages = [NSArray arrayWithArray:_fileListViewController.fileHistoryArray];
        for (WDMessage *m in originalMessages) {
            if (([m.fileURL.path isEqualToString:message.fileURL.path])
                &&(![m.state isEqualToString:kWDMessageStateFile])) {
                m.state = kWDMessageStateFile;
            };
        }
    } else {
        [_fileListViewController.fileHistoryArray addObject:message];
    }
    
    [_fileListViewController.fileHistoryArray sortUsingComparator:^NSComparisonResult(WDMessage *obj1, WDMessage * obj2) {
        if ([obj1.time compare:obj2.time] == NSOrderedAscending)
            return NSOrderedAscending;
        else if ([obj1.time compare:obj2.time] == NSOrderedDescending)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    [_fileListViewController.filehistoryTableView reloadData];
    //[_fileListViewController refreshButton];
}

- (void) clearFilehistoryTableView
{
    if([_fileListViewController.fileHistoryArray count]){
        [_fileListViewController.fileHistoryArray removeAllObjects];
        [_fileListViewController.filehistoryTableView reloadData];
    }
    
}

- (void)setCurrentRadialItemString:(NSString*)radialItemString{
    currentRadialItemString=radialItemString;
}

- (void) addSelfAndCurrentItemChildrenToFileList:(id)Item
{
    //NSString *filename = [[yourURL absoluteString] lastPathComponent];
    NSURL *_fileURL = [NSURL fileURLWithPath:[[(FLRadialItem*)Item item]path] isDirectory:NO];
    //NSURL *_fileURL =item
    //WDMessage *t = [WDMessage messageWithFile:_fileURL andState:[[(FLRadialItem*)Item item] displaySize]];//[[WDMessage messageWithFile:_fileURL andState:[[(FLRadialItem*)Item item] displaySize]] retain];
    
    WDMessage *t = [WDMessage messageWithFile:_fileURL andState:[[(FLRadialItem*)Item item] displaySize] andFLDItem:[(FLRadialItem*)Item item] isFLDrectoryType:true];
    
    [self clearFilehistoryTableView];
    //[self storeMessageToFileList:t];
    
    [self setDirectoryDisplay:t];
//    [t release];
    
    //加上子文件到显示列表中去
    id item = [(FLRadialItem*)Item item];
    
    NSArray* sortedArray;
    NSEnumerator *e;
    SequenceByWeightItem *sequenceByWeightItemChild;
    if ([item isKindOfClass: [FLFile class]]) {
        sortedArray=[item getSortedArray];
        e = [sortedArray objectEnumerator];
    }
    
    //NSLog(@"self is %@",[item path]);
    
    int m = [(FLDirectoryDataSource*)[Item getM_datasource] numberOfChildrenOfItem: item];
    
    int i;
    for (i = 0; i < m; ++i) {
        int sequence;
        if ([item isKindOfClass: [FLFile class]]) {
            sequenceByWeightItemChild=[e nextObject];
            int sequenceTemp=sequenceByWeightItemChild._sequence;
            sequence=sequenceTemp;
        }else
            sequence=i;
        
        id sub = [(FLDirectoryDataSource*)[Item getM_datasource] child: sequence ofItem: item];
        //NSLog(@"add child %d is %@",i,[sub path]);
        NSURL *_fileURL = [NSURL fileURLWithPath:[sub path] isDirectory:NO];
        //判断类型
        WDMessage *t;
        if ([sub isKindOfClass: [FLDirectory class]]) {
            t = [WDMessage messageWithFile:_fileURL andState:[sub displaySize] andFLDItem:sub isFLDrectoryType:true];
        }else{
            t = [WDMessage messageWithFile:_fileURL andState:[sub displaySize] andFLDItem:sub isFLDrectoryType:false];
        }
        //WDMessage *t = [WDMessage messageWithFile:_fileURL andState:[sub displaySize]];//[[WDMessage messageWithFile:_fileURL andState:[sub displaySize]] retain];
        //过滤
        [self addAfterFilter:t];
        //[self storeMessageToFileList:t];
//        [t release];
    }
    NSLog(@"add list done");
}

- (void)setDirectoryDisplay:(WDMessage*)t
{
    [directoryName setStringValue: [[t getFileURLofNStringPointerFormat] lastPathComponent]];
    [directorySize setStringValue: [t state]];
    
    //NSImage* image=[NSImage imageNamed:@"NSFolder"];
    NSImage* image=[_fileListViewController previewIconForCell:t];
    NSSize size;
    size.height=50;
    size.width=50;
    [image setSize:size];
    [directoryImageView setImage:image];
    //float scale=1.1;
    //[directoryImageView setScaleFactor:1.5];
}

- (void)addRootAndCurrentItemChildrenToFileList{
    NSLog(@"At root");
    
    //NSString *filename = [[yourURL absoluteString] lastPathComponent];
    NSURL *_fileURL = [NSURL fileURLWithPath:[[[self dataSource] rootDir] path] isDirectory:NO];
    //NSURL *_fileURL =item
    //WDMessage *t = [WDMessage messageWithFile:_fileURL andState:[[[self dataSource] rootDir] displaySize]];//[[WDMessage messageWithFile:_fileURL andState:[[(FLRadialItem*)Item item] displaySize]] retain];
    
    WDMessage *t = [WDMessage messageWithFile:_fileURL andState:[[[self dataSource] rootDir] displaySize] andFLDItem:[[self dataSource] rootDir] isFLDrectoryType:true];
    
    [self clearFilehistoryTableView];
    //[self storeMessageToFileList:t];
    
    [self setDirectoryDisplay:t];
//    [directoryName setStringValue: [[t getFileURLofNStringPointerFormat] lastPathComponent]];
//    [directorySize setStringValue: [t state]];
//    [directoryImageView setImage:[NSImage imageNamed:@"NSFolder"]];
    
    //[(NSTextField*)directoryName setColor:[NSColor purpleColor]];
    //    [t release];
    
    //加上子文件到显示列表中去
    id item = [[self dataSource] rootDir];
    //id item=[[m_painter getRootRadialItem] item];
    //NSLog(@"self is %@",[item path]);
    
    int m = [(FLDirectoryDataSource*)dataSource numberOfChildrenOfItem: item];
    
    //建立数组
    NSMutableArray *sequenceByWeightArray=[NSMutableArray arrayWithCapacity: m];
    int i;
    for (i = 0; i < m; ++i) {
        id sub = [(FLDirectoryDataSource*)dataSource child: i ofItem: item];
        float subw = [dataSource weightOfItem: sub];
        id sequenceByWeightItem = [[SequenceByWeightItem alloc] initWithSequence: i
                                                                          weight: subw];
        
        [sequenceByWeightArray addObject: sequenceByWeightItem];
    }
    
    //排序
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"_weight"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedArray = [sequenceByWeightArray sortedArrayUsingDescriptors:sortDescriptors];

    //准备枚举
    NSEnumerator *e=[sortedArray objectEnumerator];
    SequenceByWeightItem *sequenceByWeightItemChild;
    
    for (i = 0; i < m; ++i) {
        int sequence;
        sequenceByWeightItemChild=[e nextObject];
        int sequenceTemp=sequenceByWeightItemChild._sequence;
        sequence=sequenceTemp;
        
        id sub = [(FLDirectoryDataSource*)dataSource child: sequence ofItem: item];
        //NSLog(@"add child %d is %@",i,[sub path]);
        NSURL *_fileURL = [NSURL fileURLWithPath:[sub path] isDirectory:NO];
        
        //根据类型来添加
        WDMessage *t;
        if ([sub isKindOfClass: [FLDirectory class]]) {
            t = [WDMessage messageWithFile:_fileURL andState:[sub displaySize] andFLDItem:sub isFLDrectoryType:true];
        }else{
            t = [WDMessage messageWithFile:_fileURL andState:[sub displaySize] andFLDItem:sub isFLDrectoryType:false];
        }
        
        //过滤
        [self addAfterFilter:t];
        
        
        //        [t release];
    }
}

- (void)addAfterFilter:(WDMessage*)t{
    if ([musicCheckBox state]==0&&[compressedCheckBox state]==0&&[videoCheckBox state]==0) {//无勾选则不过滤
        [self storeMessageToFileList:t];
    }else{//有勾选
        if ([compressedCheckBox state]==1) {
            if ([_fileListViewController isCompressExtension:[t getFileExtension]]) {
                [self storeMessageToFileList:t];
            }
        }
        if ([musicCheckBox state]==1) {
            if ([_fileListViewController isMusicExtension:[t getFileExtension]]) {
                [self storeMessageToFileList:t];
            }
        }
        if ([videoCheckBox state]==1) {
            if ([_fileListViewController isVideoExtension:[t getFileExtension]]) {
                [self storeMessageToFileList:t];
            }
        }
    }
}

@end
