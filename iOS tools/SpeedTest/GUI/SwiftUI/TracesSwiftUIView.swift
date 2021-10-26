//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

struct TracesSwiftUIView: View {
    @State private var content: String = "test"
    
    init() {
        UITextView.appearance().backgroundColor = .clear
        print(UITextView.appearance())
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Button(action: {
                        for _ in 1..<200 { content += "test " }
                    }) {
                        /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
                    }
                    .background(Color.blue)
                }
                
                Spacer().background(Color.blue)

                ScrollView {
                            VStack {
                                Text(content)
                                    .lineLimit(nil)
                            }.frame(maxWidth: .infinity)
                        }
                /*
                TextEditor(text: $content)
                    .onChange(of: content) { newValue in
                        print(newValue)
                        content = ""
                    }
                    .background(Color.green)
                 */
            }
            .background(Color(red: 0.478, green: 0.539, blue: 0.613))
        }
    }
}

struct TracesSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TracesSwiftUIView()
    }
}
