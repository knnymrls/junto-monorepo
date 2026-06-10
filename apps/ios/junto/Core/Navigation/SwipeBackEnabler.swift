//
//  SwipeBackEnabler.swift
//  junto
//
//  Restores the interactive left-edge "swipe back" gesture on every
//  NavigationStack. UIKit disables that gesture whenever the navigation bar or
//  back button is hidden — and Junto hides the system bar everywhere and draws
//  its own top bars — so without this, swipe-to-go-back stops working. Setting
//  the pop-gesture delegate ourselves re-arms it (and only fires when there's
//  something to pop back to).
//

import UIKit

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
