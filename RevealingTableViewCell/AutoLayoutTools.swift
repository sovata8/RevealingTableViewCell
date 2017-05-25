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
        [
            viewA.topAnchor.constraint(equalTo: viewB.topAnchor),
            viewA.bottomAnchor.constraint(equalTo: viewB.bottomAnchor),
            viewA.widthAnchor.constraint(equalTo: viewB.widthAnchor)
        ].forEach{$0.isActive = true}
    }
    
    
    internal static func addConstraint_centerX_(ofViewA viewA: UIView,
                                                toViewB viewB: UIView,
                                                constant: CGFloat)
    {
        viewA.centerXAnchor.constraint(equalTo: viewB.centerXAnchor, constant: constant).isActive = true
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
                return
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
