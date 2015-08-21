//  AFNetworkTool.h

/**
 要使用常规的AFN网络访问
 
 1. AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
 
 所有的网络请求,均有manager发起
 
 2. 需要注意的是,默认提交请求的数据是二进制的,返回格式是JSON
 
 1> 如果提交数据是JSON的,需要将请求格式设置为AFJSONRequestSerializer
 2> 如果返回格式不是JSON的,
 
 3. 请求格式
 
 AFHTTPRequestSerializer            二进制格式
 AFJSONRequestSerializer            JSON
 AFPropertyListRequestSerializer    PList(是一种特殊的XML,解析起来相对容易)
 
 4. 返回格式
 
 AFHTTPResponseSerializer           二进制格式
 AFJSONResponseSerializer           JSON
 AFXMLParserResponseSerializer      XML,只能返回XMLParser,还需要自己通过代理方法解析
 AFXMLDocumentResponseSerializer (Mac OS X)
 AFPropertyListResponseSerializer   PList
 AFImageResponseSerializer          Image
 AFCompoundResponseSerializer       组合
 */

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface AFNetworkTool : NSObject

/**检测网路状态**/
+ (BOOL)connected;
+ (void)netWorkStatus;

/**
 *JSON方式获取数据
 *urlStr:获取数据的url地址
 *
 */
+ (void)JSONDataWithUrl:(NSString *)url success:(void (^)(id json))success fail:(void (^)())fail;
+ (void)get:(NSString *)url params: (NSMutableDictionary *)params success:(void (^)(id json))success fail:(void (^)(id json))fail;

/**
 *xml方式获取数据
 *urlStr:获取数据的url地址
 *
 */
+ (void)XMLDataWithUrl:(NSString *)urlStr success:(void (^)(id xml))success fail:(void (^)())fail;

/**
 *JSON方式post提交数据
 *urlStr:服务器地址
 *parameters:提交的内容参数
 *
 */
+ (void)postJSONWithUrl:(NSString *)urlStr parameters:(id)parameters success:(void (^)(id responseObject))success fail:(void (^)())fail;

+ (void)post:(NSString *)urlStr params:(NSMutableDictionary *)params success:(void (^)(id responseObject))success fail:(void (^)(id json))fail;
+ (void)postWithData:(NSString *)urlStr
			  params:(NSMutableDictionary *)params
			   files:(NSArray *)files
			 success:(void (^)(id responseObject))success
				fail:(void (^)(id json))fail;

/**
 *Session下载文件
 *urlStr :   下载文件的url地址
 *
 */
+ (void)sessionDownloadWithUrl:(NSString *)urlStr success:(void (^)(NSURL *fileURL))success fail:(void (^)())fail;

/**
 *文件上传,自己定义文件名
 *urlStr:    需要上传的服务器url
 *fileURL:   需要上传的本地文件URL
 *fileName:  文件在服务器上以什么名字保存
 *fileTye:   文件类型
 *
 */
+ (void)postUploadWithUrl:(NSString *)urlStr fileUrl:(NSURL *)fileURL fileName:(NSString *)fileName fileType:(NSString *)fileTye success:(void (^)(id responseObject))success fail:(void (^)())fail;

/**
 *文件上传,文件名由服务器端决定
 *urlStr:    需要上传的服务器url
 *fileURL:   需要上传的本地文件URL
 *
 */
+ (void)postUploadWithUrl:(NSString *)urlStr fileUrl:(NSURL *)fileURL success:(void (^)(id responseObject))success fail:(void (^)())fail;


+ (void) download:(NSString*) url success:(void (^)(NSString *relativePath))success fail:(void (^)())fail;

@end
