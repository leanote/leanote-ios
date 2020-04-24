//
//  AFNetworkTool.m

#import "AFNetworkTool.h"
#import "Common.h"
#import "File.h"

@implementation AFNetworkTool

// 当前网络是否可达
static BOOL reachable = NO;
static AFNetworkReachabilityStatus status;

#pragma mark 检测网路状态
+ (BOOL)connected {
	return reachable;
}
+ (AFNetworkReachabilityStatus)getNetworkStatus {
	return status;
}
+ (void)netWorkStatus
{
    /**
     AFNetworkReachabilityStatusUnknown          = -1,  // 未知
     AFNetworkReachabilityStatusNotReachable     = 0,   // 无连接
     AFNetworkReachabilityStatusReachableViaWWAN = 1,   // 3G 花钱
     AFNetworkReachabilityStatusReachableViaWiFi = 2,   // WiFi
     */
    // 如果要检测网络状态的变化,必须用检测管理器的单例的startMonitoring
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    // 检测网络连接的单例,网络变化时的回调方法
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus statuss) {
        NSLog(@"%ld", statuss);
		status = statuss;
		reachable = status != AFNetworkReachabilityStatusNotReachable;
    }];
}

+ (BOOL)retIsOk:(id)obj
{
	if([obj isKindOfClass:[NSDictionary class]]) {
		if([obj objectForKey: @"Ok"]) {
			if([obj[@"Ok"] boolValue]) {
				return true;
			}
			else {
				return false;
			}
		}
	}
	return true;
}

#pragma mark - JSON方式获取数据
+ (void)JSONDataWithUrl:(NSString *)url success:(void (^)(id json))success fail:(void (^)())fail;
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    NSDictionary *dict = @{@"format": @"json"};
	
    // 网络访问是异步的,回调是主线程的,因此程序员不用管在主线程更新UI的事情
	[manager GET:url parameters:dict headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
	} success:^(NSURLSessionDataTask *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        NSLog(@"%@", error);
        if (fail) {
            fail();
        }
    }];
}

+ (void)get:(NSString *)url params: (NSMutableDictionary *)params success:(void (^)(id json))success fail:(void (^)(id json))fail;
{
	AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
	
	// NSDictionary *dic3 = [NSDictionary dictionaryWithDictionary:params];
	
	if(params == nil) {
		params = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"json", @"format",nil];
	} else {
		params[@"format"] =  @"json";
	}
	
	NSLog(@"%@", params);
	
	// NSDictionary *dict = @{@"format": @"json"};
	// 网络访问是异步的,回调是主线程的,因此程序员不用管在主线程更新UI的事情
	[manager GET:url parameters:params headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
	} success:^(NSURLSessionDataTask *operation, id obj) {
		if([self retIsOk:obj]) {
			if (success) {
				success(obj);
			}
		}
		else if(fail) {
			fail(obj);
		}
		
	} failure:^(NSURLSessionDataTask *operation, NSError *error) {
		NSLog(@"%@", error);
		if (fail) {
			fail(nil);
		}
	}];
}


#pragma mark - xml方式获取数据
/*
+ (void)XMLDataWithUrl:(NSString *)urlStr success:(void (^)(id xml))success fail:(void (^)())fail
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    // 返回的数据格式是XML
    manager.responseSerializer = [AFXMLParserResponseSerializer serializer];
    
    NSDictionary *dict = @{@"format": @"xml"};
    
    // 网络访问是异步的,回调是主线程的,因此程序员不用管在主线程更新UI的事情
    [manager GET:urlStr parameters:dict success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", error);
        if (fail) {
            fail();
        }
    }];
}
*/

+ (void)post:(NSString *)urlStr params:(NSMutableDictionary *)params success:(void (^)(id responseObject))success fail:(void (^)(id json))fail
{
	AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

	[manager POST:urlStr parameters:params headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
	} success:^(NSURLSessionDataTask *operation, id obj) {
		if([self retIsOk:obj]) {
			if (success) {
				success(obj);
			}
		}
		else if(fail) {
			fail(obj);
		}
//		NSLog(@"JSON: %@", responseObject);
	} failure:^(NSURLSessionDataTask *operation, NSError *error) {
		NSLog(@"Error: %@", error);
		if (fail) {
			fail(nil);
		}
	}];
}

+ (void)postWithData:(NSString *)urlStr params:(NSMutableDictionary *)params
				files:(NSArray *)files
			 success:(void (^)(id responseObject))success
				fail:(void (^)(id json))fail
{
	NSString *docPath = [Common getDocPath];
	NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] multipartFormRequestWithMethod:@"POST" URLString: urlStr parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		if(files && [files count] > 0) {
			for(File *eachFile in files) {
				if(!eachFile.serverFileId || [eachFile.serverFileId length] == 0) {
					NSString *path = [NSString stringWithFormat:@"%@/%@", docPath, eachFile.filePath];
					NSURL *urlPath = [NSURL fileURLWithPath:path];
					[formData appendPartWithFileURL:urlPath name:[NSString stringWithFormat:@"FileDatas[%@]", eachFile.fileId] error:nil];
				}
			}
		}
	} error:nil];
	
	AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
	
	NSURLSessionUploadTask *uploadTask;
	uploadTask = [manager
				  uploadTaskWithStreamedRequest:request
				  progress:^(NSProgress * _Nonnull uploadProgress) {
					  
				  }
				  completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable obj, NSError * _Nullable error) {
					  if (error) {
						  NSLog(@"Error: %@", error);
						  fail(nil);
					  } else {
						  NSLog(@"%@ %@", response, obj);
						  if([self retIsOk:obj]) {
							  if (success) {
								  success(obj);
							  }
						  }
						  else if(fail) {
							  fail(obj);
						  }
					  }
				  }];
	
	[uploadTask resume];
	
	/*
	AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
	
	[manager POST:urlStr
	   parameters:params
		constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		if(files && [files count] > 0) {
			for(File *eachFile in files) {
				if(!eachFile.serverFileId || [eachFile.serverFileId length] == 0) {
					NSString *path = [NSString stringWithFormat:@"%@/%@", docPath, eachFile.filePath];
					NSURL *urlPath = [NSURL fileURLWithPath:path];
					[formData appendPartWithFileURL:urlPath name:[NSString stringWithFormat:@"FileDatas[%@]", eachFile.fileId] error:nil];
				}
			}
		}
		// [formData appendPartWithFileURL:filePath name:@"FileDatas[558e6d7105fcd12eef000000]" error:nil];
		
	} progress:^(NSProgress * _Nonnull uploadProgress) {
	} success:^(NSURLSessionDataTask *operation, id obj) {
		if([self retIsOk:obj]) {
			if (success) {
				success(obj);
			}
		}
		else if(fail) {
			fail(obj);
		}
		//		NSLog(@"JSON: %@", responseObject);
	} failure:^(NSURLSessionDataTask *operation, NSError *error) {
		//		NSLog(@"Error: %@", error);
		if (fail) {
			fail(nil);
		}
	}];
	 */
}

#pragma mark - JSON方式post提交数据
+ (void)postJSONWithUrl:(NSString *)urlStr parameters:(id)parameters success:(void (^)(id responseObject))success fail:(void (^)())fail
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // 设置请求格式
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    // 设置返回格式
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
	
	[manager POST:urlStr parameters:parameters headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
	}  success:^(NSURLSessionDataTask *operation, id responseObject) {
//        NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *operation, NSError *error) {
        NSLog(@"%@", error);
        if (fail) {
            fail();
        }
    }];
}

#pragma mark - Session 下载下载文件
+ (void)sessionDownloadWithUrl:(NSString *)urlStr success:(void (^)(NSURL *fileURL))success fail:(void (^)())fail
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:config];

    NSString *urlString = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        // 指定下载文件保存的路径
        //        NSLog(@"%@ %@", targetPath, response.suggestedFilename);
        // 将下载文件保存在缓存路径中
        NSString *cacheDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSString *path = [cacheDir stringByAppendingPathComponent:response.suggestedFilename];
        
        // URLWithString返回的是网络的URL,如果使用本地URL,需要注意
//        NSURL *fileURL1 = [NSURL URLWithString:path];
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        
//        NSLog(@"== %@ |||| %@", fileURL1, fileURL);
        if (success) {
            success(fileURL);
        }
        
        return fileURL;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSLog(@"%@ %@", filePath, error);
        if (fail) {
            fail();
        }
    }];
    
    [task resume];
}

/*
#pragma mark - 文件上传 自己定义文件名
+ (void)postUploadWithUrl:(NSString *)urlStr fileUrl:(NSURL *)fileURL fileName:(NSString *)fileName fileType:(NSString *)fileTye success:(void (^)(id responseObject))success fail:(void (^)())fail
{
    // 本地上传给服务器时,没有确定的URL,不好用MD5的方式处理
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //@"http://localhost/demo/upload.php"
    [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
//        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"头像1.png" withExtension:nil];
        
        // 要上传保存在服务器中的名称
        // 使用时间来作为文件名 2014-04-30 14:20:57.png
        // 让不同的用户信息,保存在不同目录中
//        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        // 设置日期格式
//        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
//        NSString *fileName = [formatter stringFromDate:[NSDate date]];
        
        //@"image/png"
        [formData appendPartWithFileURL:fileURL name:@"uploadFile" fileName:fileName mimeType:fileTye error:NULL];
        
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (fail) {
            fail();
        }
    }];
}

#pragma mark - POST上传文件
+ (void)postUploadWithUrl:(NSString *)urlStr fileUrl:(NSURL *)fileURL success:(void (^)(id responseObject))success fail:(void (^)())fail
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    // AFHTTPResponseSerializer就是正常的HTTP请求响应结果:NSData
    // 当请求的返回数据不是JSON,XML,PList,UIImage之外,使用AFHTTPResponseSerializer
    // 例如返回一个html,text...
    //
    // 实际上就是AFN没有对响应数据做任何处理的情况
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    // formData是遵守了AFMultipartFormData的对象
    [manager POST:urlStr parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        // 将本地的文件上传至服务器
//        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"头像1.png" withExtension:nil];
        
        [formData appendPartWithFileURL:fileURL name:@"uploadFile" error:NULL];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
//        
//        NSLog(@"完成 %@", result);
        if (success) {
            success(responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"错误 %@", error.localizedDescription);
        if (fail) {
            fail();
        }
    }];
}
*/

+ (void) download:(NSString*) url success:(void (^)(NSString *relativePath))success fail:(void (^)())fail
{
	NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
	AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
	
	NSURL *URL = [NSURL URLWithString:url];
	NSURLRequest *request = [NSURLRequest requestWithURL:URL];
	
	NSString *documentsDirectory = [Common getDocPath];
	NSURL *documentsDirectoryURL = [Common getDocPathURL];
	
	// 创建images目录
	// [Common createDir:@"/images"];

	NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
		NSString *filename = [NSString stringWithFormat:@"images/%@", [response suggestedFilename]];
		return [documentsDirectoryURL URLByAppendingPathComponent:filename];
	} completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
		// file:///Users/life/Library/Developer/CoreSimulator/Devices/42036FAF-BEE1-4C4A-8916-FFD229FDA1CB/data/Containers/Data/Application/0EC7D96A-6BCD-4D25-97DB-1F4816442F04/Documents/images/logo.png
		NSLog(@"%@", documentsDirectoryURL);
		if(error) {
			NSLog(@"%@", error);
			if(fail) {
				fail();
			}
		}
		else {
			NSString *relatedPath = [[filePath absoluteString] substringFromIndex:[[documentsDirectoryURL absoluteString] length]];
			NSLog(@"File downloaded to: %@ --> %@", documentsDirectory, relatedPath);
			if(success) {
				success(relatedPath);
			}
		}
	}];
	[downloadTask resume];
}


@end
