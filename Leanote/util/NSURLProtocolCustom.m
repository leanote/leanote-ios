
#import "NSURLProtocolCustom.h"
#import "NoteService.h"
#import "Common.h"

@implementation NSURLProtocolCustom

+ (BOOL)canInitWithRequest:(NSURLRequest*)theRequest
{
	NSLog(@"canInitWithRequest %@", theRequest.URL);
	if ([theRequest.URL.scheme caseInsensitiveCompare:@"leanote"] == NSOrderedSame) {
		return YES;
	}
	return NO;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)theRequest
{
	return theRequest;
}

- (void)startLoading
{
	NSLog(@"%@", self.request.URL);
	NSURLResponse *response = [[NSURLResponse alloc] initWithURL:self.request.URL
														MIMEType:@"image/png"
										   expectedContentLength:-1
												textEncodingName:nil];
	
	// http://stackoverflow.com/questions/5572258/ios-webview-remote-html-with-local-image-files
	
//	NSLog(@"you know");
	// myapp://splash@2x.jpg
	// leanote://getImage?fileId=551d434199c37b9965000007
//	NSLog(self.request.URL.absoluteString);
	
	NSString *fileId =[self.request.URL.absoluteString substringFromIndex:[@"leanote://getImage?fileId=" length]];
	
	NSLog(@"fileId: %@", fileId);
	
	[NoteService getImage:fileId success:^(NSString * relatedPath) {
		// relatedPath相对于doc目录
		NSString *absPath = [Common getAbsPath:relatedPath];
		NSLog(@"absPath: %@", absPath);
		NSData *data = [NSData dataWithContentsOfFile:absPath];
		
		[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		
		[[self client] URLProtocol:self didLoadData:data];
		
		[[self client] URLProtocolDidFinishLoading:self];
		
	} fail:^{
		[[self client] URLProtocolDidFinishLoading:self];
	}];
	
//	NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"splash@2x" ofType:@"jpg"];
	// [response release];
}

- (void)stopLoading
{
	NSLog(@"request cancelled. stop loading the response, if possible");
}

@end
