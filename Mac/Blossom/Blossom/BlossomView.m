//
//  BlossomView.m
//  Blossom
//
//  Created by Sergio Larrodera on 19/11/2018.
//

#import "BlossomView.h"

@implementation BlossomView

static int cellSize = 1;
static int framerate = 30.0;
static float uniformity = 0;
static float growth = 0.5f;

static double colorVariation;
static double prob1Base;
static double prob2Base;

int width; // Width of the screen
int height; // Height of the screen
long generation; // Current generation (iteration)
NSMutableArray *cells; // Cell matrix
NSMutableArray *newCells1; // List of new cells of type 1 (visible)
NSMutableArray *newCells2; // List of new cells of type 2 (invisible)
NSMutableSet *currentBorder; // List of positions where cells can spawn
NSMutableSet *nextBorder; // List of spawn positions for the next generation

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1/framerate];
    }
    
    NSSize size = [self bounds].size;
    width = size.width / cellSize;
    height = size.height / cellSize;
    
    prob1Base = (0.35 + 0.15 * uniformity) * growth;
    prob2Base = (1 - prob1Base / growth) * growth;
    colorVariation = 360.0 * exp(prob1Base) / MIN(height, width);
    
    return self;
}

- (void)startAnimation
{
    [super startAnimation];
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    
    [self initialize];
}

- (void)initialize
{
    cells = [[NSMutableArray alloc] initWithCapacity:width];
    for (int i = 0; i < width; i++) {
        cells[i] = [[NSMutableArray alloc] initWithCapacity:height];
        for (int j = 0; j < height; j++) {
            cells[i][j] = @(0);
        }
    }
    
    newCells1 = [[NSMutableArray alloc] initWithCapacity:0];
    newCells2 = [[NSMutableArray alloc] initWithCapacity:0];
    nextBorder = [[NSMutableSet alloc] initWithCapacity:0];
    generation = 0;
    
    // Spanws the initial cell
    cells[width / 2][height / 2] = @(1);
    
    [self clearScreen];
    [self drawCellWithX: width / 2 withY: height / 2];
    [self expandCellWithX: width / 2 withY: height / 2];
}

- (void)animateOneFrame
{
    currentBorder = nextBorder; // Updates the border
    
    if ([currentBorder count] == 0) {
        [self initialize];
    }
    else {
        
        generation++;
        nextBorder = [[NSMutableSet alloc] initWithCapacity:0];
        
        // Cell spwaning
        for (NSArray *cell in currentBorder) {
            
            int i = (int)cell[0];
            int j = (int)cell[1];
            
            int numNei1 = [self neighborsWithX: i withY: j withRadius: 1 withType: 1];
            int numNei2 = [self neighborsWithX: i withY: j withRadius: 1 withType: 2];
            
            double prob1 = (1 + numNei1) * prob1Base;
            double prob2 = (1 + numNei2) * prob2Base;
            
            double p = SSRandomFloatBetween(0, 1);
            
            // Spawns a visible cell
            if (p < prob1) {
                [newCells1 addObject: @[@(i), @(j)]];
                [self drawCellWithX: i withY: j];
            }
            // Spawns an invisible cell
            else if (p < prob1 + prob2) {
                [newCells2 addObject: @[@(i), @(j)]];
            }
            // Waits for the next generation
            else {
                [nextBorder addObject: @[@(i), @(j)]];
            }
        }
        
        // Cell matrix update and cell expansion
        for (int i = 0; i < [newCells1 count]; i++) {
            cells[(int)newCells1[i][0]][(int)newCells1[i][1]] = @(1);
        }
        
        while ([newCells2 count] > 0) {
            cells[(int)newCells2[0][0]][(int)newCells2[0][1]] = @(2);
            [newCells2 removeObjectAtIndex: 0];
        }
        
        while ([newCells1 count] > 0) {
            [self expandCellWithX: (int)newCells1[0][0] withY: (int)newCells1[0][1]];
            [newCells1 removeObjectAtIndex: 0];
        }
    }
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

- (void)drawCellWithX: (int)x withY: (int)y
{
    NSRect rect;
    rect.size = NSMakeSize(cellSize, cellSize);
    rect.origin = NSMakePoint(x * cellSize, y * cellSize);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    NSColor *color = [NSColor colorWithHue: ((int)(generation * colorVariation) % 360) / 360.0 saturation:1 brightness:0.5 alpha:1];
    [color set];
    [path fill];
}

- (void)clearScreen
{
    NSRect rect;
    rect.size = NSMakeSize(width, height);
    rect.origin = NSMakePoint(0, 0);
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    NSColor *color = [NSColor colorWithHue: 0 saturation:0 brightness:0 alpha:255];
    [color set];
    [path fill];
}

- (void)expandCellWithX: (int)x withY: (int)y
{
    for (int i = MAX(x - 1, 0); i < MIN(x + 2, width); i++) {
        for (int j = MAX(y - 1, 0); j < MIN(y + 2, height); j++) {
            if (i != x || j != y) {
                if ((int)cells[i][j] == 0) {
                    [nextBorder addObject: @[@(x), @(y)]];
                }
            }
        }
    }
}

- (int)neighborsWithX: (int)x withY: (int)y withRadius: (int)radius withType: (int)type
{
    int num = 0;
    
    for (int i = MAX(x - radius, 0); i < MIN(x + radius + 1, width); i++) {
        for (int j = MAX(y - radius, 0); j < MIN(y + radius + 1, height); j++) {
            if (i != x || j != y) {
                if ((int)cells[i][j] == type) {
                    num++;
                }
            }
        }
    }
    
    return num;
}

@end
