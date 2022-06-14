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
    
    public class TracesViewModel : ObservableObject {
        private let df: DateFormatter = {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return df
        }()
        
        // Contrainte à respecter : il faut toujours au moins 1 chaîne dans traces
        @Published private(set) var traces: [String] = {
            var arr = [String]()
            arr.append("")
            for i in 1...200 { arr.append("Speed Test - Traces \(i)") }
            return arr
        }()
        
        fileprivate func clear() {
            traces = [ "" ]
        }
        
        public func append(_ str: String, level _level: LogLevel = .ALL) {
            if _level.rawValue <= level.rawValue {
                traces.append(df.string(from: Date()) + ": " + str)
            }
        }
        
        @Published private(set) var level: LogLevel = .ALL
        public func setLevel(_ val: LogLevel) { level = val }
    }
    
    @ObservedObject var model = TracesViewModel()
    @State public var locked = true
    @Namespace var topID
    @Namespace var bottomID
    
    private struct ScrollViewOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = .zero
        
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value += nextValue()
        }
    }

    @State private var timer: Timer?

    var body: some View {
        GeometryReader { traceGeom in
            ScrollViewReader { scrollViewProxy in
                ZStack {
                    ScrollView {
                        ZStack {
                            LazyVStack {
                                Spacer().id(topID)
                                ForEach(0 ..< model.traces.count - 1, id: \.self) { i in
                                    Text(model.traces[i]).font(.footnote)
                                        .lineLimit(nil)
                                }
                                Text(model.traces.last!)
                                    .font(.footnote)
                                    .id(bottomID)
                                    .lineLimit(nil)
                            }
                            //                        .frame(maxWidth: .infinity).background(Color(COLORS.standard_background))
                            // Pousser le texte en bas :
                            //                        .frame(minHeight: traceGeom.size.height)
                            GeometryReader { scrollViewContentGeom in
                                Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: traceGeom.size.height - scrollViewContentGeom.size.height - scrollViewContentGeom.frame(in: .named("scroll")).minY)
                            }
                        }
                    }.coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollViewOffsetPreferenceKey.self) { value in
                            if value > 0 { locked = true }
                        }
                        .gesture(DragGesture().onChanged { _ in
                            locked = false
                        })
                        .onAppear() {
                            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                                if locked {
                                  withAnimation { scrollViewProxy.scrollTo(bottomID) }
                             }
                            }
                        }
                        .onDisappear() {
                            timer?.invalidate()
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
                                
                                // remettre car c'est essentiel pour que ça fonctionne
                                // Timer pour les tests
                                /*
                                DispatchQueue.global(qos: .userInitiated).sync {
                                    var i = 0
                                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
//                                        print("timer\(i)")
                                        model.append("timer\(i)")
                                        if locked {
                                          withAnimation { scrollViewProxy.scrollTo(bottomID) }
                                     }
                                        i += 1
                                    }
                                }*/
                                
                                
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
                                withAnimation { scrollViewProxy.scrollTo(topID) }
                            } label: {
                                Image("arrow up")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                            
                            Button {
                                locked = true
                                withAnimation { scrollViewProxy.scrollTo(bottomID) }
                            } label: {
                                Image("arrow down")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(locked ? Color.blue : Color(COLORS.standard_background).darker().darker()   ).cornerRadius(CGFloat.greatestFiniteMagnitude)
                                                    
                            Button {
                                model.clear()
                            } label: {
                                Image(systemName: "delete.left.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                            
                        }.background(Color.clear).lineLimit(1)
                        
                        Spacer()
                    }
                    //.padding() // Pour que les boutons en haut ne soient pas trop proches des bords de l'écran
                    
                }
                // Couleur de fond qui s'affiche quand on scroll au delà des limites
                .background(Color.orange)
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


