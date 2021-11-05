//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

// types de traces : selon verbosité

struct TracesSwiftUIView: View {
    public class TracesViewModel : ObservableObject
    {
        @Published private(set) var traces: String = "initstring"
        public func update(str: String) { traces = str }
        public func append(str: String) { traces += str }

        @Published private(set) var level: Int = 1
        public func setLevel(_ val: Int) { level = val }
    }

    @ObservedObject var model = TracesViewModel()

    @Namespace var topID
    @Namespace var bottomID

    var body: some View {
        ScrollViewReader { proxy in
        GeometryReader { geometry in
            ZStack {
                VStack {
                    ScrollView {
                        VStack {
                            Spacer()
                            .id(topID)
                            Text(model.traces)
                            .id(bottomID)
                            .lineLimit(nil)
                        }.frame(maxWidth: .infinity).background(Color(COLORS.standard_background))
                            .frame(minHeight: geometry.size.height)
                    }
                }

                VStack {
                    HStack {
                        Button {
                            model.setLevel(1)
                        } label: {
                            Label("level 1", systemImage: "rectangle.split.2x2")
                                .foregroundColor(model.level != 1 ? Color.gray : Color.blue)
                                .disabled(model.level != 1).padding()
                        }
                        .background(model.level != 1 ? Color(COLORS.standard_background).darker().darker() : Color(COLORS.top_down_background)).cornerRadius(20)

                        Button {
                            model.setLevel(2)
                        } label: {
                            Label("level 2", systemImage: "tablecells")
                                .foregroundColor(model.level != 2 ? Color.gray : Color.blue)
                                .disabled(model.level != 2).padding()
                        }
                        .background(model.level != 2 ? Color(COLORS.standard_background).darker().darker() : Color(COLORS.top_down_background)).cornerRadius(20)

                        Button {
                            model.setLevel(3)
                        } label: {
                            Label("level 3", systemImage: "rectangle.split.3x3")
                                .foregroundColor(model.level != 3 ? Color.gray : Color.blue)
                                .disabled(model.level != 3).padding()
                        }
                        .background(model.level != 3 ? Color(COLORS.standard_background).darker().darker() : Color(COLORS.top_down_background)).cornerRadius(20)

                        Spacer()

                        Button {
                            model.update(str: "CLEARED")
                        } label: {
                            Image("arrow up")
                                .renderingMode(.template)
                                .foregroundColor(.gray).padding()
                        }
                        .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(20)

                        Button {
                            model.update(str: "CLEARED")
                        } label: {
                            Image("arrow down")
                                .renderingMode(.template)
                                .foregroundColor(.gray).padding()
                        }
                        .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(20)

                        Button {
                            model.update(str: "")
                        } label: {
                            Image(systemName: "delete.left.fill")
                                .renderingMode(.template)
                                .foregroundColor(.gray).padding()
                        }
                        .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(20)

                        // arrow.down.to.line.circle.fill
                        // arrow.down.up.line.circle.fill

                    }.background(Color.clear)
                    
                    Spacer()
                }.padding()

            }
            // Couleur de fond qui s'affiche quand on scroll au delà des limites
            // .background(Color.orange)
            .background(Color(COLORS.standard_background))
        }
    }
    }
}

struct TracesSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TracesSwiftUIView()
    }
}
