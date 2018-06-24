/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialPainter.h"

#import "FLPolar.h"
#import "NSBezierPath+Segment.h"
#import "FLRadialItem.h"

#import "FLView.h"

@implementation NSView (FLRadialPainter)

- (NSPoint) center
{
    NSRect bounds = [self bounds];
    return NSMakePoint(NSMidX(bounds), NSMidY(bounds));
}

- (float) maxRadius
{
    NSRect bounds = [self bounds];
    NSSize size = bounds.size;
    float minDim = size.width < size.height ? size.width : size.height;
    return minDim / 2.0;
}

@end


@implementation FLRadialPainter

- (id) initWithView: (NSView <FLHasDataSource> *)view;
{
    if (self = [super init]) {
        // Default values
        m_maxLevels = 5;
        m_minRadiusFraction = 0.1;
        m_maxRadiusFraction = 0.7;
        m_minPaintAngle = 1.0;
        
        m_view = view; // No retain, view should own us
        m_colorer = nil;
    }
    return self;
}

- (void) dealloc
{
    if (m_colorer) ;//[m_colorer release];
//    [super dealloc];
}

- (void)setRootRadialItem:(FLRadialItem*)rootRadialItem{
    _rootRadialItem=rootRadialItem;
}

- (FLRadialItem*)getRootRadialItem{
    return _rootRadialItem;
}

#pragma mark Accessors

- (int) maxLevels
{
    return m_maxLevels;
}

- (void) setMaxLevels: (int)levels
{
    NSAssert(levels > 0, @"maxLevels must be positive!");
    m_maxLevels = levels;
}

- (float) minRadiusFraction
{
    return m_minRadiusFraction;
}

- (void) setMinRadiusFraction: (float)fraction
{
    NSAssert(fraction >= 0.0 && fraction <= 1.0,
             @"fraction must be between zero and one!");
    NSAssert(fraction < [self maxRadiusFraction],
             @"minRadius must be less than maxRadius!");
    m_minRadiusFraction = fraction;
}

- (float) maxRadiusFraction
{
    return m_maxRadiusFraction;
}

- (void) setMaxRadiusFraction: (float)fraction
{
    NSAssert(fraction >= 0.0 && fraction <= 1.0,
             @"fraction must be between zero and one!");
    NSAssert(fraction > [self minRadiusFraction],
             @"minRadius must be less than maxRadius!");
    m_maxRadiusFraction = fraction;
}

- (float) minPaintAngle
{
    return m_minPaintAngle;
}

- (void) setMinPaintAngle: (float)angle
{
    m_minPaintAngle = angle;
}

- (id) colorer
{
    return m_colorer;
}

- (void) setColorer: (id) c
{
//    [c retain];
    if (m_colorer) ;//[m_colorer release];
    m_colorer = c;
}

- (NSView <FLHasDataSource> *) view
{
    return m_view;
}

- (void) setView: (NSView <FLHasDataSource> *)view
{
    m_view = view; // No retain, view should own us
}

#pragma mark Misc

- (FLRadialItem *) root
{
    return [FLRadialItem rootItemWithDataSource: [[self view] dataSource]];
}

- (BOOL) wantItem: (FLRadialItem *) ritem
{
    //想要展示的Item必须满足两个条件：1、Item小于最大的层数(-1到4共六层)；2、Item大于一定的角度，也就是说Item在该目录下的比例要足够大(>=1/360)才能有机会展示
    return [ritem level] < [self maxLevels]
        && [ritem angleSpan] >= [self minPaintAngle];
}

- (float) radiusFractionPerLevel
{
    float availFraction = [self maxRadiusFraction] - [self minRadiusFraction];
    return availFraction / [self maxLevels];
}

#pragma mark Painting


- (float) innerRadiusFractionForLevel: (int)level
{
    // TODO: Deal with concept of "visible levels" <= maxLevels
    NSAssert(level <= [self maxLevels], @"Level too high!");    
    return [self minRadiusFraction] + ([self radiusFractionPerLevel] * level);
}

// Default coloring scheme
- (NSColor *) colorForItem: (id) item
                 angleFrac: (float) angle
                 levelFrac: (float) level
{
    return [NSColor colorWithCalibratedHue: angle
                                saturation: 1.0 - (level / 4)
                                brightness: 0.98
                                     alpha: 1.0];
}

- (NSColor *) colorForItem: (FLRadialItem *)ritem
{
    float levelFrac = (float)[ritem level] / ([self maxLevels] - 1);
    float midAngle = [ritem midAngle];
    float angleFrac = midAngle / 360.0;
    
    angleFrac -= floorf(angleFrac);
    NSAssert(angleFrac >= 0 && angleFrac <= 1.0,
             @"Angle fraction must be between zero and one");
    
    id c = m_colorer ? m_colorer : self;
    return [c colorForItem: [ritem item]
                 angleFrac: angleFrac
                 levelFrac: levelFrac];
}

- (void) drawItem: (FLRadialItem *)ritem setHighlight: (bool)isHightlight
{
    int level = [ritem level];//获取当前Item的层级
    float inner = [self innerRadiusFractionForLevel: level];//根据层级算出内环半径因子
    float outer = [self innerRadiusFractionForLevel: level + 1];//根据层级算出外环半径因子
    NSColor *fill = [self colorForItem: ritem];//设定颜色
//    if (isHightlight) {
//        fill=[NSColor highlightColor];
//    }
    
    //调整圆点位置
    NSPoint center_adjust;
    center_adjust.x=[[self view] center].x;
    center_adjust.y=[[self view] center].y;
    
    NSBezierPath *bp = [NSBezierPath
        circleSegmentWithCenter: center_adjust//view(FLView)的中心
                     startAngle: [ritem startAngle]//开始角度
                       endAngle: [ritem endAngle]//结束角度
                    smallRadius: inner * [[self view] maxRadius]//内环半径
                      bigRadius: outer * [[self view] maxRadius]];//外环半径
    
    //填充
    [fill set];
    [bp fill];
    
    //描边
    float strenth;
    if (isHightlight) {
        strenth=2.5;
        fill=[NSColor whiteColor];
    }else{
        strenth=0.2;
        fill=[NSColor blackColor];
    }
    //[[fill shadowWithLevel: strenth] set];
    //[[NSGraphicsContext currentContext] setShouldAntialias: NO];
    [bp setLineWidth:strenth];
    [fill set];
    
    [bp stroke];
}



- (void) drawTreeForItem: (FLRadialItem *)ritem
{
    if (![self wantItem: ritem]) {
        return;
    }
    
    // -1层不用画自然由于0层的描绘而成圆
    if ([ritem level] >= 0 && [ritem weight] > 0) {
        [self drawItem: ritem setHighlight:NOT_HIGHLIGHT];
    }
    
    // Draw the children 迭代
    NSEnumerator *e = [ritem childEnumerator];
    FLRadialItem *child;
    while (child = [e nextObject]) {
        [self drawTreeForItem: child];
    }
}

- (void)drawRect: (NSRect)rect
{
    // TODO: Choose root item(s) from rect
    _rootRadialItem=[self root];
    [self drawTreeForItem: _rootRadialItem];
}

#pragma mark Hit testing

- (id) findChildOf: (FLRadialItem *)ritem
             depth: (int)depth
             angle: (float)th
{
    NSAssert(depth >= 0, @"Depth must be at least zero");
    NSAssert(th >= [ritem startAngle], @"Not searching the correct tree");
    
    if (![self wantItem: ritem]) {
        return nil;
    }
    
    if (depth == 0) {
        //return [ritem item];
        return ritem;
    }
    
    NSEnumerator *e = [ritem childEnumerator];
    FLRadialItem *child;
    while (child = [e nextObject]) {
        if ([child endAngle] >= th) {
            return [self findChildOf: child depth: depth - 1 angle: th];
        }
    }
    
    return nil;
}

- (id) itemAt: (NSPoint)point
{
    float r, th;
    [FLPolar coordsForPoint: point center: [[self view] center] intoRadius: &r angle: &th];
    
    float rfrac = r / [[self view] maxRadius];
    
    //log
    if (rfrac < [self minRadiusFraction]) {
        NSLog(@"In center...");
        [(FLView*)m_view setIsMouseInCenterItem:true];
    }else{
        [(FLView*)m_view setIsMouseInCenterItem:false];
    }
//    if (rfrac >= [self maxRadiusFraction]) {
//        NSLog(@"Outside...");
//    }
    
    if (rfrac < [self minRadiusFraction] || rfrac >= [self maxRadiusFraction]) {
        return nil;
    }
    
   
    
    float usedFracs = rfrac - [self minRadiusFraction];
    int depth = floorf(usedFracs / [self radiusFractionPerLevel]) + 1;
    return [self findChildOf: [self root] depth: depth angle: th];
}


@end
