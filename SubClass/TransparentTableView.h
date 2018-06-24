//
//  TransparentTableView.h
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-14.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <AppKit/AppKit.h>

@class FileListViewController;

@interface TransparentTableView : NSTableView{
    NSTrackingRectTag trackingTag;//add
    int _mouseOverRow;
    IBOutlet id flView;
    IBOutlet FileListViewController *_fileListViewController;
}

- (int)getMouseOverRow;

@end
