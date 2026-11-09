#import "DelegateForwardingObjC.h"

#import <objc/runtime.h>

static BOOL DFProtocolMethodDescription(Protocol *protocol, SEL selector, struct objc_method_description *description);

/// Looks `selector` up in a list copied from the runtime, then frees the list.
static BOOL DFProtocolListMethodDescriptionAndFree(
	Protocol *__unsafe_unretained *protocols,
	unsigned int count,
	SEL selector,
	struct objc_method_description *description
) {
	BOOL isFound = NO;
	for (unsigned int index = 0; index < count && !isFound; index++) {
		isFound = DFProtocolMethodDescription(protocols[index], selector, description);
	}
	free(protocols);
	return isFound;
}

/// Looks `selector` up in `protocol` and the protocols it inherits from, required and optional methods alike.
static BOOL DFProtocolMethodDescription(Protocol *protocol, SEL selector, struct objc_method_description *description) {
	struct objc_method_description found = protocol_getMethodDescription(protocol, selector, YES, YES);
	if (found.types == NULL) {
		found = protocol_getMethodDescription(protocol, selector, NO, YES);
	}
	if (found.types != NULL) {
		*description = found;
		return YES;
	}
	unsigned int count = 0;
	Protocol *__unsafe_unretained *parents = protocol_copyProtocolList(protocol, &count);
	return DFProtocolListMethodDescriptionAndFree(parents, count, selector, description);
}

/// Looks `selector` up in the protocols `class` and its superclasses adopt.
static BOOL DFClassMethodDescription(Class class, SEL selector, struct objc_method_description *description) {
	for (Class current = class; current != Nil; current = class_getSuperclass(current)) {
		unsigned int count = 0;
		Protocol *__unsafe_unretained *protocols = class_copyProtocolList(current, &count);
		if (DFProtocolListMethodDescriptionAndFree(protocols, count, selector, description)) {
			return YES;
		}
	}
	return NO;
}

@implementation DFDelegateProxyBase

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
	NSMethodSignature *signature = [super methodSignatureForSelector:selector];
	if (signature != nil) {
		return signature;
	}
	struct objc_method_description description;
	if (DFClassMethodDescription(object_getClass(self), selector, &description)) {
		return [NSMethodSignature signatureWithObjCTypes:description.types];
	}
	return nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
	// Forwarding got here because `forwardingTargetForSelector:` had no target. Ask once more in case one has
	// appeared since; otherwise the call is dropped and the invocation's zeroed return value stands.
	id target = [self forwardingTargetForSelector:invocation.selector];
	if (target != nil && target != self && [target respondsToSelector:invocation.selector]) {
		[invocation invokeWithTarget:target];
	}
}

@end
