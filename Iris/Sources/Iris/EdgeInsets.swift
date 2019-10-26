#if os(iOS) || os(tvOS) || os(watchOS)

import UIKit

public typealias EdgeInsets = UIEdgeInsets

#elseif os(macOS)

import Cocoa

public typealias EdgeInsets = NSEdgeInsets

extension EdgeInsets {

    public static var zero: EdgeInsets {
        EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

}

#endif
