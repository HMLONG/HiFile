//
//  WDMessage.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-6.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Foundation/Foundation.h>

// DW: states actually
#define kWDMessageStateText             @"kWDMessageStateText"

// DW: files are more complicated, "File" is a well transfered file
#define kWDMessageStateFile             @"kWDMessageStateFile"
#define kWDMessageStateReadyToSend      @"kWDMessageStateReadyToSend"
#define kWDMessageStateReadyToReceive   @"kWDMessageStateReadyToReceive"
#define kWDMessageStateSending          @"kWDMessageStateSending"
#define kWDMessageStateReceiving        @"kWDMessageStateReceiving"

@class FLDirectory;

@interface WDMessage : NSObject <NSCoding,NSCopying> {
    NSString *_sender;
    NSDate *_time;
    NSString *_state;   // DW: state is used in file transfer
    NSURL *_fileURL;    // DW: available only in file type
    NSData *_content;
    
    FLDirectory* _fldItem;
    bool _isFLDirectory;
}

@property (nonatomic, retain) NSString *sender;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSURL *fileURL;
@property (nonatomic, retain) NSData *content;

@property (nonatomic, retain) FLDirectory* fldItem;
@property (nonatomic) bool isFLDirectory;

+ (BOOL)isImageURL:(NSURL *)url;
+ (id)messageWithText:(NSString *)text;
+ (id)messageWithFile:(NSURL *)url andState:(NSString *)state;
+ (id)messageWithFile:(NSURL *)url andState:(NSString *)state andFLDItem:(FLDirectory*) item isFLDrectoryType:(bool)judge;

- (NSString*)getFileURLofNStringPointerFormat;
- (NSString*)getFileExtension;
- (FLDirectory*)getFLDItem;
- (bool)isFLDirectoryType;
- (NSUInteger)fileSize;
- (void)setFileSize:(NSUInteger)fileSize;

@end
