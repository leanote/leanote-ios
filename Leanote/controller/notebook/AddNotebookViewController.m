//
//  NoteSettingsTableViewController.m
//  Leanote
//
//  Created by life on 15/6/2.

#import "AddNotebookViewController.h"
#import "NotebookService.h"
#import "NoteService.h"
#import "NotebookController.h"
#import "Note.h"

#import "Leas.h"

#import "LeaButtonForNavigationBar.h"
#import "UIImage+Util.h"
#import "WPFontManager.h"
#import "WPStyleGuide.h"
#import "WPTableViewCell.h"
#import "WPTextFieldTableViewCell.h"
#import "WPTableViewSectionHeaderFooterView.h"

typedef enum {
	PostSettingsSectionTaxonomy = 0,
	PostSettingsSectionMeta,
} PostSettingsSection;

typedef enum {
	PostSettingsRowCategories = 0,
	PostSettingsRowTags,
} PostSettingsRow;


@interface AddNotebookViewController ()

@property (nonatomic, assign) BOOL preIsBlog;

@property (nonatomic, assign) BOOL shouldHideStatusBar;
@property (nonatomic, strong) NSMutableArray *sections;

@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) NSArray *statusList;
@property (nonatomic, strong) NSArray *visibilityList;
@property (nonatomic, strong) NSArray *formatsList;

@property UIBarButtonItem *doneButton;
@property UIBarButtonItem *cancelButton;

@property (assign) BOOL textFieldDidHaveFocusBeforeOrientationChange;

@end

@implementation AddNotebookViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Add Notebook", nil);
	
	// Compensate for the first section's height of 1.0f
	self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
	self.tableView.accessibilityIdentifier = @"AddNotebookTable";
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	
//	self.doneButton = [[UIBarButtonItem alloc] init];
	self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	// self.doneButton.title = @"Done";
	self.navigationItem.rightBarButtonItem = self.doneButton;
	
	self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = self.cancelButton;
	
	if(self.notebook) {
		self.title = NSLocalizedString(@"Edit Notebook", nil);
	}
	
	// table的样式
	[self setTableStyle:self.tableView];
}

-(void) viewDidAppear:(BOOL)animated
{
	[self restoreBarStyle];
}

// 取消
- (IBAction)cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

// 完成
- (IBAction)done:(id)sender
{
	NSString *name = self.titleTextField.text;
	
	if([name length] > 0) {
		if(self.notebook) {
			if(![name isEqualToString:self.notebook.title]) {
				// TODO
				self.notebook.isDirty = M_YES;
				self.notebook.title = name;
				[NotebookService saveContext];
				
				[Leas.notebook pushAndWrite:self.notebook success:^{
					// tips 提示同步成功
					[self showSuccessMsg:NSLocalizedString(@"Synchronize notebook successful", nil)];
				} fail:^(id ret) {
					[self showErrorMsg:NSLocalizedString(@"Synchronize notebook failed", nil) ret:ret];
				}];
			}
		}
		else {
			self.notebook = [Leas.notebook addNotebook:name];
			[Leas.notebook pushAndWrite:self.notebook success:^{
				// tips 提示同步成功
				[self showSuccessMsg:NSLocalizedString(@"Synchronize notebook successful", nil)];
			} fail:^(id ret) {
				[self showErrorMsg:NSLocalizedString(@"Synchronize notebook failed", nil) ret:ret];
			}];
		}
		// 返回之
		// [self dismissViewControllerAnimated:YES];
		[self dismissViewControllerAnimated:YES completion:nil];
	}
	else {
		[self alert:NSLocalizedString(@"Title is required", nil)];
		
		if(self.notebook) {
			self.titleTextField.text = self.notebook.title;
		}
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
								duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if ([self.passwordTextField isFirstResponder] || [self.titleTextField isFirstResponder]) {
		self.textFieldDidHaveFocusBeforeOrientationChange = YES;
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.tableView reloadData];
}

#pragma mark - Table view data source

- (void)configureSections
{
	self.sections = [NSMutableArray array];
	
	[self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionTaxonomy]];

	// [self.sections addObject:[NSNumber numberWithInteger:PostSettingsSectionMeta]];
}

// 多少个section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (!self.sections) {
		[self configureSections];
	}
	return [self.sections count];
}

// 每个section多少行
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//	NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
	return 1;
//	
//	if (sec == PostSettingsSectionTaxonomy) {
//		return 2;
//		
//	} else if (sec == PostSettingsSectionMeta) {
//		return 1;
//		
//	}
	return 0;
}

// section title
- (NSString *)titleForHeaderInSection:(NSInteger)section
{
	// 暂时不需要
	return @"";
	
	NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
	if (sec == PostSettingsSectionTaxonomy) {
		return NSLocalizedString(@"Title", @"Label for the Taxonomy area (categories, keywords, ...) in post settings.");
		
	} else if (sec == PostSettingsSectionMeta) {
		return NSLocalizedString(@"Parent notebook", @"The grandiose Publish button in the Post Editor! Should use the same translation as core WP.");
	}
	return @"Hello";
}

// 必须要这个, 不然viewForHeaderInSection不执行
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Hehe";
}

// 必须要, 不然不好看
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
//	return 44.0;
	return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	WPTableViewSectionHeaderFooterView *header = [[WPTableViewSectionHeaderFooterView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 0.0f)];
	header.title = [self titleForHeaderInSection:section];
	header.backgroundColor = self.tableView.backgroundColor;
	return header;
}


// 配置每一行
- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];
	
	UITableViewCell *cell;
	
	if (sec == PostSettingsSectionTaxonomy) {
		
		// Tags, 标签啊, 逗号分隔
		WPTableViewCell *textCell = [self getTextFieldCell];
		/*
		textCell.textLabel.text = NSLocalizedString(@"Title", @"Label for the tags field. Should be the same as WP core.");
		
		textCell.textField.text = self.notebook.title;
		
		textCell.textField.secureTextEntry = NO;
		textCell.textField.clearButtonMode = UITextFieldViewModeNever;
		textCell.textField.accessibilityIdentifier = @"NotebookTitle";
		cell = textCell;
		cell.tag = PostSettingsRowTags;
		
		self.titleTextField = textCell.textField;
		
		// 获取焦点
		[self.titleTextField becomeFirstResponder];
		*/
		return textCell;
		
		
	} else if (sec == PostSettingsSectionMeta) {
		// Categories
		cell = [self getWPTableViewCell];
		cell.textLabel.text = NSLocalizedString(@"Parent notebook", @"Label for the categories field. Should be the same as WP core.");
		cell.detailTextLabel.text = self.notebook.title;
		cell.tag = PostSettingsRowCategories;
		cell.accessibilityIdentifier = @"Notebook";
	}
	
	return cell;
}

// cell

- (WPTableViewCell *)getWPTableViewCell
{
	static NSString *wpTableViewCellIdentifier = @"wpTableViewCellIdentifier";
	WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:wpTableViewCellIdentifier];
	if (!cell) {
		cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:wpTableViewCellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		[WPStyleGuide configureTableViewCell:cell];
	}
	cell.tag = 0;
	return cell;
}

// 含文本输入框的cell
- (WPTableViewCell *)getTextFieldCell
{
	static NSString *textFieldCellIdentifier = @"textFieldCellIdentifier";
	WPTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:textFieldCellIdentifier];
	
	if (!cell) {
		cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:textFieldCellIdentifier];
		self.titleTextField = [[UITextField alloc] initWithFrame:CGRectZero];
		self.titleTextField.borderStyle = UITextBorderStyleNone;
		self.titleTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.titleTextField.font = [WPStyleGuide regularTextFont];
		self.titleTextField.placeholder = NSLocalizedString(@"Title", @"Title of the new Category being created.");
		self.titleTextField.text = self.notebook.title;
	}
	
	CGRect frame = self.titleTextField.frame;
	frame.origin.x = 15.0f;
	frame.size.width = cell.contentView.frame.size.width - 30.0f;
	frame.size.height = cell.contentView.frame.size.height;
	self.titleTextField.frame = frame;
	[cell.contentView addSubview:self.titleTextField];
	
	[self.titleTextField becomeFirstResponder];
	
/*
	if (!cell) {
		cell = [[UITableViewTextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:textFieldCellIdentifier];
		cell.textField.returnKeyType = UIReturnKeyDone;
		cell.textField.delegate = self;
		[WPStyleGuide configureTableViewTextCell:cell];
		cell.textField.textAlignment = NSTextAlignmentRight;
	}
	cell.tag = 0;
 */
	return cell;
}

// 选择某一行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	
	// 配置每一行? 为什么?
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	// 然后, 触发动作
	if (cell.tag == PostSettingsRowCategories) {
		[self showNotebookSelection];
	}
}

- (void)showNotebookSelection
{
	/*
	NotebookController *controller = [[NotebookController alloc] initWithNote:self.note fromSetting:YES];
	[self.navigationController pushViewController:controller animated:YES];
	*/
	
	NSString *storyboardName = @"MainStoryboard_iPhone";
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
	NotebookController *vc = [storyboard instantiateViewControllerWithIdentifier:@"Notebook"];
	/*
	[vc initWithNote:self.note fromSetting:YES setSettingNotebook:^(Notebook *notebook) {
		self.note.notebookId = notebook.notebookId;
		[self.tableView reloadData];
		[NoteService updateNote:self.note forNotebook:YES forBlog:NO forTags:NO];
	}];
	*/
	
	vc.hidesBottomBarWhenPushed = YES;
	
	// 设置返回按钮
	UIBarButtonItem *newBackButton =
	[[UIBarButtonItem alloc] initWithTitle:@""
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
	[[self navigationItem] setBackBarButtonItem:newBackButton];
	
	/*
	// modal显示view
	// 显示nav bar http://stackoverflow.com/a/9725740/4269908
	UINavigationController *navigationController =
	[[UINavigationController alloc] initWithRootViewController:vc];
	navigationController.navigationItem.leftBarButtonItem = newBackButton;
	
	[self.navigationController presentViewController:navigationController animated:true completion:nil];
	*/
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - TextField Delegate Methods 标签

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	if (self.textFieldDidHaveFocusBeforeOrientationChange) {
		self.textFieldDidHaveFocusBeforeOrientationChange = NO;
		return NO;
	}
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == self.titleTextField) {
		// self.notebook.title = self.titleTextField.text;
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
	replacementString:(NSString *)string
{
	if (textField == self.titleTextField) {
		//self.note.tags = [self.titleTextField.text stringByReplacingCharactersInRange:range withString:string];
	}
	return YES;
}



/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
