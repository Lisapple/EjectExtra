//
//  NSMenuItem+addition.h
//  Eject Extra
//
//  Created by Max on 08/06/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSMenu (addition)

- (NSArray *)itemsWithTag:(NSInteger)tag;

- (void)removeItemWithTag:(NSInteger)tag;
- (void)removeAllItemsWithTag:(NSInteger)tag;

@end
