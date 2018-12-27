//
//  CardSwipeTableViewCell.swift
//  SwipeCellKit
//
//  Created by Sagar Shah on 26/12/18.
//

import UIKit

/**
 The `CardSwipeTableViewCell` class extends `UITableViewCell` and provides more flexible options for cell swiping behavior.
 
 
 The default behavior closely matches the stock Mail.app. If you want to customize the transition style (ie. how the action buttons are exposed), or the expansion style (the behavior when the row is swiped passes a defined threshold), you can return the appropriately configured `SwipeOptions` via the `SwipeTableViewCellDelegate` delegate.
 */
open class CardSwipeTableViewCell: UITableViewCell {
    
    /// The object that acts as the delegate of the `CardSwipeTableViewCell`.
    public weak var delegate: SwipeTableViewCellDelegate? {
        didSet {
            self.cardView.delegate = delegate
        }
    }
    
    @IBOutlet public weak var cardView: CardSwipeView!
    
    weak var tableView: UITableView?
    
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        var view: UIView = self
        while let superview = view.superview {
            view = superview
            
            if let tableView = view as? UITableView {
                self.tableView = tableView
                cardView.cell = self
                
                cardView.setTableView(tableView: tableView)
                return
            }
        }
    }
    
    // Override so we can accept touches anywhere within the cell's minY/maxY.
    // This is required to detect touches on the `SwipeActionsView` sitting alongside the
    // `CardSwipeTableCell`.
    /// :nodoc:
    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let superview = superview else { return false }
        
        let point = convert(point, to: superview)
        
        if !UIAccessibility.isVoiceOverRunning {
            for card in tableView?.cardSwipeCells ?? [] {
                if let cell: CardSwipeTableViewCell = card.cell {
                    if (card.state == .left || card.state == .right) && !cell.contains(point: point) {
                        tableView?.hideSwipeCell()
                        return false
                    }
                }
            }
        }
        
        return contains(point: point)
    }
    
    func contains(point: CGPoint) -> Bool {
        return point.y > frame.minY && point.y < frame.maxY
    }
    
    /// :nodoc:
    override open func prepareForReuse() {
        super.prepareForReuse()
        
        self.cardView.prepareForReuse()
    }
    
    override open func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            hideSwipe(animated: false)
        }
    }
    
    public func hideSwipe(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        self.cardView.hideSwipe(animated: animated, completion: completion)
    }
    
    /// :nodoc:
    override open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if self.cardView.state == .center {
            super.setHighlighted(highlighted, animated: animated)
        }
    }
    
    open override func accessibilityElementCount() -> Int {
        guard cardView.state != .center else {
            return super.accessibilityElementCount()
        }
        
        return 1
    }
    
    /// :nodoc:
    open override func accessibilityElement(at index: Int) -> Any? {
        guard cardView.state != .center else {
            return super.accessibilityElement(at: index)
        }
        
        return cardView.actionsView
    }
    
    /// :nodoc:
    open override func index(ofAccessibilityElement element: Any) -> Int {
        guard cardView.state != .center else {
            return super.index(ofAccessibilityElement: element)
        }
        
        return element is SwipeActionsView ? 0 : NSNotFound
    }
    
    open override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            guard let tableView = tableView, let indexPath = tableView.indexPath(for: self) else {
                return super.accessibilityCustomActions
            }
            
            let leftActions = delegate?.tableView(tableView, editActionsForRowAt: indexPath, for: .left) ?? []
            let rightActions = delegate?.tableView(tableView, editActionsForRowAt: indexPath, for: .right) ?? []
            
            let actions = [rightActions.first, leftActions.first].compactMap({ $0 }) + rightActions.dropFirst() + leftActions.dropFirst()
            
            if actions.count > 0 {
                return actions.compactMap({ SwipeAccessibilityCustomAction(action: $0,
                                                                           indexPath: indexPath,
                                                                           target: self,
                                                                           selector: #selector(performAccessibilityCustomAction(accessibilityCustomAction:))) })
            } else {
                return super.accessibilityCustomActions
            }
        }
        
        set {
            super.accessibilityCustomActions = newValue
        }
    }
    
    @objc func performAccessibilityCustomAction(accessibilityCustomAction: SwipeAccessibilityCustomAction) -> Bool {
        guard let tableView = tableView else { return false }
        
        let swipeAction = accessibilityCustomAction.action
        
        swipeAction.handler?(swipeAction, accessibilityCustomAction.indexPath)
        
        if swipeAction.style == .destructive {
            tableView.deleteRows(at: [accessibilityCustomAction.indexPath], with: .fade)
        }
        
        return true
    }
}
