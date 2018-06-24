//
//  MyPopover.m
//  BubbleTableViewTest
//
//  Created by 龙海明 on 7/27/16.
//  Copyright © 2016 龙海明. All rights reserved.
//

#import "MyPopover.h"

@implementation MyPopover

-(void)drawRect:(NSRect)dirtyRect
{
    [[NSColor redColor] set];
    NSRectFill(dirtyRect);
}

@end
