//
//  Leanote
//
//  Created by life on 03/06/15.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

//一个falg，用于判断显示哪个view
@property (weak,nonatomic) NSString * whichViewToPresent;

- (IBAction)login:(id)sender;
-(void)resignFirstResponder4textField:(id)sender;
-(void)resignFirstResponder4LoginView;
-(void)fromAddAccount:(BOOL)ok noAnyUser:(BOOL)noAnyUser loginOkCb:(void (^)())loginOkCb;
@end



