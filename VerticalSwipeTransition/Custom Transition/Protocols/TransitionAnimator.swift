//
//  TransitionAnimator.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/8/21.
//

import Foundation
import UIKit

protocol TransitionAnimator: UIViewControllerAnimatedTransitioning {
    init(presenting: Bool)
}
