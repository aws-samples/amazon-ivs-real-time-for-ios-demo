//
//  UISliderView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 22/05/2023.
//

import SwiftUI

struct UISliderView: UIViewRepresentable {
    @Binding var value: Float

    var minValue = 1
    var maxValue = 100
    var step: Float = 50
    var thumbColor: UIColor = UIColor(named: "Orange") ?? .orange
    var minTrackColor: UIColor = UIColor(named: "Orange") ?? .orange
    var maxTrackColor: UIColor = UIColor(named: "BackgroundGray") ?? .lightGray
    var onChange: () -> Void

    class Coordinator: NSObject {
        var value: Binding<Float>
        var step: Float
        var onChange: () -> Void

        init(value: Binding<Float>, step: Float, onChange: @escaping () -> Void) {
            self.value = value
            self.step = step
            self.onChange = onChange
        }

        @objc func valueChanged(_ sender: UISlider) {
            let newValue = round(Float(sender.value) / step) * step
            self.value.wrappedValue = newValue
            self.onChange()
        }
    }

    func makeCoordinator() -> UISliderView.Coordinator {
        Coordinator(value: $value, step: step, onChange: onChange)
    }

    func makeUIView(context: Context) -> UISlider {
        let slider = UISlider(frame: .zero)
        slider.thumbTintColor = thumbColor
        slider.minimumTrackTintColor = minTrackColor
        slider.maximumTrackTintColor = maxTrackColor
        slider.minimumValue = Float(minValue)
        slider.maximumValue = Float(maxValue)
        slider.value = Float(value)

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )

        return slider
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.value = Float(value)
    }
}
