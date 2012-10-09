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

#import "ExampleTableViewCell.h"

@implementation ExampleTableViewCell

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		_textRenderer = [[TUITextRenderer alloc] init];
		_textRenderer.shadowBlur = 1.0f;
		_textRenderer.verticalAlignment = TUITextVerticalAlignmentMiddle;
		
		// Add the text renderer to the view so events get routed to it
		// properly. Text selection, dictionary popup, etc should just work.
		// You can add more than one.
		// The text renderer encapsulates an attributed string and a frame.
		// The attributed string in this case is set by setAttributedString:
		// which is configured by the table view delegate.  The frame needs to
		// be set before it can be drawn, we do that in drawRect: below.
		self.textRenderers = [NSArray arrayWithObjects:_textRenderer, nil];
		
		self.selectionStyle = TUITableViewCellSelectionStyleGray;
		self.drawingStyle = TUITableViewCellDrawingStyleGradientDown;
		self.backgroundColor = [NSColor colorWithCalibratedWhite:0.97 alpha:1.0f];
		self.alternateBackgroundColor = [NSColor colorWithCalibratedWhite:0.92 alpha:1.0f];
		self.highlightColor = [NSColor colorWithCalibratedWhite:0.87 alpha:1.0f];
		self.animatesHighlightChanges = YES;
		
		NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 180, 91, 22)];
		[textField.cell setUsesSingleLineMode:YES];
		[textField.cell setScrollable:YES];
		
		self.textFieldContainer = [[TUIViewNSViewContainer alloc] initWithNSView:textField];
		self.textFieldContainer.backgroundColor = [NSColor blueColor];
		[self addSubview:self.textFieldContainer];
	}
	
	return self;
}

- (NSAttributedString *)attributedString {
	return _textRenderer.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString {
	_textRenderer.attributedString = attributedString;
	[self setNeedsDisplay];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGSize textFieldSize = self.textFieldContainer.bounds.size;
	CGFloat textFieldLeft = CGRectGetWidth(self.bounds) - textFieldSize.width - 16;
	self.textFieldContainer.frame = CGRectMake(textFieldLeft, 14, textFieldSize.width, textFieldSize.height);
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	// Change the text color when state changes, so it looks alright.
	if(self.highlighted || self.selected) {
		TUIAttributedString *string = (TUIAttributedString *)_textRenderer.attributedString;
		[string setColor:[NSColor whiteColor]];
		_textRenderer.attributedString = string;
		
		_textRenderer.shadowColor = [NSColor blackColor];
		_textRenderer.shadowOffset = CGSizeMake(0, -1);
	} else {
		TUIAttributedString *string = (TUIAttributedString *)_textRenderer.attributedString;
		[string setColor:[NSColor blackColor]];
		_textRenderer.attributedString = string;
		
		_textRenderer.shadowColor = [NSColor whiteColor];
		_textRenderer.shadowOffset = CGSizeMake(0, 1);
	}
	
	// Set the frame so it knows where to draw itself.
	CGRect textRect = self.bounds;
	textRect.origin.x += self.indentationWidth;
	textRect.size.width -= (self.textFieldContainer.frame.size.width + 16) + (self.indentationWidth * 2);
	
	_textRenderer.frame = textRect;
	[_textRenderer draw];
}

@end
