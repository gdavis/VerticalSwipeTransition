//
//  VerticalPanGestureRecognizer.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/9/21.
//

import Foundation
import UIKit


///
/// Gesture that only handles swipes in a given direction.
/// When a gesture occurs in the direction the gesture is not
/// configured for, the gesture will fail.
///
/// This gesture recognizer is used to only allow interactive
/// pan gestures in a single direction, typically configured in
/// the `down` direction.
///
class VerticalPanGestureRecognizer: UIPanGestureRecognizer {

    enum Direction {
        case up, down
    }

    var direction: Direction

    init(direction: Direction, target: Any?, action: Selector?) {
        self.direction = direction

        super.init(target: target, action: action)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)

        guard state != .failed,
              state != .cancelled,
              let touch: UITouch = touches.first
        else { return }

        let currentPoint = touch.location(in: view)
        let previousPoint = touch.previousLocation(in: view)

        let deltaY = previousPoint.y - currentPoint.y
        print("deltaY: \(deltaY)")

        switch direction {
        case .up:
            if deltaY < 0 {
                state = .failed
            } else {
                print("moving up")
            }
        case .down:
            if deltaY > 0 {
                // going down
                state = .failed
            } else {
                print("moving down")
            }
        }
    }
}
