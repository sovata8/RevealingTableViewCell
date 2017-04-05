# RevealingTableViewCell (experimental)
RevealingTableViewCell is a UITableViewCell that can be slided to reveal content udnerneath it's main view.

---------
*__NOTE: At this early stage, this is an experimental project. Things might change quickly, with no backwards compatibiliy. Using this in production environments is not a good idea__*
---------



## Installation

### CocoaPods

```
pod 'RevealingTableViewCell'
```


## Usage
No code changes required, everything is done in Interface Builder.

Step 1
Use RevealingTableViewCell (or your subclass of it) as a custom class for your tableview cell in Interface Builder.

STep 2
Inside the cell's default `contentView`, put a subview and connect it to the the IBOutlet `uiView_mainContent`. This will be the view that slides sideways to reveal some content underneath. Using AutoLayout, pin this `uiView_mainContent` to it's superview using a constraint: `uiView_mainContent.centerX = superview.centerX`. Connect that constraint to `layoutConstraint`. (Do not pin the left/right sides of the `uiView_mainContent` to the `contentView`, but rather add a `equal width` constraint.)

Step 3
Inside the cell's default `contentView`, put and connect `uiView_revealedContent_left` and/or `uiView_revealedContent_right` subviews. Pin them using AutoLayout to the corresponding sides of your cell. Fix their widths. Make sure they are behind the `uiView_mainContent`.
