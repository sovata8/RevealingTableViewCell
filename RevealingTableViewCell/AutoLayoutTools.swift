//
//  AutoLayoutTools.swift
//  SovaTools
//
//  Created by Nikolay Suvandzhiev on 06/04/2017.
//  Copyright © 2017 Nikolay Suvandzhiev. All rights reserved.
//

import Foundation


internal enum AutoLayoutTools
{
    internal static func removeAllConstraints(inSuperview superview: UIView,
                                              relatingTo subview: AnyObject)
    {
        var constraintsToRemove: [NSLayoutConstraint]  = []
        
        for constraint in superview.constraints
        {
            if (constraint.firstItem === subview || constraint.secondItem === subview)
            {
                constraintsToRemove.append(constraint)
                
            }
        }
        
        superview.removeConstraints(constraintsToRemove)
    }
    
    
    internal static func addConstraints_equal_topBottomWidth(ofViewA viewA: UIView,
                                                             toViewB viewB: UIView)
    {
        let constraint_top = NSLayoutConstraint(item: viewA,
                                                attribute: .top,
                                                relatedBy: .equal,
                                                toItem: viewB,
                                                attribute: .top,
                                                multiplier: 1,
                                                constant: 0)
        
        let constraint_bottom = NSLayoutConstraint(item: viewA,
                                                   attribute: .bottom,
                                                   relatedBy: .equal,
                                                   toItem: viewB,
                                                   attribute: .bottom,
                                                   multiplier: 1,
                                                   constant: 0)
        
        let constraint_width = NSLayoutConstraint(item: viewA,
                                                  attribute: .width,
                                                  relatedBy: .equal,
                                                  toItem: viewB,
                                                  attribute: .width,
                                                  multiplier: 1,
                                                  constant: 0)
        
        [constraint_top, constraint_bottom, constraint_width].forEach{$0.isActive = true}
    }
    
    
    internal static func addConstraint_centerX_(ofViewA viewA: UIView,
                                                toViewB viewB: UIView,
                                                constant: CGFloat)
    {
        NSLayoutConstraint(item: viewA,
                           attribute: .centerX,
                           relatedBy: .equal,
                           toItem: viewB,
                           attribute: .centerX,
                           multiplier: 1,
                           constant: constant
            ).isActive = true
    }
    
    
    internal static func updateConstraint_centerX_(ofViewA viewA: UIView,
                                                   toViewB viewB: UIView,
                                                   constant: CGFloat)
    {
        for constraint in viewB.constraints
        {
            if constraint.firstItem === viewA
                && constraint.secondItem === viewB
                && constraint.firstAttribute == .centerX
                && constraint.secondAttribute == .centerX
            {
                constraint.constant = constant
            }
        }
    }
    
    
    internal static func getConstraintsRecursively(view: UIView) -> [NSLayoutConstraint]
    {
        var allConstraints: [NSLayoutConstraint] = []
        
        allConstraints.append(contentsOf: view.constraints)
        
        for subview in view.subviews
        {
            allConstraints.append(contentsOf: self.getConstraintsRecursively(view: subview))
        }
        
        return allConstraints
    }
}
