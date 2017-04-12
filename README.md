# RevealingTableViewCell

[![Travis](https://img.shields.io/travis/sovata8/RevealingTableViewCell.svg)]()
[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-FD7835.svg?style=flat)]()
[![license MIT](https://img.shields.io/cocoapods/l/RevealingTableViewCell.svg)][linkMITLicence]
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/RevealingTableViewCell.svg)][linkDocumentation] 
[![CocoaPods](https://img.shields.io/cocoapods/v/RevealingTableViewCell.svg)][linkPod]
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)][linkCarthage]

---

<p align="center">
    <a href="#what-is-it">What is it?</a>
    &bull;
    <a href="#check-it-out">Check it out</a>
    &bull;
    <a href="#installation">Installation</a>
    &bull;
    <a href="#usage">Usage</a>
</p>

#

## What is it?
RevealingTableViewCell is a UITableViewCell that can be swiped to reveal content underneath its main view.  
It can be set up through Interface Builder, with no code changes.  
It does not provide anything other than the sliding view - it's up to you to set up any views that need be revealed.


<p align="center"><img src="Screenshots/RevealingCellScreenRecording10s.gif" /></p>


## Check it out

### CocoaPods
```bash
pod try RevealingTableViewCell
```
(this command clones the example project in a temporary folder and opens it in Xcode)

### Directly from the repo
Clone or download this repository and then open `Example/RevealingTableViewCellExample.xcodeproj`.

### Demo video
<a href="http://www.youtube.com/watch?feature=player_embedded&v=6Dvg48Mb0Nc
" target="_blank"><img src="http://img.youtube.com/vi/6Dvg48Mb0Nc/0.jpg" 
alt="Click to see an example" width="240" height="180" border="10" /></a>

(opens in YouTube)

## Installation
Requires: `Swift 3`, `iOS 10`


#### [CocoaPods][linkPod] (recommended)

```ruby
pod 'RevealingTableViewCell'
```

#### [Carthage][linkCarthage]
````
github "sovata8/RevealingTableViewCell"
````


## Usage
No code changes required, everything is done in Interface Builder.  
Note that this framework does not provide anything other than the sliding view - it's up to you to set up any views that need be revealed (e.g. buttons, additional information etc.).


These screenshots show how to set up your views and IBOutlets:

#

<p align="center"><img src="Screenshots/ViewStructure.png" /></p>

#

<p align="center"><img src="Screenshots/IBOutlets.png" /></p>

#

### Step 1
Use `RevealingTableViewCell` (or your subclass of it) as a custom class for your tableview cell in Interface Builder.

### Step 2
Inside the cell's default `contentView`, put a subview and connect it to the the IBOutlet `uiView_mainContent`. This will be the view that slides sideways to reveal some content underneath. Using AutoLayout, pin this `uiView_mainContent` to it's superview using constraints:  

```
uiView_mainContent.centerX = superview.centerX
uiView_mainContent.width = superview.width
uiView_mainContent.height = superview.height
uiView_mainContent.centerY = superview.centerY
```
(or instead of the `height` and `centerY` constraints, you can use `top` and `bottom` constraints)


### Step 3
Inside the cell's default `contentView`, put and connect `uiView_revealedContent_left` and/or `uiView_revealedContent_right` subviews. Pin them using AutoLayout to the corresponding sides of your cell. Fix their widths. Make sure they are behind the `uiView_mainContent`.

### Making the cells close when needed (optional)
Usually, you would want cells to automatically close whenever you scroll the tableview, or when another cell is swiped sideways. To achieve this, use the provided tableview extension function `closeAllCells(exceptThisOne:)`. Here is an example (from the example project):

```swift
// Close all cells when the tableview starts scrolling vertically
extension ViewController: UIScrollViewDelegate
{
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        self.uiTableView.closeAllCells()
    }
}
```
  
```swift
// Close all other cells when a particular cell starts being swiped
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
* At the moment it is required that all the 'hidden' views (the ones that are behind the main view and are revealed when sliding), are in the view hierarchy of the cell at all times, even if they are never shown. This is obviously not great when performance matters.


[linkDocumentation]:http://cocoadocs.org/docsets/RevealingTableViewCell
[linkPod]:https://cocoapods.org/pods/RevealingTableViewCell
[linkMITLicence]:http://opensource.org/licenses/MIT
[linkCarthage]:https://github.com/Carthage/Carthage


## License
This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file.
