//
//  ImagoDeiStandardTableViewController.m
//  ImagoDei
//
//  Created by Will Hindenburg on 5/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImagoDeiStandardTableViewController.h"
#import "ImagoDeiMediaController.h"
#import "WebViewController.h"

@interface ImagoDeiStandardTableViewController ()
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@end

@implementation ImagoDeiStandardTableViewController
@synthesize activityIndicator = _activityIndicator;
@synthesize urlForTableData = _urlForTableData;
@synthesize arrayOfTableData = _arrayOfTableData;

#define CONTENT_TITLE @"title"
#define CONTENT_DESCRIPTION @"description"
#define CONTENT_SMALL_PHOTO_URL @"smallphotourl"
#define CONTENT_UNIQUE_ID @"id"
#define CONTENT_URL_LINK @"link"

- (void)setUrlForTableData:(NSURL *)urlForTableData
{
    //If the URL is not a link to an RSS file do not load the data
    if (![[urlForTableData pathExtension] isEqualToString:@"rss"]) return;
    
    if (!_urlForTableData)
    {
        //initialize RSSParser class, send the RSS URL to the class,
        //and set the parser delegate to self
        RSSParser *parser = [[RSSParser alloc] init];
        [parser XMLFileToParseAtURL:urlForTableData withDelegate:self];
    }
    _urlForTableData = urlForTableData;
}

- (void)setArrayOfTableData:(NSArray *)arrayOfTableData
{
    _arrayOfTableData = arrayOfTableData;
    //Ensure that reloading of the tableview always happens on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)standardInitWithURL:(NSURL *)url
{
    //This class is a common function to initialize the class
    //from both a xib and non xib
    
    //Set the model equal to the URL based to the function
    self.urlForTableData = url;
    
    //Set the Imago Dei logo to the title view of the navigation controler
    //With the content mode set to AspectFit
    UIImage *logoImage = [UIImage imageNamed:@"imago-logo.png"];
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:logoImage];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = logoImageView;
    
    //Set the background of the ImagoDei app to the background image
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background.png"]];
    
    //initialize the activity indicator, set it to the center top of the view, and
    //start it animating
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.activityIndicator.hidesWhenStopped = YES;
    [self.activityIndicator startAnimating];
}

- (id)initWithModel:(NSURL *)model
{
    //Call the super classes initialization
    self = [super init];
    
    //Call the standard initialization
    [self standardInitWithURL:model];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    //Call the super classes view will appear method
    [super viewWillAppear:animated];
    
    //Set the navigation bar color to the standard color
    UIColor *standardColor = [UIColor colorWithRed:.7529 green:0.7372 blue:0.7019 alpha:1.0];
    [[[self navigationController] navigationBar] setTintColor:standardColor];
    
    //Create a small footerview so the UITableView lines do not show up
    //in blank cells
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.tableView.tableFooterView = view;
    
    //Set the right navigation bar button item to the activity indicator
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
}

- (void)RSSParser:(RSSParser *)sender RSSParsingCompleteWithArray:(NSArray *)RSSArray
{
    //This method is called when the RSSParsing class has downloaded, and completed
    //parsing of the provided RSS URL
    self.arrayOfTableData = RSSArray;
    
    //Since the RSS file has been loaded, stop animating the activity indicator
    [self.activityIndicator stopAnimating];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.arrayOfTableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Set the cell identifier to the same as the prototype cell in the story board
    static NSString *CellIdentifier = @"Main Page Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    
    //If there is no reusable cell of this type, create a new one
    if (!cell)
    {
        //Set the atributes of the main page cell
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor colorWithRed:0.29803 green:0.1529 blue:0.0039 alpha:1];
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.2666 green:0.2666 blue:0.2666 alpha:1];
    }
    
    //Set the cell text label's based upon the table contents array location
    cell.textLabel.text = [[self.arrayOfTableData objectAtIndex:[indexPath row]] valueForKey:CONTENT_TITLE];
    cell.detailTextLabel.text = [[self.arrayOfTableData objectAtIndex:[indexPath row]] valueForKey:CONTENT_DESCRIPTION];
    
    //Make sure that the imageview is set to nil when the cell is reused
    //this makes sure that the old image does not show up
    cell.imageView.image = nil;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Pull the URL from the selected tablecell, which is from the parsed RSS file with the key "link"
    NSURL *url = [[NSURL alloc] initWithString:[[self.arrayOfTableData objectAtIndex:indexPath.row] valueForKey:@"link"]];
    
    //Get the title for the next view from the selected tablecell, which is composed from the RSS file
    NSString *title = [[self.arrayOfTableData objectAtIndex:indexPath.row] valueForKey:@"title"];
    
    //Only perform actions on url if it is a valid URL
    if (url)
    {
        //If the URL is for an RSS file, initialize a mainpageviewcontroller with the URL
        //and set the title
        if ([[url pathExtension] isEqualToString:@"rss"])
        {
            ImagoDeiStandardTableViewController *idstvc = [[ImagoDeiStandardTableViewController alloc] initWithModel:url];
            idstvc.title = title;
            [self.navigationController pushViewController:idstvc animated:YES];
        }
        //If the URL is for an mp3 file, initialize a mediacontroller with the URL
        //and set the title
        else if ([[url pathExtension] isEqualToString:@"mp3"])
        {
            ImagoDeiMediaController *controller = [[ImagoDeiMediaController alloc] initImageoDeiMediaControllerWithURL:url];
            controller.title = title;
            [self.navigationController pushViewController:controller animated:YES];
        }
        //Catch all is to load a webview with the contents of the URL
        else 
        {
            WebViewController *wvc = [[WebViewController alloc] initWithToolbar:NO];
            [wvc setUrlToLoad:url];
            [wvc setTitleForWebView:title];
            [[self navigationController] pushViewController:wvc animated:YES];
        }
    }
}

@end