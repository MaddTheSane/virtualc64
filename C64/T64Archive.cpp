/*
 * (C) 2007 Dirk W. Hoffmann. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, org
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

#include "T64Archive.h"

/* "Anmerkung: Der String muß nicht wortwörtlich so vorhanden sein. Man sollte nach den
 *  Substrings"C64" und "tape" suchen. Vorsicht: TAP Images verwenden den String: C64-TAPE-RAW
 *  der ebenfalls die Substrings "C64" und "TAPE" enthält." [Power64 doc]
 *  TODO: Make sure that the archive is not a TAP file.
 */
const uint8_t T64Archive::magicBytes[] = { 0x43, 0x36, 0x34, 0x00 };

T64Archive::T64Archive()
{
    setDescription("T64Archive");
	data = NULL;
	dealloc();
}

T64Archive *
T64Archive::makeT64ArchiveWithBuffer(const uint8_t *buffer, size_t length)
{
    T64Archive *archive = new T64Archive();
    
    if (!archive->readFromBuffer(buffer, length)) {
        delete archive;
        return NULL;
    }
    
    return archive;
}

T64Archive *
T64Archive::makeT64ArchiveWithFile(const char *path)
{
    T64Archive *archive = new T64Archive();
    
    if (!archive->readFromFile(path)) {
        delete archive;
        return NULL;
    }
    
    return archive;
}

T64Archive *
T64Archive::makeT64ArchiveWithAnyArchive(Archive *otherArchive)
{
    if (otherArchive == NULL)
        return NULL;
    
    T64Archive *archive  = new T64Archive();
    
    // Determine container size and allocate memory
    unsigned currentFiles = otherArchive->getNumberOfItems();
    unsigned maxFiles = (currentFiles < 30) ? 30 : currentFiles;
    archive->size = 64 /* header */ + maxFiles * 32 /* tape entries */;
    
    for (unsigned i = 0; i < otherArchive->getNumberOfItems(); i++)
        archive->size += otherArchive->getSizeOfItem(i);
    
    if ((archive->data = (uint8_t *)malloc(archive->size)) == NULL) {
        archive->warn("Failed to allocate %d bytes of memory\n", archive->size);
        delete archive;
        return NULL;
    }
    
    // Magic bytes (32 bytes)
    uint8_t *ptr = archive->data;
    strncpy((char *)ptr, "C64 tape image file", 32);
    ptr += 32;
    
    // Version (2 bytes)
    *ptr++ = 0x00;
    *ptr++ = 0x01;
    
    // Max files (2 bytes)
    *ptr++ = LO_BYTE(maxFiles);
    *ptr++ = HI_BYTE(maxFiles);
    
    // Current files (2 bytes)
    *ptr++ = LO_BYTE(currentFiles);
    *ptr++ = HI_BYTE(currentFiles);
    
    // Reserved (2 bytes)
    *ptr++ = 0x00;
    *ptr++ = 0x00;
    
    // User description (24 bytes)
    strncpy((char *)ptr, (char *)otherArchive->getName(), 24);
    for (unsigned i = 0; i < 24; i++, ptr++)
        *ptr = ascii2pet(*ptr);
    
    // Tape entries
    uint32_t tapePosition = 64 + maxFiles * 32; // data of item 0 starts here
    memset(ptr, 0, 32 * maxFiles);
    for (unsigned n = 0; n < maxFiles; n++) {
        
        if (n >= currentFiles) {
            // Empty tape slot
            ptr += 32;
            continue;
        }
        
        // Entry used (1 byte)
        *ptr++ = 0x01;
        
        // File type (1 byte)
        *ptr++ = 0x82;
        
        // Start address (2 bytes)
        uint16_t startAddr = otherArchive->getDestinationAddrOfItem(n);
        *ptr++ = LO_BYTE(startAddr);
        *ptr++ = HI_BYTE(startAddr);
        
        // Start address (2 bytes)
        uint16_t endAddr = startAddr + otherArchive->getSizeOfItem(n);
        *ptr++ = LO_BYTE(endAddr);
        *ptr++ = HI_BYTE(endAddr);
        
        // Reserved (2 bytes)
        ptr += 2;
        
        // Tape position (4 bytes)
        *ptr++ = LO_BYTE(tapePosition);
        *ptr++ = LO_BYTE(tapePosition >> 8);
        *ptr++ = LO_BYTE(tapePosition >> 16);
        *ptr++ = LO_BYTE(tapePosition >> 24);
        tapePosition += otherArchive->getSizeOfItem(n);
        
        // Reserved (4 bytes)
        ptr += 4;
        
        // File name (16 bytes)
        strncpy((char *)ptr, (char *)otherArchive->getNameOfItem(n), 16);
        for (unsigned i = 0; i < 16; i++, ptr++)
            *ptr = ascii2pet(*ptr);
    }
    
    // File data
    for (unsigned n = 0; n < currentFiles; n++) {
        
        int byte;
        otherArchive->selectItem(n);
        while ((byte = otherArchive->getByte()) != EOF) {
            *ptr++ = (uint8_t)byte;
        }
        
    }
    
    otherArchive->dumpDirectory();
    archive->dumpDirectory();
    archive->debug(1, "T64 archive created with other archive of type %s.\n",
                   otherArchive->typeAsString());
    
    return archive;
}

void T64Archive::dealloc()
{
    if (data) free(data);
    data = NULL;
    size = 0;
    fp = -1;
    fp_eof = -1;
}

T64Archive::~T64Archive()
{
	dealloc();
}

bool
T64Archive::isT64Buffer(const uint8_t *buffer, size_t length)
{
    if (length < 0x40) return false;
    return checkBufferHeader(buffer, length, magicBytes);
}

bool 
T64Archive::isT64File(const char *path)
{	
	assert(path != NULL);
	
	if (!checkFileSuffix(path, ".T64") && !checkFileSuffix(path, ".t64"))
		return false;
	
	if (!checkFileSize(path, 0x40, -1))
		return false;
	
    if (!checkFileHeader(path, magicBytes))
		return false;
	
	return true;
}

bool 
T64Archive::readFromBuffer(const uint8_t *buffer, size_t length)
{
    assert(buffer != NULL);
    
	if ((data = (uint8_t *)malloc(length)) == NULL)
		return false;

	memcpy(data, buffer, length);
	size = length;

    // Some T64 archives contain incosistencies. We fix them asap
    (void)repair();
    
	return true;
}

size_t
T64Archive::writeToBuffer(uint8_t *buffer)
{
    assert(data != NULL);
    
    if (buffer) {
        memcpy(buffer, data, size);
    }
    return size;
}


const char *
T64Archive::getName()
{
	int i,j;
	int first = 0x28;
	int last  = 0x40;
	
	for (j = 0, i = first; i < last; i++, j++) {
		name[j] = (data[i] == 0x20 ? ' ' : data[i]);
		if (j == 255) break; 
	}
	name[j] = 0x00;
	return name;
}

const unsigned short *
T64Archive::getUnicodeName(size_t maxChars)
{
    (void)getName();
    translateToUnicode(name, unicode, 0xE000, maxChars);
    return unicode;
}

int 
T64Archive::getNumberOfItems()
{
    return LO_HI(data[0x24], data[0x25]);
}

const char *
T64Archive::getNameOfItem(int n)
{
	int i,j;
	int first = 0x50 + (n * 0x20);
	int last  = 0x60 + (n * 0x20);
	
	if (size < last) {
		name[0] = 0;
	} else {
		for (j = 0, i = first; i < last; i++, j++) {
			name[j] = (data[i] == 0x20 ? ' ' : data[i]);
			if (j == 255) break;
		}
		name[j] = 0x00;
	}
	return name;
}

const unsigned short *
T64Archive::getUnicodeNameOfItem(int n, size_t maxChars)
{
    (void)getNameOfItem(n);
    translateToUnicode(name, unicode, 0xE000, maxChars);
    return unicode;
}

const char *
T64Archive::getTypeOfItem(int n)
{
	int i = 0x41 + (n * 0x20);
	if (data[i] != 00)
		return "PRG";
	if (data[i] == 00 && data[i-1] > 0x00)
		return "FRZ";
	return "???";
}

uint16_t 
T64Archive::getDestinationAddrOfItem(int n)
{
	int i = 0x42 + (n * 0x20);
	uint16_t result = LO_HI(data[i], data[i+1]);
	return result;
}

void 
T64Archive::selectItem(int n)
{
    if (n < getNumberOfItems()) {

        // Compute start address in container
        unsigned i = 0x48 + (n * 0x20);
        fp = LO_LO_HI_HI(data[i], data[i+1], data[i+2], data[i+3]);

        // Compute start address in memory
        i = 0x42 + (n * 0x20);
        uint16_t startAddrInMemory = LO_HI(data[i], data[i+1]);
        
        // Compute end address in memory
        i = 0x44 + (n * 0x20);
        uint16_t endAddrInMemory = LO_HI(data[i], data[i+1]);

        // Compute size of item
        uint16_t length = endAddrInMemory - startAddrInMemory;

        // Compute end address in container
        fp_eof = fp + length;

        // Return if offset values are safe
        if (fp < size && fp_eof <= size)
            return;
    
        assert(0); // As repair() should have ruled out all inconsistencies, we should never be here!
    }

    fp = fp_eof = -1;
	return;
}

int 
T64Archive::getByte()
{
	int result;
	
	if (fp < 0)
		return -1;
		
	// get byte
	result = data[fp++];
	
	// check for end of file
	if (fp == fp_eof || fp == size)
		fp = -1;

    if (tracingEnabled())
        msg("%02X%c", result, fp == -1 ? '\n' : ' ');
    
	return result;
}

bool
T64Archive::directoryItemIsPresent(int n)
{
    int first = 0x40 + (n * 0x20);
    int last  = 0x60 + (n * 0x20);
    int i;
    
    // check for zeros...
    if (last < size)
        for (i = first; i < last; i++)
            if (data[i] != 0)
                return true;
    
    return false;
}

bool
T64Archive::repair()
{
    unsigned i, n;
    uint16_t noOfItems = getNumberOfItems();

    //
    // 1. Repair number of items, if this value is zero
    //
    
    if (noOfItems == 0) {

        while (directoryItemIsPresent(noOfItems))
            noOfItems++;

        uint16_t noOfItemsStatedInHeader = getNumberOfItems();
        if (noOfItems != noOfItemsStatedInHeader) {
        
            debug(1, "Repairing corrupted T64 archive: Changing number of items from %d to %d.\n",
                  noOfItemsStatedInHeader, noOfItems);
        
            data[0x24] = LO_BYTE(noOfItems);
            data[0x25] = HI_BYTE(noOfItems);
            assert(noOfItems == getNumberOfItems());
        }
    }
    
    for (i = 0; i < getNumberOfItems(); i++) {

        //
        // 2. Check relative offset information for each item
        //

        // Compute start address in container
        n = 0x48 + (i * 0x20);
        uint16_t startAddrInContainer = LO_LO_HI_HI(data[n], data[n+1], data[n+2], data[n+3]);

        if (startAddrInContainer >= size) {
            warn("T64 archive is corrupt (offset mismatch). Sorry, can't repair.\n");
            return false;
        }
    
        //
        // 3. Check for file end address mismatches (as created by CONVC64)
        //
        
        // Compute start address in memory
        n = 0x42 + (i * 0x20);
        uint16_t startAddrInMemory = LO_HI(data[n], data[n+1]);
    
        // Compute end address in memory
        n = 0x44 + (i * 0x20);
        uint16_t endAddrInMemory = LO_HI(data[n], data[n+1]);
    
        if (endAddrInMemory == 0xC3C6) {

            // Let's assume that the rest of the file data belongs to this file ...
            uint16_t fixedEndAddrInMemory = startAddrInMemory + (size - startAddrInContainer);

            debug(1, "Repairing corrupted T64 archive: Changing end address of item %d from %04X to %04X.\n",
                  i, endAddrInMemory, fixedEndAddrInMemory);

            data[n] = LO_BYTE(fixedEndAddrInMemory);
            data[n+1] = HI_BYTE(fixedEndAddrInMemory);
        }
    }
    
    return 1; // Archive repaired successfully
}
