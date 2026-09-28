import Foundation

/// Ordered like a bare backspace: a screen is only left once the search field is empty.
enum PaletteEscapeAction: Equatable {
    case clearMenuQuery
    case closeMenu
    case leaveArgumentField
    case clearQuery
    case exitExtensionScreen
    case goBack
    /// A screen summoned by its own hotkey has no back step, so it falls to the root search.
    case rootSearch
    case hidePalette

    static func resolve(
        menuOpen: Bool, menuQuery: String, argumentFocused: Bool, query: String, mode: PaletteMode,
        canGoBack: Bool, behavior: EscapeKeyBehavior
    ) -> Self {
        if menuOpen { return menu(query: menuQuery) }
        // An argument field is a step deeper than the query, so it is left before anything clears.
        if argumentFocused { return .leaveArgumentField }
        if !query.isEmpty { return .clearQuery }
        guard behavior == .navigateBackOrClose else { return .hidePalette }
        // An extension pops its own navigation stack before the command is left.
        if mode == .extensionCommand { return .exitExtensionScreen }
        if canGoBack { return .goBack }
        return mode == .launcher ? .hidePalette : .rootSearch
    }

    static func menu(query: String) -> Self {
        query.isEmpty ? .closeMenu : .clearMenuQuery
    }
}
