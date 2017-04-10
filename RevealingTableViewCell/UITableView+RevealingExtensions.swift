//
//  UITableView+RevealingExtensions.swift
//  RevealingTableViewCell
//
//  Created by sovata on 08/04/2017.
//  Copyright © 2017 Nikolay Suvandzhiev. All rights reserved.
//

import Foundation
import UIKit


/// Extension for easy closing of RevealingTableViewCells in a tableView
public extension UITableView
{
    /**
     Closes all the cells (unless you specify a cell to leave open).
     
     - Parameters:
       - cellThatShouldNotBeClosed: The cell to leave open. (optional). Just don't pass anything (or pass `nil`) if you want all the cells to close.
     */
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
