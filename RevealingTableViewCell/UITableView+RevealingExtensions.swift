//
//  UITableView+RevealingExtensions.swift
//  RevealingTableViewCell
//
//  Created by sovata on 08/04/2017.
//  Copyright © 2017 Nikolay Suvandzhiev. All rights reserved.
//

import Foundation
import UIKit


public extension UITableView
{
    /// If you leave `exceptThisOne` as `nil`, then all cells will be closed.
    /// Otherwise all cells except of the cell specified will be closed
    public func closeAllCells(exceptThisOne cellThatShouldNotBeClosed: RevealingTableViewCell? = nil)
    {
        for visibleCell in self.visibleCells
        {
            if let revealingTableViewCell = visibleCell as? RevealingTableViewCell
            {
                if let cellThatShouldNotBeClosed = cellThatShouldNotBeClosed
                {
                    if visibleCell != cellThatShouldNotBeClosed
                    {
                        revealingTableViewCell.setRevealingState(.closed, animated: true)
                    }
                }
                else
                {
                    revealingTableViewCell.setRevealingState(.closed, animated: true)
                }
            }
        }
    }
}
