//
//  RevealingTableViewCell.swift
//  RevealingTableViewCell
//
//  Created by Nikolay Suvandzhiev on 05/04/2017.
//  Copyright © 2017 Nikolay Suvandzhiev. All rights reserved.
//
// TODO: Make the pan gesture immediate?
// TODO: Implement activeTransitions and complection animation handlers?
// TODO: It would be nice if, in the case of one of the sides being limited, the spring-back animationa ctually bounces off the limited side, instead of going over it.

import Foundation
import UIKit


public enum PositionState
{
    case closed
    case openRight
    case openLeft
    
    static let allValues: [PositionState] = [.closed, .openLeft, .openRight]
}


public protocol RevealingTableViewCellDelegate: class
{
    func didChangePositionState(cell: RevealingTableViewCell, positionState: PositionState)
    func didStartPanGesture(cell: RevealingTableViewCell)
}

public class RevealingTableViewCell: UITableViewCell
{
    private func getConstraintConstantForPositionState(_ positionState: PositionState) -> CGFloat
    {
        switch positionState
        {
        case .closed:
            return 0.0
        case .openLeft:
            return self.uiView_revealedContent_left!.frame.size.width
        case .openRight:
            return -self.uiView_revealedContent_right!.frame.size.width
        }
    }
    
    
    private func isPositionStateSupported(_ positionState: PositionState) -> Bool
    {
        switch positionState
        {
        case .openLeft:
            return self.uiView_revealedContent_left != nil
            
        case .openRight:
            return self.uiView_revealedContent_right != nil
            
        case .closed:
            return true
        }
    }
    
    
    private func supportedPositionStates() -> [PositionState]
    {
        return PositionState.allValues.filter{self.isPositionStateSupported($0)}
    }
    
    private func getPositionStateForConstraintConstant(_ constraintConstant: CGFloat) -> PositionState?
    {
        for positionState in self.supportedPositionStates()
        {
            if constraintConstant == self.getConstraintConstantForPositionState(positionState)
            {
                return positionState
            }
        }
        
        return nil
    }
    
    
    
    public weak var delegate: RevealingTableViewCellDelegate?
    
    public var positionState: PositionState = .closed
    {
        didSet
        {
            self.delegate?.didChangePositionState(cell: self, positionState: self.positionState)
        }
    }
    
    
    public func setPositionState(_ positionState: PositionState, animated: Bool)
    {
        self.positionState = positionState
        
        if animated
        {
            self.animateToCurrentPositionState()
        }
        else
        {
            let constantToAnimateTo = self.getConstraintConstantForPositionState(self.positionState)
            self.layoutConstraint.constant = constantToAnimateTo
        }
    }
    
    // MARK: - IBOutlets
    @IBOutlet public weak var uiView_revealedContent_right: UIView?
    @IBOutlet public weak var uiView_revealedContent_left: UIView?
    @IBOutlet public weak var uiView_mainContent: UIView!
    @IBOutlet public weak var layoutConstraint: NSLayoutConstraint!
    // MARK: IBOutlets -

    // Properties needed for the pan logic
    private var gesture_pan: UIPanGestureRecognizer!
    private var layoutConstraint_StartingConstant: CGFloat!
    private var panStartingTranslation: CGPoint!
    
    override public func awakeFromNib()
    {
        super.awakeFromNib()
        
        if self.isPositionStateSupported(.openLeft) || self.isPositionStateSupported(.openRight)
        {
            self.gesture_pan = UIPanGestureRecognizer(target: self, action: #selector(self.selector_panGesture(_:)))
            self.gesture_pan.delegate = self
            self.contentView.addGestureRecognizer(self.gesture_pan)
        }
    }
    
    
    override public func prepareForReuse()
    {
        super.prepareForReuse()
        self.setPositionState(.closed, animated: false)
    }
    
    
    // MARK: - Gesture handlers
    func selector_panGesture(_ panGesture: UIPanGestureRecognizer)
    {
        switch panGesture.state
        {
        case .began:
            // self.propertyAnimator?.stopAnimation(true) // TODO: ?
            self.panStartingTranslation = panGesture.translation(in: panGesture.view)
            self.layoutConstraint_StartingConstant = self.layoutConstraint.constant
            self.delegate?.didStartPanGesture(cell: self)
            
        case .changed:
            let panCurrentTranslation: CGPoint = panGesture.translation(in: panGesture.view)
            let deltaX: CGFloat = panCurrentTranslation.x - self.panStartingTranslation.x
            
            let constantToSet_withoutResistance: CGFloat = self.layoutConstraint_StartingConstant + deltaX
            
            let amountOvershooting_toTheLeft: CGFloat
            if self.isPositionStateSupported(.openRight)
            {
                amountOvershooting_toTheLeft = fmax(self.getConstraintConstantForPositionState(.openRight) - constantToSet_withoutResistance, 0.0)
            }
            else
            {
                amountOvershooting_toTheLeft = 0.0
            }
            
            
            let amountOvershooting_toTheRight: CGFloat
            if self.isPositionStateSupported(.openLeft)
            {
                amountOvershooting_toTheRight = fmax(constantToSet_withoutResistance - self.getConstraintConstantForPositionState(.openLeft), 0.0)
            }
            else
            {
                amountOvershooting_toTheRight = 0.0
            }
            
            
            
            let amountOvershooting_any: CGFloat = fmax(amountOvershooting_toTheRight, amountOvershooting_toTheLeft)
            
            var constantToSet_withResistance: CGFloat = 0.0
            
            
            if amountOvershooting_any > 0.0
            {
                // 0.0 means no resistance. 1.0 means maximum resistance.
                // Note: I tried making this dependent on the `amountOvershooting`, but I was getting strange bugs (view starts going in reverse?!)
                let dragResistance: CGFloat = 0.8
                
                
                if amountOvershooting_toTheRight > 0.0
                {
                    constantToSet_withResistance = self.getConstraintConstantForPositionState(.openLeft)  + amountOvershooting_toTheRight*(1.0-dragResistance)
                }
                else if amountOvershooting_toTheLeft > 0.0
                {
                    constantToSet_withResistance = self.getConstraintConstantForPositionState(.openRight) - amountOvershooting_toTheLeft*(1.0-dragResistance)
                }
            }
            else
            {
                constantToSet_withResistance = constantToSet_withoutResistance
            }
            
            
            if self.isPositionStateSupported(.openLeft) == false && self.isPositionStateSupported(.openRight) == false
            {
                self.layoutConstraint.constant = self.getConstraintConstantForPositionState(.closed)
            }
            else if self.isPositionStateSupported(.openRight) == false
            {
                self.layoutConstraint.constant = fmax(self.getConstraintConstantForPositionState(.closed), constantToSet_withResistance)
            }
            else if self.isPositionStateSupported(.openLeft) == false
            {
                self.layoutConstraint.constant = fmin(self.getConstraintConstantForPositionState(.closed), constantToSet_withResistance)
            }
            else
            {
                self.layoutConstraint.constant = constantToSet_withResistance
            }
            
            
        case .ended:
            
            let velocityX = gesture_pan.velocity(in: self.uiView_mainContent).x
            
            let snapXPositions = self.supportedPositionStates().map{self.getConstraintConstantForPositionState($0)}
            
            let closestSnapXPosition = DistanceHelper.getClosest_X_AlsoConsideringVelocity_1D(originX: self.layoutConstraint.constant,
                                                                                      velocityDx: velocityX,
                                                                                      arrayOfX_toCheck: snapXPositions
            )
            
            self.positionState = self.getPositionStateForConstraintConstant(closestSnapXPosition)!
            self.animateToCurrentPositionState(initialVelocityX: velocityX)
            
            
        case .cancelled:
            // TODO: I need to do something here?
            break
            
        default:
            break
        }
        
    }
    
    private func animateToCurrentPositionState(initialVelocityX: CGFloat = 0.5)
    {
        let constantToAnimateTo = self.getConstraintConstantForPositionState(self.positionState)
        let distanceToTravelX = constantToAnimateTo - self.layoutConstraint.constant
        let initialSpringVelocityX:CGFloat = initialVelocityX / distanceToTravelX
        
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.5,
                       initialSpringVelocity: initialSpringVelocityX,
                       options: [.allowUserInteraction],
                       animations:
            {
                self.layoutConstraint.constant = constantToAnimateTo
                self.layoutIfNeeded()
        },
                       completion: nil
        )
    }
}



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
