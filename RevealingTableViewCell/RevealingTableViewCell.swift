//
//  RevealingTableViewCell.swift
//  RevealingTableViewCell
//
//  Created by Nikolay Suvandzhiev on 05/04/2017.
//  Copyright © 2017 Nikolay Suvandzhiev. All rights reserved.

 
import Foundation
import UIKit


/// Delegate for the `RevealingTableViewCell`
public protocol RevealingTableViewCellDelegate: class
{
    /**
     This is called when the state changes and if there is an animation, it is called at the start of the animation.
     
     - Parameters:
        - cell: The cell in question
     */
    func didChangeRevealingState(cell: RevealingTableViewCell)
    
    
    /**
     Called when the user sarts horizontally sliding the cell.
     
     - Parameters:
        - cell: The cell in question
     */
    func didStartPanGesture(cell: RevealingTableViewCell)

    
    /**
     Called at the end of an animation.

     - Parameters:
        - cell: The cell in question
        - revealingState: The `RevealingState` at which the animation ended
     */
    func didFinishAnimatingInState(cell: RevealingTableViewCell, revealingState: RevealingTableViewCell.RevealingState)
}


// Default implementations, so that in effect the protocol methods become optional.
public extension RevealingTableViewCellDelegate
{
    func didChangeRevealingState(cell: RevealingTableViewCell) { return }
    func didStartPanGesture(cell: RevealingTableViewCell) { return }
    func didFinishAnimatingInState(cell: RevealingTableViewCell, revealingState: RevealingTableViewCell.RevealingState) { return }
}


/// A `UITableViewCell` subclass that can be swiped to reveal content udnerneath it’s main view
open class RevealingTableViewCell: UITableViewCell
{
    // MARK: - IBOutlets
    /// The content to be revealed, pinned to the left of the cell's `contentView`. Optional.
    @IBOutlet public weak var uiView_revealedContent_left: UIView?
    
    /// The content to be revealed, pinned to the right of the cell's `contentView`. Optional.
    @IBOutlet public weak var uiView_revealedContent_right: UIView?
    
    /// This will be the view that slides sideways to reveal some content underneath. It needs to be pinned to the cell's `contentView` using the `layoutConstraint` (among others).
    @IBOutlet public weak var uiView_mainContent: UIView!
    
    
    // MARK: - Managing the cell's revealing state
    
    /// Describes the state of a `RevealingTableViewCell`
    public enum RevealingState
    {
        /// The default state (none of the views underneath are revealed)
        case closed
        
        /// When `uiView_revealedContent_left` is revealed
        case openLeft
        
        /// When `uiView_revealedContent_right` is revealed
        case openRight
        
        //
        static let allValues: [RevealingState] = [.closed, .openLeft, .openRight]
    }
    
    
    /// The cell's current revealing state
    public private(set) var revealingState: RevealingState = .closed

    /**
     Sets the cell's revealing state with an optional animation.
     
     - Parameters:
         - revealingState: The new `RevealingState` to set
         - animated: Whether the state change should be animated
     */
    public func setRevealingState(_ revealingState: RevealingState, animated: Bool)
    {
        guard self.revealingState != revealingState else
        {
            return
        }
        
        self.revealingState = revealingState
        
        if animated
        {
            self.animate(to: revealingState)
        }
        else
        {
            self.setMainViewConstraints(for: revealingState)
        }
        
    }
    
    
    /// Delegate for the `RevealingTableViewCell`
    public weak var revealingCellDelegate: RevealingTableViewCellDelegate?
    
    
    // MARK: Drag resistance.
    
    /**
     Drag resistance:
     Should be between `0.0` and `1.0`
     - `0.0` means no resitance at all
     - `1.0` means impossible to move
     - Any other values will produce unpredictable results
     (values below `0.0` make the view travel more than the finger in the same direcation)
     (values over `1.0` will make the view go in reverse)
     */
    
    /**
     This is the usual dragging resistance for when the user has dragged the cell past the amount ocupied by the revealed view.
     */
    internal let dragResistance_normal: CGFloat = 0.7
    
    
    /**
     This is the dragging resistance for when there isn't a view to reveal.
     For example a cell might only support revealing a view from the right side.
     This indicates how hard it should be to drag the cell to the right.
     This value should normally be higher than the `dragResistance_normal`.
     */
    internal let dragResistance_unsupportedState: CGFloat = 0.9
    
    
    // MARK: - Cocoa overrides
    
    /// Documented in: `NSObject`
    override open func awakeFromNib()
    {
        super.awakeFromNib()
        
        if self.isRevealingStateSupported(.openLeft) || self.isRevealingStateSupported(.openRight)
        {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.selector_panGesture(_:)))
            panGesture.delegate = self
            self.uiView_mainContent.addGestureRecognizer(panGesture)
            self.uiView_mainContent.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    /// Documented in: `UITableViewCell`
    override open func prepareForReuse()
    {
        super.prepareForReuse()
        self.setRevealingState(.closed, animated: false)
    }
    
    // MARK: -
    
    // We need this because apple's UIAnimations completion handlers still suck (even with iOS 10 and UIViewPropertyAnimator).
    private var activeAnimationsCount: Int = 0
    
    // We disable constraints while dragging.
    private var constraintsToTemporaryDisable: [NSLayoutConstraint] = []
    
    // Properties needed for the pan logic
    private var initialPositionX: CGFloat!
    
    // MARK: - Gesture handlers
    func selector_panGesture(_ panGesture: UIPanGestureRecognizer)
    {
        let translationX = panGesture.translation(in: self.uiView_mainContent).x
        let adjustmentSoThatXmeansMidX = self.uiView_mainContent.frame.width/2
        
        switch panGesture.state
        {
        case .began:
            // We need to do this, because otherwise we can't animate things properly
            // Note that we also need to disable the constraints that affect the children.
            AutoLayoutTools.removeAllConstraints(inSuperview: self.contentView, relatingTo: self.uiView_mainContent)
            self.constraintsToTemporaryDisable = AutoLayoutTools.getConstraintsRecursively(view: self.uiView_mainContent)
            self.constraintsToTemporaryDisable.forEach{$0.isActive = false}

            // BAD: Magic values.
            self.activeAnimationsCount = -999
            self.removeMainViewAnimations()
            
            self.initialPositionX = (self.uiView_mainContent.center.x - adjustmentSoThatXmeansMidX)
            
            self.revealingCellDelegate?.didStartPanGesture(cell: self)
            

        case .changed:
            // let xCurrent = (self.uiView_mainContent.center.x - adjustmentSoThatXmeansMidX) // Keep this, it might be useful.
            let xProposed = self.initialPositionX + translationX
            
            let widthToUseForRevealedView_left = self.isRevealingStateSupported(.openLeft) ? self.getCenterXConstraintConstant(for: .openLeft) : 0.0
            let widthToUseForRevealedView_right = self.isRevealingStateSupported(.openRight) ? self.getCenterXConstraintConstant(for: .openRight) : 0.0
            
            let xOvershoot_ToTheLeft = fmax(0, widthToUseForRevealedView_right - xProposed)
            let xOvershoot_ToTheRight = fmax(0, xProposed - widthToUseForRevealedView_left)
            

            // INVESTIGATE:
            // I need help: Why does trying to set the dragging resistance based on the overshooting, cause reverse effect (seems after the resiatance passes 0.5).
            // e.g.
            // let xMaxOvershootAllowed:CGFloat = 200.0
            // let dragResistance: CGFloat = fmin(1.0, xOvershoot_ToTheRight/xMaxOvershootAllowed)
            
            
            let dragResistance_toTheLeft = self.isRevealingStateSupported(.openRight) ? self.dragResistance_normal : self.dragResistance_unsupportedState
            let dragResistance_toTheRight = self.isRevealingStateSupported(.openLeft) ? self.dragResistance_normal : self.dragResistance_unsupportedState
            
            let xToSet: CGFloat
            
            if xOvershoot_ToTheLeft == 0 && xOvershoot_ToTheRight == 0
            {
                xToSet = xProposed
            }
            else
            {
                if xOvershoot_ToTheLeft > 0
                {
                    xToSet = xProposed + xOvershoot_ToTheLeft*dragResistance_toTheLeft
                }
                else if xOvershoot_ToTheRight > 0
                {
                    xToSet = xProposed - xOvershoot_ToTheRight*dragResistance_toTheRight
                }
                else
                {
                    print("WARNING: Impossible! Check if you're clamping the overshoot variables. They should never go negative.")
                    xToSet = xProposed
                }
            }
            
            self.uiView_mainContent.center = CGPoint(x: xToSet + adjustmentSoThatXmeansMidX, y: self.uiView_mainContent.center.y)
            
            
        case .ended:
            self.constraintsToTemporaryDisable.forEach{$0.isActive = true}
            self.activeAnimationsCount = 0
            let velocityX = panGesture.velocity(in: self.uiView_mainContent).x
            let possibleSnapPositionsX = self.supportedRevealingStates.map{self.getCenterXConstraintConstant(for: $0)}
            
            let closestSnapPositionX = DistanceHelper.getClosestX_consideringVelocity(originX: self.uiView_mainContent.frame.origin.x,
                                                                                      velocityDx: velocityX,
                                                                                      arrayOfX_toCheck: possibleSnapPositionsX)
            
            self.revealingState = self.getRevealingStateForConstraintConstant(closestSnapPositionX)!
            
            self.animate(to: self.revealingState,
                         initialVelocityX: velocityX,
                         needsToCreateConstraints: true)
            
            
        case .cancelled:
            // INVESTIGATE: I need to do something here?
            break
            
        default:
            break
        }
    }
    
    
    private func animate(to revealingState: RevealingState,
                         initialVelocityX: CGFloat = 0.5,
                         needsToCreateConstraints: Bool = false)
    {
        let constantToAnimateTo = self.getCenterXConstraintConstant(for: revealingState)
        let distanceToTravelX = constantToAnimateTo - self.uiView_mainContent.frame.origin.x
        let initialSpringVelocityX:CGFloat = initialVelocityX / distanceToTravelX
        
        self.activeAnimationsCount += 1
        
        // NOTE: I tried using the UIViewPropertyAnimator with the UISpringTimingParameters, but it caused a strange vertical drift, even when the initialVelocity vector has a y = 0.
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: initialSpringVelocityX,
                       options: [.allowUserInteraction],
                       animations:
                        {
                            self.setMainViewConstraints(for: revealingState,
                                                        needsToCreateConstraints: needsToCreateConstraints)
                            
                            self.layoutIfNeeded()
                        },
                       
                       completion:
                        { (finished: Bool) in
                            
                            self.activeAnimationsCount -= 1
                            
                            if (self.activeAnimationsCount == 0)
                            {
                                if finished
                                {
                                    self.revealingCellDelegate?.didFinishAnimatingInState(cell: self, revealingState: revealingState)
                                }
                                else
                                {
                                    // This must mean the view is being dragged.
                                }
                            }
                        }
        )
    }
    
    
    private func setMainViewConstraints(for revealingState: RevealingState,
                                        needsToCreateConstraints: Bool = false)
    {
        let constantToAnimateTo = self.getCenterXConstraintConstant(for: revealingState)

        if needsToCreateConstraints
        {
            // These three are always the same. We need to re-add them, because we removed them while dragging.
            AutoLayoutTools.addConstraints_equal_topBottomWidth(ofViewA: self.uiView_mainContent, toViewB: self.contentView)
            
            // This is the constraint we're animating
            AutoLayoutTools.addConstraint_centerX_(ofViewA: self.uiView_mainContent,
                                                   toViewB: self.contentView,
                                                   constant: constantToAnimateTo)
        }
        else // This means the constraints are already there, so we just need to update the constrant for the centreX one.
        {
            AutoLayoutTools.updateConstraint_centerX_(ofViewA: self.uiView_mainContent,
                                                      toViewB: self.contentView,
                                                      constant: constantToAnimateTo)
        }
    }
    
    
    /// Returns the midX value (of the mainContent view as relative to the cell's contentView
    private func getCenterXConstraintConstant(for revealingState: RevealingState) -> CGFloat
    {
        switch revealingState
        {
        case .closed:
            return 0.0
        case .openLeft:
            return self.uiView_revealedContent_left!.frame.size.width
        case .openRight:
            return -self.uiView_revealedContent_right!.frame.size.width
        }
    }
    
    
    private func isRevealingStateSupported(_ revealingState: RevealingState) -> Bool
    {
        switch revealingState
        {
        case .openLeft:
            return self.uiView_revealedContent_left != nil
            
        case .openRight:
            return self.uiView_revealedContent_right != nil
            
        case .closed:
            return true
        }
    }
    
    
    private var supportedRevealingStates: [RevealingState]
    {
        return RevealingState.allValues.filter{self.isRevealingStateSupported($0)}
    }
    
    
    private func getRevealingStateForConstraintConstant(_ constraintConstant: CGFloat) -> RevealingState?
    {
        for revealingState in self.supportedRevealingStates
        {
            if constraintConstant == self.getCenterXConstraintConstant(for: revealingState)
            {
                return revealingState
            }
        }
        
        return nil
    }
    
    
    // NOTE: I tried using a UIViewPropertyAnimator and it's methods for stopping, pausing etc., but nothing worked as expected.
    // Maybe I need to look into it more. For now, drop down to the CoreAnimation API to achieve this.
    private func removeMainViewAnimations()
    {
        self.uiView_mainContent.layer.removeAllAnimations()
        self.uiView_mainContent.layer.model().frame = (self.uiView_mainContent.layer.presentation()!.frame)
    }
}


// MARK: - UIGestureRecognizerDelegate override
extension RevealingTableViewCell // : UIGestureRecognizerDelegate
{
    /// Documented in: `UIGestureRecognizerDelegate`
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer
        {
            let translation = panGestureRecognizer.translation(in: panGestureRecognizer.view)
            let isHorizontalTranslationLargerThanVertical = (fabs(translation.x) > fabs(translation.y))
            return isHorizontalTranslationLargerThanVertical
        }
        
        return false
    }
}
