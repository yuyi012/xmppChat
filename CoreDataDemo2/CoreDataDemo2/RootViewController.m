//
//  RootViewController.m
//  CoreDataDemo2
//
//  Created by 俞 億 on 12-5-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"
#import "Group.h"
#import "Person.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"

@interface RootViewController ()

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSArray *groupNameArray = [NSArray arrayWithObjects:@"group1",@"group2",@"group3", nil];
    NSArray *personNameArray = [NSArray arrayWithObjects:@"person1",@"person1",@"person1", nil];
    AppDelegate *appDelegate= (AppDelegate*)[[UIApplication sharedApplication]delegate];
    NSMutableArray *groupEntityArray = [NSMutableArray array];
    for (NSString *groupName in groupNameArray) {
        Group *group = [NSEntityDescription insertNewObjectForEntityForName:@"Group" 
                                                     inManagedObjectContext:appDelegate.managedObjectContext];
        group.name = groupName;
        [groupEntityArray addObject:group];
    }
    [appDelegate.managedObjectContext save:nil];
    for (NSString *personName in personNameArray) {
        Person *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" 
                                                     inManagedObjectContext:appDelegate.managedObjectContext];
        person.name = personName;
        Group *firstGroup = [groupEntityArray objectAtIndex:0];
        [firstGroup addMemberArrayObject:person];
        for (Group *group in groupEntityArray) {
            [person addGroupArrayObject:group];
        }
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Group"];
    NSArray *fetchedGroupArray = [appDelegate.managedObjectContext 
                                  executeFetchRequest:fetchRequest error:NULL];
    NSLog(@"----group-----");
    for (Group *group in fetchedGroupArray) {
        NSLog(@"group:%@",group.name);
        for(Person* person in group.memberArray){
            NSLog(@"member:%@",person.name);
        }
    }
    NSLog(@"----group-----");
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subquery(groupArray,$x,$x.name=%@).@count>0",@"group1"];
    [fetchRequest setPredicate:predicate];
    NSArray *fetchedPersonArray = [appDelegate.managedObjectContext 
                                  executeFetchRequest:fetchRequest error:NULL];
    for (Person *person in fetchedPersonArray) {
        NSLog(@"person:%@",person.name);
        for(Group *group in person.groupArray){
            NSLog(@"group:%@",group.name);
        }
    }
}
@end
