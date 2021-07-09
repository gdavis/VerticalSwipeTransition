# VerticalSwipeTransition
An interactive, interruptible, and customizable vertical swipe transition for iOS. 

![20210709131637050](https://user-images.githubusercontent.com/110691/125126323-25efaa00-e0b8-11eb-823f-c1af9c950b54.gif)

This is a sample project that demonstrates using a custom transition to perform an interactive swipe to present and dismiss a view controller. The view controller is presented using a standard `present(_, animated:, completion)` method call, but implements a transitioning delegate to vend a custom animation and interaction controller.

## Features
- Vertical pan gesture to present and dismiss the modal view
- Supports embedded scroll view to dismiss when the scroll view is scrolled to the top of its content
- Supports cancellable transitions if a user interrupts the animation by interacting with a new swipe gesture
- Supports use of custom presentation controllers
- Supports customization of transition metrics, such as customizing the frame, vertical position of swipes, and max y position limits

# Usage
#### Getting Started
The example application demonstrates how to customize a presentation to make use of the vertical swipe transition. First, you define the transition controller that will be used as the transitioning delegate when presenting your view:

```swift
lazy var transitionController = TransitionController<VerticalSlideTransitionAnimator>(
    interactionController: interactionController
)
```
The `TransitionController` takes a generic animation type that will be created when the transition delegate asks for it. It must conform to `TransitionAnimator` which requires a common initialization with a simple boolean that describes if the animation is presenting or dismissing.

For interactivity, you must also provide an object conforming to `InteractionControlling` which defines a couple of properties that determines the current interaction phase of whether it is presenting or dismissing the view, and a boolean that defines if an interaction is currently in progress. For this demo app, we have a `VSwipeInteractionController` that conforms to this protocol that handles pan geture actions to update the transition as it updates the translation within the view. 

To invoke a presentation of a view controller directly from a pan gesture, you use the gesture that is provided by the `VSwipeInteractionController`. You can add that gesture to the view you want a swipe to occur on to engage the presentation. The following code shows how to add the gesture to your view, and being your presentation:

```swift
// take the interaction controller's guestre and add it to our invoking view
swipeView.addGestureRecognizer(interactionController.externalGesture)

// listen for the gesture's state to invoke presentation of the modal
interactionController.externalGesture.addTarget(self, action: #selector(gestureAction))
```
```swift
@objc func gestureAction() {
    // do not present while another presentation is in progress.
    guard presentedViewController == nil else { return }

    // create the view controller to present
    guard let viewController = ModalViewController.instantiateFromStoryboard() as? UINavigationController
    else {
        assertionFailure()
        return
    }

    // configure the presented view controller to use our custom controller,
    // and set it to use a custom presentation style to make use of it
    viewController.transitioningDelegate = transitionController
    viewController.modalPresentationStyle = .custom

    // finally present
    present(viewController, animated: true, completion: nil)
}
```

#### Supporting Content Scroll Views
The `VSwipeInteractionController` is built to handle embedded content scroll views so that you may interact with the scroll view, and still be able to dismiss the modal with a swipe action when the scroll view is at the top of its content.

Enabling this functionality is simple, just set the `scrollView` property to your content scroll view when presenting your view:
```swift
// tell the interaction controller to handle dismissal from the table view
// when it is scrolled to the top of its content
interactionController.scrollView = modalViewController.tableView
```

The interaction controller will install a new gesture onto your scroll view. This new gesture is required to fail before the `panGestureRecognizer` of scroll view is allowed to perform its normal actions. 

That's it! Your modal will now dismiss with a swipe gesture when the scroll view is scrolled to the top.

#### Custom Presentation Controllers
The `TransitionController` supports custom presentation controllers for when you need to control frame of the presented view, or need to add custom animations that occur outside of the transition itself. You can adopt the `PresentationControllerProvider` protocol to vend custom presentation controllers to the `TransitionController`. The example app uses a custom presentation controller to demonstrate this behavior.

# Support & Contribution
All code provided here is free to use, but I do not provide any help whatsoever to fix issues for your implementation. If you have a bug or feature request, please create a pull request that adjusts the code as you need it, and I will review the changes and consider making an update to the repository.

# Credits
All code was written by and developed [Grant Davis](https://grantdavisinteractive.com).

A big thanks to [Daniel Gauthier](https://danielgauthier.me/) for writing articles on custom transitions, as well as providing [example code on github](https://github.com/danielmgauthier/ViewControllerTransitionExample).

# License
[MIT License](LICENSE)
