# RevealingTableViewCell
RevealingTableViewCell is a UITableViewCell that can be swiped to reveal content udnerneath it's main view.  
It can be set up through Interface Builder alone, with no code changes.

## Check it out

### CocoaPods
`pod try RevealingTableViewCell`

### Directly from the repo
Clone or download this repository and then open `Example/RevealingTableViewCellExample.xcodeproj`.

### YouTube
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

Check out the Screenshots:

![](https://github.com/sovata8/RevealingTableViewCell/raw/master/Screenshots/ViewStructure.png "")
![](https://github.com/sovata8/RevealingTableViewCell/raw/master/Screenshots/IBOutlets.png "")

### Step 1  
Use `RevealingTableViewCell` (or your subclass of it) as a custom class for your tableview cell in Interface Builder.

### Step 2  
Inside the cell's default `contentView`, put a subview and connect it to the the IBOutlet `uiView_mainContent`. This will be the view that slides sideways to reveal some content underneath. Using AutoLayout, pin this `uiView_mainContent` to it's superview using a constraints:  

* `uiView_mainContent.centerX = superview.centerX`
* `uiView_mainContent.width = superview.width`
* `uiView_mainContent.height = superview.height`
* `uiView_mainContent.centerY = superview.centerY`.

(or instead of the `height` and `centerY` constraints, you can use `top` and `bottom` constraints)


### Step 3  
Inside the cell's default `contentView`, put and connect `uiView_revealedContent_left` and/or `uiView_revealedContent_right` subviews. Pin them using AutoLayout to the corresponding sides of your cell. Fix their widths. Make sure they are behind the `uiView_mainContent`.

### Making the cells close when needed (optional)
Usually, you would want cells to automatically close whenever you scroll the tableview, or when another cell is slided sideways. To achieve this, use the provided tableview extension function `closeAllCells(exceptThisOne:)`. Here is an example (from the example project):

```
extension ViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        self.uiTableView.closeAllCells()
    }
}


extension ViewController: RevealingTableViewCellDelegate
{
    func didStartPanGesture(cell: RevealingTableViewCell)
    {
        self.uiTableView.closeAllCells(exceptThisOne: cell)
    }
}
```
(of course when you are creating the cell in your `cellForRowAt indexPath` logic, don't forget to specify that `cell.revealingCellDelegate = self`)


## Known issues and considerations
* At the moment it is required that all the 'hidden' views (the ones that are behind the main view and are revealed when sliding), are in the view hierarchy of the cell at all times, even if they are never shown. This is obvously not great when performance matters.
