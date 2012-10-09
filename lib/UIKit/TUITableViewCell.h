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

#import "TUIView.h"

typedef enum {
	
	// A basic table view cell.
	TUITableViewCellStyleDefault,
} TUITableViewCellStyle;

typedef enum {
	
	// The cell has no distinct seperator style.
	TUITableViewCellSeparatorStyleNone,
	
	// The cell has a single gray seperator line at its base.
	TUITableViewCellSeparatorStyleLine,
	
	// The cell has double lines running across its width,
	// giving it an etched or embossed look. The upper line
	// is white, while the lower line is gray.
	// This is the default value.
	TUITableViewCellSeparatorStyleEtched
} TUITableViewCellSeparatorStyle;

typedef enum {
	
	// The cell has no distinct style for when it is selected.
	TUITableViewCellSelectionStyleNone,
	
	// The cell, when selected has a blue background.
	TUITableViewCellSelectionStyleBlue,
	
	// The cell, when selected, has a gray background.
	TUITableViewCellSelectionStyleGray,
	
	// This coalesces the highlight color and the background color
	// of the cell to create an automatic selection color.
	// This is the default value.
	TUITableViewCellSelectionStyleAutomatic,
} TUITableViewCellSelectionStyle;

typedef enum {
	
	// The cell, when selected is drawn with a flat color background.
	TUITableViewCellDrawingStyleFlat = -1,
	
	// The cell, when selected, draws a gradiented background in an
	// angle provided. You may also provide a custom angle, by casting it
	// as a TUITableViewCellDrawingStyle, as long as it is between 0 and 360.
	// TUITableViewCellDrawingStyleGradientDown is the default value.
	TUITableViewCellDrawingStyleGradientLeft = 0,
	TUITableViewCellDrawingStyleGradientUp = 90,
	TUITableViewCellDrawingStyleGradientDown = 270,
	TUITableViewCellDrawingStyleGradientRight = 360,
} TUITableViewCellDrawingStyle;

@class TUITableView;

// The TUITableViewCell class defines the attributes and behavior of
// the cells that appear in TUITableViews. A table cell includes
// properties and methods for managing cell selection, highlighted
// state, and content indentation.
// It also has predefined cell styles that position elements of the
// cell in certain locations and with certain attributes. You can still
// extend the standard TUITableViewCell by adding subviews to it, or
// subclassing it to obtain custom cell characteristics and behavior.
// If you do wish to subclass TUITableViewCell, and want to implement
// custom drawing, call the super method drawRect: BEFORE your custom
// drawing, or your drawing may not appear on the cell.
@interface TUITableViewCell : TUIView

// The reuse identifier is associated with a TUITableViewCell that
// the table view’s delegate creates with the intent to reuse it as
// the basis for multiple rows of a table view. It is assigned to the
// cell object in initWithFrame:reuseIdentifier: and cannot be changed
// thereafter. A table view maintains a list of the currently reusable
// cells, each with its own reuse identifier, and makes them available
// to the delegate in the dequeueReusableCellWithIdentifier: method.
@property (nonatomic, copy, readonly) NSString *reuseIdentifier;

// A weak accessor to the table view this cell is currently managed by.
@property (nonatomic, assign, readonly) TUITableView *tableView;

// The current index path, if on screen, of this cell in the table view.
@property (nonatomic, strong, readonly) NSIndexPath *indexPath;

// The style of this cell. It cannot be changed after initialization.
@property (nonatomic, assign, readonly) TUITableViewCellStyle style;

// The seperator, selection, and drawing styles of this cell.
@property (nonatomic, assign) TUITableViewCellSeparatorStyle seperatorStyle;
@property (nonatomic, assign) TUITableViewCellSelectionStyle selectionStyle;
@property (nonatomic, assign) TUITableViewCellDrawingStyle drawingStyle;

// The color the cell highlights in, and optionally, animates to
// and from this highlighted state. The default value is NO.
// The alternate background color must be set to alternate background
// colors every other cell. It defaults to nil.
@property (nonatomic, strong) NSColor *highlightColor;
@property (nonatomic, strong) NSColor *alternateBackgroundColor;
@property (nonatomic, assign) BOOL animatesHighlightChanges;

// The cell's indentation level, and the size of each indent. The total
// indentation level is indentationLevel * indentationWidth. Defaults to 10px.
@property (nonatomic, assign) NSInteger indentationLevel;
@property (nonatomic, assign) CGFloat indentationWidth;

// The highlighting affects the appearance of the cell. The default
// value is is NO. If you set the highlighted state to YES through
// this property, the transition to the new state appearance is not
// animated. For animated highlighted-state transitions, see
// the setHighlighted:animated: method.
@property (nonatomic, assign, getter = isHighlighted) BOOL highlighted;

// The selection affects the appearance of the cell. The default
// value is is NO. If you set the selected state to YES through
// this property, the transition to the new state appearance is not
// animated. For animated selected-state transitions, see
// the setSelected:animated: method.
@property (nonatomic, assign, getter = isSelected) BOOL selected;

// This method is the designated initializer for the class. The
// reuse identifier is associated with those cells of a table view
// that have the same general configuration, minus cell content.
// In its implementation of tableView:cellForRowAtIndexPath:, the
// table view's delegate calls the TUITableView method
// dequeueReusableCellWithIdentifier:, passing in a reuse identifier,
// to obtain the cell object to use as the basis for the current row.
// If you want a table cell that has a configuration different that
// those defined by TUITableViewCell for style, you must create your
// own custom cell. If you want to set the row height of cells on
// an individual basis, implement the delegate method
// tableView:heightForRowAtIndexPath:.
- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

// If the cell is reusable (has a reuseIdentifier), this method
// is called just before the cell is returned from the table view
// method dequeueReusableCellWithIdentifier:. If you override this
// method, you MUST call the super method.
- (void)prepareForReuse;

// This method is called after frame is set, but before it is
// brought on screen. This method does not require a super method
// call if overridden.
- (void)prepareForDisplay;

// Called by a table view (avoid direct calls). Subclasses may override.
// Highlighted is set upon mouse down, and selected upon mouse up, and
// where selected triggers a didSelectRowAtPath: delegate method call.
- (void)setSelected:(BOOL)s animated:(BOOL)animated;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;

@end
