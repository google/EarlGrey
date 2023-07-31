import Foundation

/// A Swift class that is compatible with EarlGrey, for testing EarlGrey’s Swift support.
///
/// To be compatible with EarlGrey, the class’s members need to be marked `@objc dynamic` because
/// EarlGrey relies on Objective-C message dispatch to forward method calls across processes. The
/// class itself does not need to be marked `@objc`, but it must inherit from `NSObject` or a
/// subclass so that the compiler uses the Objective-C runtime for object allocation instead of the
/// Swift runtime.
@objcMembers
public class EarlGreyCompatibleSwiftClass: NSObject {
  private let instanceMethodReturnValue: Int

  public required dynamic init(instanceMethodReturnValue: Int) {
    self.instanceMethodReturnValue = instanceMethodReturnValue

    super.init()
  }

  public class dynamic func myClassMethod(returnValue: Int) -> Int {
    return returnValue
  }

  public dynamic func myInstanceMethod() -> Int {
    return instanceMethodReturnValue
  }
}
