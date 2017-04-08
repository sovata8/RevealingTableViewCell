# RevealingTableViewCell (experimental)
RevealingTableViewCell is a UITableViewCell that can be swiped to reveal content udnerneath it's main view.  
It can be set all through Interface Builder, with no code changges.

---------
*__NOTE: At this early stage, this is an experimental project. Things might change quickly, with no backwards compatibility. Using this in production environments is not a good idea__*
---------

# Example
You can check out the example project.

<a href="http://www.youtube.com/watch?feature=player_embedded&v=KwBGBTtiSr8
" target="_blank"><img src="http://img.youtube.com/vi/KwBGBTtiSr8/0.jpg" 
alt="Click to see an example" width="240" height="180" border="10" /></a>


## Installation
Requires: `Swift 3`, `iOS 10`


### CocoaPods

```
pod 'RevealingTableViewCell'
```

## Usage
No code changes required, everything is done in Interface Builder.

Step 1  
Use RevealingTableViewCell (or your subclass of it) as a custom class for your tableview cell in Interface Builder.

Step 2  
Inside the cell's default `contentView`, put a subview and connect it to the the IBOutlet `uiView_mainContent`. This will be the view that slides sideways to reveal some content underneath. Using AutoLayout, pin this `uiView_mainContent` to it's superview using a constraints:
* `uiView_mainContent.centerX = superview.centerX`
* `uiView_mainContent.width = superview.width`
* `uiView_mainContent.height = superview.height`
* `uiView_mainContent.centerY = superview.centerY`
(or instead of the `height` and `centerY` constraints, you can use `top` and `bottom` constraints)


Step 3  
Inside the cell's default `contentView`, put and connect `uiView_revealedContent_left` and/or `uiView_revealedContent_right` subviews. Pin them using AutoLayout to the corresponding sides of your cell. Fix their widths. Make sure they are behind the `uiView_mainContent`.

## Known issues and considerations
* At the moment it is required that all the 'hidden' views (the ones that are behind the main view and are revealed when sliding), are in the view hierarchy of the cell at all times, even if they are never to be shown. This might be a performance issue in some cases.
