//
//  PresentationControllerProvider.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/9/21.
//

import Foundation
import UIKit

/// Protocol that allows conforming objects to provide a custom
/// presentation controller that will be used during a view controller transition.
protocol PresentationControllerProvider {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController
}
