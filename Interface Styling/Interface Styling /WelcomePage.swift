//
//  WelcomePage.swift
//  ChatPrototype
//
//  Created by MJ Moshiri on 9/29/25.
//


import SwiftUI


struct WelcomePage: View {
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 30)
                    .frame(width: 150, height: 150)
                    .foregroundStyle(.tint)
                
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 70))
                    .foregroundStyle(.white)
            }
            
            Text("Welcome to My App")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top)


            
            Text("Description text")
                .font(.title2)
            
        }
        
        .padding()
        
    }
}


#Preview {
    WelcomePage()
}