//
//  BottomSheetConfirmationView.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct BottomSheetConfirmationView<Content: View>: View {
    @Binding var isPresent: Bool
    var title: String
    var secondaryTitle: String?
    var contentHeight: CGFloat = 200
    var dismissTitle: String = "Cancel"
    var contentView: Content

    @State private var YOffset: CGFloat = 200
    @State private var backOpacity: CGFloat = 0.8

    func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            YOffset = 200
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            backOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresent.toggle()
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black
                .opacity(backOpacity)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismiss()
                }

            ZStack(alignment: .top) {
                Color("BackgroundWhite")
                    .cornerRadius(30)
                    .edgesIgnoringSafeArea(.bottom)

                VStack {
                    VStack(spacing: 12) {
                        Text(title)
                            .font(Constants.fInterExtraBold22)
                            .foregroundColor(.black)
                        if let secondaryTitle = secondaryTitle {
                            Text(secondaryTitle)
                                .font(Constants.fInterRegular14)
                                .foregroundColor(Color("BackgroundDark"))
                        }
                    }
                    .padding(.bottom, 40)

                    contentView

                    Button(action: {
                        dismiss()
                    }) {
                        Text(dismissTitle)
                            .frame(height: 50)
                    }
                    .modifier(PrimaryButton(color: .clear))
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
            }
            .frame(height: contentHeight)
            .offset(y: YOffset)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                YOffset = 0
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}
