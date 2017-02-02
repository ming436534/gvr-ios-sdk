#import "TreasureHuntViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "TreasureHuntRenderLoop.h"
#import "TreasureHuntRenderer.h"

@interface TreasureHuntViewController ()<TreasureHuntRendererDelegate> {
  GVRCardboardView *_cardboardView;
  TreasureHuntRenderer *_treasureHuntRenderer;
  TreasureHuntRenderLoop *_renderLoop;
}
@end

@implementation TreasureHuntViewController

- (void)loadView {
    
    
//    NSURL *videoURL = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
//    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
//    
//    UIView *playerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 300)];
//    player = [AVPlayer playerWithPlayerItem:playerItem];
//    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//    [playerLayer setFrame:[[playerView layer] bounds]];
    
    
    
    
//    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] init];
//    player.movieSourceType = MPMovieSourceTypeStreaming;
//    player.controlStyle =  MPMovieControlStyleNone;
//    player.shouldAutoplay = YES;
//    player.repeatMode = NO;
//    player.scalingMode = MPMovieScalingModeAspectFit;
//    player.view.backgroundColor = [UIColor redColor];
//    player.view.frame = CGRectMake(25, 25, 100, 100);
//    player.contentURL = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
//    [player prepareToPlay];

//    UIView *renderedView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 400, 300)];
//    [renderedView setBackgroundColor:[UIColor yellowColor]];
//    [renderedView addSubview:playerView];
//    [renderedView.layer addSublayer:playerLayer];
//    UITextView *textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
//    textView.text = @"hihi";
//    [renderedView addSubview:textView];
//    self.view = renderedView;
    
    _treasureHuntRenderer = [[TreasureHuntRenderer alloc] init];
  _treasureHuntRenderer.delegate = self;

  _cardboardView = [[GVRCardboardView alloc] initWithFrame:CGRectZero];
  _cardboardView.delegate = _treasureHuntRenderer;
  _cardboardView.autoresizingMask =
      UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

  _cardboardView.vrModeEnabled = YES;

  // Use double-tap gesture to toggle between VR and magic window mode.
  UITapGestureRecognizer *doubleTapGesture =
      [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapView:)];
  doubleTapGesture.numberOfTapsRequired = 2;
  [_cardboardView addGestureRecognizer:doubleTapGesture];

  self.view = _cardboardView;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
    
//    [player play];
  _renderLoop = [[TreasureHuntRenderLoop alloc] initWithRenderTarget:_cardboardView
                                                            selector:@selector(render)];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];

  // Invalidate the render loop so that it removes the strong reference to cardboardView.
  [_renderLoop invalidate];
  _renderLoop = nil;
}

- (GVRCardboardView *)getCardboardView {
  return _cardboardView;
}

#pragma mark - TreasureHuntRendererDelegate

- (void)shouldPauseRenderLoop:(BOOL)pause {
  _renderLoop.paused = pause;
}

#pragma mark - Implementation

- (void)didDoubleTapView:(id)sender {
  _cardboardView.vrModeEnabled = !_cardboardView.vrModeEnabled;
}

@end
