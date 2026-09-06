/*
 * Stubbed macOS plugin for the vendored ffmpeg_kit_flutter_new_audio.
 *
 * DAW Project Manager never invokes ffmpeg-kit on macOS (that path uses
 * afconvert / a PATH ffmpeg instead), so this only has to provide the
 * FFmpegKitFlutterPlugin class that GeneratedPluginRegistrant.swift registers.
 * Every method channel call would raise FlutterMethodNotImplemented - nothing
 * on macOS makes one. No <ffmpegkit/...> import, so no framework is needed.
 */

#import "FFmpegKitFlutterPlugin.h"

static NSString *const METHOD_CHANNEL = @"flutter.arthenica.com/ffmpeg_kit";
static NSString *const EVENT_CHANNEL = @"flutter.arthenica.com/ffmpeg_kit_event";

@implementation FFmpegKitFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *methodChannel =
      [FlutterMethodChannel methodChannelWithName:METHOD_CHANNEL
                                  binaryMessenger:[registrar messenger]];
  FlutterEventChannel *eventChannel =
      [FlutterEventChannel eventChannelWithName:EVENT_CHANNEL
                               binaryMessenger:[registrar messenger]];

  FFmpegKitFlutterPlugin *instance = [[FFmpegKitFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:methodChannel];
  [eventChannel setStreamHandler:instance];
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  result(FlutterMethodNotImplemented);
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                      eventSink:(FlutterEventSink)events {
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  return nil;
}

@end
