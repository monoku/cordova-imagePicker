//
//  ELCAssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"

@interface ELCAssetTablePicker ()

@property (nonatomic, strong) ALAssetsLibrary *library;
@property (nonatomic, assign) int columns;

@end

@implementation ELCAssetTablePicker

//Using auto synthesizers

- (id)init
{
    self = [super init];
    if (self) {
        //Sets a reasonable default bigger then 0 for columns
        //So that we don't have a divide by 0 scenario
        self.columns = 4;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self.navigationItem setTitle:@"Loading..."];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.03921568627 green:0.03921568627 blue:0.03921568627 alpha:1];
    
    self.navigationController.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                   [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                                   [UIFont fontWithName:@"HelveticaNeue" size:13.0], NSFontAttributeName, nil];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 30, 30);
    UIImage *imgClose = [[UIImage imageNamed:@"close.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [btn setImage:imgClose forState:UIControlStateNormal];
    [btn addTarget:self.parent action:@selector(cancelImagePicker) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithCustomView:btn];
    
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
  [self.tableView setAllowsSelection:NO];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    self.elcAssets = tempArray;
  
//    UIView *footerContainer = [[UIView alloc]initWithFrame:CGRectMake(0,0, 300, 80)];
//    
//    UIButton *doneButtonItem = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    doneButtonItem.frame = CGRectMake(10,10, 300, 40);
//    [doneButtonItem setTitle:@"Calibration" forState:UIControlStateNormal];
//    [doneButtonItem addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
//    [footerContainer addSubview:doneButtonItem];
//    
//    self.tableView.tableFooterView = footerContainer;
    if (self.immediateReturn) {
        
    } else {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
////        [self.navigationItem setTitle:@"LOADING..."];
    }

//    UIView *barBottom = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 103, [UIScreen mainScreen].bounds.size.width, 103)];
//    [barBottom setBackgroundColor:[UIColor colorWithRed:0.1294117647 green:0.1294117647 blue:0.1294117647 alpha:1]];
//
//    [self.view addSubview:barBottom];
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetLibrary;
    self.foundGroup = NO;
    self.firstFound = Nil;
    
    if(self.assetGroup){
        [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
    }else{
        // Load Albums into assetGroups
        dispatch_async(dispatch_get_main_queue(), ^
               {
                   @autoreleasepool {
                       
                       // Group enumerator Block
                       void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
                       {
                           if (self.foundGroup) {
                               return;
                           }
                           
                           // added fix for camera albums order
                           NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
                           NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                           NSString *lowerCaseName = [sGroupPropertyName lowercaseString];
                           
                           if (([lowerCaseName isEqualToString:@"camera roll"] || [lowerCaseName isEqualToString:@"all photos"])
                               && nType == ALAssetsGroupSavedPhotos) {
                               self.foundGroup = YES;
                               self.assetGroup = group;
                               [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
                           } else {
                               if( group ){
                                   if( !self.firstFound ){
                                       self.firstFound = group;
                                   }
                               } else {
                                   self.assetGroup = self.firstFound;
                                   [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
                               }
                           }
                       };
                       
                       // Group Enumerator Failure Block
                       void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                           
                           UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                           [alert show];
                           
                           NSLog(@"A problem occured %@", [error description]);
                       };
                       
                       // Enumerate Albums
                       [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                                   usingBlock:assetGroupEnumerator
                                                 failureBlock:assetGroupEnumberatorFailure];
                       
                   }
               });

    }
    
}

- (void)cancelImagePicker
{
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.columns = self.view.bounds.size.width / 80;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.columns = self.view.bounds.size.width / 80;
    [self.tableView reloadData];
}

- (void)preparePhotos
{
    @autoreleasepool {
        [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            
            if (result == nil) {
                return;
            }
            
            ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
            [elcAsset setParent:self];
            
            BOOL isAssetFiltered = NO;
            if (self.assetPickerFilterDelegate &&
               [self.assetPickerFilterDelegate respondsToSelector:@selector(assetTablePicker:isAssetFilteredOut:)])
            {
                isAssetFiltered = [self.assetPickerFilterDelegate assetTablePicker:self isAssetFilteredOut:(ELCAsset*)elcAsset];
            }

            if (!isAssetFiltered) {
                [self.elcAssets addObject:elcAsset];
            }

         }];

        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            // scroll to bottom
            long section = [self numberOfSectionsInTableView:self.tableView] - 1;
            long row = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
            if (section >= 0 && row >= 0) {
                NSIndexPath *ip = [NSIndexPath indexPathForRow:row
                                                     inSection:section];
                        [self.tableView scrollToRowAtIndexPath:ip
                                              atScrollPosition:UITableViewScrollPositionBottom
                                                      animated:NO];
            }
            
//            [self.navigationItem setTitle:self.singleSelection ? @"PICK PHOTO" : @"PICK PHOTOS"];
            
            UIButton *titleLabelButton = [UIButton buttonWithType:UIButtonTypeCustom];
            NSString *sGroupPropertyName = (NSString *)[self.assetGroup valueForProperty:ALAssetsGroupPropertyName];
            
            [titleLabelButton setTitle:sGroupPropertyName forState:UIControlStateNormal];
            titleLabelButton.frame = CGRectMake(0, 0, 70, 44);
//            titleLabelButton.font = [UIFont boldSystemFontOfSize:16];
            [titleLabelButton addTarget:self action:@selector(didTapTitleView:) forControlEvents:UIControlEventTouchUpInside];
            self.navigationItem.titleView = titleLabelButton;
        });
    }
}

- (IBAction)didTapTitleView:(id) sender{
//    NSLog(@"GONNA SHOW ALBUMPICKER");
    // Create the an album controller and image picker
    ELCAlbumPickerController *albumController = [[ELCAlbumPickerController alloc] init];

    albumController.immediateReturn = false;
    albumController.singleSelection = false;
    
    [albumController setImagePickerParent:self];
//    NSLog(@"GONNA SHOW ALBUMPICKER x 2");
    [UIView animateWithDuration:0.4
                     animations:^{
                         [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                         [self.navigationController pushViewController:albumController animated:NO];
                         [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
                     }];
    // TODO SHOOOOOWWWW
}

- (void)assignAssetGroupName:(NSString*)name{
        if([[self.assetGroup valueForProperty:ALAssetsGroupPropertyName] isEqualToString:name]){
            return;
        }
    
        ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
        self.library = assetLibrary;
    
        // Load Albums into assetGroups
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           @autoreleasepool {

                               // Group enumerator Block
                               void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
                               {
                                   if (group == nil) {
                                       return;
                                   }
    
                                   // added fix for camera albums order
                                   NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
    
                                   if ([sGroupPropertyName isEqualToString:name]) {
                                       [self assignAssetGroup:group];
                                   }
                               };
    
                               // Group Enumerator Failure Block
                               void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
    
                                   UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                                   [alert show];
    
                                   NSLog(@"A problem occured %@", [error description]);
                               };
    
                               // Enumerate Albums
                               [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                                           usingBlock:assetGroupEnumerator
                                                         failureBlock:assetGroupEnumberatorFailure];
                               
                           }
                       });
}
- (void)assignAssetGroup:(ALAssetsGroup*)assetGroup{
//    self.tableView.contentOffset = CGPointMake(0, 0 - self.tableView.contentInset.top);
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    //    [self.elcAssets removeAllObjects];
    if([self.elcAssets count] > 0){
        while([self.elcAssets count] > 0)
        {
//            NSLog(@"LENNN %ld",(long)[self.elcAssets count]);
            [self.elcAssets removeLastObject];
        }
    }
//    NSLog(@"RECEIVED NEW GROUUUPFF %@", [assetGroup valueForProperty:ALAssetsGroupPropertyName]);
    [self.tableView reloadData];
    self.assetGroup = assetGroup;
    [self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

//    [self.assetGroups removeAllObjects];
//    NSLog(@"CLEAR!!!!");
//    
//    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
//    self.library = assetLibrary;
//    
//    // Load Albums into assetGroups
//    dispatch_async(dispatch_get_main_queue(), ^
//                   {
//                       @autoreleasepool {
//                           
//                           // Group enumerator Block
//                           void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop)
//                           {
//                               if (group == nil) {
//                                   return;
//                               }
//                               
//                               // added fix for camera albums order
//                               NSString *sGroupPropertyName = (NSString *)[group valueForProperty:ALAssetsGroupPropertyName];
//                               NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
//                               
//                               if ([[sGroupPropertyName lowercaseString] isEqualToString:@"camera roll"] && nType == ALAssetsGroupSavedPhotos) {
//                                   [self.assetGroups insertObject:group atIndex:0];
//                               }
//                               else {
//                                   [self.assetGroups addObject:group];
//                               }
//                               
//                               // Reload albums
////                               [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];
//                               NSLog(@"ADDED!!!! %@",group);
//                               
//                               //                if(!self.ready){
//                               //                    self.ready = YES;
//                               //                }
//                           };
//                           
//                           // Group Enumerator Failure Block
//                           void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
//                               
//                               UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Album Error: %@ - %@", [error localizedDescription], [error localizedRecoverySuggestion]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
//                               [alert show];
//                               
//                               NSLog(@"A problem occured %@", [error description]);                                  
//                           }; 
//                           
//                           // Enumerate Albums
//                           [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
//                                                       usingBlock:assetGroupEnumerator
//                                                     failureBlock:assetGroupEnumberatorFailure];
//                           
//                       }
//                   });
//}

- (void)doneAction:(id)sender
{ 
  NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];
      
  for (ELCAsset *elcAsset in self.elcAssets) {
    if ([elcAsset selected]) {
      [selectedAssetsImages addObject:[elcAsset asset]];
    }
  }
    [self.parent selectedAssets:selectedAssetsImages];
}


- (BOOL)shouldSelectAsset:(ELCAsset *)asset
{
    NSUInteger selectionCount = 0;
    for (ELCAsset *elcAsset in self.elcAssets) {
        if (elcAsset.selected) selectionCount++;
    }
    BOOL shouldSelect = YES;
    if ([self.parent respondsToSelector:@selector(shouldSelectAsset:previousCount:)]) {
        shouldSelect = [self.parent shouldSelectAsset:asset previousCount:selectionCount];
    }
    return shouldSelect;
}

- (void)assetSelected:(ELCAsset *)asset
{
    if (self.singleSelection) {

        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset.asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
}

#pragma mark UITableViewDataSource Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.columns <= 0) { //Sometimes called before we know how many columns we have
        self.columns = 4;
    }
    NSInteger numRows = ceil([self.elcAssets count] / (float)self.columns);
    return numRows;
}

- (NSArray *)assetsForIndexPath:(NSIndexPath *)path
{
    long index = path.row * self.columns;
    long length = MIN(self.columns, [self.elcAssets count] - index);
    return [self.elcAssets subarrayWithRange:NSMakeRange(index, length)];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    static NSString *CellIdentifier = @"Cell";
        
    ELCAssetCell *cell = (ELCAssetCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {            
        cell = [[ELCAssetCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [cell setAssets:[self assetsForIndexPath:indexPath]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 79;
}

- (int)totalSelectedAssets
{
    int count = 0;
    
    for (ELCAsset *asset in self.elcAssets) {
    if (asset.selected) {
            count++;  
    }
  }
    
    return count;
}


@end
