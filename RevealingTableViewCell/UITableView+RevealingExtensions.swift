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
    public func closeAllCells(exceptThisOne: RevealingTableViewCell? = nil)
    {
        for visibleCell in self.visibleCells as! [RevealingTableViewCell]
        {
            if let exceptThisOne = exceptThisOne
            {
                if visibleCell != exceptThisOne
                {
                    visibleCell.setRevealingState(.closed, animated: true)
                }
            }
            else
            {
                visibleCell.setRevealingState(.closed, animated: true)
            }
        }
    }
}
