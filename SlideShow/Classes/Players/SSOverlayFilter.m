//
//  SSOverlayFilter.m
//  SlideShow
//
//  Created by Arda Ozupek on 9.04.2019.
//  Copyright © 2019 Arda Ozupek. All rights reserved.
//

#import "SSOverlayFilter.h"

NSString *const kSSOverlayFilterFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate);
     
     float mixturePercent = 1.0;
     
     lowp float alphaDivisor = textureColor2.a + step(textureColor2.a, 0.0); // Protect against a divide-by-zero blacking out things in the output
     gl_FragColor = vec4(mix(textureColor.rgb, textureColor2.rgb / alphaDivisor, mixturePercent * textureColor2.a), textureColor.a);
     
     //gl_FragColor = vec4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * mixturePercent), textureColor.a);
 }
 );

@implementation SSOverlayFilter

-(id)init {
    if (!(self = [super initWithFragmentShaderFromString:kSSOverlayFilterFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

@end
