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
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/WPTableViewCell.h>
#import <WordPress-iOS-Shared/UITableViewTextFieldCell.h>
#import <WordPress-iOS-Shared/WPTableViewSectionHeaderView.h>

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

@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;

@property (nonatomic, assign) BOOL textFieldDidHaveFocusBeforeOrientationChange;

@end

@implementation AddNotebookViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Add Notebook", nil);
	
	// Compensate for the first section's height of 1.0f
	self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0, 0, 0);
	self.tableView.accessibilityIdentifier = @"AddNotebookTable";
	
	self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
	self.navigationItem.rightBarButtonItem = self.doneButton;
	
	self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = self.cancelButton;
	
	if(self.notebook) {
		self.title = NSLocalizedString(@"Edit Notebook", nil);
	}
	
	[self setTableStyle:self.tableView];
}

-(void) viewDidAppear:(BOOL)animated
{
	[self restoreBarStyle];
}


#pragma mark - Action

- (IBAction)cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}


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
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (!self.sections) {
		[self configureSections];
	}
	return [self.sections count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (NSString *)titleForHeaderInSection:(NSInteger)section
{
	return @"";
	
	NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
	if (sec == PostSettingsSectionTaxonomy) {
		return NSLocalizedString(@"Title", @"Label for the Taxonomy area (categories, keywords, ...) in post settings.");
		
	} else if (sec == PostSettingsSectionMeta) {
		return NSLocalizedString(@"Parent notebook", @"The grandiose Publish button in the Post Editor! Should use the same translation as core WP.");
	}
	return @"Hello";
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Hehe";
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 0.0f)];
	header.title = [self titleForHeaderInSection:section];
	header.backgroundColor = self.tableView.backgroundColor;
	return header;
}


- (UITableViewCell *)tableView:(UITableView *)tableView
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger sec = [[self.sections objectAtIndex:indexPath.section] integerValue];
	
	UITableViewCell *cell;
	
	if (sec == PostSettingsSectionTaxonomy) {
		
		WPTableViewCell *textCell = [self getTextFieldCell];
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
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	
	if (cell.tag == PostSettingsRowCategories) {
		[self showNotebookSelection];
	}
}

- (void)showNotebookSelection
{
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
	
	UIBarButtonItem *newBackButton =
	[[UIBarButtonItem alloc] initWithTitle:@""
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
	[[self navigationItem] setBackBarButtonItem:newBackButton];
	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	if (self.textFieldDidHaveFocusBeforeOrientationChange) {
		self.textFieldDidHaveFocusBeforeOrientationChange = NO;
		return NO;
	}
	return YES;
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
	return YES;
}

@end
