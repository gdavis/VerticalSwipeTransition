//
//  VSwipePresentationInteractionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

class VSwipePresentationInteractionController: NSObject, InteractionControlling {

    private let finalAnimationDuration: TimeInterval = 0.6

    private(set) weak var scrollView: UIScrollView?
    private(set) var isInteractionInProgress: Bool = false
    private var interactionDistance: CGFloat = 0
    private var presentedFinalFrame: CGRect = .zero

    private var externalGesture: UIPanGestureRecognizer?

    private var transitionContext: UIViewControllerContextTransitioning?
    private var transitionAnimator: UIViewPropertyAnimator?

    /// Tracks the position of the view when an interruption occurs
    /// which is then used to offset the translation of a new gesture
    /// panning phase.
    private lazy var interruptedTranslation: CGFloat = 0

    /// Gesture that is used to interrupt an animator transitioning to the finish or
    /// cancelled state, that allows the user to restart interactivity.
    private lazy var interruptionGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureAction(_:)))
        gesture.delaysTouchesBegan = false
        return gesture
    }()
}


// MARK: - Configuration

extension VSwipePresentationInteractionController {

    func configure(forGesture gesture: UIPanGestureRecognizer, scrollView: UIScrollView? = nil) {
        gesture.delegate = self
        gesture.addTarget(self, action: #selector(gestureAction(_:)))

        self.externalGesture = gesture

        // set the given scroll view to not scroll unless the pan gesture fails
        if let scrollView = scrollView {
            self.scrollView = scrollView
            scrollView.panGestureRecognizer.require(toFail: gesture)
        }
    }
}


// MARK: - <UIViewControllerInteractiveTransitioning>

extension VSwipePresentationInteractionController {

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedViewController = transitionContext.viewController(forKey: .to) else {
            assertionFailure()
            return
        }

        // setup the initial placement within the container and its position
        let containerFrame = transitionContext.containerView.frame
        let initialFrame = CGRect(origin: CGPoint(x: containerFrame.minX, y: containerFrame.maxY), size: presentedViewController.view.frame.size)

        presentedViewController.view.frame = initialFrame
        transitionContext.containerView.addSubview(presentedViewController.view)

        self.transitionContext = transitionContext
        self.isInteractionInProgress = true

        // store frame and total travelled distance for later use
        presentedFinalFrame = transitionContext.finalFrame(for: presentedViewController)
        interactionDistance = transitionContext.containerView.bounds.height - presentedFinalFrame.minY

        disableOtherTouches()

        print(#function + ", interactionDistance: \(interactionDistance)")
    }
}


// MARK: - Transition Completion

private extension VSwipePresentationInteractionController {

    func finish() {
        print(#function)
        enableOtherTouches()
        transitionContext?.finishInteractiveTransition()
        transitionContext?.completeTransition(true)
        reset()
    }

    func cancel() {
        print(#function)
        enableOtherTouches()
        transitionContext?.cancelInteractiveTransition()
        transitionContext?.completeTransition(false)
        reset()
    }

    private func reset() {
        removeInterruptionGesture()

        interruptedTranslation = 0
        isInteractionInProgress = false
        presentedFinalFrame = .zero

        transitionContext = nil
        transitionAnimator = nil
    }
}


// MARK: - Gesture Handling

extension VSwipePresentationInteractionController {

    struct GestureStatus {
        let verticalTranslation: CGFloat
        let velocity: CGPoint
    }

    @objc private func gestureAction(_ gesture: UIPanGestureRecognizer) {
        // create a new status object to track the translation and velocity values.
        // include the value of an interrupted animation translation to "pick up"
        // where we left off from an interrupted animation position and include
        // that translation within the gesture's current translation.
        let status = GestureStatus(
            verticalTranslation: gesture.translation(in: gesture.view).y - interruptedTranslation,
            velocity: gesture.velocity(in: gesture.view)
        )
//        print(#function + "translation: \(status.verticalTranslation), velocity: \(status.verticalVelocity)")

        switch gesture.state {
        case .began:
            gestureBegan(status)

        case .changed:
            gestureChanged(status)

        case .ended:
            gestureEnded(status)

        case .cancelled:
            gestureCancelled(status)

        default:
            break
        }
    }

    private func gestureBegan(_ status: GestureStatus) {
        guard let transitionContext = transitionContext,
              let presentedViewController = transitionContext.viewController(forKey: .to)
              else { return }

        print(#function)

        // if the user restarts a pan gesture, we want to cancel
        // the existing transition animation so we can
        // begin the dragging of the view again to keep things
        // fully interactive, even while animating to a
        // finish or cancel position in the view.
        transitionAnimator?.stopAnimation(true)

        if isInteractionInProgress {
            // store the distance of the presented view to the final frame position,
            // and later use it to include in the interrupted gesture's translation
            // so we account for the distance travelled from the interrupted gesture.
            let finalFrame = transitionContext.finalFrame(for: presentedViewController)
            interruptedTranslation = finalFrame.height - presentedViewController.view.frame.minY
            print("Interrupting animation, interruptedTranslation: \(interruptedTranslation)")
        }
    }

    private func gestureChanged(_ status: GestureStatus) {
        let progress = progress(status: status)
        updatePresentedView(progress)
    }

    private func gestureEnded(_ status: GestureStatus) {
        let progress = progress(status: status)

        // determine where to finish and start an animation to go there.
        if progress > 0.5 || status.velocity.y < -300 {
            performFinishTransition(status)
        } else {
            performCancelTransition(status)
        }

        installInterruptionGesture()
    }

    private func gestureCancelled(_ status: GestureStatus) {
        performCancelTransition(status)
    }
}


// MARK: - Progress Update

private extension VSwipePresentationInteractionController {

    private func updatePresentedView(_ progress: CGFloat) {
        guard let presentedViewController = transitionContext?.viewController(forKey: .to) else { return }

        presentedViewController.view.frame = CGRect(
            x: presentedFinalFrame.minX,
            y: presentedFinalFrame.maxY - interactionDistance * progress,
            width: presentedFinalFrame.width,
            height: presentedFinalFrame.height
        )

        transitionContext?.updateInteractiveTransition(progress)
    }

    private func progress(status: GestureStatus) -> CGFloat {
        -status.verticalTranslation / interactionDistance
    }
}


// MARK: - Interruption Gesture

private extension VSwipePresentationInteractionController {

    func installInterruptionGesture() {
        // setup a custom pan gesture within the container to respond
        // to gestures that interrupt the animation transition
        transitionContext?.containerView.addGestureRecognizer(interruptionGesture)
    }

    func removeInterruptionGesture() {
        interruptionGesture.view?.removeGestureRecognizer(interruptionGesture)
    }
}


// MARK: - Ending Transition Animations

private extension VSwipePresentationInteractionController {

    func performFinishTransition(_ status: GestureStatus) {
        guard let transitionContext = transitionContext,
              let presentedViewController = transitionContext.viewController(forKey: .to)
        else {
            assertionFailure("Presented view controller not defined, unable to finish transition")
            return
        }

        print(#function)

        let finalFrame = transitionContext.finalFrame(for: presentedViewController)
        let initialVelocity = initialVelocity(to: finalFrame.origin, from: presentedViewController.view.frame.origin, gestureVelocity: status.velocity)

        let timingParameters = UISpringTimingParameters(dampingRatio: 0.98, initialVelocity: initialVelocity)
        let finishAnimator = UIViewPropertyAnimator(duration: finalAnimationDuration, timingParameters: timingParameters)

        finishAnimator.addAnimations {
            presentedViewController.view.frame = finalFrame
        }

        finishAnimator.addCompletion { [unowned self] _ in
            self.finish()
        }

        finishAnimator.startAnimation()

        self.transitionAnimator = finishAnimator
    }

    func performCancelTransition(_ status: GestureStatus) {
        guard let transitionContext = transitionContext,
              let presentedViewController = transitionContext.viewController(forKey: .to)
        else {
            assertionFailure("Presented view controller not defined, unable to finish transition")
            return
        }

        print(#function)

        let containerFrame = transitionContext.containerView.frame
        let initialFrame = CGRect(origin: CGPoint(x: containerFrame.minX, y: containerFrame.maxY), size: presentedViewController.view.frame.size)
        let initialVelocity = initialVelocity(to: initialFrame.origin, from: presentedViewController.view.frame.origin, gestureVelocity: status.velocity)

        let timingParameters = UISpringTimingParameters(dampingRatio: 0.98, initialVelocity: initialVelocity)
        let cancelAnimator = UIViewPropertyAnimator(duration: finalAnimationDuration, timingParameters: timingParameters)

        cancelAnimator.addAnimations {
            presentedViewController.view.frame = initialFrame
        }

        cancelAnimator.addCompletion { [unowned self] _ in
            self.cancel()
        }

        cancelAnimator.startAnimation()

        self.transitionAnimator = cancelAnimator
    }

    func initialVelocity(to finalPosition: CGPoint, from currentPosition: CGPoint, gestureVelocity: CGPoint) -> CGVector {
        var vector: CGVector = .zero

        let deltaY = finalPosition.y - currentPosition.y
        if deltaY != 0 {
            vector.dy = gestureVelocity.y / deltaY
        }

        return vector
    }
}

private extension VSwipePresentationInteractionController {
    func disableOtherTouches() {
        guard let transitionContext = transitionContext,
              let presentedViewController = transitionContext.viewController(forKey: .to)
        else {
            assertionFailure("Presented view controller not defined, unable to finish transition")
            return
        }

        presentedViewController.view.subviews.forEach {
            $0.isUserInteractionEnabled = false
        }
    }

    func enableOtherTouches() {
        guard let transitionContext = transitionContext,
              let presentedViewController = transitionContext.viewController(forKey: .to)
        else {
            assertionFailure("Presented view controller not defined, unable to finish transition")
            return
        }

        presentedViewController.view.subviews.forEach {
            $0.isUserInteractionEnabled = true
        }
    }
}


extension VSwipePresentationInteractionController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = scrollView {
            return scrollView.contentOffset.y <= 0
        }

        return true
    }
}
