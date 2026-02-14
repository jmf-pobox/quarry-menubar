import AppKit
import SwiftUI

// MARK: - SelectAllTextField

/// A text field that auto-focuses and selects all text on focus, matching Spotlight.
///
/// Uses `NSViewRepresentable` wrapping `NSTextField` because SwiftUI's `TextField`
/// does not support select-all-on-focus. Focus is requested via `makeFirstResponder`
/// in `updateNSView`. Text selection happens in `controlTextDidBeginEditing` — the
/// earliest point where the field editor is guaranteed to be installed and ready.
/// Also intercepts Escape and Return via the delegate's `doCommandBy` selector.
struct SelectAllTextField: NSViewRepresentable {

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextFieldDelegate {

        // MARK: Lifecycle

        init(text: Binding<String>, onSubmit: @escaping () -> Void, onEscape: @escaping () -> Void) {
            _text = text
            self.onSubmit = onSubmit
            self.onEscape = onEscape
        }

        // MARK: Internal

        /// When true, the next editing session will select all text.
        var selectAllOnNextFocus = true

        var onSubmit: () -> Void
        var onEscape: () -> Void

        func controlTextDidBeginEditing(_ notification: Notification) {
            guard selectAllOnNextFocus else { return }
            selectAllOnNextFocus = false
            guard let field = notification.object as? NSTextField,
                  let editor = field.currentEditor()
            else { return }
            editor.selectAll(nil)
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            _text.wrappedValue = field.stringValue
        }

        func control(
            _ control: NSControl,
            textView _: NSTextView,
            doCommandBy commandSelector: Selector
        ) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                onSubmit()
                return true
            }
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                onEscape()
                return true
            }
            return false
        }

        // MARK: Private

        @Binding private var text: String
    }

    let placeholder: String
    @Binding var text: String

    var onSubmit: () -> Void = {}
    var onEscape: () -> Void = {}

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.delegate = context.coordinator
        field.placeholderString = placeholder
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.lineBreakMode = .byTruncatingTail
        field.cell?.sendsActionOnEndEditing = false
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        // Only update stringValue when the field is NOT being edited, to avoid
        // clobbering the field editor's state (selection, cursor position).
        if nsView.currentEditor() == nil, nsView.stringValue != text {
            nsView.stringValue = text
        }

        context.coordinator.onSubmit = onSubmit
        context.coordinator.onEscape = onEscape

        // Request focus once after the field is added to a window.
        if nsView.window != nil, nsView.currentEditor() == nil {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit, onEscape: onEscape)
    }
}
