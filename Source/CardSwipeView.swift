//
//  CardSwipeView.swift
//  SwipeCellKit
//
//  Created by Sagar Shah on 26/12/18.
//

import UIKit

open class CardSwipeView: UIView, Swipeable {
    
    var state = SwipeState.center
    var actionsView: SwipeActionsView?
    
    var scrollView: UIScrollView? {
        return tableView
    }
    
    var indexPath: IndexPath? {
        if let cell: CardSwipeTableViewCell = self.cell {
            return tableView?.indexPath(for: cell)
        } else {
            return nil
        }
    }
    
    var panGestureRecognizer: UIGestureRecognizer
    {
        return swipeController.panGestureRecognizer
    }
    
    public weak var delegate: SwipeTableViewCellDelegate?
    
    var swipeController: SwipeController!
    var isPreviouslySelected = false
    
    weak var tableView: UITableView?
    weak var cell: CardSwipeTableViewCell?
    
    /// :nodoc:
    open override var frame: CGRect {
        set {
            super.frame = state.isActive ? CGRect(origin: CGPoint(x: frame.minX, y: newValue.minY), size: newValue.size) : newValue
        }
        get {
            return super.frame
        }
    }
    
    /// :nodoc:
    open override var layoutMargins: UIEdgeInsets {
        get {
            return frame.origin.x != 0 ? swipeController.originalLayoutMargins : super.layoutMargins
        }
        set {
            super.layoutMargins = newValue
        }
    }
    
    /// :nodoc:
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configure()
    }
    
    deinit {
        tableView?.panGestureRecognizer.removeTarget(self, action: nil)
    }
    
    func configure() {
        clipsToBounds = false
        
        swipeController = SwipeController(swipeable: self, actionsContainerView: self)
        swipeController.delegate = self
    }
    
    /// :nodoc:
    func prepareForReuse() {
        reset()
        resetSelectedState()
    }
    
    private func getCell(from view: UIView) -> CardSwipeTableViewCell? {
        if let view: UIView = view.superview {
            if let cell: CardSwipeTableViewCell = view as? CardSwipeTableViewCell {
                return cell
            } else {
                return getCell(from: view)
            }
        } else {
            return nil
        }
    }
    
    func setTableView(tableView: UITableView) {
        self.tableView = tableView
        swipeController.scrollView = tableView
        
        tableView.panGestureRecognizer.removeTarget(self, action: nil)
        tableView.panGestureRecognizer.addTarget(self, action: #selector(handleTablePan(gesture:)))
    }
    
//    // Override so we can accept touches anywhere within the cell's minY/maxY.
//    // This is required to detect touches on the `SwipeActionsView` sitting alongside the
//    // `SwipeTableCell`.
//    /// :nodoc:
//    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
//        guard let superview = superview else { return false }
//        
//        let point = convert(point, to: superview)
//        
//        if !UIAccessibility.isVoiceOverRunning {
//            for card in tableView?.cardSwipeCells ?? [] {
//                if (card.state == .left || card.state == .right) && !card.contains(point: point) {
//                    tableView?.hideSwipeCell()
//                    return false
//                }
//            }
//        }
//        
//        return contains(point: point)
//    }
//    
//    func contains(point: CGPoint) -> Bool {
//        return point.y > frame.minY && point.y < frame.maxY
//    }
    
    /// :nodoc:
    override open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return swipeController.gestureRecognizerShouldBegin(gestureRecognizer)
    }
    
    /// :nodoc:
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        swipeController.traitCollectionDidChange(from: previousTraitCollection, to: self.traitCollection)
    }
    
    @objc func handleTablePan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .began {
            hideSwipe(animated: true)
        }
    }
    
    func reset() {
        swipeController.reset()
        clipsToBounds = false
    }
    
    func resetSelectedState() {
        if isPreviouslySelected {
            if let cell: CardSwipeTableViewCell = self.cell {
                if let tableView = tableView, let indexPath = tableView.indexPath(for: cell) {
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
        isPreviouslySelected = false
    }
    
    func hideSwipe(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        swipeController.hideSwipe(animated: animated, completion: completion)
    }
    
    public var swipeOffset: CGFloat {
        set { setSwipeOffset(newValue, animated: false) }
        get { return frame.midX - bounds.midX }
    }
    
    public func showSwipe(orientation: SwipeActionsOrientation, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        setSwipeOffset(.greatestFiniteMagnitude * orientation.scale * -1,
                       animated: animated,
                       completion: completion)
    }
    
    public func setSwipeOffset(_ offset: CGFloat, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        swipeController.setSwipeOffset(offset, animated: animated, completion: completion)
    }
}

extension CardSwipeView: SwipeControllerDelegate {
    func swipeController(_ controller: SwipeController, canBeginEditingSwipeableFor orientation: SwipeActionsOrientation) -> Bool {
        return self.cell?.isEditing == false
    }
    
    func swipeController(_ controller: SwipeController, editActionsForSwipeableFor orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        guard let cell: CardSwipeTableViewCell = self.cell else { return nil }
        
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: cell) else { return nil }
        
        return delegate?.tableView(tableView, editActionsForRowAt: indexPath, for: orientation)
    }
    
    func swipeController(_ controller: SwipeController, editActionsOptionsForSwipeableFor orientation: SwipeActionsOrientation) -> SwipeOptions {
        
        guard let cell: CardSwipeTableViewCell = self.cell else { return SwipeOptions() }
        
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: cell) else { return SwipeOptions() }
        
        return delegate?.tableView(tableView, editActionsOptionsForRowAt: indexPath, for: orientation) ?? SwipeOptions()
    }
    
    func swipeController(_ controller: SwipeController, visibleRectFor scrollView: UIScrollView) -> CGRect? {
        guard let tableView = tableView else { return nil }
        
        return delegate?.visibleRect(for: tableView)
    }
    
    func swipeController(_ controller: SwipeController, willBeginEditingSwipeableFor orientation: SwipeActionsOrientation) {
        
        guard let cell: CardSwipeTableViewCell = self.cell else { return }
        
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: cell) else { return }
        
        // Remove highlight and deselect any selected cells
        cell.setHighlighted(false, animated: false)
        isPreviouslySelected = cell.isSelected
        tableView.deselectRow(at: indexPath, animated: false)
        
        delegate?.tableView(tableView, willBeginEditingRowAt: indexPath, for: orientation)
    }
    
    func swipeController(_ controller: SwipeController, didEndEditingSwipeableFor orientation: SwipeActionsOrientation) {
        
        guard let cell: CardSwipeTableViewCell = self.cell else { return }
        
        guard let tableView = tableView, let indexPath = tableView.indexPath(for: cell), let actionsView = self.actionsView else { return }
        
        resetSelectedState()
        
        delegate?.tableView(tableView, didEndEditingRowAt: indexPath, for: actionsView.orientation)
    }
    
    func swipeController(_ controller: SwipeController, didDeleteSwipeableAt indexPath: IndexPath) {
        tableView?.deleteRows(at: [indexPath], with: .none)
    }
}
