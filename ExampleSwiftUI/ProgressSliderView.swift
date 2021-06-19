//
//  ProgressSliderView.swift
//  ExampleSwiftUI
//
//  Created by Yoheimuta on 2021/06/19.
//  Copyright © 2021 YOSHIMUTA YOHEI. All rights reserved.
//

import SwiftUI

struct ProgressSliderView: UIViewRepresentable {
    @Binding var value: Float
    @Binding var maximumValue: Float
    @Binding var isUserInteractionEnabled: Bool
    @Binding var playableProgress: Float
    var updateValueHandler: (Float) -> Void

    @State private var touching = false

    init(value: Binding<Float>,
         maximumValue: Binding<Float>,
         isUserInteractionEnabled: Binding<Bool>,
         playableProgress: Binding<Float>,
         updateValueHandler: @escaping (Float) -> Void) {
        self._value = value
        self._maximumValue = maximumValue
        self._isUserInteractionEnabled = isUserInteractionEnabled
        self._playableProgress = playableProgress
        self.updateValueHandler = updateValueHandler
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIProgressSlider {
        let slider = UIProgressSlider()
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.updateValue(sender:)),
            for: .valueChanged)

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.startTouch(sender:)),
            for: .touchDown)

        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.endTouch(sender:)),
            for: .touchUpInside)

        return slider
    }

    func updateUIView(_ uiView: UIProgressSlider, context: Context) {
        if !touching {
            uiView.value = value
        }
        uiView.maximumValue = maximumValue
        uiView.isUserInteractionEnabled = isUserInteractionEnabled
        uiView.playableProgress = playableProgress
        uiView.setNeedsDisplay()
    }

    class Coordinator: NSObject {
        var view: ProgressSliderView

        init(_ view: ProgressSliderView) {
            self.view = view
        }

        @objc
        func updateValue(sender: UIProgressSlider) {
            view.updateValueHandler(sender.value)
        }

        @objc
        func startTouch(sender: UIProgressSlider) {
            view.touching = true
        }

        @objc
        func endTouch(sender: UIProgressSlider) {
            view.touching = false
        }
    }
}

struct ProgressSliderView_Previews: PreviewProvider {
    @State static var value = Float(50.0)
    @State static var maximumValue = Float(50.0)
    @State static var isUserInteractionEnabled = true
    @State static var playableProgress = Float(70.0)

    static var previews: some View {
        ProgressSliderView(value: $value,
                           maximumValue: $maximumValue,
                           isUserInteractionEnabled: $isUserInteractionEnabled,
                           playableProgress: $playableProgress) {
            print("value changed: \($0)")
        }
    }
}
