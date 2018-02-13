/*
 * Author: Dirk W. Hoffmann, 2011 - 2015
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
#import <MetalKit/MetalKit.h>
#import "VirtualC64-Swift.h"

@implementation MyController

@synthesize c64;

@synthesize propertiesDialog;
@synthesize hardwareDialog;
@synthesize mediaDialog;
@synthesize mountDialog;
@synthesize tapeDialog;

// Toolbar
@synthesize joystickPortA;
@synthesize joystickPortB;

// Main screen
@synthesize debugPanel;
@synthesize cheatboxPanel;

// Bottom bar
@synthesize greenLED;
@synthesize redLED;
@synthesize progress;
@synthesize driveIcon;
@synthesize cartridgeIcon;
@synthesize tapeIcon;
@synthesize tapeProgress;
@synthesize clockSpeed;
@synthesize clockSpeedBar;
@synthesize warpIcon;

@synthesize cheatboxImageBrowserView;
@synthesize menuItemFinalIII;
@synthesize gamePadManager;
@synthesize modifierFlags;
@synthesize statusBar;
@synthesize gamepadSlotA;
@synthesize gamepadSlotB;

@synthesize keyboardcontroller;
@synthesize metalScreen;
@synthesize cpuTableView;
@synthesize memTableView;
@synthesize speedometer;
@synthesize animationCounter;

@synthesize timer;
@synthesize timerLock;

// --------------------------------------------------------------------------------
//       Metal screen API (remove when controller is Swift only!)
// --------------------------------------------------------------------------------

- (BOOL)fullscreen { return [metalScreen fullscreen]; }
- (NSImage *)screenshot { return [metalScreen screenshot]; }
- (void)rotateBack { [metalScreen rotateBack]; }
 - (void)shrink { [metalScreen shrink]; }
- (void)expand { [metalScreen expand]; }
- (float)eyeX { return [metalScreen eyeX]; }
- (void)setEyeX:(float)x { [metalScreen setEyeX:x]; }
- (float)eyeY { return [metalScreen eyeY]; }
- (void)setEyeY:(float)y { [metalScreen setEyeY:y]; }
- (float)eyeZ { return [metalScreen eyeZ]; }
- (void)setEyeZ:(float)z { [metalScreen setEyeZ:z]; }
- (long)videoUpscaler { return [metalScreen videoUpscaler]; }
- (void)setVideoUpscaler:(long)val { [metalScreen setVideoUpscaler:val]; }
- (long)videoFilter { return [metalScreen videoFilter]; }
- (void)setVideoFilter:(long)val { [metalScreen setVideoFilter:val]; }
- (BOOL)fullscreenKeepAspectRatio { return [metalScreen fullscreenKeepAspectRatio]; }
- (void)setFullscreenKeepAspectRatio:(BOOL)val { [metalScreen setFullscreenKeepAspectRatio:val]; }

// --------------------------------------------------------------------------------
//     KeyboardController API (remove when controller is Swift only!)
// --------------------------------------------------------------------------------

- (void)simulateUserPressingKey:(C64KeyFingerprint)key {
    [keyboardcontroller simulateUserPressingKey:key];
}
- (void)simulateUserPressingKeyWithShift:(C64KeyFingerprint)key {
    [keyboardcontroller simulateUserPressingKeyWithShift:key];
}
- (void)simulateUserPressingKeyWithRunstop:(C64KeyFingerprint)key {
    [keyboardcontroller simulateUserPressingKeyWithRunstop:key];
}
- (void)simulateUserTypingText:(NSString *)text {
    [keyboardcontroller simulateUserTypingWithText:text initialDelay:0 completion:nil];
}
- (void)simulateUserTypingText:(NSString *)text withInitialDelay:(useconds_t)delay {
    [keyboardcontroller simulateUserTypingWithText:text initialDelay:delay completion:nil];
}
- (void)simulateUserTypingTextAndPressPlay:(NSString *)text {
    [keyboardcontroller simulateUserTypingAndPressPlayWithText:text];
}

- (BOOL)getDisconnectEmulationKeys { return [keyboardcontroller getDisconnectEmulationKeys]; }
- (void)setDisconnectEmulationKeys:(BOOL)b { [keyboardcontroller setDisconnectEmulationKeys:b]; }



// --------------------------------------------------------------------------------
//          Refresh methods: Force all GUI items to refresh their value
// --------------------------------------------------------------------------------

- (void)refresh
{		
	[self refreshCPU];
	[self refreshMemory];
	[self refreshCIA];
	[self refreshVIC];
	[cpuTableView refresh];
	[memTableView refresh];
}

- (void)refresh:(NSFormatter *)byteFormatter word:(NSFormatter *)wordFormatter threedigit:(NSFormatter *)threeDigitFormatter disassembler:(NSFormatter *)disassembler
{		
	NSControl *ByteFormatterControls[] = { 
		// CPU panel
		sp, a, x, y,
		// CIA panel
		cia1DataPortA, cia1DataPortDirectionA, cia1DataPortB, cia1DataPortDirectionB,
		tod1Hours, tod1Minutes, tod1Seconds, tod1Tenth, alarm1Hours, alarm1Minutes, alarm1Seconds, alarm1Tenth,
		cia2DataPortA, cia2DataPortDirectionA, cia2DataPortB, cia2DataPortDirectionB,
		tod2Hours, tod2Minutes, tod2Seconds, tod2Tenth, alarm2Hours, alarm2Minutes, alarm2Seconds, alarm2Tenth,
		// VIC panel
		VicSpriteY1, VicSpriteY2, VicSpriteY3, VicSpriteY4, VicSpriteY5, VicSpriteY6, VicSpriteY7, VicSpriteY8,
 		NULL };
	
	NSControl *WordFormatterControls[] = { 
		// CPU panel
		pc, breakpoint,
		// Memory panel
		addr_search,
		// CIA panel
		cia1TimerA, cia1LatchedTimerA, cia1TimerB, cia1LatchedTimerB,
		cia2TimerA, cia2LatchedTimerA, cia2TimerB, cia2LatchedTimerB,
		// VIC panel
		VicRasterline, VicRasterInterrupt,
		NULL };

    NSControl *threeDigitFormatterControls[] = { 
		// VIC panel
		VicSpriteX1, VicSpriteX2, VicSpriteX3, VicSpriteX4, VicSpriteX5, VicSpriteX6, VicSpriteX7, VicSpriteX8,
		NULL };

	// Bind formatters
	for (int i = 0; ByteFormatterControls[i] != NULL; i++) {
		[ByteFormatterControls[i] abortEditing];
		[ByteFormatterControls[i] setFormatter:byteFormatter];
		[ByteFormatterControls[i] setNeedsDisplay];
	}
	
	for (int i = 0; WordFormatterControls[i] != NULL; i++) {
		[WordFormatterControls[i] abortEditing];
		[WordFormatterControls[i] setFormatter:wordFormatter];
		[WordFormatterControls[i] setNeedsDisplay];
	}

    for (int i = 0; threeDigitFormatterControls[i] != NULL; i++) {
		[threeDigitFormatterControls[i] abortEditing];
		[threeDigitFormatterControls[i] setFormatter:threeDigitFormatter];
		[threeDigitFormatterControls[i] setNeedsDisplay];
	}

	// Assign formatters to all table view cells
	[[[cpuTableView tableColumnWithIdentifier:@"addr"] dataCell] setFormatter:wordFormatter];
	[[[cpuTableView tableColumnWithIdentifier:@"data01"] dataCell] setFormatter:byteFormatter];
	[[[cpuTableView tableColumnWithIdentifier:@"data02"] dataCell] setFormatter:byteFormatter];
	[[[cpuTableView tableColumnWithIdentifier:@"data03"] dataCell] setFormatter:byteFormatter];
	[[[cpuTableView tableColumnWithIdentifier:@"ascii"] dataCell] setFormatter:disassembler];
	
	[[[memTableView tableColumnWithIdentifier:@"addr"] dataCell] setFormatter:wordFormatter];
	[[[memTableView tableColumnWithIdentifier:@"hex0"] dataCell] setFormatter:byteFormatter];
	[[[memTableView tableColumnWithIdentifier:@"hex1"] dataCell] setFormatter:byteFormatter];
	[[[memTableView tableColumnWithIdentifier:@"hex2"] dataCell] setFormatter:byteFormatter];
	[[[memTableView tableColumnWithIdentifier:@"hex3"] dataCell] setFormatter:byteFormatter];	
	
	[self refresh];
}

- (void)enableUserEditing:(BOOL)enabled
{
	NSControl *controls[] = { 
		// CPU panel
		pc, sp, a, x, y, 
		Nflag, Zflag, Cflag, Iflag, Bflag, Dflag, Vflag,
		// CIA panel
		cia1DataPortA, cia1DataPortDirectionA, cia1TimerA, cia1LatchedTimerA, 
		//cia1RunningA, cia1OneShotA, cia1CountUnderflowsA, cia1SignalPendingA, cia1InterruptEnableA,
		cia1DataPortB, cia1DataPortDirectionB, cia1TimerB, cia1LatchedTimerB, 
		//cia1RunningB, cia1OneShotB, cia1CountUnderflowsB, cia1SignalPendingB, cia1InterruptEnableB,
		tod1Hours, tod1Minutes, tod1Seconds, tod1Tenth,
		alarm1Hours, alarm1Minutes, alarm1Seconds, alarm1Tenth,
        // tod1InterruptEnabled,
		cia2DataPortA, cia2DataPortDirectionA, cia2TimerA, cia2LatchedTimerA, 
		// cia2RunningA, cia2OneShotA, cia2CountUnderflowsA, cia2SignalPendingA, cia2InterruptEnableA,
		cia2DataPortB, cia2DataPortDirectionB, cia2TimerB, cia2LatchedTimerB, 
		//cia2RunningB, cia2OneShotB, cia2CountUnderflowsB, cia2SignalPendingB, cia2InterruptEnableB,
		tod2Hours, tod2Minutes, tod2Seconds, tod2Tenth,
		alarm2Hours, alarm2Minutes, alarm2Seconds, alarm2Tenth,
        // tod2InterruptEnabled,
		// VIC panel
		VicSpriteX1, VicSpriteX2, VicSpriteX3, VicSpriteX4, VicSpriteX5, VicSpriteX6, VicSpriteX7, VicSpriteX8,
        VicSpriteY1, VicSpriteY2, VicSpriteY3, VicSpriteY4, VicSpriteY5, VicSpriteY6, VicSpriteY7, VicSpriteY8,
        
        VicRasterline, VicRasterInterrupt, VicDX, VicDY,
		NULL };
	
	// Enable / disable controls
	for (int i = 0;; i++) {
		if (controls[i] == NULL) break;
		[controls[i] setEnabled:enabled];
	}
	
	// Enable / disable table columns
	[[memTableView tableColumnWithIdentifier:@"hex0"] setEditable:enabled];
	[[memTableView tableColumnWithIdentifier:@"hex1"] setEditable:enabled];
	[[memTableView tableColumnWithIdentifier:@"hex2"] setEditable:enabled];
	[[memTableView tableColumnWithIdentifier:@"hex3"] setEditable:enabled];
	
	// Change image and state of debugger control buttons
	if (![c64 isRunnable]) {
		[stopAndGoButton setImage:[NSImage imageNamed:@"play32"]];		
		[stopAndGoButton setEnabled:false];
		[stepIntoButton setEnabled:false];
		[stepOverButton setEnabled:false];
		[stepOutButton setEnabled:false];		
		
	} else if ([c64 isHalted]) {
		[stopAndGoButton setImage:[NSImage imageNamed:@"play32"]];		
		[stopAndGoButton setEnabled:true];
		[stepIntoButton setEnabled:true];
		[stepOverButton setEnabled:true];
		[stepOutButton setEnabled:true];		
	} else {
		[stopAndGoButton setImage:[NSImage imageNamed:@"pause32"]];
		[stopAndGoButton setEnabled:true];
		[stepIntoButton setEnabled:false];
		[stepOverButton setEnabled:false];
		[stepOutButton setEnabled:false];		
	}		
}

// --------------------------------------------------------------------------------
//                                     Dialogs
// --------------------------------------------------------------------------------

- (bool)showPropertiesDialog
{
    [propertiesDialog initialize:self];
    [[self window] beginSheet:propertiesDialog completionHandler:nil];
    
    return YES;
}

- (IBAction)cancelPropertiesDialog:(id)sender
{
	[propertiesDialog orderOut:sender]; // Hide sheet
    [[self window] endSheet:propertiesDialog returnCode:NSModalResponseCancel];
}

- (bool)showHardwareDialog
{
    [hardwareDialog initialize:self];
    [[self window] beginSheet:hardwareDialog completionHandler:nil];

    return YES;
}

- (IBAction)cancelHardwareDialog:(id)sender
{
    [hardwareDialog orderOut:sender];
    [[self window] endSheet:hardwareDialog returnCode:NSModalResponseCancel];
}

- (bool)showMediaDialog
{
    [mediaDialog initialize:self];
    [[self window] beginSheet:mediaDialog completionHandler:nil];
    
    return YES;
}

- (IBAction)cancelMediaDialog:(id)sender
{
    [mediaDialog orderOut:sender]; // Hide sheet
    [[self window] endSheet:mediaDialog returnCode:NSModalResponseCancel];
}

@end
