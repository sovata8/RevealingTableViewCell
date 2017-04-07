//
//  RevealingTableViewCell.swift
//  RevealingTableViewCell
//
//  Created by Nikolay Suvandzhiev on 05/04/2017.
//  Copyright © 2017 Nikolay Suvandzhiev. All rights reserved.
//
// TODO: Make the pan gesture immediate? Not sure if this is a good idea though...
// TODO: Implement completion animation handlers?
// TODO: It would be nice if, in the case of one of the sides being limited, the spring-back animationa atually bounces off the limited side, instead of going over it. Alternativly, even when one side is not reveal-able, maybe the mainView should be movable in the oposite direction (but with strong resistance).
// NOTE: Using `UISpringTimingParameters` with initialVelocity vector causes the view to get offset slighly in the Y axis, even if we set the vector to have y=0.
// NOTE: We need to completely remove and re-add constraints during dragging and animation. Setting isActive does not work.
// TODO: If while dragging the orientation changes, react somehow?
// TODO: If the spring is animating and is outside of the allowed ranges (overshooting), when we start drugging, the view will jump.
// TODO: Expose the draggingResitance constants as a public API


import Foundation
import UIKit


public protocol RevealingTableViewCellDelegate: class
{
    /// This is called when the state changes and if there is an animation, it is called at the start of the animation.
    func didChangeRevealingState(cell: RevealingTableViewCell)
    
    /// Called when the user sarts horizontally sliding the cell.
    func didStartPanGesture(cell: RevealingTableViewCell)

    /// Called at the end of an animation.
    func didFinishAnimatingInState(revealingState: RevealingTableViewCell.RevealingState)
}


public class RevealingTableViewCell: UITableViewCell
{
    ////////////////////////////////////////////////////////////////////////////////////////////

    // MARK: - Public API
    
    
    // MARK: - IBOutlets
    /// The content to be revealed, pinned to the left of the cell's `contentView`. Optional.
    @IBOutlet public weak var uiView_revealedContent_left: UIView?
    
    /// The content to be revealed, pinned to the right of the cell's `contentView`. Optional.
    @IBOutlet public weak var uiView_revealedContent_right: UIView?
    
    /// This will be the view that slides sideways to reveal some content underneath. It needs to be pinned to the cell's `contentView` using the `layoutConstraint` (among others).
    @IBOutlet public weak var uiView_mainContent: UIView!
    // MARK: IBOutlets -
    
    
    public enum RevealingState
    {
        /// The default state (none of the views underneath are revealed)
        case closed
        /// When `uiView_revealedContent_left` is revealed
        case openLeft
        /// When `uiView_revealedContent_right` is revealed
        case openRight
        
        static let allValues: [RevealingState] = [.closed, .openLeft, .openRight]
    }
    
    /// Defines the cell's revealing state
    public private(set) var revealingState: RevealingState = .closed
    
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
    
    public weak var delegate: RevealingTableViewCellDelegate?
    
    // MARK: Public API -
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////

    
    // MARK: - UITableViewCell overrides
    override public func awakeFromNib()
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
    
    override public func prepareForReuse()
    {
        super.prepareForReuse()
        self.setRevealingState(.closed, animated: false)
    }
    // MARK: UITableViewCell overrides -
    
    
    
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
            // Note that we also need to disable the constraints that affect the direct children.
            // TODO: URGENT: Check if I need to also disable all constraints recursivly down. (e.g. if there are more constraints in subviews of subviews.
            AutoLayoutTools.removeAllConstraints(inSuperview: self.contentView, relatingTo: self.uiView_mainContent)
            self.constraintsToTemporaryDisable = self.uiView_mainContent.constraints
            self.uiView_mainContent.removeConstraints(self.constraintsToTemporaryDisable)
            
            // BAD: Magic values.
            self.activeAnimationsCount = -999
            self.removeMainViewAnimations()
            
            self.initialPositionX = (self.uiView_mainContent.center.x - adjustmentSoThatXmeansMidX)
            
            self.delegate?.didStartPanGesture(cell: self)
            

        case .changed:
            // let xCurrent = (self.uiView_mainContent.center.x - adjustmentSoThatXmeansMidX) // Keep this, it might be useful.
            let xProposed = self.initialPositionX + translationX
            
            let widthToUseForRevealedView_left = self.isRevealingStateSupported(.openLeft) ? self.getCenterXConstraintConstant(for: .openLeft) : 0.0
            let widthToUseForRevealedView_right = self.isRevealingStateSupported(.openRight) ? self.getCenterXConstraintConstant(for: .openRight) : 0.0
            
            let xOvershoot_ToTheLeft: CGFloat = fmax(0, widthToUseForRevealedView_right - xProposed)
            let xOvershoot_ToTheRight: CGFloat = fmax(0, xProposed - widthToUseForRevealedView_left)
            
            // Drag resistance:
            // Should be between 0.0 and 1.0
            // 0.0 means no resitance at all.
            // 1.0 means impossible.
            // Any other values will produce unpredictable results
            // (negative values will make the view travel more than the finger in the same direcation)
            // (values over 1.0 will make the view go in reverse (i.e. travel more than the finger in the opposite direction))
            
            
            // INVESTIGATE:
            // I need help: Why does trying to set the dragging resistance based on the overshooting, cause reverse effect (seems after the resiatance passes 0.5).
            // e.g.
            // let xMaxOvershootAllowed:CGFloat = 200.0
            // let dragResistance: CGFloat = fmin(1.0, xOvershoot_ToTheRight/xMaxOvershootAllowed)
            
            
            // This is the usual dragging resistance for when the user has dragged the cell past the amount ocupied by the revealed view.
            let dragResistance_normal: CGFloat = 0.7
            
            // This is the dragging resistance for when there isn't even a view to reveal. For example a cell might only support revealing a view from the right side. This indicates how hard it should be to drag the cell to the right.
            // This value should normally be higher than the regular `dragResistance_normal`.
            let dragResistance_whenRevealingStateIsNotSupported: CGFloat = 0.9
            
            let dragResistance_toTheLeft: CGFloat = self.isRevealingStateSupported(.openRight) ? dragResistance_normal : dragResistance_whenRevealingStateIsNotSupported
            let dragResistance_toTheRight: CGFloat = self.isRevealingStateSupported(.openLeft) ? dragResistance_normal : dragResistance_whenRevealingStateIsNotSupported
            
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
            self.uiView_mainContent.addConstraints(self.constraintsToTemporaryDisable)
            self.activeAnimationsCount = 0
            let velocityX = panGesture.velocity(in: self.uiView_mainContent).x
            let possibleSnapPositionsX = self.supportedRevealingStates().map{self.getCenterXConstraintConstant(for: $0)}
            
            let closestSnapPositionX = DistanceHelper.getClosestX_consideringVelocity(originX: self.uiView_mainContent.frame.origin.x,
                                                                                      velocityDx: velocityX,
                                                                                      arrayOfX_toCheck: possibleSnapPositionsX)
            
            self.revealingState = self.getRevealingStateForConstraintConstant(closestSnapPositionX)!
            self.animate(to: self.revealingState, initialVelocityX: velocityX, needsToCreateConstraints: true)
            
            
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
                                    self.delegate?.didFinishAnimatingInState(revealingState: revealingState)
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
    
    
    private func supportedRevealingStates() -> [RevealingState]
    {
        return RevealingState.allValues.filter{self.isRevealingStateSupported($0)}
    }
    
    
    private func getRevealingStateForConstraintConstant(_ constraintConstant: CGFloat) -> RevealingState?
    {
        for revealingState in self.supportedRevealingStates()
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


// MARK: - UIGestureRecognizerDelegate
extension RevealingTableViewCell // : UIGestureRecognizerDelegate
{
    override public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool
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
