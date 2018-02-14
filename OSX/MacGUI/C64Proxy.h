/*
 * Author: Dirk W. Hoffmann. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "C64_defs.h"
#import "VIC_globals.h"
#import "basic.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class MyController;
@class C64Proxy;
@class SnapshotProxy;
@class D64ArchiveProxy; 
@class ArchiveProxy;
@class TAPProxy;
@class CRTProxy;

// Forward declarations of wrappers for C++ classes.
// We wrap classes into normal C structs to avoid any reference to C++ here.

struct C64Wrapper;
struct CpuWrapper;
struct MemoryWrapper;
struct VicWrapper;
struct CiaWrapper;
struct KeyboardWrapper;
struct JoystickWrapper;
struct SidWrapperWrapper; // Yes, it's a double wrapper
struct IecWrapper;
struct ExpansionPortWrapper;
struct Via6522Wrapper;
struct Disk525Wrapper;
struct Vc1541Wrapper;
struct DatasetteWrapper;
struct ContainerWrapper;

// --------------------------------------------------------------------------
//                                    CPU
// --------------------------------------------------------------------------

@interface CPUProxy : NSObject {
        
	struct CpuWrapper *wrapper;
}

- (void) dump;
@property (setter=setTraceMode:) BOOL tracingEnabled;
@property uint16_t PC;
@property uint8_t SP;
@property uint8_t A;
@property uint8_t X;
@property uint8_t Y;
@property BOOL Nflag;
@property BOOL  Zflag;
@property BOOL  Cflag;
@property BOOL  Iflag;
@property BOOL  Bflag;
@property BOOL  Dflag;
@property BOOL  Vflag;

- (uint16_t) peekPC;
- (uint8_t) lengthOfInstruction:(uint8_t)opcode;
- (uint8_t) lengthOfInstructionAtAddress:(uint16_t)addr;
@property (readonly) uint8_t lengthOfCurrentInstruction;
@property (readonly) uint16_t addressOfNextInstruction;
- (const char *) mnemonic:(uint8_t)opcode;
- (AddressingMode) addressingMode:(uint8_t)opcode;

@property (readonly) int topOfCallStack;
- (int) breakpoint:(int)addr;
- (void) setBreakpoint:(int)addr tag:(uint8_t)t;
- (void) setHardBreakpoint:(int)addr;
- (void) deleteHardBreakpoint:(int)addr;
- (void) toggleHardBreakpoint:(int)addr;
- (void) setSoftBreakpoint:(int)addr;
- (void) deleteSoftBreakpoint:(int)addr;
- (void) toggleSoftBreakpoint:(int)addr;

@end

// --------------------------------------------------------------------------
//                                  Memory
// --------------------------------------------------------------------------

@interface MemoryProxy : NSObject {
    
	struct MemoryWrapper *wrapper;
}

- (void) dump;

- (uint8_t) peek:(uint16_t)addr;
- (uint16_t) peekWord:(uint16_t)addr;
- (uint8_t) peekFrom:(uint16_t)addr memtype:(MemoryType)source;
- (void) poke:(uint16_t)addr value:(uint8_t)val;
- (void) pokeTo:(uint16_t)addr value:(uint8_t)val memtype:(MemoryType)source;
- (bool) isValidAddr:(uint16_t)addr memtype:(MemoryType)source;

@end

// --------------------------------------------------------------------------
//                                    VIC
// --------------------------------------------------------------------------

@interface VICProxy : NSObject {
    
	struct VicWrapper *wrapper;
}

- (void) dump;

@property (readonly, nullable) void *screenBuffer;

- (NSColor *) color:(NSInteger)nr;
@property NSInteger colorScheme;

@property uint16_t memoryBankAddr;
@property uint16_t screenMemoryAddr;
@property uint16_t characterMemoryAddr;

- (int) displayMode;
- (void) setDisplayMode:(long)mode;
- (int) screenGeometry;
- (void) setScreenGeometry:(long)mode;
@property int horizontalRasterScroll;
@property int verticalRasterScroll;

- (bool) spriteVisibilityFlag:(NSInteger)nr;
- (void) setSpriteVisibilityFlag:(NSInteger)nr value:(bool)flag;
- (void) toggleSpriteVisibilityFlag:(NSInteger)nr;

- (int) spriteX:(NSInteger)nr;
- (void) setSpriteX:(NSInteger)nr value:(int)x;
- (int) spriteY:(NSInteger)nr;
- (void) setSpriteY:(NSInteger)nr value:(int)y;

- (int) spriteColor:(NSInteger)nr;
- (void) setSpriteColor:(NSInteger)nr value:(int)c;
- (bool) spriteMulticolorFlag:(NSInteger)nr;
- (void) setSpriteMulticolorFlag:(NSInteger)nr value:(bool)flag;
- (void) toggleSpriteMulticolorFlag:(NSInteger)nr;

- (bool) spriteStretchXFlag:(NSInteger)nr;
- (void) setSpriteStretchXFlag:(NSInteger)nr value:(bool)flag;
- (void) toggleSpriteStretchXFlag:(NSInteger)nr;
- (bool) spriteStretchYFlag:(NSInteger)nr;
- (void) setSpriteStretchYFlag:(NSInteger)nr value:(bool)flag;
- (void) toggleSpriteStretchYFlag:(NSInteger)nr;

@property BOOL spriteSpriteCollisionFlag;
- (void) toggleSpriteSpriteCollisionFlag;

@property BOOL spriteBackgroundCollisionFlag;
- (void) toggleSpriteBackgroundCollisionFlag;

@property uint16_t rasterline;
@property uint16_t rasterInterruptLine;
@property BOOL rasterInterruptFlag;
- (void) toggleRasterInterruptFlag;

@property BOOL hideSprites;
@property BOOL showIrqLines;
@property BOOL showDmaLines;

@end

// --------------------------------------------------------------------------
//                                     CIA
// --------------------------------------------------------------------------

@interface CIAProxy : NSObject {
    
	struct CiaWrapper *wrapper;
}

- (void) dump;
@property (setter=setTraceMode:) BOOL tracingEnabled;

@property uint8_t dataPortA;
@property uint8_t dataPortDirectionA;
@property uint16_t timerA;
@property uint16_t timerLatchA;
@property bool startFlagA;
- (void) toggleStartFlagA;
@property bool oneShotFlagA;
- (void) toggleOneShotFlagA;
@property bool underflowFlagA;
- (void) toggleUnderflowFlagA;
@property bool pendingSignalFlagA;
- (void) togglePendingSignalFlagA;
@property bool interruptEnableFlagA;
- (void) toggleInterruptEnableFlagA;

@property uint8_t dataPortB;
@property uint8_t dataPortDirectionB;
@property uint16_t timerB;
@property uint16_t timerLatchB;
@property bool startFlagB;
- (void) toggleStartFlagB;
@property bool oneShotFlagB;
- (void) toggleOneShotFlagB;
@property bool underflowFlagB;
- (void) toggleUnderflowFlagB;
@property bool pendingSignalFlagB;
- (void) togglePendingSignalFlagB;
@property bool interruptEnableFlagB;
- (void) toggleInterruptEnableFlagB;

@property uint8_t todHours;
@property uint8_t todMinutes;
@property uint8_t todSeconds;
@property uint8_t todTenth;

@property uint8_t alarmHours;
@property uint8_t alarmMinutes;
@property uint8_t alarmSeconds;
@property uint8_t alarmTenth;
@property (getter=isTodInterruptEnabled) BOOL todInterruptEnabled;

@end 

// --------------------------------------------------------------------------
//                                  Keyboard
// --------------------------------------------------------------------------

@interface KeyboardProxy : NSObject {
    
    struct KeyboardWrapper *wrapper;
}

- (void) dump;

@property (readonly) BOOL shiftKeyIsPressed;
@property (readonly) BOOL commodoreKeyIsPressed;
@property (readonly) BOOL ctrlKeyIsPressed;
@property (readonly) BOOL runstopKeyIsPressed;

- (void) pressKey:(C64KeyFingerprint)c;
- (void) pressShiftKey;
- (void) pressCommodoreKey;
- (void) pressCtrlKey;
- (void) pressRunstopKey;
- (void) pressShiftRunstopKey;
- (void) pressRestoreKey;

- (void) releaseKey:(C64KeyFingerprint)c;
- (void) releaseShiftKey;
- (void) releaseCommodoreKey;
- (void) releaseCtrlKey;
- (void) releaseRunstopKey;
- (void) releaseShiftRunstopKey;
- (void) releaseRestoreKey;

- (void) toggleShiftKey;
- (void) toggleCommodoreKey;
- (void) toggleCtrlKey;
- (void) toggleRunstopKey;

@end 

// --------------------------------------------------------------------------
//                                 Joystick
// -------------------------------------------------------------------------

@interface JoystickProxy : NSObject {
    
    struct JoystickWrapper *wrapper;
}

- (void) trigger:(JoystickEvent)event; 

// DEPRECATED
/*
- (void) setButton:(NSInteger)pressed;
- (void) pressButton;
- (void) releaseButton;
- (void) pullUp;
- (void) pullDown;
- (void) pullLeft;
- (void) pullRight;
- (void) releaseAxes;
- (void) setXAxis:(NSInteger)value;
- (void) setYAxis:(NSInteger)value;
- (void) releaseXAxis;
- (void) releaseYAxis;
*/

- (void) dump;

@end

// --------------------------------------------------------------------------
//                                    SID
// --------------------------------------------------------------------------

@interface SIDProxy : NSObject {
    
	struct SidWrapperWrapper *wrapper;
}

- (void) dump;
@property uint32_t sampleRate;
- (float) getSample;
- (void) readMonoSamples:(float *)target size:(NSInteger)n;
- (void) readStereoSamples:(float *)target1 buffer2:(float *)target2 size:(NSInteger)n;
- (void) readStereoSamplesInterleaved:(float *)target size:(NSInteger)n;

@end

// --------------------------------------------------------------------------
//                                   IEC bus
// -------------------------------------------------------------------------

@interface IECProxy : NSObject {

    struct IecWrapper *wrapper;
}

- (void) dump;
@property (setter=setTraceMode:) BOOL tracingEnabled;
@property (readonly, getter=isDriveConnected) BOOL driveConnected;
- (void) connectDrive;
- (void) disconnectDrive;

@end

// --------------------------------------------------------------------------
//                                 Expansion port
// -------------------------------------------------------------------------

@interface ExpansionPortProxy : NSObject {
    
    struct ExpansionPortWrapper *wrapper;
}

- (void) dump;
@property (readonly) BOOL cartridgeAttached;
@property (readonly) CartridgeType cartridgeType;
- (void) pressFirstButton;
- (void) pressSecondButton;

@end

// --------------------------------------------------------------------------
//                                      VIA
// -------------------------------------------------------------------------

@interface VIAProxy : NSObject {
    
	struct Via6522Wrapper *wrapper;
}

- (void) dump;
@property (setter=setTraceMode:) BOOL tracingEnabled;

@end

// --------------------------------------------------------------------------
//                                5,25" diskette
// -------------------------------------------------------------------------

@interface Disk525Proxy : NSObject {
    
    struct Disk525Wrapper *wrapper;
}

@property (getter=isWriteProtected) BOOL writeProtection;
@property (getter=isModified) BOOL modified;
@property (readonly) NSInteger numTracks;

@end

// --------------------------------------------------------------------------
//                                    VC1541
// -------------------------------------------------------------------------

@interface VC1541Proxy : NSObject {
    
	struct Vc1541Wrapper *wrapper;
    
    // sub proxys
	CPUProxy *cpu;
	MemoryProxy *mem;
	VIAProxy *via1;
	VIAProxy *via2;
    Disk525Proxy *disk;
}

@property (readonly) struct Vc1541Wrapper *wrapper;
@property (readonly) CPUProxy *cpu;
@property (readonly) MemoryProxy *mem;
@property (readonly) VIAProxy *via1;
@property (readonly) VIAProxy *via2;
@property (readonly) Disk525Proxy *disk;

- (VIAProxy *) via:(int)num;

- (void) dump;
@property (setter=setTraceMode:) BOOL tracingEnabled;
@property (readonly) BOOL hasRedLED;
@property (readonly) BOOL hasDisk;
- (void) ejectDisk;
@property BOOL writeProtection;
@property bool DiskModified;
@property bool bitAccuracy;
@property (readonly) BOOL soundMessagesEnabled;
- (void) setSendSoundMessages:(bool)b;
- (bool) exportToD64:(NSString *)path;

- (void) playSound:(NSString *)name volume:(float)v;

@end

// --------------------------------------------------------------------------
//                                  Datasette
// --------------------------------------------------------------------------

@interface DatasetteProxy : NSObject {
    
    struct DatasetteWrapper *wrapper;
}

- (void) dump;

@property (readonly) BOOL hasTape;
- (void) pressPlay;
- (void) pressStop;
- (void) rewind;
- (void) ejectTape;
@property (readonly, getter=getType) NSInteger type;
@property (readonly) long durationInCycles;
@property (readonly) int durationInSeconds;
@property (readonly) NSInteger head;
@property NSInteger headInCycles;
@property (readonly) int headInSeconds;
@property (readonly) BOOL motor;
@property (readonly) BOOL playKey;

@end


// -------------------------------------------------------------------------
//                                    C64
// -------------------------------------------------------------------------

@interface C64Proxy : NSObject {
    
	struct C64Wrapper *wrapper;
    
	// Sub component proxys
	CPUProxy *cpu;
	MemoryProxy *mem;
	VICProxy *vic;
	CIAProxy *cia1;
	CIAProxy *cia2;
	SIDProxy *sid;
	KeyboardProxy *keyboard;
    JoystickProxy *joystickA;
    JoystickProxy *joystickB;
	IECProxy *iec;
    ExpansionPortProxy *expansionport;
	VC1541Proxy *vc1541;
    DatasetteProxy *datasette;

	//! Indicates that data is transmitted on the IEC bus
	BOOL iecBusIsBusy;

    //! Indicates that data is transmitted on the datasette data line
    BOOL tapeBusIsBusy;

    //! Currently used color scheme
    long colorScheme;
}

// @property (strong,readonly) MyMetalView *metalScreen;
@property (readonly) CPUProxy *cpu;
@property (readonly) MemoryProxy *mem;
@property (readonly) VICProxy *vic;
@property (readonly) CIAProxy *cia1;
@property (readonly) CIAProxy *cia2;
@property (readonly) SIDProxy *sid;
@property (readonly) KeyboardProxy *keyboard;
@property (readonly) JoystickProxy *joystickA;
@property (readonly) JoystickProxy *joystickB;
@property (readonly) IECProxy *iec;
@property (readonly) ExpansionPortProxy *expansionport;
@property (readonly) VC1541Proxy *vc1541;
@property (readonly) DatasetteProxy *datasette;

@property BOOL iecBusIsBusy;
@property BOOL tapeBusIsBusy;

@property (readonly) struct C64Wrapper *wrapper;
- (void) kill;

// Hardware configuration
@property BOOL reSID;
@property BOOL audioFilter;
- (int) samplingMethod;
- (void) setSamplingMethod:(long)value;
- (int) chipModel;
- (void) setChipModel:(long)value;
- (void) rampUp;
- (void) rampUpFromZero;
- (void) rampDown;

// Loadind and saving
- (void)_loadFromSnapshotWrapper:(struct ContainerWrapper *) snapshot;
- (void)loadFromSnapshot:(SnapshotProxy *) snapshot;
- (void)_saveToSnapshotWrapper:(struct ContainerWrapper *) snapshot;
- (void)saveToSnapshot:(SnapshotProxy *) snapshot;

- (CIAProxy *) cia:(int)num;

- (void) dump;
- (BOOL) developmentMode;

- (VC64Message)message;
- (void) putMessage:(VC64Message)msg;
- (void) setListener:(const void *)sender function:(void(*)(const void *_Nullable, int))func;

- (void) powerUp;
- (void) ping;
- (void) halt;
- (void) step;
@property (readonly, getter=isRunnable) BOOL runnable;
- (void) run;
- (void) suspend;
- (void) resume; 
@property (readonly, getter=isHalted) BOOL halted;
@property (readonly, getter=isRunning) BOOL running;
@property (readonly, getter=isPAL) BOOL PAL;
@property (getter=isNTSC) BOOL NTSC;
- (void) setPAL;
- (void) setNTSC;

- (uint8_t) missingRoms; // DEPRECATED


- (bool) isBasicRom:(NSURL *)url;
- (bool) loadBasicRom:(NSURL *)url;
@property (readonly, getter=isBasicRomLoaded) BOOL basicRomLoaded;
- (bool) isCharRom:(NSURL *)url;
- (bool) loadCharRom:(NSURL *)url;
@property (readonly, getter=isCharRomLoaded) BOOL charRomLoaded;
- (bool) isKernelRom:(NSURL *)url;
- (bool) loadKernelRom:(NSURL *)url;
@property (readonly, getter=isKernelRomLoaded) BOOL kernelRomLoaded;
- (bool) isVC1541Rom:(NSURL *)url;
- (bool) loadVC1541Rom:(NSURL *)url;
@property (readonly, getter=isVC1541RomLoaded) BOOL VC1541RomLoaded;
- (bool) isRom:(NSURL *)url;
- (bool) loadRom:(NSURL *)url;

- (bool) attachCartridgeAndReset:(CRTProxy *)c;
- (void) detachCartridgeAndReset;
@property (readonly, getter=isCartridgeAttached) BOOL cartridgeAttached;

- (bool) insertDisk:(ArchiveProxy *)a;
- (bool) flushArchive:(ArchiveProxy *)a item:(NSInteger)nr;

- (bool) insertTape:(TAPProxy *)a;

@property (atomic) BOOL warp;
@property (atomic) BOOL alwaysWarp;
@property (atomic) BOOL warpLoad;
@property (readonly) UInt64 cycles;
@property (readonly) UInt64 frames;

// - (SnapshotProxy *) takeSnapshot;

// Cheatbox
@property (readonly) NSInteger historicSnapshots;
- (NSInteger) historicSnapshotHeaderSize:(NSInteger)nr;
- (uint8_t *) historicSnapshotHeader:(NSInteger)nr;
- (NSInteger) historicSnapshotDataSize:(NSInteger)nr;
- (uint8_t *) historicSnapshotData:(NSInteger)nr;

- (time_t)historicSnapshotTimestamp:(NSInteger)nr;
- (nullable unsigned char *)historicSnapshotImageData:(NSInteger)nr;
- (NSInteger)historicSnapshotImageWidth:(NSInteger)nr;
- (NSInteger)historicSnapshotImageHeight:(NSInteger)nr;

- (bool)restoreHistoricSnapshot:(NSInteger)nr;

// Audio hardware
- (BOOL) enableAudio;
- (void) disableAudio;

@end


// --------------------------------------------------------------------------
//               C O N T A I N E R   P R O X Y   C L A S S E S
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
//                              ContainerProxy
// --------------------------------------------------------------------------

@interface ContainerProxy : NSObject {
    
    struct ContainerWrapper *wrapper;
}

@property (readonly) struct ContainerWrapper *wrapper;

@property (readonly) ContainerType type;
@property (readonly) NSInteger sizeOnDisk;
- (void)readFromBuffer:(const void *)buffer length:(NSInteger)length;
- (NSInteger)writeToBuffer:(void *)buffer;
@end

// --------------------------------------------------------------------------
//                               SnapshotProxy
// --------------------------------------------------------------------------

@interface SnapshotProxy : ContainerProxy

+ (BOOL)isSnapshotFile:(NSString *)path;
+ (BOOL)isUsupportedSnapshotFile:(NSString *)path;
+ (nullable instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype)makeWithFile:(NSString *)path NS_SWIFT_NAME(init(file:));
+ (nullable instancetype)makeWithC64:(C64Proxy *)c64proxy NS_SWIFT_NAME(init(c64:));
@end

// --------------------------------------------------------------------------
//                                  CRTProxy
// --------------------------------------------------------------------------

@interface CRTProxy : ContainerProxy

+ (BOOL)isCRTFile:(NSString *)path;
+ (nullable instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype)makeWithFile:(NSString *)path NS_SWIFT_NAME(init(file:));

@property (readonly, copy) NSString *cartridgeName;
@property (readonly) CartridgeType cartridgeType;
@property (readonly, copy) NSString *cartridgeTypeName;
@property (readonly, getter=isSupported) BOOL supported;
@property (readonly) NSInteger exromLine;
@property (readonly) NSInteger gameLine;
@property (readonly) NSInteger chipCount;
- (NSInteger)typeOfChip:(NSInteger)nr;
- (NSInteger)loadAddrOfChip:(NSInteger)nr;
- (NSInteger)sizeOfChip:(NSInteger)nr;
@end

// --------------------------------------------------------------------------
//                                  TAPProxy
// --------------------------------------------------------------------------

@interface TAPProxy : ContainerProxy

+ (BOOL)isTAPFile:(NSString *)path;
+ (nullable instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype)makeWithFile:(NSString *)path NS_SWIFT_NAME(init(file:));

@property (readonly) NSInteger TAPversion;
@end

// --------------------------------------------------------------------------
//                                ArchiveProxy
// --------------------------------------------------------------------------

@interface ArchiveProxy : ContainerProxy

+ (instancetype)make;
+ (nullable instancetype)makeWithFile:(NSString *)path NS_SWIFT_NAME(init(file:));

@property (readonly) NSInteger numberOfItems;
- (NSString *)nameOfItem:(NSInteger)item;
- (NSString *)unicodeNameOfItem:(NSInteger)item maxChars:(NSInteger)max;
- (NSInteger)sizeOfItem:(NSInteger)item;
- (NSInteger)sizeOfItemInBlocks:(NSInteger)item;
- (NSString *)typeOfItem:(NSInteger)item;

// Think about a better API for accessing tracks and sectors directly
- (NSString *)byteStream:(NSInteger)n offset:(NSInteger)offset num:(NSInteger)num;
@end

@interface T64Proxy : ArchiveProxy

+ (BOOL)isT64File:(NSString *)filename;
+ (nullable instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype)makeWithFile:(NSString *)filename;
+ (nullable instancetype)makeWithAnyArchive:(ArchiveProxy *)otherArchive;
@end

@interface PRGProxy : ArchiveProxy

+ (BOOL)isPRGFile:(NSString *)filename;
+ (nullable instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype)makeWithFile:(NSString *)filename;
+ (nullable instancetype)makeWithAnyArchive:(ArchiveProxy *)otherArchive;
@end

@interface P00Proxy : ArchiveProxy

+ (BOOL)isP00File:(NSString *)filename;
+ (nullable instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype)makeWithFile:(NSString *)filename;
+ (nullable instancetype)makeWithAnyArchive:(ArchiveProxy *)otherArchive;
@end

@interface D64Proxy : ArchiveProxy

+ (BOOL)isD64File:(NSString *)filename;
+ (nullable instancetype)makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype)makeWithFile:(NSString *)filename NS_SWIFT_NAME(init(file:));
+ (nullable instancetype)makeWithAnyArchive:(ArchiveProxy *)otherArchive;
+ (nullable instancetype)makeWithVC1541:(VC1541Proxy *)vc1541;
@end

@interface G64Proxy : ArchiveProxy

+ (BOOL)isG64File:(NSString *)filename;
+ (nullable instancetype) makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype) makeWithFile:(NSString *)filename NS_SWIFT_NAME(init(file:));
@end

@interface NIBProxy : ArchiveProxy

+ (BOOL) isNIBFile:(NSString *)filename;
+ (nullable instancetype) makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype) makeWithFile:(NSString *)filename NS_SWIFT_NAME(init(file:));
@end

@interface FileProxy : ArchiveProxy

+ (nullable instancetype) makeWithBuffer:(const void *)buffer length:(NSInteger)length NS_SWIFT_NAME(init(buffer:length:));
+ (nullable instancetype) makeWithFile:(NSString *)filename NS_SWIFT_NAME(init(file:));
@end

NS_ASSUME_NONNULL_END
