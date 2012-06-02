//
//  Person.h
//  CoreDataDemo2
//
//  Created by 俞 億 on 12-5-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Group;

@interface Person : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *groupArray;
@end

@interface Person (CoreDataGeneratedAccessors)

- (void)addGroupArrayObject:(Group *)value;
- (void)removeGroupArrayObject:(Group *)value;
- (void)addGroupArray:(NSSet *)values;
- (void)removeGroupArray:(NSSet *)values;

@end
