# ObjCRuntimeTools

[![CI](https://github.com/davdroman/objc-runtime-tools/actions/workflows/ci.yml/badge.svg)](https://github.com/davdroman/objc-runtime-tools/actions/workflows/ci.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavdroman%2Fobjc-runtime-tools%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/davdroman/objc-runtime-tools)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdavdroman%2Fobjc-runtime-tools%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/davdroman/objc-runtime-tools)
[![](https://img.shields.io/badge/Documentation-gray?logo=swift&logoColor=white)](https://swiftpackageindex.com/davdroman/objc-runtime-tools/main/documentation/objcruntimetools)

ObjCRuntimeTools is a Swift library that provides powerful tools for working with Objective-C runtime features, including property association and method swizzling. It leverages modern Swift macros to simplify and enhance the use of these runtime capabilities.

## Features

- **Property Association**: easily associate properties with Objective-C objects using the `@Associated` macro.
- **Delegate Forwarding**: intercept some of an object's delegate calls while its existing delegate keeps receiving the rest, with `DelegateProxy`.
- **Swizzling**: perform type-safe and boilerplate-free runtime swizzling with the `#swizzle` macro.

## Installation

Add `ObjCRuntimeTools` to your Swift Package Manager dependencies:

```swift
.package(url: "https://github.com/davdroman/objc-runtime-tools", from: "0.1.0"),
```

Then, add the dependency to your desired target:

```swift
.product(name: "ObjCRuntimeTools", package: "objc-runtime-tools"),
```

## Usage

### Property Association

Use the `@Associated` macro to associate properties with Objective-C objects:

```swift
class MyClass: NSObject {}

extension MyClass {
    @Associated(.retain(.nonatomic))
    var associatedProperty: String = "Default Value"
}
```

### Delegate Forwarding

Subclass `DelegateProxy` to take over an object's delegate slot without replacing its delegate. The proxy handles the methods it implements and forwards every other call to the delegate it replaced, which stays in place when the proxy is released.

This is useful when a framework owns a delegate you can't replace, such as the presentation controller delegate SwiftUI sets for a sheet:

```swift
@MainActor
final class DismissInterceptor: DelegateProxy<any UIAdaptivePresentationControllerDelegate>,
    UIAdaptivePresentationControllerDelegate
{
    var isDismissible = true

    func presentationControllerShouldDismiss(_ controller: UIPresentationController) -> Bool {
        isDismissible && forwardee?.presentationControllerShouldDismiss?(controller) ?? true
    }
}

interceptor.install(on: presentationController, at: \.delegate)
```

Methods the proxy implements replace the original delegate's, so call through `forwardee` to keep its behavior. Installing again on the slot the proxy already holds does nothing, so it's safe to call from callbacks that repeat.

`DelegateProxy` itself isn't isolated: the subclass takes the isolation of the delegate protocol. Delegates UIKit and AppKit call on the main actor get a `@MainActor` subclass, and delegates a framework calls from its own threads, such as `XMLParserDelegate` or `URLSessionTaskDelegate`, get a nonisolated subclass that protects its own state. When the delegate protocol inherits `Sendable`, as `URLSessionTaskDelegate` does, declare the subclass `@unchecked Sendable` too:

```swift
final class CompletionObserver: DelegateProxy<any URLSessionTaskDelegate>, URLSessionTaskDelegate, @unchecked Sendable {
    let completions = Mutex(0)

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        completions.withLock { $0 += 1 }
        forwardee?.urlSession?(session, task: task, didCompleteWithError: error)
    }
}
```

The proxy gives the slot back in the isolation it was installed from. Releasing or uninstalling it from somewhere else schedules that write on the right actor instead of performing it immediately. Some owners stop accepting delegates at some point, such as a `URLSessionTask` once resumed, so a proxy on one of those has to outlive it.

### Swizzling

Use the `#swizzle` macro to perform function, getter, or setter swizzling.

#### Function Swizzling

```swift
try #swizzle(UIViewController.viewDidLoad) { $self in
    print("Before")
    self.viewDidLoad()
    print("After")
}

try #swizzle(UIViewController.viewDidAppear, params: Bool.self) { $self, animated in
    print("Before")
    self.viewDidAppear(animated)
    print("After")
}

try #swizzle(UITextField.resignFirstResponder, returning: Bool.self) { $self in
    print("Before")
    let result = self.resignFirstResponder()
    print("After")
    return result
}

try #swizzle(
    UIScrollView.touchesShouldBegin,
    params: Set<UITouch>.self, UIEvent?.self, UIView.self,
    returning: Bool.self
) { $self, touches, event, view in
    print("Before")
    let result = self.touchesShouldBegin(touches, with: event, in: view)
    print("After")
    return result
}
```

#### Getter and Setter Swizzling

```swift
try #swizzle(getter: \UIView.isHidden, returning: Bool.self) { $self in
    print("Before")
    let isHidden = self.isHidden
    print("After")
    return isHidden
}
```

```swift
try #swizzle(setter: \UIView.isHidden, param: Bool.self) { $self, isHidden in
    print("Before")
    self.isHidden = isHidden
    print("After")
}
```

#### ⚠️ Important: how to swizzle only once ⚠️

It's up to you to ensure that the swizzling is done only once. You can use a static variable to track whether the swizzling has already been performed:

```swift
class MyClass: NSObject {
    static var isSwizzled = false

    static func swizzleOnce() throws {
        guard !MyClass.isSwizzled else { return }
        MyClass.isSwizzled = true

        try #swizzle(MyClass.doSomething) { $self in
            print("Before")
            self.doSomething()
            print("After")
        }
    }
}
```

However this is error prone, noisy and not very maintainable, especially if you have multiple swizzling points. Not to mention Swift 6's strict concurrency rules, which will make this approach even more difficult because static variables aren't thread-safe by default.

A better approach is to use a macro such as [`#once`](https://github.com/davdroman/swift-once-macro) which ensures any action is executed only once, regardless of how many times it is called over the lifetime of the app.

```swift
class MyClass: NSObject {
    static func swizzleOnce() throws {
        try #once {
            try #swizzle(MyClass.doSomething) { $self in
                print("Before")
                self.doSomething()
                print("After")
            }
        }
    }
}
```

## Development

Install [Mise](https://mise.jdx.dev/), then install the project tools and Git hooks:

```sh
mise install
mise exec -- hk install --mise
```

## Credits

This library is inspired by and builds upon the following projects:

- [AssociatedObject](https://github.com/p-x9/AssociatedObject)
- [InterposeKit](https://github.com/steipete/InterposeKit)
