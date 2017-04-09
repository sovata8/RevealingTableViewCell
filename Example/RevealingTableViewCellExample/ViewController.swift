//
//  ViewController.swift
//  RevealingTableViewCellExample
//
//  Created by sovata on 07/04/2017.
//  Copyright © 2017 Nikolay Suvandzhiev. All rights reserved.
//

import UIKit
import RevealingTableViewCell

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    
    @IBOutlet weak var uiTableView: UITableView!
    
    
}



extension ViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 3
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cellIdentifier: String
        
        switch indexPath.row
        {
        case 0:
            cellIdentifier = "DemoCell1"
            
        case 1:
            cellIdentifier = "DemoCell2"
            
        case 2:
            cellIdentifier = "DemoCell3"
            
        case 3:
            cellIdentifier = "DemoCell4"
            
        default:
            print("Unexpected row!")
            cellIdentifier = "DemoCell1"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! RevealingTableViewCell
        cell.revealingCellDelegate = self
        return cell
    }
}


extension ViewController: UITableViewDelegate
{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath) as! RevealingTableViewCell
        
        if cell.revealingState != .closed
        {
            cell.setRevealingState(.closed, animated: true)
        }
        else
        {
            // do something else.
        }
    }
}


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
