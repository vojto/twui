/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUITableViewController.h"

@interface TUITableViewController ()

@property (nonatomic, assign) TUITableViewStyle style;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) BOOL firstReload;

@end

@implementation TUITableViewController

- (id)init {
    return [self initWithStyle:TUITableViewStylePlain];
}

- (id)initWithStyle:(TUITableViewStyle)style {
    if((self = [super init])) {
        _style = style;
		_frame = CGRectZero;
    }
	
    return self;
}

- (id)initWithFrame:(CGRect)frame style:(TUITableViewStyle)style {
	if((self = [super init])) {
        _style = style;
		_frame = frame;
    }
	
	return self;
}

- (void)loadView {
    self.tableView = [[TUITableView alloc] initWithFrame:self.frame style:self.style];
	self.tableView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
	
	self.tableView.maintainContentOffsetAfterReload = YES;
	self.tableView.needsDisplayWhenWindowsKeyednessChanges = YES;
}

- (TUITableView *)tableView {
    return (TUITableView *)self.view;
}

- (void)setTableView:(TUITableView *)tableView {
    self.view = tableView;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
    if(!self.firstReload) {
        [self.tableView reloadData];
        self.firstReload = YES;
    }
    
    if(self.clearsSelectionOnViewWillAppear) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:animated];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	
    [self.tableView flashScrollIndicators];
}

- (NSInteger)tableView:(TUITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 44.0f;
}

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p | TUITableView = %@>", [self className], self, self.tableView];
}

@end
