//
//  MapVC.m
//  FindMyClasses
//
//  Created by Student on 11/23/13.
//  Copyright (c) 2013 Student. All rights reserved.
//

#import "MapVC.h"
#import "Building.h"
#import <ArcGIS/ArcGIS.h>
#import <UIKit/UIKit.h>

@interface MapVC () <AGSMapViewLayerDelegate, AGSFeatureLayerQueryDelegate, AGSLayerDelegate, AGSLocationDisplayDataSource, AGSLocationDisplayDataSourceDelegate>
@property (weak, nonatomic) IBOutlet AGSMapView *mapView;
@property (strong, nonatomic) AGSFeatureLayer *buildingLayer;
@property (strong, nonatomic) AGSPoint *userLocationPoint;
@property (strong, nonatomic) AGSGraphic *selectedPoint;

@end

@implementation MapVC

- (NSString *)bldgName {
    if (!_bldgName) {
        _bldgName = [[NSString alloc] init];
    }
    return _bldgName;
}


- (AGSPoint *)userLocationPoint {
    if (!_userLocationPoint) {
        _userLocationPoint = [[AGSPoint alloc] init];
    }
    return _userLocationPoint;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    AGSLocalTiledLayer *localLayer = [AGSLocalTiledLayer localTiledLayerWithName:@"whatdonenot-2.tpk"];
    [self.mapView addMapLayer:localLayer withName:@"Campus Basemap"];
    
    [self.mapView zoomToScale:25000 animated:NO];
    
    NSURL *url = [NSURL URLWithString:@"http://services1.arcgis.com/NJwGfMFyNOx11mNU/arcgis/rest/services/Buildings/FeatureServer/0"];
    self.buildingLayer = [AGSFeatureLayer featureServiceLayerWithURL:url mode:AGSFeatureLayerModeOnDemand];
    [self.mapView addMapLayer:self.buildingLayer withName:@"BYU Buildings"];
    
    
    NSURL *swktwallsurl = [NSURL URLWithString:@"http://services1.arcgis.com/NJwGfMFyNOx11mNU/arcgis/rest/services/swkt2walls/FeatureServer/0"];
    AGSFeatureLayer *swktWalls = [AGSFeatureLayer featureServiceLayerWithURL:swktwallsurl mode:AGSFeatureLayerModeOnDemand];
    [self.mapView addMapLayer:swktWalls withName:@"SWKT Walls"];
    
    NSURL *swktroomsurl = [NSURL URLWithString:@"http://services1.arcgis.com/NJwGfMFyNOx11mNU/arcgis/rest/services/swkt2Rooms/FeatureServer/0"];
    AGSFeatureLayer *swktRooms = [AGSFeatureLayer featureServiceLayerWithURL:swktroomsurl mode:AGSFeatureLayerModeOnDemand];
    [self.mapView addMapLayer:swktRooms withName:@"SWKT 2 Rooms"];
    
    
    self.mapView.layerDelegate = self;
    self.buildingLayer.delegate = self;

}

- (void)mapViewDidLoad:(AGSMapView *)mapView {
    //self.mapView.locationDisplay.dataSource = self;
    self.mapView.locationDisplay.dataSource.delegate = self;
    [self.mapView.locationDisplay startDataSource];
}

- (void)locationDisplayDataSourceStarted:(id<AGSLocationDisplayDataSource>)dataSource {
    
}

- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource didFailWithError:(NSError *)error {
    
}

- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource didUpdateWithHeading:(double)heading {
    
}

- (void)locationDisplayDataSource:(id<AGSLocationDisplayDataSource>)dataSource didUpdateWithLocation:(AGSLocation *)location {
    self.userLocationPoint = location.point;
}

- (void)locationDisplayDataSourceStopped:(id<AGSLocationDisplayDataSource>)dataSource {
    
}

- (void)layerDidLoad:(AGSLayer *)layer {
    
    self.buildingLayer.queryDelegate = self;
    
    AGSQuery *query = [AGSQuery query];
    query.where = [NSString stringWithFormat:@"Abbr = '%@'", self.bldgName];
    query.outFields = [NSArray arrayWithObjects:@"FID", @"Abbr", @"Name", nil];
    AGSSimpleMarkerSymbol *selectedBuildingSymbol = [AGSSimpleMarkerSymbol simpleMarkerSymbol];
    selectedBuildingSymbol.style = AGSSimpleMarkerSymbolStyleCircle;
    selectedBuildingSymbol.color = [UIColor greenColor];
    selectedBuildingSymbol.size = CGSizeMake(20,20);
    
    self.buildingLayer.selectionSymbol = selectedBuildingSymbol;
    
    
    [self.buildingLayer selectFeaturesWithQuery:query selectionMethod:AGSFeatureLayerSelectionMethodNew];

}


- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didSelectFeaturesWithFeatureSet:(AGSFeatureSet *)featureSet {
    for (AGSGraphic *selectedFeature in featureSet.features) {
        Building *building = [[Building alloc] init];
        building.fid = [[selectedFeature attributeForKey:@"FID"] integerValue];
        building.abbreviation = [selectedFeature attributeAsStringForKey:@"Abbr"];
        building.fullName = (NSString *)[selectedFeature attributeForKey:@"Name"];
    }
    
    NSArray *graphicSelected = featureLayer.selectedGraphics;
    
    //there should only be one result.
    self.selectedPoint = [graphicSelected objectAtIndex:0];
    
    
    AGSPoint *selectedPtMapUnits = (AGSPoint *)self.selectedPoint.geometry;
     NSString *decDe = [selectedPtMapUnits decimalDegreesStringWithNumDigits:5];
    AGSPoint *selectedPt = [AGSPoint pointFromDegreesMinutesSecondsString:decDe withSpatialReference:self.userLocationPoint.spatialReference];
    
    //[self.mapView centerAtPoint:selectedPt animated:YES];
    
    AGSMutableEnvelope *envelope = [[AGSMutableEnvelope alloc] init];
    
    double xMin = 0;
    double yMin = 0;
    double xMax = 0;
    double yMax = 0;
    
    //if selected point is less than user point,
    if (selectedPt.x < self.userLocationPoint.x) {
        xMin = selectedPt.x;
        xMax = self.userLocationPoint.x;
    } else {
        xMin = self.userLocationPoint.x;
        xMax = selectedPt.x;
    }
    
    if (selectedPt.y < self.userLocationPoint.y) {
        yMin = selectedPt.y;
        yMax = self.userLocationPoint.y;
    } else {
        yMin = self.userLocationPoint.y;
        yMax = selectedPt.y;
    }
    
    envelope = [envelope initWithXmin:xMin ymin:yMin xmax:xMax ymax:yMax spatialReference:selectedPt.spatialReference];
    [self.mapView zoomToGeometry:envelope withPadding:120 animated:YES];
}

- (void)featureLayer:(AGSFeatureLayer *)featureLayer operation:(NSOperation *)op didFailSelectFeaturesWithError:(NSError *)error {
    NSLog(@"Query Failed.");
}


@end
