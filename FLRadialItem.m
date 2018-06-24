/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

#import "FLRadialItem.h"
#import "FLRadialPainter.h"
#import "FLDirectoryDataSource.h"

@implementation SequenceByWeightItem
@synthesize _sequence;
@synthesize _weight;
- (id) initWithSequence: (int)sequence
                 weight: (float)weight{
    if (self = [super init]) {
        _sequence = sequence;
        _weight = weight;
    }
    return self;
}
@end

@implementation FLRadialItem

- (id) initWithItem: (id)item
         dataSource: (id)dataSource
             weight: (float)weight
         startAngle: (float)a1
           endAngle: (float)a2
              level: (int)level
{
    if (self = [super init]) {
        m_item = item;
        m_dataSource = dataSource;
        m_weight = weight;
        m_startAngle = a1;
        m_endAngle = a2;
        m_level = level;
    }
    return self;
}

- (id) item
{
    return m_item;
}

- (float) weight
{
    return m_weight;
}

- (float) startAngle
{
    return m_startAngle;
}

- (float) endAngle
{
    return m_endAngle;
}

- (int) level
{
    return m_level;
}

- (float) midAngle
{
    return ([self startAngle] + [self endAngle]) / 2.0;
}

- (float) angleSpan
{
    return [self endAngle] - [self startAngle];
}

- (NSArray *) children;
{
    if ([self weight] == 0.0) {
        return [NSArray array];
    }
    
    float curAngle = [self startAngle];
    float anglePerWeight = [self angleSpan] / [self weight];
    id item = [self item];
    
    int m = [(FLDirectoryDataSource*)m_dataSource numberOfChildrenOfItem: item];
    NSMutableArray *children = [NSMutableArray arrayWithCapacity: m];
    
    //建立数组
    NSMutableArray *sequenceByWeightArray=[NSMutableArray arrayWithCapacity: m];
    int i;
    for (i = 0; i < m; ++i) {
        id sub = [(FLDirectoryDataSource*)m_dataSource child: i ofItem: item];
        float subw = [m_dataSource weightOfItem: sub];
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
    //保存排序结果
    if ([item isKindOfClass: [FLFile class]]) {
        [item setSortedArray:sortedArray];
    }else{
        [(FLFile*)item setSortedArray:sortedArray];
    }
    
    //测试
    NSEnumerator *e = [sortedArray objectEnumerator];
    SequenceByWeightItem *sequenceByWeightItemChild;
//    while (child = [e nextObject]) {
//        NSLog(@" %d",child._sequence);
//    }
//    SequenceByWeightItem* testItem=[sortedArray objectAtIndex:0];
//    NSLog(@"%d ",testItem._sequence);
    
    //按序添加child
    for (i = 0; i < m; ++i) {
        //获取序号
        sequenceByWeightItemChild=[e nextObject];
        int sequence=sequenceByWeightItemChild._sequence;
        
        id sub = [(FLDirectoryDataSource*)m_dataSource child: sequence ofItem: item];
        float subw = [m_dataSource weightOfItem: sub];
        float subAngle = anglePerWeight * subw;
        float nextAngle = curAngle + subAngle;
        
        id child = [[FLRadialItem alloc] initWithItem: sub
                                           dataSource: m_dataSource
                                               weight: subw
                                           startAngle: curAngle
                                             endAngle: nextAngle
                                                level: [self level] + 1];
        
//        if ([self level]==-1) {
//            NSLog(@"Now root dir need to find childs");
//            NSLog(@"child %d is %@",i,[[(FLRadialItem*)child item] path]);
//        }
        [children addObject: child];
//        [child release];
        
        curAngle = nextAngle;
    }
    //保存结果
    _children=children;
    
    return children;
}

- (NSArray *) getChildren{
    return _children;
}

- (void)showSelfAndCurrentItemChildren
{
    id item = [self item];
    //NSLog(@"self is %@",[item path]);
    
    int m = [(FLDirectoryDataSource*)m_dataSource numberOfChildrenOfItem: item];
    
    int i;
    for (i = 0; i < m; ++i) {
        id sub = [(FLDirectoryDataSource*)m_dataSource child: i ofItem: item];
        //NSLog(@"child %d is %@",i,[sub path]);
    }
}

- (id) getM_datasource{
    return m_dataSource;
}

- (NSEnumerator *)childEnumerator
{
    //先调用children进行child的获取，然后再调用系统函数进行item的枚举
    return [[self children] objectEnumerator];
}

+ (FLRadialItem *) rootItemWithDataSource: (id)dataSource
{
    float weight = [dataSource weightOfItem: nil];
    FLRadialItem *ri = [[FLRadialItem alloc] initWithItem: nil
                                               dataSource: dataSource
                                                   weight: weight
                                               startAngle: 0
                                                 endAngle: 360
                                                    level: -1];
    return ri;//[ri autorelease];
}


@end
