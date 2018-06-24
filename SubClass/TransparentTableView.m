//
//  TransparentTableView.m
//  Bubbles
//
//  Created by 吴 wuziqi on 12-2-14.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "TransparentTableView.h"
#import "FileListViewController.h"
#import "FLView.h"

@implementation TransparentTableView

- (void)awakeFromNib {
    
    [[self enclosingScrollView] setDrawsBackground: NO];
    [[self window] setAcceptsMouseMovedEvents:YES];//add
    //[[self window] makeMainWindow];
    //[[self window] makeKeyAndOrderFront:self];
    //trackingTag = [self addTrackingRect:[self frame] owner:self userData:nil assumeInside:NO];//add
    
    //刚进入程序初始化为-1，因为0表示鼠标在第一行
    _mouseOverRow=-1;
    
    //使鼠标移动在该区域始终有效
    NSTrackingAreaOptions options = (NSTrackingActiveAlways | NSTrackingInVisibleRect |
                                     NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved);
    
    NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                        options:options
                                                          owner:self
                                                       userInfo:nil];
    [self addTrackingArea:area];
}

- (BOOL)isOpaque {
    
    return NO;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    
    // don't draw a background rect
}

//- (void)dealloc//add
//{
//    [self removeTrackingRect:trackingTag];
//    //[super dealloc];
//}
//
//- (void)viewDidEndLiveResize//add
//{
//    [super viewDidEndLiveResize];
//    
//    [self removeTrackingRect:trackingTag];
//    trackingTag = [self addTrackingRect:[self frame] owner:self userData:nil assumeInside:NO];
//}

- (void)mouseMoved:(NSEvent *)theEvent {//add
    // Pass it on to window controller view
   // [[[[self window] contentView] superview] mouseDownInTableViewWithEvent:event];
    //	[super mouseDown:event];
    
    NSPoint location = [theEvent locationInWindow];
    int mouseOverRow = [self rowAtPoint:[self convertPoint:location fromView:nil]];
    _mouseOverRow=mouseOverRow;
    //NSLog(@"Mouse moved in TransparentTableView class,row is %d",_mouseOverRow);
    [self reloadData];
}

- (void)mouseExited:(NSEvent *)theEvent{
    NSLog(@"Mouse Exit");
    //退出鼠标区域时使列表高亮消失
    _mouseOverRow=-1;
    [self reloadData];
    
    //退出鼠标区域时使饼图高亮消失
    [(FLView*)flView clearRItemHightlight];
    //更新鼠标在列表的历史位置
    [_fileListViewController refreshLastMouseOverRowAfterMouseExitTable];
}

- (int)getMouseOverRow{
    return _mouseOverRow;
}

@end
