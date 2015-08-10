#import "MSKitMacros.h"

#import "MSKitGeometryFunctions.h"
#import "MSPickerInputView.h"
#import "MSPickerInputButton.h"
#import <objc/runtime.h>



@class MSPickerInputTemplate, MSPickerInputOptional;

#pragma mark - MSPickerInput Extension

@interface MSPickerInputView ()

@property (nonatomic, strong) IBOutlet UIPickerView * pickerView;
@property (nonatomic, strong) IBOutlet UIToolbar * toolbar;
@property (nonatomic, strong) IBOutlet UIBarButtonItem * flexibleSpaceBarButtonItem;

- (NSArray *)defaultBarButtonItems;

- (IBAction)cancelAction:(id)sender;

- (IBAction)selectAction:(id)sender;

+ (void)instantiateSubclassForPickerInput:(MSPickerInputView *)pickerInput 
                                 delegate:(id<MSPickerInputDelegate>)delegate;

@end

@interface MSPickerInputTemplate : MSPickerInputView  <UIPickerViewDelegate, UIPickerViewDataSource> @end

@interface MSPickerInputOptional : MSPickerInputView @end

#pragma mark - MSPickerInput

@implementation MSPickerInputView

@synthesize 
delegate = _delegate,
pickerInputButton,
pickerView = _pickerView,
toolbar = _toolbar,
flexibleSpaceBarButtonItem = _flexibleSpaceBarButtonItem,
cancelBarButtonItem = _cancelBarButtonItem,
selectBarButtonItem = _selectBarButtonItem;

+ (MSPickerInputView *)pickerInput {
    return [[MSPickerInputView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 260.0)];
}

+ (void)instantiateSubclassForPickerInput:(MSPickerInputView *)pickerInput 
                                 delegate:(id<MSPickerInputDelegate>)delegate 
{
    static NSUInteger subclassSuffix = 0;
    
    NSString * className = 
        [ClassString([self class]) stringByAppendingFormat:@"%lu",(unsigned long)subclassSuffix++];
    // NSLog(@"%@ creating new subclass:%@", ClassTagString, className);
    
    Class superClass = [MSPickerInputTemplate class];
    Class optionalClass = [MSPickerInputOptional class];
    Class subclass = NSClassFromString(className);
    
    if (ValueIsNil(subclass))
        subclass = objc_allocateClassPair(superClass, [className UTF8String], 0);
    else {
        // NSLog(@"%@ subclass already exists, how did this happen?", ClassTagString);
        object_setClass(pickerInput, subclass);
        return;
    }
    
    if ([delegate respondsToSelector:@selector(pickerInput:widthForComponent:)]) {
        SEL selector = @selector(pickerView:widthForComponent:);
        Method method = class_getInstanceMethod(optionalClass, selector);
        IMP implementation = class_getMethodImplementation(optionalClass, selector);
        class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method));
    }

    if ([delegate respondsToSelector:@selector(pickerInput:rowHeightForComponent:)]) {
        SEL selector = @selector(pickerView:rowHeightForComponent:);
        Method method = class_getInstanceMethod(optionalClass, selector);
        IMP implementation = class_getMethodImplementation(optionalClass, selector);
        class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method));
    }

    if ([delegate respondsToSelector:@selector(pickerInput:titleForRow:forComponent:)]) {
        SEL selector = @selector(pickerView:titleForRow:forComponent:);
        Method method = class_getInstanceMethod(optionalClass, selector);
        IMP implementation = class_getMethodImplementation(optionalClass, selector);
        class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method));
    }

    if ([delegate respondsToSelector:@selector(pickerInput:viewForRow:forComponent:reusingView:)]) {
        SEL selector = @selector(pickerView:viewForRow:forComponent:reusingView:);
        Method method = class_getInstanceMethod(optionalClass, selector);
        IMP implementation = class_getMethodImplementation(optionalClass, selector);
        class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method));
    }

    if ([delegate respondsToSelector:@selector(pickerInput:didSelectRow:inComponent:)]) {
        SEL selector = @selector(pickerView:didSelectRow:inComponent:);
        Method method = class_getInstanceMethod(optionalClass, selector);
        IMP implementation = class_getMethodImplementation(optionalClass, selector);
        class_addMethod(subclass, selector, implementation, method_getTypeEncoding(method));
    }
    
    objc_registerClassPair(subclass);
    object_setClass(pickerInput, subclass);
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector])
        return YES;
    else 
        return [self.pickerView respondsToSelector:aSelector];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([self.pickerView respondsToSelector:aSelector]) {
        // NSLog(@"%@ forwarding %@ to pickerView", 
        //  ClassTagSelectorString,
        //         SelectorString(aSelector));
       return _pickerView;
    } else {
        // NSLog(@"%@ forwarding %@ to super implementation", 
        // ClassTagSelectorString,
        //         SelectorString(aSelector));
        return [super forwardingTargetForSelector:aSelector];
    }
}

- (void)setDelegate:(id<MSPickerInputDelegate>)delegate {
	_delegate = delegate;

	if (ValueIsNil(_delegate)) {
		// NSLog(@"%@ delegate is nil, should probably reset class if dynamic subclass",
        //    ClassTagString);
		return;
	}

	else {
		// NSLog(@"%@ instantiating subclass for delegate:%@\nself before instantiation:%@",
        //   ClassTagSelectorString, delegate, self);
		[MSPickerInputView instantiateSubclassForPickerInput:self delegate:_delegate];
		// NSLog(@"%@ self after instantiation:%@", ClassTagSelectorString, self);

		if (  [self conformsToProtocol:@protocol(UIPickerViewDelegate)]
		   && [self conformsToProtocol:@protocol(UIPickerViewDataSource)]) {
			// NSLog(@"%@ assigning self as data source and delegate for picker view:%@", ClassTagSelectorString, self.pickerView);
			self.pickerView.delegate = (id<UIPickerViewDelegate>)self;
			self.pickerView.dataSource = (id<UIPickerViewDataSource>)self;
		}
	}

}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {                               
        
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
        
        self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 44.0)];
        _toolbar.autoresizesSubviews = YES;
        _toolbar.barStyle = UIBarStyleBlackTranslucent;
        _toolbar.items = [self defaultBarButtonItems];
        [self addSubview:_toolbar];

        self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, 44.0, 320.0, 216.0)];
        _pickerView.showsSelectionIndicator = YES;
        [self addSubview:_pickerView];
        
    }
    return self;
}

- (IBAction)cancelAction:(id)sender {
    [_delegate pickerInputDidCancel:self];
}

- (IBAction)selectAction:(id)sender {
    NSInteger numberOfComponents = _pickerView.numberOfComponents;
    NSMutableArray * selectedRows = [NSMutableArray arrayWithCapacity:numberOfComponents];
    for (int i = 0; i < numberOfComponents; i++) {
        [selectedRows addObject:
         @([_pickerView selectedRowInComponent:i])];
    }
    [_delegate pickerInput:self selectedRows:selectedRows];
}

- (void)setCancelBarButtonItem:(UIBarButtonItem *)cancelBarButtonItem {
    if (ValueIsNil(_toolbar)) 
        return;
    
    NSMutableArray * toolbarItems = [_toolbar.items mutableCopy];
    
    if (ValueIsNotNil(cancelBarButtonItem)) {
        if (  ValueIsNotNil(cancelBarButtonItem.customView)
           && [cancelBarButtonItem.customView isKindOfClass:[UIButton class]])
        {
            [(UIButton *)cancelBarButtonItem.customView addTarget:self 
                                                           action:@selector(cancelAction:)
                                                 forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            cancelBarButtonItem.target = self;
            cancelBarButtonItem.action = @selector(cancelAction:);
        }        
    }
    
    NSUInteger cancelItemIndex = [toolbarItems indexOfObject:_cancelBarButtonItem];
    
    if (cancelItemIndex != NSNotFound) {
        if (ValueIsNil(cancelBarButtonItem))
            [toolbarItems removeObjectAtIndex:cancelItemIndex];
        else
             toolbarItems[cancelItemIndex] = cancelBarButtonItem;
    } else if (ValueIsNotNil(cancelBarButtonItem))
        toolbarItems[0] = cancelBarButtonItem;
    
    _cancelBarButtonItem = cancelBarButtonItem;
    _toolbar.items = toolbarItems;
}

- (void)setSelectBarButtonItem:(UIBarButtonItem *)selectBarButtonItem {
    if (ValueIsNil(_toolbar)) 
        return;
    
    NSMutableArray * toolbarItems = [_toolbar.items mutableCopy];
    
    if (ValueIsNotNil(selectBarButtonItem)) {
        if (  ValueIsNotNil(selectBarButtonItem.customView)
            && [selectBarButtonItem.customView isKindOfClass:[UIButton class]])
        {
            [(UIButton *)selectBarButtonItem.customView addTarget:self 
                                                           action:@selector(selectAction:)
                                                 forControlEvents:UIControlEventTouchUpInside];
        }
        else {
            selectBarButtonItem.target = self;
            selectBarButtonItem.action = @selector(selectAction:);
        }        
    }
    
    NSUInteger selectItemIndex = [toolbarItems indexOfObject:_selectBarButtonItem];
    
    if (selectItemIndex != NSNotFound) {
        if (ValueIsNil(selectBarButtonItem))
            [toolbarItems removeObjectAtIndex:selectItemIndex];
        else
             toolbarItems[selectItemIndex] = selectBarButtonItem;
    } else if (ValueIsNotNil(selectBarButtonItem))
        [toolbarItems addObject:selectBarButtonItem];
    
    _selectBarButtonItem = selectBarButtonItem;
    _toolbar.items = toolbarItems;
}

- (void)insertBarButtonItem:(UIBarButtonItem *)barButtonItem atIndex:(NSUInteger)index {
    
    NSMutableArray * toolbarItems = [_toolbar.items mutableCopy];
    
    if (ValueIsNotNil(barButtonItem) && [toolbarItems count] >= index) {
    
        if ([toolbarItems count] == index)
            [toolbarItems addObject:barButtonItem];
        
        else
            toolbarItems[index] = barButtonItem;
    
    } 
    
    else if (index < [toolbarItems count]) {
        
        UIBarButtonItem * itemToRemove = toolbarItems[index];
        
        if (itemToRemove != _cancelBarButtonItem && itemToRemove != _selectBarButtonItem)
            [toolbarItems removeObject:itemToRemove];
        
    }
    
    _toolbar.items = toolbarItems;
}

- (NSArray *)defaultBarButtonItems {
    _cancelBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                  target:self 
                                                  action:@selector(cancelAction:)];
    
    self.flexibleSpaceBarButtonItem =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                  target:nil 
                                                  action:nil];
    
    _selectBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Select"
                                     style:UIBarButtonItemStyleDone 
                                    target:self 
                                    action:@selector(selectAction:)];
    return @[_cancelBarButtonItem, _flexibleSpaceBarButtonItem, _selectBarButtonItem];
}

@end

#pragma mark - MSPickerInputTemplate

@implementation MSPickerInputTemplate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	NSInteger count = 0;
    
	if (  ValueIsNotNil(self.delegate)
        && [self.delegate respondsToSelector:@selector(numberOfComponentsInPickerInput:)])
		count = [self.delegate numberOfComponentsInPickerInput:self];
    
	return count;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	NSInteger count = 0;
    
	if (  ValueIsNotNil(self.delegate)
        && [self.delegate respondsToSelector:@selector(pickerInput:numberOfRowsInComponent:)])
		count = [self.delegate pickerInput:self numberOfRowsInComponent:component];
    
	return count;
}

@end

#pragma mark - MSPickerInputOptional

@implementation MSPickerInputOptional

- (CGFloat)pickerView:(UIPickerView *)pickerView
     widthForComponent:(NSInteger)component
{
    return [self.delegate pickerInput:self widthForComponent:component];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView 
rowHeightForComponent:(NSInteger)component
{
    return [self.delegate pickerInput:self rowHeightForComponent:component];
}

- (NSString *)pickerView:(UIPickerView *)pickerView 
              titleForRow:(NSInteger)row 
             forComponent:(NSInteger)component
{
    return [self.delegate pickerInput:self titleForRow:row forComponent:component];
}

- (UIView *)pickerView:(UIPickerView *)pickerView 
             viewForRow:(NSInteger)row
           forComponent:(NSInteger)component
            reusingView:(UIView *)view
{
    return [self.delegate pickerInput:self viewForRow:row forComponent:component reusingView:view];
}

- (void)pickerView:(UIPickerView *)pickerView 
       didSelectRow:(NSInteger)row 
        inComponent:(NSInteger)component
{
    [self.delegate pickerInput:self didSelectRow:row inComponent:component];
}

@end

