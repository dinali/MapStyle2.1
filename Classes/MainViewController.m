// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//
#import "MainViewController.h"
#import "TOCViewController.h"
#import "LegendViewController.h"

@interface MainViewController()

@property (nonatomic, strong) TOCViewController *tocViewController;

@end

@implementation MainViewController

@synthesize mapView=_mapView;
@synthesize infoButton=_infoButton;
@synthesize legendButton = _legendButton;
@synthesize tocViewController = _tocViewController;
@synthesize popOverController = _popOverController;

#define kTiledLayerURL @"http://gis2.ers.usda.gov/ArcGIS/rest/services/Background_Cache/MapServer"
#define kDynamicMapServiceURL @"http://gis2.ers.usda.gov/ArcGIS/rest/services/snap_Benefits/MapServer"
#define kMapServiceURL @"http://gis2.ers.usda.gov/ArcGIS/rest/services/Reference2/MapServer" // states

- (void)viewDidLoad {
    [super viewDidLoad];    

    //create the toc view controller
    self.tocViewController = [[TOCViewController alloc] initWithMapView:self.mapView];
    
    // Calls method that adds the layer to the legend each time layer is loaded
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(respondToLayerLoaded:) name:AGSLayerDidLoadNotification object:nil];
	
    NSURL *mapUrl = [NSURL URLWithString:kTiledLayerURL];
	AGSTiledMapServiceLayer *tiledLyr = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:mapUrl];
	[self.mapView addMapLayer:tiledLyr withName:@"Base Map"];
    
    NSURL *stateMapUrl = [NSURL URLWithString:kMapServiceURL];
    AGSDynamicMapServiceLayer *dynamicLyr = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithURL:stateMapUrl];
    [self.mapView addMapLayer:dynamicLyr withName:@"States"];
    
    NSURL *mapUrl3 = [NSURL URLWithString:kDynamicMapServiceURL];
    
    NSError *error = nil;
    AGSMapServiceInfo *info = [AGSMapServiceInfo mapServiceInfoWithURL:mapUrl3 error:&error];
    
    AGSDynamicMapServiceLayer* layer = [AGSDynamicMapServiceLayer dynamicMapServiceLayerWithMapServiceInfo: info];
    
    // specifies which layer(s) are displayed on the map - this is different from what's displayed in the legend; without this code, nothing is displayed
    if(layer.loaded)
    {
        // only show the Xth layer
        layer.visibleLayers= [NSArray arrayWithObjects:[NSNumber numberWithInt:0], nil];
        layer.opacity = .8;
    } 
    
    [self.mapView addMapLayer:layer withName:@"Snap Benefits"];
    
    //Zooming to an initial envelope with the specified spatial reference of the map.
	AGSSpatialReference *sr = [AGSSpatialReference webMercatorSpatialReference];
	AGSEnvelope *env = [AGSEnvelope envelopeWithXmin:-14314526
                                                ymin:2616367
                                                xmax:-7186578
                                                ymax:6962565
									spatialReference:sr];
	[self.mapView zoomToEnvelope:env animated:NO];
    
    // current location marker
    [self.mapView.locationDisplay startDataSource];
    
	//A data source that will hold the legend items
	self.legendDataSource = [[LegendDataSource alloc] init];
	
	//Initialize the legend view controller
	//This will be displayed when user clicks on the info button
    
	self.legendViewController = [[LegendViewController alloc] initWithNibName:@"LegendViewController" bundle:nil];
	self.legendViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
	self.legendViewController.legendDataSource = self.legendDataSource;
}

#pragma mark -
#pragma mark AGSMapViewDelegate

- (void)respondToLayerLoaded:(NSNotification*)notification {
    
	//Add legend for each layer added to the map
	[self.legendDataSource addLegendForLayer:(AGSLayer *)notification.object];
}

- (void) mapViewDidLoad:(AGSMapView *) mapView {
    NSLog(@"loaded mapView");
}

#pragma mark - show the associated table view depending on which button was clicked

- (IBAction)presentTableOfContents:(id)sender
{
    //If iPad, show legend in the PopOver, else transition to the separate view controller
	if([[AGSDevice currentDevice] isIPad]) {
        if(!self.popOverController) {
            self.popOverController = [[UIPopoverController alloc] initWithContentViewController:self.tocViewController];
            self.tocViewController.popOverController = self.popOverController;
            self.popOverController.popoverContentSize = CGSizeMake(320, 500);
            self.popOverController.passthroughViews = [NSArray arrayWithObject:self.view];
        }        
		[self.popOverController presentPopoverFromRect:self.infoButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];		
	}
    else {
		[self presentModalViewController:self.tocViewController animated:YES];
	}    
}

- (IBAction) presentLegendViewController: (id) sender{
	//If iPad, show legend in the PopOver, else transition to the separate view controller
	if([[AGSDevice currentDevice] isIPad]){
        
        self.popOverController = [[UIPopoverController alloc]
								  initWithContentViewController:self.legendViewController];
		[self.popOverController setPopoverContentSize:CGSizeMake(250, 500)];
		self.popOverController.passthroughViews = [NSArray arrayWithObject:self.view];
		self.legendViewController.popOverController = self.popOverController;
        
		[_popOverController presentPopoverFromRect:self.legendButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES ];
		
	}else {
		[self presentModalViewController:self.legendViewController animated:YES];
	}
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {

    [self setLegendButton:nil];
    [super viewDidUnload];
	self.mapView = nil;
	self.infoButton = nil;
    self.tocViewController = nil;
    if([[AGSDevice currentDevice] isIPad])
        self.popOverController = nil;
}



@end
