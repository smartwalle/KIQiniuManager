//
//  KIQiniuManager.m
//  Kitalker
//
//  Created by apple on 15/4/23.
//
//

#import "KIQiniuManager.h"
#include <CommonCrypto/CommonHMAC.h>

#define KIDeadline(seconds) [[NSDate dateWithTimeInterval:(seconds) sinceDate:[NSDate date]] timeIntervalSince1970]

@interface KIQiniuKey : NSObject
@property (nonatomic, copy) NSString    *accessKey;
@property (nonatomic, copy) NSString    *secretKey;
@property (nonatomic, copy) NSString    *scope;
@property (nonatomic, assign) BOOL      privateScope;
@property (nonatomic, copy) NSString    *domain;
@end

@implementation KIQiniuKey

+ (KIQiniuKey *)sharedInstance {
    static KIQiniuKey *KI_QINIU_KEY;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KI_QINIU_KEY = [[KIQiniuKey alloc] init];
    });
    
    return KI_QINIU_KEY;
}

@end

@interface KIQiniuManager ()
@property (nonatomic, strong) QNUploadManager *uploadManager;
@end

static KIQiniuManager *KI_QINIU_MANAGER;

@implementation KIQiniuManager

- (id)init {
    if (KI_QINIU_MANAGER == nil) {
        if (self = [super init]) {
            KI_QINIU_MANAGER = self;
        }
    }
    return KI_QINIU_MANAGER;
}

- (NSString *)accessKey {
    return [KIQiniuKey sharedInstance].accessKey;
}

- (NSString *)secretKey {
    return [KIQiniuKey sharedInstance].secretKey;
}

- (NSString *)scope {
    return [KIQiniuKey sharedInstance].scope;
}

- (BOOL)privateScope {
    return [KIQiniuKey sharedInstance].privateScope;
}

- (NSString *)domain {
    return [KIQiniuKey sharedInstance].domain;
}

- (QNUploadManager *)uploadManager {
    if (_uploadManager == nil) {
        _uploadManager = [[QNUploadManager alloc] init];
    }
    return _uploadManager;
}

- (NSMutableDictionary *)defaultPutPolicy {
    NSMutableDictionary *policy = [[NSMutableDictionary alloc] init];
    [policy setObject:[self scope] forKey:@"scope"];
    [policy setObject:@((NSInteger)KIDeadline(60*60*24*1)) forKey:@"deadline"];
    [policy setObject:@"{\"name\":$(fname),\"size\":$(fsize),\"w\":$(imageInfo.width),\"h\":$(imageInfo.height),\"hash\":$(etag)}" forKey:@"returnBody"];
    return policy;
}

- (NSString *)tokenWithAccessKey:(NSString *)accessKey
                       secretKey:(NSString *)secretKey
                           scope:(NSString *)scope
                        deadline:(NSTimeInterval)deadline
                          policy:(NSDictionary *)policy {
    NSMutableDictionary *policyDict = [self defaultPutPolicy];
    if (policy != nil) {
        [policyDict addEntriesFromDictionary:policy];
    }
    
    if (scope != nil && scope.length > 0) {
        [policyDict setObject:scope forKey:@"scope"];
    }
    
    [policyDict setObject:@((NSInteger)deadline) forKey:@"deadline"];
    
    NSData *policyData = [NSJSONSerialization dataWithJSONObject:policyDict options:0 error:nil];
    NSString *policyStr = [[NSString alloc] initWithData:policyData encoding:NSUTF8StringEncoding];
    
    NSString *encodedPolicy = [QNUrlSafeBase64 encodeString:policyStr];
    NSData *sign = [self hmacsha1WithSecret:secretKey value:encodedPolicy];
    NSString *encodeSign = [QNUrlSafeBase64 encodeData:sign];
    
    NSString *token = [NSString stringWithFormat:@"%@:%@:%@", accessKey, encodeSign, encodedPolicy];
    return token;
}

- (NSString *)tokenWithPolicy:(NSDictionary *)policy {
    return [self tokenWithAccessKey:[self accessKey]
                          secretKey:[self secretKey]
                              scope:[self scope]
                           deadline:(NSInteger)KIDeadline(60*60*24*1)
                             policy:policy];
}

- (NSString *)tokenWithScope:(NSString *)scope deadline:(NSTimeInterval)deadline {
    NSUInteger time = deadline;
    
    NSMutableDictionary *policyDict = [[NSMutableDictionary alloc] init];
    
    [policyDict setObject:scope forKey:@"scope"];
    [policyDict setObject:@(time) forKey:@"deadline"];
    
    return [self tokenWithPolicy:policyDict];
}

- (NSString *)fileURLString:(NSString *)filePath
                     domain:(NSString *)domain
                  accessKey:(NSString *)accessKey
                  secretKey:(NSString *)secretKey
               privateScope:(BOOL)privateScope
                   deadline:(NSTimeInterval)deadline {
    BOOL hasParam = NO;
    
    if ([filePath rangeOfString:@"?"].location != NSNotFound) {
        hasParam = YES;
    }
    
    NSString *sep = hasParam ? @"&" : @"?";
    
    NSMutableString *urlString = nil;
    
    if (privateScope) {
        urlString = [NSMutableString stringWithFormat:@"%@/%@%@e=%ld", domain, filePath, sep, (long)deadline];
        NSData *sign = [self hmacsha1WithSecret:secretKey value:urlString];
        NSString *encodeSign = [QNUrlSafeBase64 encodeData:sign];
        NSString *token = [NSString stringWithFormat:@"%@:%@", accessKey, encodeSign];
        
        [urlString appendFormat:@"&token=%@", token];
    } else {
        urlString = [NSMutableString stringWithFormat:@"%@/%@", domain, filePath];
    }
    
    return urlString;
}

- (NSString *)fileURLString:(NSString *)filePath domain:(NSString *)domain deadline:(NSTimeInterval)deadline {
    return [self fileURLString:filePath
                        domain:domain
                     accessKey:[self accessKey]
                     secretKey:[self secretKey]
                  privateScope:[self privateScope]
                      deadline:deadline];
}

- (NSData *)hmacsha1WithSecret:(NSString *)secret value:(NSString *)value {
    
    const char *cKey  = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [value cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    return HMAC;
}

+ (KIQiniuManager *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KI_QINIU_MANAGER = [[KIQiniuManager alloc] init];
    });
    return KI_QINIU_MANAGER;
}

+ (void)setAccessKey:(NSString *)key {
    [[KIQiniuKey sharedInstance] setAccessKey:key];
}

+ (void)setSecretKey:(NSString *)key {
    [[KIQiniuKey sharedInstance] setSecretKey:key];
}

+ (void)setScope:(NSString *)scope {
    [[KIQiniuKey sharedInstance] setScope:scope];
}

+ (void)setPrivateScope:(BOOL)value {
    [[KIQiniuKey sharedInstance] setPrivateScope:value];
}

+ (void)setDomain:(NSString *)domain {
    [[KIQiniuKey sharedInstance] setDomain:domain];
}


+ (NSString *)tokenWithAccessKey:(NSString *)accessKey
                       secretKey:(NSString *)secretKey
                           scope:(NSString *)scope
                        deadline:(NSTimeInterval)deadline
                          policy:(NSDictionary *)policy {
    return [[KIQiniuManager sharedInstance] tokenWithAccessKey:accessKey
                                                     secretKey:secretKey
                                                         scope:scope
                                                      deadline:deadline
                                                        policy:policy];
}

+ (NSString *)tokenWithPolicy:(NSDictionary *)policy {
    return [[KIQiniuManager sharedInstance] tokenWithPolicy:policy];
}

+ (NSString *)tokenWithScope:(NSString *)scope deadline:(NSTimeInterval)deadline {
    return [[KIQiniuManager sharedInstance] tokenWithScope:scope deadline:deadline];
}

+ (NSString *)tokenWithScope:(NSString *)scop {
    return [KIQiniuManager tokenWithScope:scop deadline:KIDeadline(60*60*24*30)];
}

+ (NSString *)token {
    return [KIQiniuManager tokenWithScope:[[KIQiniuManager sharedInstance] scope]];
}

+ (NSString *)fileURLString:(NSString *)filePath
                     domain:(NSString *)domain
                  accessKey:(NSString *)accessKey
                  secretKey:(NSString *)secretKey
               privateScope:(BOOL)privateScope
                   deadline:(NSTimeInterval)deadline {
    return [[KIQiniuManager sharedInstance] fileURLString:filePath
                                                   domain:domain
                                                accessKey:accessKey
                                                secretKey:secretKey
                                             privateScope:privateScope
                                                 deadline:deadline];
}

+ (NSString *)fileURLString:(NSString *)filePath domain:(NSString *)domain deadline:(NSTimeInterval)deadline {
    return [[KIQiniuManager sharedInstance] fileURLString:filePath domain:domain deadline:deadline];
}

+ (NSString *)fileURLString:(NSString *)filePath domain:(NSString *)domain {
    return [KIQiniuManager fileURLString:filePath domain:domain deadline:KIDeadline(60*60*24*1)];
}

+ (NSString *)fileURLString:(NSString *)filePath {
    return [KIQiniuManager fileURLString:filePath domain:[[KIQiniuManager sharedInstance] domain]];
}

+ (QNUploadManager *)uploadManager {
    return [[KIQiniuManager sharedInstance] uploadManager];
}

+ (void)putData:(NSData *)data
            key:(NSString *)key
          token:(NSString *)token
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option {
    [[KIQiniuManager uploadManager] putData:data
                                        key:key
                                      token:token
                                   complete:completionHandler
                                     option:option];
}

+ (void)putData:(NSData *)data
            key:(NSString *)key
         policy:(NSDictionary *)policy
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option {
    [KIQiniuManager putData:data
                        key:key
                      token:[KIQiniuManager tokenWithPolicy:policy]
                   complete:completionHandler
                     option:option];
}

+ (void)putData:(NSData *)data
            key:(NSString *)key
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option {
    [KIQiniuManager putData:data
                        key:key
                     policy:nil
                   complete:completionHandler
                     option:option];
}

+ (void)putFile:(NSString *)filePath
            key:(NSString *)key
          token:(NSString *)token
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option {
    [[KIQiniuManager uploadManager] putFile:filePath
                                        key:key
                                      token:token
                                   complete:completionHandler
                                     option:option];
}

+ (void)putFile:(NSString *)filePath
            key:(NSString *)key
         policy:(NSDictionary *)policy
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option {
    [KIQiniuManager putFile:filePath
                        key:key
                      token:[KIQiniuManager tokenWithPolicy:policy]
                   complete:completionHandler
                     option:option];
}

+ (void)putFile:(NSString *)filePath
            key:(NSString *)key
       complete:(QNUpCompletionHandler)completionHandler
         option:(QNUploadOption *)option {
    [KIQiniuManager putFile:filePath
                        key:key
                     policy:nil
                   complete:completionHandler
                     option:option];
}

@end
