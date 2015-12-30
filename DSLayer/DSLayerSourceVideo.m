//
//  LayerSourceVideo.m
//  Confess
//
//  Created by Andrew on 11/21/15.
//  Copyright © 2015 Digital Scenographic. All rights reserved.
//

#import "DSLayerSourceVideo.h"
#import <AVFoundation/AVFoundation.h>
#import <DSCommon/NSImage+util.h>
@implementation DSLayerSourceVideo

- (id)initWithPath:(NSString*)path{
    if (self = [super init]){
        
        _loop = NO;
        
        // Does file exist?
        if([[NSFileManager defaultManager] fileExistsAtPath:path  isDirectory:NO]){
            
            
            // If user provided a name use it, otherwise extrapolate from path
            [self setName:[[path lastPathComponent] stringByDeletingPathExtension]];
            [self setPath:path];
            
            // Convert string to URL
            NSString *urlAsString=[NSString stringWithFormat:@"file://%@",path];
            NSString* urlTextEscaped = [urlAsString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            NSURL *url = [NSURL URLWithString: urlTextEscaped];
            
            // Create Video player
            NSDictionary* settings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] };
            player = [[AVPlayer alloc] init];
            player.actionAtItemEnd=AVPlayerActionAtItemEndNone;
            playerOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:settings];
            playerItem = [AVPlayerItem playerItemWithURL:url];
            
            
            // Register for end of video notification
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(playerItemDidReachEnd:)
                                                         name:AVPlayerItemDidPlayToEndTimeNotification
                                                       object:[player currentItem]];
            
            // Problem loading video
            if(!playerItem){
                NSLog(@"INTERNAL ERROR: Cannot load video from %@",url);
                [self setWarning:YES];
                
            // Video is fine, set up some stuff
            }else{
                [playerItem addOutput:playerOutput];
                if(playerItem){[player replaceCurrentItemWithPlayerItem:playerItem];}
                // Start video and unpause
                // FIXME: Should be moved to layer so we only play videos as needed
                [[player currentItem] seekToTime:kCMTimeZero];
                [player setRate:([player rate] == 0.0f ? 1.0f : 0.0f)];
                
                [player setVolume:0];
                
                // Make a screengrab
                asset = [AVAsset assetWithURL:url];
                AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]initWithAsset:asset];
                CMTime time = CMTimeMake(1, 1);
                CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
                [self setStillFrame:[[NSImage alloc] initWithCGImage:imageRef size:NSMakeSize(640, 480)]];
                CGImageRelease(imageRef);
                [self setWarning:NO];
                [player play];
            }
            
            
        // File does not exist (can happen on reload from disk)
        }else{
            [self setWarning:YES];

        }
        

    
    }
    return self;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    if(_loop){
        AVPlayerItem *p = [notification object];
        [p seekToTime:kCMTimeZero];
    }
}

-(GLuint) glTextureForContext:(NSOpenGLContext*)context
                       atTime:(const CVTimeStamp *)cvOutputTime{
    if(playerItem && !textureDefined){
        
        CGLLockContext([context CGLContextObj]);
        [context makeCurrentContext];
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glGenTextures(1, &glTexture);
        CGLUnlockContext([context CGLContextObj]);
        
        textureDefined=YES;
        
        
        CVOpenGLTextureCacheCreate(NULL, 0,
                                   CGLGetCurrentContext(),
                                   CGLGetPixelFormat(CGLGetCurrentContext()),
                                   0,
                                   &textureCache);

    }
    
    [self setGlContext:context];
    
    
    // Grab a framebuffer and make a texture from the framebuffer
    // For videos in particular, we update the gltextures on the *source*
    // This doesn't happen every call, and we might have >1 layer with the same video on it
    
    CMTime playerTime = [playerOutput itemTimeForCVTimeStamp:*cvOutputTime];
    
    //NSLog(@"%f",CMTimeGetSeconds(playerTime));
    //[thisLayer.layerSource.videoPlayer setRate:1.0];
    
    if ([playerOutput hasNewPixelBufferForItemTime:playerTime]){
        
        frameBuffer= [playerOutput copyPixelBufferForItemTime:playerTime itemTimeForDisplay:NULL];
        CVReturn result= CVOpenGLTextureCacheCreateTextureFromImage(NULL,
                                                                    textureCache,
                                                                    frameBuffer,
                                                                    NULL,
                                                                    &textureRef);
        if(result == kCVReturnSuccess){
            // These appear to be GL_TEXTURE_RECTANGLE_ARB
            glTextureTarget=CVOpenGLTextureGetTarget(textureRef);
            glTexture=CVOpenGLTextureGetName(textureRef);
            glTextureSize=NSMakeSize(CVPixelBufferGetWidth(frameBuffer), CVPixelBufferGetHeight(frameBuffer));
            vid_ciimage=[CIImage imageWithCVImageBuffer:frameBuffer];
            
            CFRelease(textureRef);
            CVOpenGLTextureCacheFlush(textureCache, 0);
        }else{
            NSLog(@"INTERNAL ERROR FAILED WITH CODE: %i",result);
        }
        CVBufferRelease(frameBuffer);
        
    }
    glTextureTarget=GL_TEXTURE_RECTANGLE_ARB;
    return glTexture;
}
-(GLuint) glTextureTarget{return GL_TEXTURE_2D;}
-(NSSize) glTextureSize{return glTextureSize;}
-(NSSize) size{return glTextureSize;}

-(NSImage*)frameAsNSImage{
    return [NSImage imageWithGLTexture:glTexture
                                            textureType:GL_TEXTURE_2D//glTextureTarget
                                            textureSize:glTextureSize
                                                context:_glContext
                                                flipped:NO];
}



@end
