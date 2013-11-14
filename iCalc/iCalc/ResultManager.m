//
//  ResultManager.m
//  iCalc
//
//  Created by Marty Pye on 14/11/13.
//  Copyright (c) 2013 Florian Heller. All rights reserved.
//

#import "ResultManager.h"

@interface ResultManager () {
    // stores the results
    NSMutableArray *historyOfResults;
}

@end

@implementation ResultManager

- (id)init
{
	self = [super init];
	if (self != nil) {
        historyOfResults = [NSMutableArray arrayWithCapacity:10];
        self.currentPositionInHistory = 0;
        [self restoreState];
	}
	return self;
}

- (NSNumber*) getNextResult;
{
    if (self.currentPositionInHistory < historyOfResults.count - 1) {
        self.currentPositionInHistory++;
    }
    
    return [historyOfResults objectAtIndex:self.currentPositionInHistory];
}


- (NSNumber*) getPreviousResult;
{
    if (self.currentPositionInHistory > 0) {
        self.currentPositionInHistory--;
    }
    
    return [historyOfResults objectAtIndex:self.currentPositionInHistory];
}

- (NSUInteger) historySize;
{
    return historyOfResults.count;
}


- (void) addNewResultToHistory:(NSNumber*)theResult;
{
    // history still has space
    if (historyOfResults.count < 10) {
        [historyOfResults addObject:theResult];
        self.currentPositionInHistory = historyOfResults.count - 1;
    }
    
    // history is full, remove oldest result
    else {
        [historyOfResults removeObjectAtIndex:0];
        [historyOfResults addObject:theResult];
    }
    
    self.currentPositionInHistory = historyOfResults.count - 1;
}

// receive KVO notification
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    if ([keyPath isEqual:@"lastResult"]) {
        [self addNewResultToHistory:(NSNumber*)[change objectForKey:NSKeyValueChangeNewKey]];
        [self storeHistory];
    }
}

// ----------------------------------------------------------------------------------------------------
// Saves the state of to NSUserDefaults
// ----------------------------------------------------------------------------------------------------
- (void) saveState;
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:self.currentPositionInHistory] forKey:@"currentPositionInHistory"];
    
    [self storeHistory];
}

- (void) restoreState;
{
    self.currentPositionInHistory = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentPositionInHistory"];
    
    [self restoreHistory];
}

- (void) storeHistory
{
    NSString *error;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"Data.plist"];
    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:
                               [NSArray arrayWithObjects: historyOfResults, [[NSNumber alloc] initWithInt:self.currentPositionInHistory], nil]
                                                          forKeys:[NSArray arrayWithObjects: @"history", @"posInHistory", nil]];
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                         errorDescription:&error];
    if(plistData) {
        [plistData writeToFile:plistPath atomically:YES];
    }
    else {
        NSLog(@"%@", error);
    }
}

- (void) restoreHistory;
{
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"Data.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"Data" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    if (!temp) {
        NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
    }
    historyOfResults = (NSMutableArray*)[temp objectForKey:@"history"];
    NSNumber* num = [temp objectForKey:@"posInHistory"];
    self.currentPositionInHistory = [num integerValue];
    
    if (!historyOfResults)
        historyOfResults = [NSMutableArray arrayWithCapacity:10];
}



@end
