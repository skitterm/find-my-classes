//
//  BuildingsTVC.m
//  FindMyClasses
//
//  Created by Student on 11/21/13.
//  Copyright (c) 2013 Student. All rights reserved.
//

#import "BuildingsTVC.h"
#import "Building.h"
#import "MapVC.h"

@interface BuildingsTVC ()

@property (strong, nonatomic) NSArray *buildings;

@property (strong, nonatomic) AGSFeatureLayer *layer;

@end

@implementation BuildingsTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSArray *)buildings {
    if (!_buildings) {
        _buildings = [[NSArray alloc] init];
    }
    return _buildings;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL *url = [NSURL URLWithString:@"http://services1.arcgis.com/NJwGfMFyNOx11mNU/arcgis/rest/services/Buildings/FeatureServer/0"];
    self.layer = [AGSFeatureLayer featureServiceLayerWithURL:url mode:AGSFeatureLayerModeOnDemand];

    self.layer.delegate = self;
    
    self.layer.queryDelegate = self;
    
    AGSQuery *query = [AGSQuery query];
    
    //query all records (anything with an FID)
    query.where = [NSString stringWithFormat:@"FID > -1"];
    query.outFields = [NSArray arrayWithObjects:@"FID", @"Abbr", @"Name", nil];
    query.orderByFields = @[@"Abbr ASC"];
    
    AGSSimpleMarkerSymbol *selectedBuildingSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
    selectedBuildingSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    selectedBuildingSymbol.color = [UIColor greenColor];
    selectedBuildingSymbol.size = CGSizeMake(20,20);
    
    [self.layer selectFeaturesWithQuery:query selectionMethod:AGSFeatureLayerSelectionMethodNew];
    
}


- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didSelectFeaturesWithFeatureSet:(AGSFeatureSet *)featureSet {
    
    NSMutableArray *buildingsTemp = [[NSMutableArray alloc] init];
    
    for (AGSGraphic *selectedFeature in featureSet.features) {
        Building *building = [[Building alloc] init];
        building.fid = [[selectedFeature attributeForKey:@"FID"] integerValue];
        building.abbreviation = [selectedFeature attributeAsStringForKey:@"Abbr"];
        building.fullName = (NSString *)[selectedFeature attributeForKey:@"Name"];
        [buildingsTemp addObject:building];
    }
    self.buildings = [NSArray arrayWithArray:buildingsTemp];
    [self.tableView reloadData];
    
}

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFailSelectFeaturesWithError:(NSError *)error {
    NSLog(@"Query Failed.");
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (Building *)BuildingForRow:(NSInteger)row {
    Building *building = (Building *)self.buildings[row];
    return building;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    MapVC *mapVc = (MapVC *)segue.destinationViewController;
    UITableViewCell *tableCell = (UITableViewCell *)sender;
    mapVc.bldgName = tableCell.textLabel.text;
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.buildings count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"bldg";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    Building *bld = [self BuildingForRow:indexPath.row];
    cell.textLabel.text = bld.abbreviation;
    cell.detailTextLabel.text = bld.fullName;
    
    return cell;
}


@end
