//
//  BWWifiConnection.m
//  bluewoki
//
//  Created by Adrian on 9/14/11.
//  Copyright 2011 akosma software. All rights reserved.
//

#import "BWWifiConnection.h"
#import "BWPeerService.h"
#import "BWPeerProxy.h"

@interface BWWifiConnection ()

@property (nonatomic, retain) BWPeerService *service;
@property (nonatomic, retain) BWPeerProxy *peerProxy;

- (void)startChatWithPeerID:(NSString *)peerID;

@end


@implementation BWWifiConnection

@synthesize service = _service;
@synthesize peerProxy = _peerProxy;

- (void)dealloc
{
    [_service release];
    [_peerProxy release];
    [super dealloc];
}

#pragma mark - Public methods

- (void)connect
{
    [GKVoiceChatService defaultVoiceChatService].client = self;

    self.service = [[[BWPeerService alloc] init] autorelease];
    self.service.delegate = self;
    [self.service startService];
}

- (void)disconnect
{
    [super disconnect];
    [self.service stopService];
}

#pragma mark - GKPeerPickerControllerDelegate methods

- (void)peerPickerController:(GKPeerPickerController *)picker 
              didConnectPeer:(NSString *)peerID
                   toSession:(GKSession *)session 
{
    self.chatSession = session;
    self.chatSession.delegate = self;
    
    picker.delegate = nil;
    [picker dismiss];
    
    [self startChatWithPeerID:peerID];
}

#pragma mark - GKSessionDelegate methods

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
    if (session == self.chatSession)
    {
        [self.chatSession acceptConnectionFromPeer:peerID 
                                             error:nil];
        [self.chatSession connectToPeer:peerID withTimeout:60];
    }
}

- (void)session:(GKSession *)session 
           peer:(NSString *)peerID
 didChangeState:(GKPeerConnectionState)state
{
    if (session == self.chatSession)
    {
        switch (state) 
        {
            case GKPeerStateAvailable:
                break;
                
            case GKPeerStateUnavailable:
                break;
                
            case GKPeerStateConnected:
            {
                [self startChatWithPeerID:peerID];
                break;
            }
                
            case GKPeerStateDisconnected:
            {
                break;
            }
                
            case GKPeerStateConnecting:
            {
                break;
            }
                
            default:
                break;
        }
    }
}

-          (void)session:(GKSession *)session 
connectionWithPeerFailed:(NSString *)peerID
               withError:(NSError *)error
{
    if (session == self.chatSession)
    {
    }
}

#pragma mark - GKVoiceChatClient methods

- (void)voiceChatService:(GKVoiceChatService *)voiceChatService
didStopWithParticipantID:(NSString *)participantID
                   error:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(connectionDidDisconnect:)])
    {
        [self.delegate connectionDidDisconnect:self];
    }
}

-  (void)voiceChatService:(GKVoiceChatService *)voiceChatService 
didStartWithParticipantID:(NSString *)participantID
{
}

#pragma mark - BWPeerServiceDelegate methods

- (void)peerService:(BWPeerService *)service didReceiveCallRequestFromPeer:(NSString *)peerID
{
    if (service == self.service)
    {
    }
}

#pragma mark - BWBrowserControllerDelegate methods

- (void)peersBrowserController:(BWBrowserController *)controller didSelectPeer:(BWPeerProxy *)peer
{
    self.peerProxy = peer;
    self.peerProxy.delegate = self;
    [self.peerProxy connect];
    if ([self.delegate respondsToSelector:@selector(connectionIsConnecting:)])
    {
        [self.delegate connectionIsConnecting:self];
    }
}

#pragma mark - PeerProxyDelegate methods

- (void)proxyDidConnect:(BWPeerProxy *)proxy
{
    if (proxy == self.peerProxy)
    {
        self.peerProxy.chatSession = self.chatSession;
        [self.peerProxy sendVoiceCallRequest];
    }
}

- (void)proxy:(BWPeerProxy *)proxy didReceiveCallRequestFromPeer:(NSString *)peerID;
{
    if (proxy == self.peerProxy)
    {
        NSString *sessionId = @"bluewoki";
        NSString *name = [[UIDevice currentDevice] name];
        GKSession* session = [[[GKSession alloc] initWithSessionID:sessionId 
                                                       displayName:name 
                                                       sessionMode:GKSessionModePeer] autorelease];
        self.chatSession = session;
        self.chatSession.delegate = self;
        self.peerProxy.chatSession = self.chatSession;

        if ([self.delegate respondsToSelector:@selector(connectionIsConnecting:)])
        {
            [self.delegate connectionIsConnecting:self];
        }
        [self.chatSession connectToPeer:peerID withTimeout:60];
    }
}

#pragma mark - Private methods

- (void)startChatWithPeerID:(NSString *)peerID
{
    self.otherPeerID = peerID;
    [[GKVoiceChatService defaultVoiceChatService] startVoiceChatWithParticipantID:self.otherPeerID 
                                                                            error:nil];
}

@end
