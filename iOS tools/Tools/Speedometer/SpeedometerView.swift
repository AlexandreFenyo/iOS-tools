import Foundation
import SwiftUI

struct SpeedometerView: View {
    @State var width: CGFloat = 0
    @State var height: CGFloat = 0

    let image = UIImage(named: "compteur")

    var body: some View {

        GeometryReader { geometry in
            
            if #available(iOS 17.0, *) {
                Image("compteur")
                    .resizable()
                    .background(.red)
                    .scaledToFit()
                    .clipped()
                    .frame(width: width, height: height)
                    .clipped()
                    .border(.black)
                    .background(.blue)
                    .opacity(0.8)
                    .onAppear {
                        print("appear: width=\(geometry.size.width)")
                        width = geometry.size.width
                        height = geometry.size.height
                    }
                    .onChange(of: geometry.size) { _, size in
                        print("change: width=\(size.width)")
                        width = size.width
                        height = size.height
                    }
            } else {
                Image("compteur")
                    .resizable()
                    .background(.red)
                    .scaledToFit()
                    .clipped()
                    .frame(width: width, height: height)
                    .clipped()
                    .border(.black)
                    .background(.blue)
                    .opacity(0.8)
                    .onAppear {
                        print("appear: width=\(geometry.size.width)")
                        width = geometry.size.width
                        height = geometry.size.height
                    }
                    .onChange(of: geometry.size) { size in
                        print("change: width=\(size.width)")
                        width = size.width
                        height = size.height
                    }
            }

            Text("250").position(x: 85, y: 74)
                .font(.system(size: 5))

        }.background(.yellow)

//        Text("sous image")

        //.onAppear {            print("debut")        }
    }
}
