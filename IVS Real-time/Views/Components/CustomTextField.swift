//
//  CustomTextField.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct CustomTextField: UIViewRepresentable {
    @Binding public var text: String
    var font: UIFont
    var textColor: UIColor
    var background: UIColor?
    var cornerRadius: CGFloat
    let onCommit: () -> Void

    public init(text: Binding<String>,
                font: UIFont? = UIFont(name: "Inter-SemiBold", size: 16),
                textColor: UIColor = .black,
                background: UIColor? = .clear,
                cornerRadius: CGFloat = 0,
                onCommit: @escaping () -> Void) {
        self.onCommit = onCommit
        self._text = text
        self.font = font ?? UIFont.systemFont(ofSize: 16)
        self.textColor = textColor
        self.background = background
        self.cornerRadius = cornerRadius
    }

    public func makeUIView(context: Context) -> UITextField {
        let view = TextField()
        view.returnKeyType = .send
        view.textColor = textColor
        view.backgroundColor = background ?? .clear
        view.layer.cornerRadius = cornerRadius
        view.font = font
        view.addTarget(context.coordinator, action: #selector(Coordinator.textViewDidChange), for: .editingChanged)
        view.delegate = context.coordinator
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.textAlignment = .left
        return view
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator($text, onCommit: onCommit)
    }

    public class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var onCommit: () -> Void

        init(_ text: Binding<String>, onCommit: @escaping () -> Void) {
            self.text = text
            self.onCommit = onCommit
        }

        public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onCommit()
            return false
        }

        @objc public func textViewDidChange(_ textField: UITextField) {
            self.text.wrappedValue = textField.text ?? ""
        }
    }
}

class TextField: UITextField {
    let padding = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
}
