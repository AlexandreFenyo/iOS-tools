import SwiftUI

struct DemoView: View {
    @State private var angle: Double = 20
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")

            ZStack {
                SpeedometerView()
                    .frame(width: 100, height: 100)
                NeedleView(size: 50, angle: $angle)
//                    .opacity(0.5)
                    .offset(y: 20)
            }
            
            Text("test1").onTapGesture {
                print("TEST1")
                withAnimation {
                    angle = 120
              }
            }
        }
        .padding()
    }
}
