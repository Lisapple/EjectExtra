//
//  Eject_ExtraAppDelegate.h
//  Eject Extra
//
//  Created by Max on 20/01/2010.
//  Copyright 2010 Lis@cintosh. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>

@interface Eject_ExtraAppDelegate : NSObject 
#if defined(MAC_OS_X_VERSION_10_6)
<NSApplicationDelegate, NSMenuDelegate>
#endif
{
	NSStatusItem * statusItem;
	NSMenu * menu;
	
	NSModalSession modalSession;
	
	NSSound * ejectSound;
}

@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSTextField * versionLabel, * copyrightLabel;

@property (nonatomic, strong) NSSound * ejectSound;

- (IBAction)showWebsite:(id)sender;

- (void)deviceDidMount:(NSNotification *)aNotification;
- (void)deviceDidUnmount:(NSNotification *)aNotification;

- (NSArray *)mountedRemovableVolumes;

- (void)unmountDeviceWithPath:(NSString *)path;

- (void)ejectAll:(id)sender;
- (void)eject:(id)sender;

- (BOOL)applicationIsLaunchedAtLogin;

- (IBAction)launchOptionAction:(id)sender;

- (void)launchAtLogin;
- (void)unlaunchAtLogin;

- (NSInteger)indexOfLoginPreferenceEntry;

- (IBAction)showFeedback:(id)sender;

- (void)about;
- (void)quit;

- (NSDictionary *)attributesForDeviceAtPath:(NSString *)aPath;

@end
