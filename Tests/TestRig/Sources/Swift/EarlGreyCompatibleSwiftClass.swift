import Foundation

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
