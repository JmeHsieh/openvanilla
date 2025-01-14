//
// VTHorizontalCandidateController.m
//
// Copyright (c) 2012 Lukhnos D. Liu (http://lukhnos.org)
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import "VTHorizontalCandidateController.h"
#import "VTHorizontalCandidateView.h"

@interface VTHorizontalCandidateController (Private)
- (NSUInteger)pageCount;
- (void)layoutCandidateView;
- (void)pageButtonAction:(id)sender;
- (void)candidateViewMouseDidClick:(id)sender;
@end


@implementation VTHorizontalCandidateController

- (id)init
{
    NSRect contentRect = NSMakeRect(128.0, 128.0, 0.0, 0.0);
    NSWindowStyleMask styleMask = NSBorderlessWindowMask | NSNonactivatingPanelMask;

    NSPanel *panel = [[NSPanel alloc] initWithContentRect:contentRect styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
    panel.level = kCGPopUpMenuWindowLevel;
    panel.hasShadow = YES;

    self = [self initWithWindow:panel];
    if (self) {
        contentRect.origin = NSMakePoint(0.0, 0.0);
        _candidateView = [[VTHorizontalCandidateView alloc] initWithFrame:contentRect];
        _candidateView.target = self;
        _candidateView.action = @selector(candidateViewMouseDidClick:);
        [panel.contentView addSubview:_candidateView];

        contentRect.size = NSMakeSize(36.0, 20.0);
        _nextPageButton = [[NSButton alloc] initWithFrame:contentRect];
        _prevPageButton = [[NSButton alloc] initWithFrame:contentRect];
        _nextPageButton.buttonType = NSMomentaryLightButton;
        _nextPageButton.bezelStyle = NSSmallSquareBezelStyle;
        _nextPageButton.title = @"»";
        _nextPageButton.target = self;
        _nextPageButton.action = @selector(pageButtonAction:);

        _prevPageButton.buttonType = NSMomentaryLightButton;
        _prevPageButton.bezelStyle = NSSmallSquareBezelStyle;
        _prevPageButton.title = @"«";
        _prevPageButton.target = self;
        _prevPageButton.action = @selector(pageButtonAction:);

        [panel.contentView addSubview:_nextPageButton];
        [panel.contentView addSubview:_prevPageButton];
    }

    return self;
}

- (void)reloadData
{
    _candidateView.highlightedIndex = 0;
    _currentPage = 0;
    [self layoutCandidateView];
}

- (BOOL)showNextPage
{
    if (_currentPage + 1 >= self.pageCount) {
        return NO;
    }

    _currentPage++;
    _candidateView.highlightedIndex = 0;
    [self layoutCandidateView];
    return YES;
}

- (BOOL)showPreviousPage
{
    if (_currentPage == 0) {
        return NO;
    }

    _currentPage--;
    _candidateView.highlightedIndex = 0;
    [self layoutCandidateView];
    return YES;
}

- (BOOL)highlightNextCandidate
{
    NSUInteger currentIndex = self.selectedCandidateIndex;
    if (currentIndex + 1 >= [self.delegate candidateCountForController:self]) {
        return NO;
    }

    self.selectedCandidateIndex = currentIndex + 1;
    return YES;
}

- (BOOL)highlightPreviousCandidate
{
    NSUInteger currentIndex = self.selectedCandidateIndex;
    if (currentIndex == 0) {
        return NO;
    }

    self.selectedCandidateIndex = currentIndex - 1;
    return YES;
}

- (NSUInteger)candidateIndexAtKeyLabelIndex:(NSUInteger)index
{
    NSUInteger result = _currentPage * self.keyLabels.count + index;
    return result < [self.delegate candidateCountForController:self] ? result : NSUIntegerMax;
}


- (NSUInteger)selectedCandidateIndex
{
    return _currentPage * self.keyLabels.count + _candidateView.highlightedIndex;
}

- (void)setSelectedCandidateIndex:(NSUInteger)newIndex
{
    NSUInteger keyLabelCount = self.keyLabels.count;
    if (newIndex < [self.delegate candidateCountForController:self]) {
        _currentPage = newIndex / keyLabelCount;
        _candidateView.highlightedIndex = newIndex % keyLabelCount;
        [self layoutCandidateView];
    }
}
@end


@implementation VTHorizontalCandidateController (Private)
- (NSUInteger)pageCount
{
    NSUInteger totalCount = [self.delegate candidateCountForController:self];
    NSUInteger keyLabelCount = self.keyLabels.count;
    return totalCount / keyLabelCount + ((totalCount % keyLabelCount) != 0 ? 1 : 0);
}

- (void)layoutCandidateView
{
    [_candidateView setKeyLabelFont:self.keyLabelFont candidateFont:self.candidateFont];

    NSMutableArray *candidates = [NSMutableArray array];
    NSUInteger count = [self.delegate candidateCountForController:self];
    NSUInteger keyLabelCount = self.keyLabels.count;
    for (NSUInteger index = _currentPage * keyLabelCount, j = 0; index < count && j < keyLabelCount; index++, j++) {
        [candidates addObject:[self.delegate candidateController:self candidateAtIndex:index]];
    }

    [_candidateView setKeyLabels:self.keyLabels displayedCandidates:candidates];

    NSSize newSize = _candidateView.sizeForView;
    NSRect frameRect = _candidateView.frame;
    frameRect.size = newSize;
    _candidateView.frame = frameRect;

    if ([self pageCount] > 1) {
        NSRect buttonRect = _nextPageButton.frame;
        CGFloat spacing = 0.0;

        if (newSize.height < 40.0) {
            buttonRect.size.height = floor(newSize.height / 2);
        }
        else {
            buttonRect.size.height = 20.0;
        }

        if (newSize.height >= 60.0) {
            spacing = ceil(newSize.height * 0.1);
        }

        CGFloat buttonOriginY = (newSize.height - (buttonRect.size.height * 2.0 + spacing)) / 2.0;
        buttonRect.origin = NSMakePoint(newSize.width + 8.0, buttonOriginY);
        _nextPageButton.frame = buttonRect;

        buttonRect.origin = NSMakePoint(newSize.width + 8.0, buttonOriginY + buttonRect.size.height + spacing);
        _prevPageButton.frame = buttonRect;

        _nextPageButton.enabled = _currentPage + 1 < [self pageCount];
        _prevPageButton.enabled = _currentPage != 0;

        newSize.width += 52.0;

        _nextPageButton.hidden = NO;
        _prevPageButton.hidden = NO;
    }
    else {
        _nextPageButton.hidden = YES;
        _prevPageButton.hidden = YES;
    }

    frameRect = self.window.frame;
    NSPoint topLeftPoint = NSMakePoint(frameRect.origin.x, frameRect.origin.y + frameRect.size.height);

    frameRect.size = newSize;
    frameRect.origin = NSMakePoint(topLeftPoint.x, topLeftPoint.y - frameRect.size.height);

    [self.window setFrame:frameRect display:NO];
    _candidateView.needsDisplay = YES;

}

- (void)pageButtonAction:(id)sender
{
    if (sender == _nextPageButton) {
        [self showNextPage];
    }
    else if (sender == _prevPageButton) {
        [self showPreviousPage];
    }
}

- (void)candidateViewMouseDidClick:(id)sender
{
    [self.delegate candidateController:self didSelectCandidateAtIndex:self.selectedCandidateIndex];
}
@end
