/* Copyright (C) 1996 Dave Vasilevsky
* This file is licensed under the GNU General Public License,
* see the file Copying.txt for details. */

#import "FLController.h"
#import "FLDirectoryDataSource.h"

#import "FileListViewController.h"
#import "HistoryPopOverViewController.h"
#import "WDBubble.h"
#import "TransparentTableView.h"
#import "FLView.h"

static NSString *ToolbarID = @"Filelight Toolbar";
static NSString *ToolbarItemUpID = @"Up ToolbarItem";
static NSString *ToolbarItemRefreshID = @"Refresh ToolbarItem";


@implementation FLController

@synthesize array = _array;

#pragma mark Toolbar

- (void) setupToolbar
{
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier: ToolbarID];
    [toolbar setDelegate: self];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
//    [window setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *) toolbar
      itemForItemIdentifier: (NSString *) itemID
  willBeInsertedIntoToolbar: (BOOL) willInsert
{
    NSToolbarItem *item = [[NSToolbarItem alloc]
        initWithItemIdentifier: itemID];
    
    if ([itemID isEqual: ToolbarItemUpID]) {
        [item setLabel: @"Up"];
        [item setToolTip: @"Go to the parent directory"];
        [item setImage: [NSImage imageNamed: @"arrowUp"]];
        [item setAction: @selector(parentDir:)];
    } else if ([itemID isEqual: ToolbarItemRefreshID]) {
        [item setLabel: @"Refresh"];
        [item setToolTip: @"Rescan the current directory"];
        [item setImage: [NSImage imageNamed: @"reload"]];
        [item setAction: @selector(refresh:)];
    } else {
//        [item release];
        return nil;
    }
    
    if (![item paletteLabel]) {
        [item setPaletteLabel: [item label]];
    }
    if (![item target]) {
        [item setTarget: self];
    }
//    return [item autorelease];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:
        ToolbarItemUpID,
        ToolbarItemRefreshID,
        nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:
        ToolbarItemUpID,
        ToolbarItemRefreshID,
        NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarSeparatorItemIdentifier,
        nil];
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) item
{
    if ([[item itemIdentifier] isEqual: ToolbarItemUpID]) {
        return ![FLScanner isMountPoint: [[self rootDir] path]];
    }
    return YES;
}

#pragma mark Scanning

- (FLDirectory *) scanDir
{
    return m_scanDir;
}

- (void) setScanDir: (FLDirectory *) dir
{
//    [dir retain];
    if (m_scanDir) ;//[m_scanDir release];
    m_scanDir = dir;
}

- (BOOL) startScan: (NSString *) path
{
    if (m_scanner) {
        return NO;
    }
    
    [(NSTabView*)tabView selectTabViewItemWithIdentifier: @"Progress"];
    [progress setDoubleValue: [progress minValue]];
    [scanDisplay setStringValue: @""];
    [window makeKeyAndOrderFront: self];
    
    m_scanner = [[FLScanner alloc] initWithPath: path
                                       progress: progress
                                        display: scanDisplay];
    [m_scanner scanThenPerform: @selector(finishScan:)
                            on: self];
    return YES;
}

- (void) finishScan: (id) data
{
    if ([m_scanner scanError]) {
        if (![m_scanner isCancelled]) {
            NSRunAlertPanel(@"Directory scan could not complete",
                            [m_scanner scanError], nil, nil, nil);
        }
        [window orderOut: self];
    } else {
        [self setScanDir: [m_scanner scanResult]];
        [self setRootDir: [self scanDir]];
        [(NSTabView*)tabView selectTabViewItemWithIdentifier: @"Filelight"];
        
        //扫描后根据静态鼠标位置更新列表显示
        [flView updateFileListAfterFirstScanThroughMousePoint:[NSEvent mouseLocation]];
        
        //清空面包屑
        [self.pathbar removeAllItems];
        //设定面包屑导航起始位置
        NSURL *_fileURL = [NSURL fileURLWithPath:[[self rootDir] path] isDirectory:NO];
        NSString* title=[[_fileURL absoluteString] lastPathComponent];
        [self.pathbar addItemWithTitle:title WithURL:_fileURL AndItem:[self rootDir]];
    }
    
//    [m_scanner release];
    m_scanner = nil;
}

- (IBAction) cancelScan: (id) sender
{
    if (m_scanner) {
        [m_scanner cancel];
    }
}

#pragma mark Breadcrumb Navigation
- (IBAction)pathbarAction:(id)sender {
    ITPathbarComponentCell* cell=[(ITPathbar *)sender clickedPathComponentCell];
    NSLog(@"%@ clicked", cell.URL);
    //[self remove:self];
    if([self.pathbar closeRightTabsByITPathbarComponentCell:cell]){//点击有效区域
        //获取点击的cell对应的item
        FLDirectory* item=[cell getItem];
        //NSLog(@"item get,is %@",[item path]);
        //更新饼图
        [self setRootDir: item];
        //更新列表
        [flView addRootAndCurrentItemChildrenToFileList];
    }
}

- (void)updateBreadcrumbNavigationByFLDirectoryItem:(FLDirectory*)item WithMode:(BOOL)mode{
    NSLog(@"updateBreadcrumbNavigationByFLDirectoryItem");
//    ITPathbarComponentCell* parentCell=[[self.pathbar mutablePathComponentCells] objectAtIndex:[[self.pathbar pathComponentCells] count]-2];
//    NSString* parentCellString=[parentCell.URL absoluteString];
//    
//    NSURL *_parentURL = [NSURL fileURLWithPath:[item path] isDirectory:NO];
//    NSString* parentString=[_parentURL absoluteString];
//    
//    NSLog(@"parentCellString is %@",parentCellString);
//    NSLog(@"parentString is %@",parentString);
    
    if (mode) {
        [self addCellByItemRecursively:item];
    }else{
        [self.pathbar removeLastItem];
    }
    
}

- (void)addCellByItemRecursively:(FLDirectory*)item{
    //1、获取currentHightLightCellString和parentString
    //获取item的父项
    FLDirectory *parent = [item parent];
    //获取当前高亮的cell
    ITPathbarComponentCell* currentHightLightCell=[[self.pathbar mutablePathComponentCells] objectAtIndex:[[self.pathbar pathComponentCells] count]-1];
    NSString* currentHightLightCellString=[currentHightLightCell.URL absoluteString];
//    NSLog(@"in addCellByItemRecursively");
    NSURL *_parentURL = [NSURL fileURLWithPath:[parent path] isDirectory:NO];
    NSString* parentString=[_parentURL absoluteString];
//    NSLog(@"parent path is %@",[parent path]);
//    NSLog(@"parentString is %@",parentString);
//    NSLog(@"currentHightLightCellString is %@",currentHightLightCellString);
    //2、比较是否一致，若一致则说明到了最里边一层，停止迭代，下加之
    if(![parentString isEqualToString:currentHightLightCellString]){
        [self addCellByItemRecursively:parent];
    }
    //3、添加导航项
    NSURL *_fileURL = [NSURL fileURLWithPath:[item path] isDirectory:NO];
    NSString* title=[[_fileURL absoluteString] lastPathComponent];
    [self.pathbar addItemWithTitle:title WithURL:_fileURL AndItem:item];
}

#pragma mark Misc

- (BOOL) application: (NSApplication *) app openFile: (NSString *) filename
{
    return [self startScan: filename];
}

- (void) awakeFromNib
{
    m_scanner = nil;
    m_scanDir = nil;
    
    [self setupToolbar];
    NSLog(@"hello disk");
    
//    //设置背景显示
//    window.titlebarAppearsTransparent = YES;
//    //window.titlebarAppearsTransparent = true // gives it "flat" look
//    //NSColor *color=[NSColor colorWithWhite:0.3 alpha:1.0];
//    NSColor *color=[NSColor blackColor];
//    window.backgroundColor = color;
//    tabView.backgroundColor=color;
}

- (IBAction) open: (id) sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setCanChooseFiles: NO];
    int result = [openPanel runModal];
    if (result == NSOKButton) {
        NSURL *fileURL = [[openPanel URLs] objectAtIndex: 0];
        NSString *path = [fileURL path];
        [self startScan: path];
    }
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
    if (![window isVisible]) {
        //[self open: self];
        [window makeKeyAndOrderFront: self];
    }
    
    //设置背景显示
    window.titlebarAppearsTransparent = YES;
    //window.titlebarAppearsTransparent = true // gives it "flat" look
    //NSColor *color=[NSColor colorWithWhite:0.3 alpha:1.0];
    NSColor *color=[NSColor whiteColor];
    //window.backgroundColor = color;
    //如用户未设定默认值，则设定颜色为白色，否则按照用户设定的颜色
    if ([self preferenceTableBgColor]!=nil) {
        tabView.backgroundColor=[self preferenceTableBgColor];
        window.backgroundColor =[self preferenceTableBgColor];
    }else{
//        tabView.backgroundFilters=[NSColor whiteColor];
        window.backgroundColor =[NSColor whiteColor];
    }
    
    //建立 _historyPopOverController
    _historyPopOverController = [[HistoryPopOverViewController alloc]
                                 initWithNibName:@"HistoryPopOverViewController" bundle:nil];
    
    [_fileListViewController setHistoryPopOverViewController:_historyPopOverController];
    
    //[window setDrawsBackground: NO];
    //[tabView setDrawsBackground: NO];
    
    
    NSLog(@"%@",[self preferenceTableBgColor]);
    
    //初始化breadcrumb navigation
    //self.pathbar.backgroundColor=[NSColor clearColor];
    [self.pathbar setAction:@selector(pathbarAction:)];
    [self.pathbar setTarget:self];
//    NSURL *_fileURL = [NSURL fileURLWithPath:@"/Users/HMLONG/Desktop/test.mp3" isDirectory:NO];
//    
//    [self.pathbar addItemWithTitle:@"Copyright" WithURL:_fileURL];
//    [self.pathbar addItemWithTitle:@"©" WithURL:_fileURL];
//    [self.pathbar addItemWithTitle:@"2012" WithURL:_fileURL];
//    [self.pathbar addItemWithTitle:@"by" WithURL:_fileURL];
//    [self.pathbar addItemWithTitle:@"Ilija Tovilo" WithURL:_fileURL];
}

- (void) setRootDir: (FLDirectory *) dir
{
    [[sizer dataSource] setRootDir: dir];
    [sizer setNeedsDisplay: YES];
    [window setTitle: [dir path]];
}

- (FLDirectory *) rootDir
{
    return [[sizer dataSource] rootDir];
}

- (void) parentDir: (id) sender
{
    FLDirectory *parent = [[self rootDir] parent];
    if (parent) {
        [self setRootDir: parent];
    } else {//parent为空则说明之前尚未扫描，进行扫描
        NSString *path = [[self rootDir] path];
        path = [path stringByDeletingLastPathComponent];
        [self startScan: path];
    }
}

- (void)enterParentDir{
    FLDirectory *parent = [[self rootDir] parent];
    if (parent) {
        [self setRootDir: parent];
        [self updateBreadcrumbNavigationByFLDirectoryItem:parent WithMode:false];
    } else {//parent为空则说明之前尚未扫描，进行扫描
//        NSString *path = [[self rootDir] path];
//        path = [path stringByDeletingLastPathComponent];
//        [self startScan: path];
    }
}

- (void) refresh: (id) sender
{
    [self startScan: [[self rootDir] path]];
}

//- (IBAction) setSkin: (id) sender{
////    //设置背景显示
////    window.titlebarAppearsTransparent = YES;
////    //window.titlebarAppearsTransparent = true // gives it "flat" look
////    //NSColor *color=[NSColor colorWithWhite:0.3 alpha:1.0];
////    NSColor *color=[NSColor blackColor];
////    //window.backgroundColor = color;
//    if ([self preferenceTableBgColor]!=nil) {
//        tabView.backgroundColor=[self preferenceTableBgColor];
//    }else{
//        tabView.backgroundColor=[NSColor whiteColor];
//    }
//    
//    
//    NSLog(@"%@",[self preferenceTableBgColor]);
//}

#pragma mark Set skin

- (IBAction) setSkinBlue: (id) sender{
    tabView.backgroundColor=[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.5];
    //window.backgroundColor=[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.2]];
    [self setPreferenceTableBgColor:[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.5]];
}

- (IBAction) setSkinBlack: (id) sender{
    tabView.backgroundColor=[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.8];
    //window.backgroundColor=[NSColor colorWithCalibratedRed:0 green:0 blue:1 alpha:0.2]];
    [self setPreferenceTableBgColor:[NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:0.8]];
}

- (IBAction) setSkinOrange: (id) sender{
    tabView.backgroundColor=[NSColor orangeColor];
    [self setPreferenceTableBgColor:[NSColor orangeColor]];
}

- (IBAction) setSkinWhite: (id) sender{
    tabView.backgroundColor=[NSColor whiteColor];
    [self setPreferenceTableBgColor:[NSColor whiteColor]];
}

- (NSColor *)preferenceTableBgColor
{
    NSString * const SkinColorKey = @"TheSkinColor";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *colorAsData = [defaults objectForKey:SkinColorKey];
    return [NSKeyedUnarchiver unarchiveObjectWithData:colorAsData];
}

- (void)setPreferenceTableBgColor:(NSColor *)color
{
    NSString * const SkinColorKey = @"TheSkinColor";
    NSData *colorAsData =
    [NSKeyedArchiver archivedDataWithRootObject:color];
    [[NSUserDefaults standardUserDefaults] setObject:colorAsData
                                              forKey:SkinColorKey];
}

#pragma mark File Table View

- (IBAction)addFile:(id)sender{
    NSURL *_fileURL = [NSURL fileURLWithPath:@"/Users/HMLONG/Desktop/test.mp3" isDirectory:NO];
    WDMessage *t = [WDMessage messageWithFile:_fileURL andState:kWDMessageStateReadyToSend];//[[WDMessage messageWithFile:_fileURL andState:kWDMessageStateReadyToSend] retain];
    [self storeMessageToFileList:t];
//    [t release];
}

- (IBAction)addFileToHistory:(id)sender{
    NSURL *_fileURL = [NSURL fileURLWithPath:@"/Users/HMLONG/Desktop/test.mid" isDirectory:NO];
    WDMessage *t = [WDMessage messageWithFile:_fileURL andState:kWDMessageStateReadyToSend] ;//[[WDMessage messageWithFile:_fileURL andState:kWDMessageStateReadyToSend] retain];
    [self storeMessage:t];
//    [t release];
}

- (void)storeMessage:(WDMessage *)message
{
    if ([message.state isEqualToString:kWDMessageStateFile]) {
        NSArray *originalMessages = [NSArray arrayWithArray:_historyPopOverController.fileHistoryArray];
        for (WDMessage *m in originalMessages) {
            if (([m.fileURL.path isEqualToString:message.fileURL.path])
                &&(![m.state isEqualToString:kWDMessageStateFile])) {
                m.state = kWDMessageStateFile;
            };
        }
    } else {
        [_historyPopOverController.fileHistoryArray addObject:message];
    }
    
    [_historyPopOverController.fileHistoryArray sortUsingComparator:^NSComparisonResult(WDMessage *obj1, WDMessage * obj2) {
        if ([obj1.time compare:obj2.time] == NSOrderedAscending)
            return NSOrderedAscending;
        else if ([obj1.time compare:obj2.time] == NSOrderedDescending)
            return NSOrderedDescending;
        else
            return NSOrderedSame;
    }];
    [_historyPopOverController.filehistoryTableView reloadData];
    [_historyPopOverController refreshButton];
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

#pragma mark Remove history File Table View
- (IBAction)openHistoryPopOver:(id)sender{
    NSLog(@"open");
    //NSButton *button  = (NSButton *)[_historyItem view];
    [_historyPopOverController showHistoryPopOver:historyButton];
}


- (void)showPreviewInHistory
{
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel]isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    } else {
        [[QLPreviewPanel sharedPreviewPanel]makeKeyAndOrderFront:nil];
    }
}

#pragma mark - QLPreviewPanel Support

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel;
{
    NSLog(@"acceptsPreviewPanelControl");
    
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    NSLog(@"beginPreviewPanelControl");
    
    // This document is now responsible of the preview panel
    // It is allowed to set the delegate, data source and refresh panel.
    _panel = panel;//[panel retain];
    panel.delegate = self;
    panel.dataSource = self;
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    // This document loses its responsisibility on the preview panel
    // Until the next call to -beginPreviewPanelControl: it must not
    // change the panel's delegate, data source or refresh it.
    NSLog(@"endPreviewPanelControl");
//    [_panel release];
    _panel = nil;
}

#pragma mark - QLPreviewPanel data source

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [_array count];
}

- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    return [_array objectAtIndex:index];
}

#pragma mark - QLPreviewPanel Delegate

- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)event
{
    return YES;
}

// This delegate method provides the rect on screen from which the panel will zoom.
- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item
{
    return NSZeroRect;
}

// This delegate method provides a transition image between the table view and the preview panel
- (id)previewPanel:(QLPreviewPanel *)panel transitionImageForPreviewItem:(id <QLPreviewItem>)item contentRect:(NSRect *)contentRect
{
    return nil;
}

#pragma mark - Check box file filter
- (IBAction)clickCompressedCheckBox:(id)sender{
    //[compressedCheckBoxButton state];
    //NSLog(@"compressed check box click, state is %ld",(long)[compressedCheckBoxButton state]);
    [flView addRootAndCurrentItemChildrenToFileList];
    
//    //获取按钮状态
//    int state=[compressedCheckBoxButton state];
//    
//    //如状态为选中(1)则过滤列表文件
//    if (state) {
//        //过滤
//        [_fileListViewController reserveCompressedFiles];
//        
//    }else{
//        //反过滤
//    }
    
}

- (IBAction)clickMusicCheckBox:(id)sender{
    //NSLog(@"music check box click, state is %ld",(long)[compressedCheckBoxButton state]);
    [flView addRootAndCurrentItemChildrenToFileList];
}

- (IBAction)clickVideoCheckBox:(id)sender{
    [flView addRootAndCurrentItemChildrenToFileList];
}

@end
