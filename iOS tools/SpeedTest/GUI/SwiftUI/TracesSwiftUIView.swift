//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

struct TracesSwiftUIView: View {
    public enum LogLevel : Int {
        case INFO = 0
        case DEBUG
        case ALL
    }
    
    public class TracesViewModel : ObservableObject
    {
        private let df: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df
        }()
        
        @Published private(set) var traces: String = {
            var str : String = ""
            for i in 1...200 { str += "Speed Test - Traces \(i)\n" }
            return str
        }()
        
        fileprivate func update(str: String) {
            traces = str
        }
        
        public func append(_ str: String, level _level: LogLevel = .ALL) {
            if _level.rawValue <= level.rawValue {
                traces += df.string(from: Date())
                traces += ": "
                traces += str
                traces += "\n"
            }
        }
        
        @Published private(set) var level: LogLevel = .ALL
        public func setLevel(_ val: LogLevel) { level = val }
    }
    
    @ObservedObject var model = TracesViewModel()
    
    @Namespace var topID
    @Namespace var bottomID
    

    
    // https://swiftwithmajid.com/2020/09/24/mastering-scrollview-in-swiftui/
    // https://developer.apple.com/forums/thread/650312
    
    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGPoint = .zero
        
        static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
            print("salut")
        }
    }

    struct MyScrollView<Content: View>: View {
        let axes: Axis.Set
        let showsIndicators: Bool
        let offsetChanged: (CGPoint) -> Void
        let content: Content

        init(
            axes: Axis.Set = .vertical,
            showsIndicators: Bool = true,
            offsetChanged: @escaping (CGPoint) -> Void = { _ in },
            @ViewBuilder content: () -> Content
        ) {
            self.axes = axes
            self.showsIndicators = showsIndicators
            self.offsetChanged = offsetChanged
            self.content = content()
        }
        
        var body: some View {
                SwiftUI.ScrollView(axes, showsIndicators: showsIndicators) {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scrollView")).origin
                        )
                    }.frame(width: 0, height: 0)
                    content
                }
                .coordinateSpace(name: "scrollView")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: offsetChanged)
            }

    }

    
    // produire un evt quand le contentOffset est au max
    
    var body: some View {
        ScrollViewReader { proxy in
            GeometryReader { geometry in
                ZStack {
                    MyScrollView {
                        VStack {
                            Spacer().id(topID)
                            
                            Text(model.traces)
                                .font(.footnote)
                                .id(bottomID)
                                .lineLimit(nil)
                            
                        }
                        .frame(maxWidth: .infinity).background(Color(COLORS.standard_background))
                        // Pousser le texte en bas :
                        .frame(minHeight: geometry.size.height)
                    }
                   
                    VStack {
                        HStack {
                            Button {
                                model.setLevel(.INFO)
                                model.append("set trace level to INFO", level: .INFO)
                            } label: {
                                Label("Level 1", systemImage: "rectangle.split.2x2")
                                    .foregroundColor(model.level != .INFO ? Color.gray : Color.blue)
                                    .disabled(model.level != .INFO).padding(12)
                            }
                            .background(model.level != .INFO ? Color(COLORS.standard_background).darker().darker() : Color(COLORS.top_down_background)).cornerRadius(20).font(.footnote)
                            
                            Button {
                                model.setLevel(.DEBUG)
                                model.append("set trace level to DEBUG", level: .INFO)
                            } label: {
                                Label("Level 2", systemImage: "tablecells")
                                    .foregroundColor(model.level != .DEBUG ? Color.gray : Color.blue)
                                    .disabled(model.level != .DEBUG).padding(12)
                            }
                            .background(model.level != .DEBUG ? Color(COLORS.standard_background).darker().darker() : Color(COLORS.top_down_background)).cornerRadius(20).font(.footnote)
                            
                            Button {
                                model.setLevel(.ALL)
                                model.append("set trace level to ALL", level: .INFO)
                            } label: {
                                Label("Level 3", systemImage: "rectangle.split.3x3")
                                    .foregroundColor(model.level != .ALL ? Color.gray : Color.blue)
                                    .disabled(model.level != .ALL).padding(12)
                            }
                            .background(model.level != .ALL ? Color(COLORS.standard_background).darker().darker() : Color(COLORS.top_down_background)).cornerRadius(20).font(.footnote)
                            
                            Spacer()
                            
                            Button {
                                withAnimation { proxy.scrollTo(topID) }
                            } label: {
                                Image("arrow up")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                            
                            Button {
                                withAnimation { proxy.scrollTo(bottomID) }
                            } label: {
                                Image("arrow down")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                            
                            Button {
                                model.update(str: "")
                            } label: {
                                Image(systemName: "delete.left.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                            
                        }.background(Color.clear).lineLimit(1)
                        
                        Spacer()
                    }.padding() // Pour que les boutons en haut ne soient pas trop proches des bords de l'écran
                    
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


