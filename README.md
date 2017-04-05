# RevealingTableViewCell
RevealingTableViewCell is a UITableViewCell that can be slided to reveal content udnerneath it's main view.


## Installation

#### CocoaPods

```
pod 'RevealingTableViewCell'
```


## Usage
Use as a custom class for your tableview cell in InterfaceBuilder (subclass as needed).

Inside the cell's default `contentView`, put a subview and connect it to the the IBOutlet `uiView_mainContent`. This will be the view that slides sideways to reveal some content underneath. Using AutoLayout, connect this `uiView_mainContent` to it's superview using a constraint: `uiView_mainContent.centerX = superview.centerX`. Connect that constraint to `layoutConstraint`.

Inside the cell's default `contentView`, put and connect `uiView_revealedContent_left` and/or `uiView_revealedContent_right`. Pin them using AutoLayout to the sides of your cell. Make sure they are behind the `uiView_mainContent`.
