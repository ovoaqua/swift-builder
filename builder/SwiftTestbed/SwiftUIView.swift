//
//  SwiftUIView.swift
//  SwiftTestbed
//
//  Created by Craig Rouse on 29/10/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import SwiftUI
import UIKit

struct SwiftUIView: View {
    @State var text: String = "Enter Trace ID"
    
    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 15.0) {
                Button(action: {
                    print("Track View")
                    TealiumHelper.shared.trackView(title: "iOS View", data: nil)
                },
                       label: {
                        Text("Track View")
                })
                
                Button(action: {
                    print("Track Event")
                    TealiumHelper.shared.track(title: "iOS Event", data: nil)
                },
                       label: {
                        Text("Track Event")
                })
                
                Button(action: {
                    TealiumHelper.shared.toggleConsentStatus()
                },
                       label: {
                        Text("Toggle consent status")
                })
                TextField("Trace ID", text: $text) {
                    TealiumHelper.shared.joinTrace(self.text)
                }.multilineTextAlignment(.center)
                    .border(Color.black)
                    .overlay(RoundedRectangle(cornerRadius: 4.0)
                        .stroke(lineWidth: 2.0)
                        .foregroundColor(.black))
                    .frame(width: 150.0, height: nil, alignment: .center)
                Button(action: {
                    TealiumHelper.shared.leaveTrace()
                    self.text = "Enter Trace ID"
                },
                       label: {
                        Text("Leave Trace")
                })
                
                Button(action: {
                    TealiumHelper.shared.tealium?.disable()
                }, label: {
                    Text("Stop Tealium")
                })
            }
            .navigationBarTitle("Swift Demo App")
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
