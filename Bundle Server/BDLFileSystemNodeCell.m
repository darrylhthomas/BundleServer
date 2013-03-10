//
//  BDLFileSystemNodeCell.m
//  Bundle Server
//
//  Created by Darryl H. Thomas on 3/10/13.
//

#import "BDLFileSystemNodeCell.h"

#define ICON_SIZE 16.0f
#define ICON_HORIZONTAL_INSET 4.0f
#define ICON_VERTICAL_INSET 2.0f
#define ICON_TEXT_SPACING 2.0f

@implementation BDLFileSystemNodeCell

- (id)init
{
    self = [super init];
    if (self) {
        [self setLineBreakMode:NSLineBreakByTruncatingTail];
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    BDLFileSystemNodeCell *result = [super copyWithZone:zone];
    result->_image = nil;
    result.image = self.image;
    
    return result;
}

- (NSRect)imageRectForBounds:(NSRect)theRect
{
    theRect.origin.x += ICON_HORIZONTAL_INSET;
    theRect.size.width = ICON_SIZE;
    theRect.origin.y += truncf((theRect.size.height - ICON_SIZE) / 2.0f);
    theRect.size.height = ICON_SIZE;
    
    return theRect;
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
    CGFloat inset = (ICON_HORIZONTAL_INSET + ICON_SIZE + ICON_TEXT_SPACING);
    theRect.origin.x += inset;
    theRect.size.width -= inset;
    
    return [super titleRectForBounds:theRect];
}

- (NSSize)cellSizeForBounds:(NSRect)aRect
{
    NSSize result = [super cellSizeForBounds:aRect];
    result.width += (ICON_HORIZONTAL_INSET + ICON_SIZE + ICON_TEXT_SPACING);
    result.height = (ICON_VERTICAL_INSET + ICON_SIZE + ICON_VERTICAL_INSET);
    
    return result;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect imageFrame = [self imageRectForBounds:cellFrame];
    NSImage *image = self.image;
    if (image) {
        BOOL flipped = [controlView isFlipped] != [image isFlipped];
        if (flipped) {
            [[NSGraphicsContext currentContext] saveGraphicsState];
            NSAffineTransform *transform = [[NSAffineTransform alloc] init];
            [transform translateXBy:0.0f yBy:cellFrame.origin.y + cellFrame.size.height];
            [transform scaleXBy:1.0f yBy:-1.0f];
            [transform translateXBy:0.0f yBy:-cellFrame.origin.y];
            [transform concat];
        }
        
        [image drawInRect:imageFrame fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
        
        if (flipped) {
            [[NSGraphicsContext currentContext] restoreGraphicsState];
        }
    }
    
    CGFloat inset = (ICON_HORIZONTAL_INSET + ICON_SIZE + ICON_TEXT_SPACING);
    cellFrame.origin.x += inset;
    cellFrame.size.width -= inset;
    cellFrame.origin.y += 1.0f;
    cellFrame.size.height -= 1.0f;
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawWithExpansionFrame:(NSRect)cellFrame inView:(NSView *)view
{
    [super drawInteriorWithFrame:cellFrame inView:view];
}

@end
