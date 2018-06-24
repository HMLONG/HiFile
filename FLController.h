/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLScanner.h"
#import <Quartz/Quartz.h>

#import "ITPathbar.h"

@class FileListViewController;
@class HistoryPopOverViewController;
@class FLView;

@interface FLController : NSObject<NSApplicationDelegate> {
    IBOutlet id sizer;
    IBOutlet NSTableView * tabView;
    IBOutlet id progress;
    IBOutlet id scanDisplay;
    IBOutlet NSWindow * window;
    IBOutlet FLView* flView;
    
    IBOutlet FileListViewController *_fileListViewController;
    HistoryPopOverViewController *_historyPopOverController;
    IBOutlet NSButton *historyButton;
    
    IBOutlet NSButton *compressedCheckBoxButton;
    
    FLScanner *m_scanner;
    FLDirectory *m_scanDir;
    
    NSArray *_array;
    QLPreviewPanel *_panel;
}

@property (copy) NSArray *array;

@property (assign) IBOutlet ITPathbar *pathbar;

- (IBAction) cancelScan: (id) sender;
- (IBAction) open: (id) sender; 
- (IBAction) refresh: (id) sender;
//- (IBAction) setSkin: (id) sender;
- (IBAction) setSkinBlue: (id) sender;
- (IBAction) setSkinOrange: (id) sender;
- (IBAction) setSkinWhite: (id) sender;
- (IBAction) setSkinBlack: (id) sender;

- (IBAction)addFile:(id)sender;
- (IBAction)addFileToHistory:(id)sender;
- (IBAction)openHistoryPopOver:(id)sender;

- (IBAction)clickCompressedCheckBox:(id)sender;
- (IBAction)clickMusicCheckBox:(id)sender;
- (IBAction)clickVideoCheckBox:(id)sender;

- (NSColor *)preferenceTableBgColor;
- (void)setPreferenceTableBgColor:(NSColor *)color;

- (void) setRootDir: (FLDirectory *) dir;
- (FLDirectory *) rootDir;

- (void)showPreviewInHistory;
- (void)enterParentDir;
- (void)updateBreadcrumbNavigationByFLDirectoryItem:(FLDirectory*)item WithMode:(BOOL)mode;
@end
