//
//  HistoryPopOverViewController.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-9.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class WDBubble;
@class TransparentTableView;
@class WDMessage;
@class ImageAndTextCell;
@class MyPopover;
@class HistoryPopOverViewController;
@class FLView;
@class FLController;
#import "ImageAndTextCell.h"
#import "NSTableView+ContextMenu.h"

#define kPreviewColumn 1
#define kDeleteColumn 2
#define kQuickLookColumn 3

#define kRestoreLabelAndImage @"kRestoreLabelAndImage"

@interface FileListViewController : NSViewController<NSPopoverDelegate,NSTableViewDataSource,NSTableViewDelegate,ImageAndTextCellDelegate,ContextMenuDelegate>
{
    IBOutlet TransparentTableView *_fileHistoryTableView;
    //IBOutlet NSView *view;
    NSPopover *_historyPopOver;
    NSMutableArray *_fileHistoryArray;
    
    ImageAndTextCell *_imageAndTextCell;
    
    IBOutlet NSButton *_removeButton;
    
    WDBubble *_bubbles;
    HistoryPopOverViewController *_historyPopOverViewController;
    
    IBOutlet FLController* flController;
    IBOutlet FLView* flView;
    
    int lastMouseOverRow;
}

@property (nonatomic ,retain) NSPopover *historyPopOver;
@property (nonatomic ,retain) NSMutableArray *fileHistoryArray;
@property (nonatomic ,retain) TransparentTableView *filehistoryTableView;
@property (nonatomic ) WDBubble *bubbles;

// Wu:attachedView is the the view which popover attach to like the effect in Safari
- (void)showHistoryPopOver:(NSView *)attachedView;
- (void)deleteMessageFromHistory:(WDMessage *)aMessage;
- (void)refreshButton;
- (void)reloadTableView;
- (void)setHistoryPopOverViewController:(HistoryPopOverViewController *)historyPopOverViewController;

- (void)reserveCompressedFiles;

- (bool)isCompressExtension:(NSString*) extension;
- (bool)isMusicExtension:(NSString*) extension;
- (bool)isVideoExtension:(NSString*) extension;
-(void)refreshLastMouseOverRowAfterMouseExitTable;
@end
