//
//  KIQiniuManager.h
//  Kitalker
//
//  Created by apple on 15/4/23.
//
//

#import <Foundation/Foundation.h>
#import "QiniuSDK.h"
//pod "KIAdditions/NSString", :git=> "https://github.com/smartwalle/KIAdditions.git"
#import "NSString+KIAdditions.h"

#define KIQiniuFileURLString(fileKey) [KIQiniuManager fileURLString:fileKey]

@interface KIQiniuManager : NSObject

+ (QNUploadManager *)uploadManager;

+ (void)setAccessKey:(NSString *)key;

+ (void)setSecretKey:(NSString *)key;

/*设置默认上传空间*/
+ (void)setScope:(NSString *)scope;

/*设置空间权限*/
+ (void)setPrivateScope:(BOOL)value;

/*设置默认域名，用于文件下载*/
+ (void)setDomain:(NSString *)domain;

/*生成上传Token*/

+ (NSString *)tokenWithAccessKey:(NSString *)accessKey
                       secretKey:(NSString *)secretKey
                           scope:(NSString *)scope
                        deadline:(NSTimeInterval)deadline
                          policy:(NSDictionary *)policy;

+ (NSString *)tokenWithPolicy:(NSDictionary *)policy;

+ (NSString *)tokenWithScope:(NSString *)scope deadline:(NSTimeInterval)deadline;

+ (NSString *)tokenWithScope:(NSString *)scope;

+ (NSString *)token;

/*下载*/
+ (NSString *)fileURLString:(NSString *)filePath
                     domain:(NSString *)domain
                  accessKey:(NSString *)accessKey
                  secretKey:(NSString *)secretKey
               privateScope:(BOOL)privateScope
                   deadline:(NSTimeInterval)deadline;

+ (NSString *)fileURLString:(NSString *)filePath domain:(NSString *)domain deadline:(NSTimeInterval)deadline;

+ (NSString *)fileURLString:(NSString *)filePath domain:(NSString *)domain;

+ (NSString *)fileURLString:(NSString *)filePath;

/**
 *    直接上传数据
 *
 *    @param data              待上传的数据
 *    @param key               上传到云存储的key，为nil时表示是由七牛生成
 *    @param token             上传需要的token, 由服务器生成
 *    @param completionHandler 上传完成后的回调函数
 *    @param option            上传时传入的可选参数
 */
+ (void)putData:(NSData *)data
            key:(NSString *)key
          token:(NSString *)token
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option;

+ (void)putData:(NSData *)data
            key:(NSString *)key
         policy:(NSDictionary *)policy
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option;

+ (void)putData:(NSData *)data
            key:(NSString *)key
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option;

/**
 *    上传文件
 *
 *    @param filePath          文件路径
 *    @param key               上传到云存储的key，为nil时表示是由七牛生成
 *    @param token             上传需要的token, 由服务器生成
 *    @param completionHandler 上传完成后的回调函数
 *    @param option            上传时传入的可选参数
 */
+ (void)putFile:(NSString *)filePath
            key:(NSString *)key
          token:(NSString *)token
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option;

+ (void)putFile:(NSString *)filePath
            key:(NSString *)key
         policy:(NSDictionary *)policy
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option;

+ (void)putFile:(NSString *)filePath
            key:(NSString *)key
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option;

@end



/*
 一、图片缩放  imageMogr2/thumbnail
 
 例：KIQiniuFileURLString(@"image/file3?imageMogr2/thumbnail/120x")
 
参数名称	必填	说明
/thumbnail/!<Scale>p                基于原图大小，按指定百分比缩放。 取值范围0-1000。
/thumbnail/!<Scale>px               以百分比形式指定目标图片宽度，高度不变。取值范围0-1000。
/thumbnail/!x<Scale>p               以百分比形式指定目标图片高度，宽度不变。取值范围0-1000。
/thumbnail/<Width>x                 指定目标图片宽度，高度等比缩放。取值范围0-10000。
/thumbnail/x<Height>                指定目标图片高度，宽度等比缩放。取值范围0-10000。
/thumbnail/<Width>x<Height>         限定长边，短边自适应缩放，将目标图片限制在指定宽高矩形内。取值范围不限，但若宽高超过10000只能缩不能放。
/thumbnail/!<Width>x<Height>r		限定短边，长边自适应缩放，目标图片会延伸至指定宽高矩形外。取值范围不限，但若宽高超过10000只能缩不能放。
/thumbnail/<Width>x<Height>!		限定目标图片宽高值，忽略原图宽高比例，按照指定宽高值强行缩略，可能导致目标图片变形。取值范围不限，但若宽高超过10000只能缩不能放。
/thumbnail/<Width>x<Height>>		当原图尺寸大于给定的宽度或高度时，按照给定宽高值缩小。取值范围不限，但若宽高超过10000只能缩不能放。
/thumbnail/<Width>x<Height><		当原图尺寸小于给定的宽度或高度时，按照给定宽高值放大。取值范围不限，但若宽高超过10000只能缩不能放。
/thumbnail/<Area>@                  按原图高宽比例等比缩放，缩放后的像素数量不超过指定值。取值范围不限，但若像素数超过100000000只能缩不能放。
*/

