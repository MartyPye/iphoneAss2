//
//  ResultManager.h
//  iCalc
//
//  Created by Marty Pye on 14/11/13.
//  Copyright (c) 2013 Florian Heller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResultManager : NSObject

// current position index in history
@property (assign) NSUInteger currentPositionInHistory;
@property (assign, readonly) NSUInteger historySize;

- (NSNumber*) getNextResult;
- (NSNumber*) getPreviousResult;

- (void) saveState;
- (void) restoreState;


@end
