//
//  FacebookSocialMediaViewController.m
//  ImagoDei
//
//  Created by Will Hindenburg on 4/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacebookSocialMediaViewController.h"
#import "ImagoDeiAppDelegate.h"
#import "Facebook.h"

@interface FacebookSocialMediaViewController ()
@property (nonatomic, strong) FBRequest *facebookRequest;

- (void)facebookInit;
@end

@implementation FacebookSocialMediaViewController
@synthesize facebook = _facebook;
@synthesize facebookRequest = _facebookRequest;

#define FACEBOOK_CONTENT_TITLE @"message"
#define FACEBOOK_CONTENT_DESCRIPTION @"from.name"
#define FACEBOOK_FONT_SIZE 18.0

- (IBAction)LogOutInButtonClicked:(id)sender 
{
    UIBarButtonItem *barButton = nil;
    
    //Verify that object that was clicked was a UIBarButtonItem
    if ([sender isKindOfClass:[UIBarButtonItem class]])
    {
        //If it was, then assign barButton to sender
        barButton = sender;
    }
    //If not return without any action
    else return;
    
    //If the barbutton says Log Out, tell the facebook app to logout
    //and set the title of the button to Log In
    if ([barButton.title isEqualToString: @"Log Out"])
    {
        [self.facebook logout];
        barButton.title = @"Log In";
    }
    //If the barbutton says Log In, check if the facebook session is still valid
    else if ([barButton.title isEqualToString: @"Log In"])
    {
        //If it is not valid, reauthorize the app for single sign on
        if (![self.facebook isSessionValid]) 
        {
            [self.facebook authorize:nil];
        }
    }
}

#pragma mark - View Lifecycle

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.tabBarItem setFinishedSelectedImage:[UIImage imageNamed:@"fb-logo-active.png"] withFinishedUnselectedImage:[UIImage imageNamed:@"fb-logo-inactive.png"]];
    self.tabBarItem.title = @"Facebook";
    
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
}

- (void)viewDidDisappear:(BOOL)animated
{
    //When the view disappears the code in this fucnction removes all delegation to this class
    //and it stops the loading
    
    //This is required incase a connection request is in progress when the view disappears
    [self.facebookRequest setDelegate:nil];
    
    //This is required incase a facebook method completes after the view has disappered
    ImagoDeiAppDelegate *appDelegate = (ImagoDeiAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.facebook.sessionDelegate = nil;
    
    //Super method
    [super viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.arrayOfTableData count] > 0) return;
    //Init the facebook session
    [self facebookInit];
    
    //If the facebook session is already valid, the barButtonItem will be change to say "Log Out"
    if ([self.facebook isSessionValid]) 
    {
        self.navigationItem.leftBarButtonItem.title = @"Log Out";
    }
    
    //Help to verify small data requirement
    NSLog(@"Loading Web Data - Social Media View Controller");
    
    //Begin the facebook request, the data that comes back form this method will be used
    //to populate the UITableView
    [self.facebook requestWithGraphPath:@"ImagoDeiChurch/posts" andDelegate:self];
}

#pragma mark - Table view data source

- (NSString *)keyForMainCellLabelText
{
    return FACEBOOK_CONTENT_TITLE;
}

- (NSString *)keyForDetailCellLabelText
{
    return FACEBOOK_CONTENT_DESCRIPTION;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Set the cell identifier to the same as the prototype cell in the story board
    static NSString *CellIdentifier = @"Main Page Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    UITextView *textView = nil;
    
    //If there is no reusable cell of this type, create a new one
    if (!cell)
    {
        //Set the atributes of the main page cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor colorWithRed:0.29803 green:0.1529 blue:0.0039 alpha:1];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.2666 green:0.2666 blue:0.2666 alpha:1];
        textView = [[UITextView alloc] initWithFrame:CGRectZero];
        textView.font = [UIFont systemFontOfSize:FACEBOOK_FONT_SIZE];
        textView.scrollEnabled = NO;
        textView.editable = NO;
        textView.tag = 1;
        textView.dataDetectorTypes = UIDataDetectorTypeLink;
        textView.backgroundColor = [UIColor clearColor];
        [cell.contentView addSubview:textView];
    }
    else 
    {
        textView = (UITextView *)[cell.contentView viewWithTag:1];
    }
    
    //Retrieve the corresponding dictionary to the index row requested
    NSDictionary *dictionaryForCell = [self.arrayOfTableData objectAtIndex:[indexPath row]];
    
    //Pull the main and detail text label out of the corresponding dictionary
    NSString *mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForMainCellLabelText]];
    
    if (mainTextLabel == nil)
    {
        mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForDetailCellLabelText]];
    }
    
    //Set the cell text label's based upon the table contents array location
    textView.text = mainTextLabel;
    
    CGSize maxSize = CGSizeMake(320 - FACEBOOK_FONT_SIZE, CGFLOAT_MAX);
    CGSize size = [mainTextLabel sizeWithFont:[UIFont systemFontOfSize:FACEBOOK_FONT_SIZE]  constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    textView.frame = CGRectMake(0, 0, 320, size.height + (FACEBOOK_FONT_SIZE));    
    
    return cell;
}


#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Retrieve the corresponding dictionary to the index row requested
    NSDictionary *dictionaryForCell = [self.arrayOfTableData objectAtIndex:[indexPath row]];
    
    //Pull the main and detail text label out of the corresponding dictionary
    NSString *mainTextLabel = [dictionaryForCell valueForKey:[self keyForMainCellLabelText]];
    
    if (mainTextLabel == nil)
    {
        mainTextLabel = [dictionaryForCell valueForKeyPath:[self keyForDetailCellLabelText]];
    }
    
    CGSize maxSize = CGSizeMake(320 - FACEBOOK_FONT_SIZE, CGFLOAT_MAX);
    CGSize size = [mainTextLabel sizeWithFont:[UIFont systemFontOfSize:FACEBOOK_FONT_SIZE]  constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    
    return size.height + FACEBOOK_FONT_SIZE;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"Cell Push" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //If the sender for the seque is not a Cell, return
    if (![sender isKindOfClass:[UITableViewCell class]]) return;
    
    //Set the sender to a UITableViewCell
    UITableViewCell *cell = sender;
    
    //Retrieve index path for cell
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    //Retrieve the corresponding dictionary to the index row selected
    NSDictionary *tmpDictionary = [[NSDictionary alloc] initWithDictionary:[self.arrayOfTableData objectAtIndex:[indexPath row]]];
    
    //Set the model for the MVC we are about to push onto the stack
    [segue.destinationViewController setShortCommentsDictionaryModel:tmpDictionary];
    
    //Set the delegate of the social media detail controller to this class
    [segue.destinationViewController setSocialMediaDelegate:self];
}

#pragma mark - SocialMediaDetailView datasource

- (void)SocialMediaDetailViewController:(SocialMediaDetailViewController *)sender dictionaryForFacebookGraphAPIString:(NSString *)facebookGraphAPIString
{
    NSLog(@"Loading Web Data - Social Media View Controller");
    
    //When the SocialMediaDetailViewController needs further information from
    //the facebook class, this method is called
    [self.facebook requestWithGraphPath:facebookGraphAPIString andDelegate:sender];
}

#pragma mark - Facebook Initialization Method

- (void)facebookInit
{
    //Retrieve a pointer to the appDelegate
    ImagoDeiAppDelegate *appDelegate = (ImagoDeiAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Set the local facebook property to point to the appDelegate facebook property
    self.facebook = appDelegate.facebook;
    
    //Set the facebook session delegate to this class
    self.facebook.sessionDelegate = self;
    
    //Retrieve the user defaults and store them in a variable
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //If the User defaults contain the facebook access tokens, save them into the
    //facebook instance
    if ([defaults objectForKey:@"FBAccessTokenKey"] 
        && [defaults objectForKey:@"FBExpirationDateKey"]) 
    {
        self.facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
        self.facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
    }
}

#pragma mark - Facebook Dialog Methods

- (IBAction)postToWall:(id)sender 
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   FACEBOOK_APP_ID, @"app_id",
                                   @"http://developers.facebook.com/docs/reference/dialogs/", @"link",
                                   @"http://fbrell.com/f8.jpg", @"picture",
                                   @"Facebook Dialogs", @"name",
                                   @"Reference Documentation", @"caption",
                                   @"Using Dialogs to interact with users.", @"description",
                                   nil];
    
    [self.facebook dialog:@"feed" andParams:params andDelegate:self];
}

#pragma mark - Facebook Request Delegate Methods

- (void)requestLoading:(FBRequest *)request
{
    //When a facebook request starts, save the request
    //so the delegate can be set to nill when the view disappears
    self.facebookRequest = request;
}

- (void)request:(FBRequest *)request didFailWithError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //Since the request has been recieved, and parsed, stop the Activity Indicator
        [self.activityIndicator stopAnimating];
        self.arrayOfTableData = nil;
        [self.tableView reloadData];
        [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
    });
    
}

- (void)request:(FBRequest *)request didLoad:(id)result
{
    //Since the facebook request is complete, and setting the delegate to nil
    //will not be required if the view disappears, set the request to nil
    self.facebookRequest = nil;
    
    //Verify the result from the facebook class is actually a dictionary
    if ([result isKindOfClass:[NSDictionary class]])
    {
        
        NSMutableArray *array = [result mutableArrayValueForKey:@"data"];
        NSDictionary *dictionaryForCell = nil;
        
        //Create an array of dictionaries, with each have an id, message, postedby, and comments key
        for (int i = 0; i < [array count]; i++) 
        {
            //Retrieve the corresponding dictionary to the index row requested
            dictionaryForCell = [array objectAtIndex:i];
            NSString *tmpString = [dictionaryForCell objectForKey:FACEBOOK_CONTENT_TITLE];
            if (tmpString == nil)
            {
                NSLog(@"%@", dictionaryForCell);
            }
        }
        //Set the property equal to the new comments array, which will then trigger a table reload
        self.arrayOfTableData = array;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //Since the request has been recieved, and parsed, stop the Activity Indicator
        [self.activityIndicator stopAnimating];
        
        //If an oldbutton was removed from the right bar button spot, put it back
        self.navigationItem.rightBarButtonItem = self.oldBarButtonItem;
        
        [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0];
    });
}


#pragma mark - Facebook Session Delegate Methods

- (void)fbDidLogin 
{
    //Since facebook had to log in, data will need to be requested, start the activity indicator
    [self.activityIndicator startAnimating];
    
    //Retireve the User Defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //Pull the accessToken, and expirationDate from the facebook instance, and
    //save them to the user defaults
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
    
    //Retrieve the left bar button item, and change the text to "Log Out"
    self.navigationItem.leftBarButtonItem.title = @"Log Out";
    
    //This method will request the full comments array from the delegate and
    //the facebook class will call request:request didLoad:result when complete
    [self.facebook requestWithGraphPath:@"ImagoDeiChurch/posts" andDelegate:self];
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
    //Do nothing here for now, stubbed out to get rid of compiler warning
}

- (void) fbDidLogout 
{
    // Remove saved authorization information if it exists
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt
{
    //Retrieve the user defaults, and save the new tokens
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

- (void)fbSessionInvalidated
{
    //Do nothing here for now, stubbed out to get rid of compiler warning
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)refresh {
    //This method will request the full comments array from the delegate and
    //the facebook class will call request:request didLoad:result when complete
    [self.facebook requestWithGraphPath:@"ImagoDeiChurch/posts" andDelegate:self];
}
@end
