//
//  DSLayerView.h
//  DSCore
//
//  Created by Andrew on 12/30/15.
//  Copyright © 2015 Digital Scenographic. All rights reserved.
//

@class DSLayer;
@class SyphonServer;

@interface DSLayerView : NSView{
    CALayer *baseLayer;
    NSPoint centeredPosition;
    NSMutableArray* filterArray;
}
@property NSWindow* myWindow;
@property NSColor *backgroundColor;
@property float overlayAlpha;
@property float shiftX;
@property float shiftY;
@property float scaleZ;
@property float rotation;
@property (readonly) BOOL isFullscreen;
@property (readonly) NSMutableArray *layers;
@property BOOL enableLayerTransformWithTouchpad;
@property NSString* syphonOutputName;
@property NSSize syphonOutputResolution;


-(NSMutableArray*)filterArray;
-(void)setFilterArray:(NSMutableArray *)filterArray;
-(void)addFilter:(CIFilter*)filter;
-(void)removeFilter:(CIFilter*)filter;
-(void)removeAllFilters;

-(void)toggleFullscreen;
-(void)removeAllLayers;
-(DSLayer*)addEmptyLayer;
-(DSLayer*)replaceLayerwithPlaceholder:(int)layerIndex;

-(DSLayer*)addSyphonLayer:(NSString*)syphonName withAlpha:(float)alpha;
-(DSLayer*)addSyphonLayer:(NSString*)syphonName;
-(DSLayer*)replaceLayer:(int)layerIndex withSyphonLayer:(NSString*)syphonName;

-(DSLayer*)addImageLayer:(NSString*)path;
-(DSLayer*)addImageLayer:(NSString*)path withAlpha:(float)alpha;
-(DSLayer*)replaceLayer:(int)layerIndex withImageLayer:(NSString*)path;

-(DSLayer*)addVideoLayer:(NSString*)path;
-(DSLayer*)addVideoLayer:(NSString *)path withAlpha:(float)alpha;
-(DSLayer*)addVideoLayer:(NSString *)path withAlpha:(float)alpha loop:(BOOL)shouldLoop;
-(DSLayer*)replaceLayer:(int)layerIndex withVideoLayer:(NSString*)path;
-(float)alphaForLayer:(long)layerIndex;
-(void)setAlpha:(float)alpha forLayer:(long)layerIndex;



@end
