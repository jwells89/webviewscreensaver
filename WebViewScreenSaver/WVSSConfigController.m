//
//  WVSSConfigController.m
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

#import "WVSSConfigController.h"
#import "WVSSAddress.h"
#import "WVSSAddressListFetcher.h"
#import "WVSSConfig.h"

#import <WebKit/WebKit.h>

static NSString *const kURLTableRow = @"WebViewScreenSaver.TableRow";
// Configuration sheet columns.
static NSString *const kTableColumnURL = @"url";
static NSString *const kTableColumnTime = @"time";

NS_ENUM(NSInteger, WVSSColumn){kWVSSColumnURL = 0, kWVSSColumnDuration = 1};

@interface WVSSConfigController () <WVSSAddressListFetcherDelegate>
@property(nonatomic, strong) WVSSConfig *config;
@end

@implementation WVSSConfigController

- (instancetype)initWithUserDefaults:(NSUserDefaults *)userDefaults {
  self = [super init];
  if (self) {
    self.config = [[WVSSConfig alloc] initWithUserDefaults:userDefaults];
    [self appendSampleAddressIfEmpty];

    // Fetch URLs if we're using the URLsURL.
    [self fetchAddresses];
  }
  return self;
}

- (void)synchronize {
  self.config.addressListURL = self.urlsURLField.stringValue;
  [self.config synchronize];
}

- (void)appendSampleAddressIfEmpty {
  if (!self.config.addresses.count) {
    [self appendAddress];
  }
}

- (NSArray *)addresses {
  return self.config.addresses;
}

- (void)appendAddress {
  WVSSAddress *address = [WVSSAddress defaultAddress];
  [self.config.addresses addObject:address];
  [self.urlTable reloadData];
}

- (void)removeAddressAtIndex:(NSInteger)index {
  [self.config.addresses removeObjectAtIndex:(NSUInteger)index];
  [self.urlTable reloadData];
}

- (void)fetchAddresses {
  if (!self.config.shouldFetchAddressList) return;

  NSString *addressFetchURL = self.config.addressListURL;
  if (!addressFetchURL.length) return;
  if (!([addressFetchURL hasPrefix:@"http://"] || [addressFetchURL hasPrefix:@"https://"])) return;

  WVSSAddressListFetcher *fetcher = [[WVSSAddressListFetcher alloc] initWithURL:addressFetchURL];
  fetcher.delegate = self;
}

#pragma mark - Actions

- (IBAction)addRow:(id)sender {
  [self appendAddress];
}

- (IBAction)removeRow:(id)sender {
  NSInteger row = [self.urlTable selectedRow];
  if (row != NSNotFound) {
    [self removeAddressAtIndex:row];
  }
}

- (IBAction)resetData:(id)sender {
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:@"Clear History"];
  [alert setInformativeText:@"Clears history, cookies, cache and more."];
  [alert setIcon:[NSImage imageNamed:NSImageNameCaution]];
  [alert addButtonWithTitle:@"Clear Data"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setAlertStyle:NSAlertStyleWarning];
  [alert beginSheetModalForWindow:self.sheet
                completionHandler:^(NSModalResponse returnCode) {
                  if (returnCode == NSAlertFirstButtonReturn) {
                    [self clearWebViewHistory];
                  }
                }];
}

- (void)clearWebViewHistory {
  NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
  NSDate *since = [NSDate dateWithTimeIntervalSince1970:0];
  [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes
                                             modifiedSince:since
                                         completionHandler:^{
                                           NSLog(@"Web cache cleared");
                                         }];
}

#pragma mark -

- (void)addressListFetcher:(WVSSAddressListFetcher *)fetcher didFailWithError:(NSError *)error {
}

- (void)addressListFetcher:(WVSSAddressListFetcher *)fetcher
        didFinishWithArray:(NSArray *)response {
  [self.config.addresses removeAllObjects];
  [self.config.addresses addObjectsFromArray:response];
  [self.urlTable reloadData];

  // TODO(altse): tell delegate that the URL list had had updated.
  //_currentIndex = -1;
  //[self loadNext:nil];
}

#pragma mark Bundle

- (NSArray *)bundleHTML {
  NSString *resourcePath = [[NSBundle bundleForClass:[self class]] resourcePath];
  NSError *error = nil;
  NSArray *bundleResourceContents =
      [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:&error];

  NSMutableArray *bundleURLs = [NSMutableArray array];
  for (NSString *filename in bundleResourceContents) {
    if ([[filename pathExtension] isEqual:@"html"]) {
      NSString *path = [resourcePath stringByAppendingPathComponent:filename];
      NSURL *urlForPath = [NSURL fileURLWithPath:path];
      WVSSAddress *address = [WVSSAddress addressWithURL:[urlForPath absoluteString] duration:180];
      [bundleURLs addObject:address];
    }
  }
  return [bundleURLs count] ? bundleURLs : nil;
}

#pragma mark - User Interface

- (NSWindow *)configureSheet {
  if (!self.sheet) {
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    if (![thisBundle loadNibNamed:@"ConfigureSheet" owner:self topLevelObjects:NULL]) {
      // NSLog(@"Unable to load configuration sheet");
    }

    // If there is a urlListURL.
    if (self.config.addressListURL.length) {
      self.urlsURLField.stringValue = self.config.addressListURL;
    } else {
      self.urlsURLField.stringValue = @"";
    }

    // URLs
    [self.urlTable setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [self.urlTable registerForDraggedTypes:[NSArray arrayWithObject:kURLTableRow]];

    [self.fetchURLCheckbox setIntegerValue:self.config.shouldFetchAddressList];
    [self.urlsURLField setEnabled:self.config.shouldFetchAddressList];
  }
  return self.sheet;
}

- (IBAction)dismissConfigSheet:(id)sender {
  [self synchronize];
  [self.delegate configController:self dismissConfigSheet:self.sheet];
}

#pragma mark NSTableView

- (NSView *)tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row {
  // In IB the tableColumn has the identifier set to the same string as the keys in our dictionary
  NSString *identifier = [tableColumn identifier];

  WVSSAddress *address = [self.config.addresses objectAtIndex:row];

  if ([identifier isEqual:kTableColumnURL]) {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    cellView.textField.stringValue = address.url;
    return cellView;
  } else if ([identifier isEqual:kTableColumnTime]) {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    cellView.textField.stringValue = [[NSNumber numberWithLong:address.duration] stringValue];
    return cellView;
  } else {
    NSAssert1(NO, @"Unhandled table column identifier %@", identifier);
  }
  return nil;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
  return [self.config.addresses count];
}

- (BOOL)canDragRowsWithIndexes:(NSIndexSet *)rowIndexes atPoint:(NSPoint)mouseDownPoint {
  return YES;
}

- (id<NSPasteboardWriting>)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row {
    NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
    [pasteboardItem setString:[@(row) stringValue] forType: kURLTableRow];
    
    return pasteboardItem;
}

- (NSDragOperation)tableView:(NSTableView *)tv
                validateDrop:(id)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)op {
    if (op == NSTableViewDropAbove) {
        return NSDragOperationMove;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)tableView:(NSTableView *)aTableView
       acceptDrop:(id)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)operation {
  NSPasteboardItem *pboardItem = [[[info draggingPasteboard] pasteboardItems] firstObject];
  NSString *rowString = [pboardItem stringForType: kURLTableRow];
    NSIndexSet *rowIndexes = [NSIndexSet indexSetWithIndex:[rowString integerValue]];
  NSInteger dragRow = [rowIndexes firstIndex];

  NSMutableArray *addresses = self.config.addresses;
  id draggedObject = [addresses objectAtIndex:dragRow];
  NSLog(@"draggedObject: %@", draggedObject);
  if (dragRow < row) {
    [addresses insertObject:draggedObject atIndex:row];
    [addresses removeObjectAtIndex:dragRow];
  } else {
    [addresses removeObjectAtIndex:dragRow];
    [addresses insertObject:draggedObject atIndex:row];
  }
    
    [aTableView beginUpdates];
    [aTableView moveRowAtIndex:rowIndexes.firstIndex toIndex:row];
    [aTableView endUpdates];
    
  return YES;
}

#pragma mark -

- (IBAction)tableViewCellDidEdit:(NSTextField *)textField {
  NSInteger col = [self.urlTable columnForView:textField];
  NSInteger row = [self.urlTable selectedRow];

  if (col == kWVSSColumnURL) {
    WVSSAddress *address = [self.config.addresses objectAtIndex:row];
    address.url = textField.stringValue;
  } else if (col == kWVSSColumnDuration) {
    WVSSAddress *address = [self.config.addresses objectAtIndex:row];
    address.duration = [textField.stringValue intValue];
  }
  // I don't think we need to reload the table.
  //    [self.urlTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
  //                             columnIndexes:[NSIndexSet indexSetWithIndex:col]];
}

- (IBAction)toggleFetchingURLs:(id)sender {
  BOOL currentValue = self.config.shouldFetchAddressList;
  self.config.shouldFetchAddressList = !currentValue;
  [self.fetchURLCheckbox setIntegerValue:self.config.shouldFetchAddressList];
  [self.urlsURLField setEnabled:self.config.shouldFetchAddressList];
}

@end
