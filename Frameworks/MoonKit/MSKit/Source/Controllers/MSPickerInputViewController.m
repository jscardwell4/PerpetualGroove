//
//  MSPickerInputViewController.m
//  Remote
//
//  Created by Jason Cardwell on 4/6/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"
#import "MSPickerInputViewController.h"

@interface MSPickerInputViewController ()

@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *selectBarButtonItem;
@property (assign, nonatomic) NSInteger numberOfComponents;
@property (strong, nonatomic) NSMutableArray * selectedRows;

- (IBAction)cancelAction:(id)sender;
- (IBAction)selectAction:(id)sender;

@end

@implementation MSPickerInputViewController
@synthesize numberOfComponents = _numberOfComponents;
@synthesize selectedRows = _selectedRows;
@synthesize pickerView = _pickerView;
@synthesize toolbar = _toolbar;
@synthesize cancelBarButtonItem = _cancelBarButtonItem;
@synthesize selectBarButtonItem = _selectBarButtonItem;
@synthesize pickerViewData = _pickerViewData;
@synthesize delegate = _delegate;


+ (MSPickerInputViewController *)pickerInputViewController {
    MSPickerInputViewController * controller =
        [[MSPickerInputViewController alloc] initWithNibName:@"MSPickerInputViewController"
                                                      bundle:nil];
    return controller;
}

- (void)customCancelButtonFromView:(UIView *)view {
    UIBarButtonItem * cancelItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    
    if ([view isKindOfClass:[UIButton class]]) {
        [(UIButton *)view addTarget:self
                             action:@selector(cancelAction:) 
                   forControlEvents:UIControlEventTouchUpInside];
    } else {
        cancelItem.target = self;
        cancelItem.action = @selector(cancelAction:);
    }
    
    NSMutableArray * items = [_toolbar.items mutableCopy];
     items[0] = cancelItem;
    _toolbar.items = items;
}

- (void)customSelectButtonFromView:(UIView *)view {
    UIBarButtonItem * selectItem = [[UIBarButtonItem alloc] initWithCustomView:view];
    if ([view isKindOfClass:[UIButton class]]) {
        [(UIButton *)view addTarget:self
                             action:@selector(selectAction:) 
                   forControlEvents:UIControlEventTouchUpInside];
    } else {
        selectItem.target = self;
        selectItem.action = @selector(selectAction:);
    }
    
    NSMutableArray * items = [_toolbar.items mutableCopy];
     items[2] = selectItem;
    _toolbar.items = items;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [self setPickerView:nil];
    [self setToolbar:nil];
    [self setCancelBarButtonItem:nil];
    [self setSelectBarButtonItem:nil];
    if ([self isViewLoaded] && self.view.window == nil) self.view = nil;
}
#pragma mark - UIPickerViewDataSource methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    NSInteger count = 0;
    if (ValueIsNotNil(_pickerViewData))
        count = [_pickerViewData count];
    
	return count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    NSInteger count = 0;
    if (ValueIsNotNil(_pickerViewData)) {
        NSArray * rowsInComponent = _pickerViewData[component];
        if (ValueIsNotNil(rowsInComponent)) {
            count = [rowsInComponent count];
        }
    }
	return count;
}

#pragma mark - UIPickerViewDelegate methods

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row 
       inComponent:(NSInteger)component
{
	 _selectedRows[component] = @(row);
}

- (NSString *)pickerView:(UIPickerView *)pickerView 
			 titleForRow:(NSInteger)row
			forComponent:(NSInteger)component
{
    NSString * title = nil;
    
    if (ValueIsNotNil(_pickerViewData)) {
        NSArray * rowsInComponent = _pickerViewData[component];
        if (ValueIsNotNil(rowsInComponent)) {
            title = rowsInComponent[row];
        }
    }
    
	return title;
}

- (void)setPickerViewData:(NSArray *)pickerViewData {
    _pickerViewData = pickerViewData;
    
    if (ValueIsNotNil(_pickerViewData)) {
        self.numberOfComponents = [_pickerViewData count];
        self.selectedRows = [NSMutableArray arrayWithCapacity:_numberOfComponents];
        for (int i = 0; i < _numberOfComponents; i++) {
            [_selectedRows addObject:@0];
        }
    }
}

- (void)selectRow:(NSInteger)row inComponent:(NSInteger)component animated:(BOOL)animated {
    [_pickerView selectRow:row inComponent:component animated:animated];
}

- (IBAction)cancelAction:(id)sender {
    [_delegate pickerInputViewControllerDidCancel:self];
}

- (IBAction)selectAction:(id)sender {
    [_delegate pickerInputViewController:self selectedRows:[NSArray arrayWithArray:_selectedRows]];
}

@end

