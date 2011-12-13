#import "FBTextView.h"

@implementation FBTextView

@synthesize placeholder, placeholderColour;

#pragma mark -
#pragma mark Init Methods

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:UITextViewTextDidChangeNotification object:self];
    }
    
    return self;
}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self];
    
    [placeholder release];
    [placeholderColour release];
    [super dealloc];
}

#pragma mark -
#pragma mark Edge Inserts Fix

- (UIEdgeInsets)contentInset
{ 
    return UIEdgeInsetsZero;
}

#pragma mark -
#pragma mark Placeholder Overrides

- (void)drawRect:(CGRect)rect 
{
    [super drawRect:rect];
    
    if ([[self text] length] == 0) 
    {
        [self.placeholderColour set];
        [self.placeholder drawInRect:CGRectMake(8.0, 8.0, self.frame.size.width - 16.0, self.frame.size.height - 16.0) withFont:self.font];
    }
}

- (void)setText:(NSString *)string 
{
    [super setText:string];
    [self setNeedsDisplay];
}


- (void)textChanged:(NSNotification *)notificaiton 
{
    [self setNeedsDisplay];    
}

@end
