/*
 * (C) 2011 Dirk W. Hoffmann. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "C64GUI.h"

@implementation MyController(Toolbar) 

#pragma mark NSToolbarItemValidation 

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
	/* */
	if ([c64 isRunning]) {
		[[self document] updateChangeCount:NSChangeDone];
	}
	
	/* Pause/Continue */
	if ([theItem tag] == 1) { 
		if ([c64 isRunning]) {
			[theItem setImage:[NSImage imageNamed:@"pause32"]];
			[theItem setLabel:@"Pause"];
		} else {
			[theItem setImage:[NSImage imageNamed:@"play32"]];
			[theItem setLabel:@"Run"];
		}
		return YES;
	}
	
	/* Step into, Step out, Step over */
	if ([theItem tag] >= 2 && [theItem tag] <= 4) {
		return ![c64 isRunning] && [c64 isRunnable];
	}
	
	/* Jostick port */
	if ([theItem tag] == 10 || [theItem tag] == 11) { 

		int port = ([theItem tag] == 10) ? [c64 getPortAssignment:0] : [c64 getPortAssignment:1];
		switch (port) {
			case IPD_KEYBOARD:
				[theItem setImage:[NSImage imageNamed:@"keyboard32"]];
				return YES;
			case IPD_JOYSTICK_1:
				[theItem setImage:[NSImage imageNamed:@"joystick1_32"]];
				return YES;
			case IPD_JOYSTICK_2:
				[theItem setImage:[NSImage imageNamed:@"joystick2_32"]];
				return YES;
			case IPD_UNCONNECTED:
				[theItem setImage:[NSImage imageNamed:@"none_32"]];
				return YES;
			default:
				assert(0);
		}
	}	
	
	/* All other items */
    return YES;
}

- (void) setupToolbarIcons
{
	//NSImage *tmIcon = [[NSWorkspace sharedWorkspace] iconForFile:@"/Applications/Time Machine.app"];
	//[cheatboxIcon setImage:tmIcon];
}


- (void) printDocument:(id) sender
{
	// Set printing properties
	NSPrintInfo *myPrintInfo = [[self document] printInfo];
	[myPrintInfo setHorizontalPagination:NSFitPagination];
	[myPrintInfo setHorizontallyCentered:YES];
	[myPrintInfo setVerticalPagination:NSFitPagination];
	[myPrintInfo setVerticallyCentered:YES];
	[myPrintInfo setOrientation:NSLandscapeOrientation];
	[myPrintInfo setLeftMargin:0.0]; // 32.0
	[myPrintInfo setRightMargin:0.0]; // 32.0
	[myPrintInfo setTopMargin:0.0]; // 32.0
	[myPrintInfo setBottomMargin:0.0]; // 32.0
	
	// Capture image and create image view
	NSImage *image = [screen screenshot];
	NSRect printRect = NSMakeRect(0.0, 0.0, [image size].width, [image size].height);
	NSImageView *imageView = [[NSImageView alloc] initWithFrame:printRect];
	[imageView setImage:image];
	[imageView setImageScaling:NSScaleToFit];
	
	// Print image
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:imageView  printInfo:myPrintInfo];
    [printOperation runOperationModalForWindow:[[self document] windowForSheet] delegate: nil didRunSelector: NULL contextInfo:NULL];
	
	[imageView release];
}

- (IBAction)debugAction:(id)sender
{	
	[debug_panel toggle:self];
	[self refresh];
}


- (IBAction)joystick1Action:(id)sender
{
	[c64 switchInputDevice:0];
}

- (IBAction)joystick2Action:(id)sender
{
	[c64 switchInputDevice:1];
}

- (IBAction)switchJoysticksAction:(id)sender
{
	[c64 switchInputDevices];
}

- (IBAction)fullscreenAction:(id)sender
{
	[screen toggleFullscreenMode];
}

- (IBAction)cheatboxAction:(id)sender
{	
	if ([cheatboxPanel state] == NSDrawerOpenState) {
		[c64 run];
		[cheatboxPanel close];
	}
	if ([cheatboxPanel state] == NSDrawerClosedState) {
		[c64 halt];
		[cheatboxImageBrowserView refresh];		
		[cheatboxPanel open];
	}	
}

@end