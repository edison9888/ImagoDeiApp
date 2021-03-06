//
//  ImagoDeiDataFetcher.m
//  ImagoDei
//
//  Created by Will Hindenburg on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImagoDeiDataFetcher.h"
#import "XMLReader.h"

@implementation ImagoDeiDataFetcher

+ (NSDictionary *)DictionaryForMainPageTab
{
    return nil;
}

+ (NSArray *)ArrayForPlanningCenterDataWithAuthenticationData:(GTMOAuthAuthentication *)auth;
{
    NSArray *tmpArray = [[NSArray alloc] init];
    NSString *futurePlansURL = @"https://www.planningcenteronline.com/me/future_plans.xml";
    NSMutableURLRequest *xmlURLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:futurePlansURL]];
    [auth authorizeRequest:xmlURLRequest];
    NSDictionary *futurePlansDictionary = [self DictionaryOfXMLDataForURL:xmlURLRequest];
    if (futurePlansDictionary)
    {
        id futurePlans = [futurePlansDictionary valueForKeyPath:@"plans.plan"];
        if ([futurePlans isKindOfClass:[NSDictionary class]])
        {
            tmpArray = [tmpArray arrayByAddingObject:futurePlans];
        }
        else if ([futurePlans isKindOfClass:[NSArray class]]) 
        {
            tmpArray = [tmpArray arrayByAddingObjectsFromArray:futurePlans];
        }
    }
    
    NSMutableArray *mutableArray = [tmpArray mutableCopy];
    for (int x = 0; x < [mutableArray count]; x++)
    {
        id items = [mutableArray objectAtIndex:x];
        id planPerson = [items valueForKeyPath:@"my-plan-people.my-plan-person"];
        if ([planPerson isKindOfClass:[NSArray class]])
        {
            if ([items isKindOfClass:[NSMutableDictionary class]])
            {
                [mutableArray removeObjectAtIndex:x];
                NSMutableDictionary *myPlanPerson = nil;
                for (int i = 0; i < [planPerson count]; i++)
                {
                    myPlanPerson = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[planPerson objectAtIndex:i], @"my-plan-person", nil];
                    NSMutableDictionary *tmpItems = [items mutableCopy];
                    [tmpItems setObject:myPlanPerson forKey:@"my-plan-people"];
                    [mutableArray insertObject:tmpItems atIndex:x];
                }
            }
        }
    }
    return mutableArray;
}

+ (NSDictionary *)DictionaryOfXMLDataForURL:(NSMutableURLRequest *)url
{
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *response;
    NSData *xmlData = [NSURLConnection sendSynchronousRequest:url returningResponse:&response error:&error];
    NSDictionary *xmlDictionary = nil;
    if (!xmlData)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ImagoDei" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
            [alertView show];
        });
    }
    else
    {
        xmlDictionary = [XMLReader dictionaryForXMLData:xmlData error:nil];
        if (!xmlDictionary)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"ImagoDei" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil];
                [alertView show];
            });
        }
    }
    return xmlDictionary;
}

@end
