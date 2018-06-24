/* Copyright (C) 1996 Dave Vasilevsky
 * This file is licensed under the GNU General Public License,
 * see the file Copying.txt for details. */

// Data source: generalization of NSOutlineViewDataSource
// nil object means the root.
@interface NSObject (FLRadialPainterDataSource)
- (id) child: (int) index ofItem: (id) item;
- (int) numberOfChildrenOfItem: (id) item;

- (float) weightOfItem: (id) item;
@end

@interface SequenceByWeightItem : NSObject{
    int _sequence;
    float _weight;
}
@property (readwrite) int _sequence;
@property (readwrite) float _weight;
- (id) initWithSequence: (int)sequence
                 weight: (float)weight;
@end

@interface FLRadialItem : NSObject {
    id m_dataSource;
    id m_item;
    float m_weight;
    float m_startAngle, m_endAngle;
    int m_level;
    
    NSArray* _children;
}

- (id) initWithItem: (id)item
         dataSource: (id)dataSource
             weight: (float)weight
         startAngle: (float)a1
           endAngle: (float)a2
              level: (int)level;

- (id) item;
- (id) getM_datasource;
- (float) weight;
- (float) startAngle;
- (float) endAngle;
- (int) level;

- (float) midAngle;
- (float) angleSpan;

- (NSArray *) children;
- (NSArray *) getChildren;
- (NSEnumerator *)childEnumerator;

+ (FLRadialItem *) rootItemWithDataSource: (id)dataSource;

- (void)showSelfAndCurrentItemChildren;

@end
