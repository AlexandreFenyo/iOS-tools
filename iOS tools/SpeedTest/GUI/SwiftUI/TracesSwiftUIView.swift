//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI
import UIKit

struct TracesSwiftUIView: View {
    public class TracesViewModel : ObservableObject
    {
        @Published private(set) var traces: String = "initstring"
        public func update(str: String) { traces = str }
        public func append(str: String) { traces += str }
    }

    public class TracesViewModel2
    {
        private(set) var traces: String = "initstring"
        public func update(str: String) { traces = str }
        public func append(str: String) { traces += str }
    }

    @ObservedObject var model = TracesViewModel()
    @State var model2: TracesViewModel2 = TracesViewModel2()

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
                            Text(model2.traces)

                                .id(bottomID)
                            .lineLimit(nil)
                        }.frame(maxWidth: .infinity).background(Color.yellow)
                            .frame(minHeight: geometry.size.height)
                    }
                }

                VStack {
                    HStack {
                        Button {
                            withAnimation {
                                proxy.scrollTo(bottomID)
                            }
                        } label: {
                            Label("Scroll to bottom", systemImage: "network").foregroundColor(.green).padding()
                        }.background(Color.blue).cornerRadius(20)

                        Button {
                            for _ in 1..<200 {
                                // marche pas car il faut créer un nouveau modèle !
                                model.append(str: "text ")
                                model2.append(str: "text ")
                                // content += "test "
                                // addText("test ")
                            }
                        } label: {
                            Text("Add lines").foregroundColor(.green).padding()
                        }
                        .background(Color.blue).cornerRadius(20).padding()

                        Spacer()
                        
                        Button {
                            model.update(str: "CLEARED")
                            model2.update(str: "CLEARED")
                        } label: {
                            Label("do not use", systemImage: "arrow.down.to.line.circle.fill").padding()
                        }
                        .background(Color.gray).cornerRadius(20)

                        Button {
                            model.update(str: "")
                            model2.update(str: "")
                        } label: {
                            Image(systemName: "delete.left.fill").padding()
                        }
                        .background(Color.gray).cornerRadius(20)

                        // arrow.down.to.line.circle.fill
                        // arrow.down.up.line.circle.fill

                    }.background(Color.clear)
                    
                    Spacer()
                }.padding()
                
//                Spacer().background(Color.blue)

            }.background(Color.orange)
            .background(Color(red: 0.478, green: 0.539, blue: 0.613))
        }
    }
    }
}

/*
struct TracesSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TracesSwiftUIView(content2: Binding<String>)
    }
}
*/
