//
//  TracesSwiftUIView.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

// https://useyourloaf.com/blog/adapting-swiftui-label-style/
struct AdaptiveLabelStyle: LabelStyle {
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  func makeBody(configuration: Configuration) -> some View {
    if horizontalSizeClass == .compact {
      VStack {
        configuration.icon
        configuration.title
      }
    } else {
      Label(configuration)
    }
  }
}

public class TracesViewModel : ObservableObject {
    static let shared = TracesViewModel()
    
    private let log_level_to_string: [LogLevel: String] = [
        LogLevel.INFO: "INFO",
        LogLevel.DEBUG: "DEBUG",
        LogLevel.ALL: "ALL"
    ]
    
    private let df: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    
    // Contrainte à respecter : il faut toujours au moins 1 chaîne dans traces
    // le 7 mars 2023 : Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates. => identifier pourquoi et corriger
    // Idem le 15 juin
    @Published private(set) var traces: [String] = {
        var arr = [String]()
        arr.append("")
        for i in 1...200 {
//                arr.append("Speed Test - Traces zfeiopjf oifj o jefozi jeofjioj ei jozefij ezoi jezo ijezo ijezoi ejzfo jzeo jzefi oezfj ziefo jzeo ijzef oizejfoize jfezo ijzefo ijzef ozefj zieo jezio jzeoi jzeofi jezo ijzeoi jzeoi jzeoi jezo ijzeo ijzeo ijzeio jzeio j \(i)")
//                arr.append("Speed Test - Traces \(i)")
        }
        return arr
    }()
    
    fileprivate func clear() {
        traces = [ "" ]
    }
    
    public func append(_ str: String, level _level: LogLevel = .ALL) {
        if _level.rawValue <= level.rawValue {
            let level = log_level_to_string[_level]!
            traces.append(df.string(from: Date()) + " [" + level + "]: " + str)
        }
    }
    
    @Published private(set) var level: LogLevel = .ALL
    public func setLevel(_ val: LogLevel) { level = val }
}

public enum LogLevel : Int {
    case INFO = 0
    case DEBUG
    case ALL
}

struct TracesSwiftUIView: View {
    @ObservedObject var model = TracesViewModel.shared
    
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
                            LazyVStack(alignment: .leading, spacing: 0) {
                                Spacer().id(topID)
                                ForEach(0 ..< model.traces.count - 1, id: \.self) { i in
                                    Text(model.traces[i]).font(.footnote)
                                        .lineLimit(nil)
                                        .foregroundColor(Color(COLORS.standard_background.darker().darker()))
                                }
                                Text(model.traces.last!)
                                    .font(.footnote)
                                    .id(bottomID)
                                    .lineLimit(nil)
                                    .foregroundColor(Color(COLORS.standard_background.darker().darker()))
                            }.padding()
                            
                            GeometryReader { scrollViewContentGeom in
                                Color.clear.preference(key: ScrollViewOffsetPreferenceKey.self, value: traceGeom.size.height - scrollViewContentGeom.size.height - scrollViewContentGeom.frame(in: .named("scroll")).minY)
                            }
                        }
                    }
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
                                Label("INFO", systemImage: "rectangle.split.2x2")
                                    .labelStyle(AdaptiveLabelStyle())
                                    .foregroundColor(model.level != .INFO ? Color.gray : Color.white.lighter())
                                    .disabled(model.level != .INFO).padding(12)
                                    .font(.footnote)
                            }
                            .background(model.level != .INFO ? Color(COLORS.standard_background).darker().darker() : COLORS.tabbar_bg5).cornerRadius(20).font(.footnote)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
                            
                            Button {
                                model.setLevel(.DEBUG)
                                model.append("set trace level to DEBUG", level: .INFO)
                            } label: {
                                Label("DEBUG", systemImage: "tablecells")
                                    .labelStyle(AdaptiveLabelStyle())
                                    .foregroundColor(model.level != .DEBUG ? Color.gray : Color.white.lighter())
                                    .disabled(model.level != .DEBUG).padding(12)
                                    .font(.footnote)
                            }
                            .background(model.level != .DEBUG ? Color(COLORS.standard_background).darker().darker() : COLORS.tabbar_bg5).cornerRadius(20)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
                            
                            Button {
                                model.setLevel(.ALL)
                                model.append("set trace level to ALL", level: .INFO)
                            } label: {
                                Label("ALL", systemImage: "rectangle.split.3x3")
                                    .labelStyle(AdaptiveLabelStyle())
                                    .foregroundColor(model.level != .ALL ? Color.gray : Color.white.lighter())
                                    .disabled(model.level != .ALL).padding(12)
                                    .font(.footnote)
                            }
                            .background(model.level != .ALL ? Color(COLORS.standard_background).darker().darker() : COLORS.tabbar_bg5).cornerRadius(20)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
                            
                            Spacer()
                            
                            Button {
                                withAnimation { scrollViewProxy.scrollTo(topID) }
                            } label: {
                                Image("arrow up")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
                            
                            Button {
                                locked = true
                                withAnimation { scrollViewProxy.scrollTo(bottomID) }
                            } label: {
                                Image("arrow down")
                                    .renderingMode(.template)
                                    .foregroundColor(locked ? Color.white : .gray)
                                    .padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker())
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
                            
                            Button {
                                model.clear()
                            } label: {
                                Image(systemName: "delete.left.fill")
                                    .renderingMode(.template)
                                    .foregroundColor(.gray).padding(12)
                            }
                            .background(Color(COLORS.standard_background).darker().darker()).cornerRadius(CGFloat.greatestFiniteMagnitude)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(COLORS.right_pannel_bg), lineWidth: 3))
                            
                        }.background(Color.clear).lineLimit(1)
                        
                        Spacer()
                    }
                    .padding() // Pour que les boutons en haut ne soient pas trop proches des bords de l'écran
                }
                .background(Color(COLORS.right_pannel_bg))
            }
        }
    }
}

struct TracesSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        TracesSwiftUIView()
    }
}


