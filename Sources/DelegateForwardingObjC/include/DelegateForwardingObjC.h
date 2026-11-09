#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The Objective-C part of `DelegateProxy`: drops calls that reach message forwarding without a target.
///
/// Frameworks such as UIKit decide which methods a delegate implements once, when it's assigned, so after the
/// delegate a proxy forwards to goes away they keep calling methods only that delegate implemented. Those calls
/// have no target, and without a method signature the process would crash. This class answers with the signature
/// from the delegate protocol the subclass adopts and lets the invocation return its zeroed result. Swift can't
/// override `methodSignatureForSelector:` or `forwardInvocation:`, so this lives in Objective-C.
NS_SWIFT_NAME(DelegateProxyBase)
@interface DFDelegateProxyBase : NSObject
@end

NS_ASSUME_NONNULL_END
