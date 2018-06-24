/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialPainter.h"
#import "FLFile.h"

@class FileListViewController;
@class FLRadialItem;
@class FLController;

@interface FLView : NSView <FLHasDataSource> {
    IBOutlet id locationDisplay;
    IBOutlet id sizeDisplay;
    IBOutlet id dataSource;
    IBOutlet id controller;
    IBOutlet id contextMenu;
    
    IBOutlet id directoryName;
    IBOutlet id directorySize;
    IBOutlet id directoryImageView;
    
    IBOutlet FLController* flController;
    
    IBOutlet NSButton* compressedCheckBox;
    IBOutlet NSButton* musicCheckBox;
    IBOutlet NSButton* videoCheckBox;
    
    FLRadialPainter *m_painter;
    NSTrackingRectTag m_trackingRect;
    BOOL m_wasAcceptingMouseEvents;
    BOOL isMouseInCenterItem;
    
    NSString *currentRadialItemString;
    
    FLFile *m_context_target;
   
    
    IBOutlet FileListViewController *_fileListViewController;
    
    bool isNeedHightlight;
    int hightlightIndex;
}

- (IBAction) zoom: (id) sender;
- (IBAction) open: (id) sender;
- (IBAction) reveal: (id) sender;
- (IBAction) trash: (id) sender;
- (IBAction) copyPath: (id) sender;

- (IBAction)addFile:(id)sender;
- (void)setIsMouseInCenterItem:(bool)isMouseInCenterItemOrNot;
- (void) updateFileListAfterFirstScanThroughMousePoint:(NSPoint)mousePoint;
- (void) addSelfAndCurrentItemChildrenToFileList:(id)Item;
- (void)setCurrentRadialItemString:(NSString*)radialItemString;
- (void)addRootAndCurrentItemChildrenToFileList;
- (void)hightlightChildRadialItemAtIndex: (int)index;
- (void)needHightlightChildRadialItemAtIndex: (int)index;
- (void)clearRItemHightlight;
@end
