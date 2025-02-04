//
//  WVSSAddressFetcher.h
//  WebViewScreenSaver
//
//  Created by Alastair Tse on 26/04/2015.
//
//  Copyright 2015 Alastair Tse.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

@protocol WVSSAddressListFetcherDelegate;

@interface WVSSAddressListFetcher : NSObject <NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate>
@property(nonatomic, weak) id<WVSSAddressListFetcherDelegate> delegate;

- (id)initWithURL:(NSString *)url;
@end

@protocol WVSSAddressListFetcherDelegate <NSObject>
- (void)addressListFetcher:(WVSSAddressListFetcher *)fetcher
          didFailWithError:(NSError *)error;

- (void)addressListFetcher:(WVSSAddressListFetcher *)fetcher
        didFinishWithArray:(NSArray *)response;
@end
