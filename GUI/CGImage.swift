// -----------------------------------------------------------------------------
// This file is part of VirtualC64
//
// Copyright (C) Dirk W. Hoffmann. www.dirkwhoffmann.de
// Licensed under the GNU General Public License v3
//
// See https://www.gnu.org for license information
// -----------------------------------------------------------------------------

public extension CGImage {
    
    private static func bitmapInfo() -> CGBitmapInfo {
        
        let noAlpha = CGImageAlphaInfo.noneSkipLast.rawValue
        let bigEn32 = CGBitmapInfo.byteOrder32Big.rawValue
    
        return CGBitmapInfo(rawValue: noAlpha | bigEn32)
    }
    
    /// Creates a CGImage from a Swift `Data` struct in 32 bit big endian format
    static func make(with data: Data, size: CGSize) -> CGImage? {
        
        let w = Int(size.width)
        let h = Int(size.height)
        
        return CGImage(width: w, height: h,
                       bitsPerComponent: 8,
                       bitsPerPixel: 32,
                       bytesPerRow: 4 * w,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: bitmapInfo(),
                       provider: CGDataProvider(data: data as NSData)!,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: CGColorRenderingIntent.defaultIntent)
    }
    
    // Creates a CGImage from a MTLTexture
    static func make(texture: MTLTexture, rect: CGRect) -> CGImage? {
        
        // Compute texture cutout
        //   (x,y) : upper left corner
        //   (w,h) : width and height
        let x = Int(CGFloat(texture.width) * rect.minX)
        let y = Int(CGFloat(texture.height) * rect.minY)
        let w = Int(CGFloat(texture.width) * rect.width)
        let h = Int(CGFloat(texture.height) * rect.height)
        
        // Get texture data as a byte stream
        var data = Data(count: 4 * w * h)
        data.withUnsafeMutableBytes { umrbp in
            
            texture.getBytes(umrbp.baseAddress!,
                             bytesPerRow: 4 * w,
                             from: MTLRegionMake2D(x, y, w, h),
                             mipmapLevel: 0)
        }
        
        return make(with: data, size: CGSize(width: w, height: h))
    }
}
