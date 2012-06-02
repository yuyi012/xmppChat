//
//  Group.h
//  CoreDataDemo2
//
//  Created by 俞 億 on 12-5-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *memberArray;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addMemberArrayObject:(NSManagedObject *)value;
- (void)removeMemberArrayObject:(NSManagedObject *)value;
- (void)addMemberArray:(NSSet *)values;
- (void)removeMemberArray:(NSSet *)values;

@end
