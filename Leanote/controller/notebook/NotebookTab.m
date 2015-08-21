#import "NotebookTab.h"

@interface NotebookTab ()

@end

@implementation NotebookTab


- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
    // 设置图片
    if (!self.tabbarItemImagePath) { //如果没有设置过图片则设置
        self.tabbarItemImagePath = @"tabbed_icon.bundle/notebook3";
        [self setTabBarImage];
		
		/*
		NotebookControllerForTest *a = [[NotebookControllerForTest alloc] init];
		[self initWithRootViewController:a];
		*/
    }
	else {
        return; 
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/





@end
