import SwiftUI

// Select the property wrapper explicitly: the macOS 27 SDK also declares a
// State macro whose SwiftUIMacros plugin is absent from Command Line Tools.
typealias ViewState<Value> = SwiftUI.State<Value>
