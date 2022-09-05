func SetOfClasses(prefix: String, postfix: String) -> [AnyClass]
{
    let expectedClassCount = objc_getClassList(nil, 0)
    let allClasses = UnsafeMutablePointer<AnyClass>.allocate(capacity: numericCast(expectedClassCount))
    defer { allClasses.deallocate() }
    let actualClassCount = objc_getClassList(AutoreleasingUnsafeMutablePointer<AnyClass>(allClasses), expectedClassCount)

    return stride(from: allClasses, to: allClasses.advanced(by: numericCast(actualClassCount)), by: 1).compactMap { c in
        let klass: AnyClass = c.pointee
        let name = String(describing: klass)
        return name.hasPrefix(prefix) && name.hasSuffix(postfix) ? klass : nil
    }
}

func Object(by anyClass: AnyClass) -> NSObject
{
    return (anyClass as! NSObject.Type).init()
}
