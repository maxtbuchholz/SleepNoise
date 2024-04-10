//
//  ContentView.swift
//  SleepNoise
//
//  Created by Max Buchholz on 4/7/24.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel()
    @State private var soundPlaying = false
    @State private var transparency = 0.0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    var body: some View {
        VStack {
            Image(systemName: "mic.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("\(viewModel.text)").onReceive(timer){ _ in
                viewModel.updateClock()}
            Button{
                soundPlaying.toggle()
                viewModel.setSoundPlaying(soundPlaying: soundPlaying)
                transparency = 0.4
                withAnimation(.easeOut(duration: 0.2)){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                        transparency = 0.0
                    }
                }
            } label :{
                ZStack{
                    Circle().frame(width: 90, height: 90).opacity(transparency).tint(Color.accentColor)
                    Image(systemName: "pause.fill").font(.system(size: 64)).scaleEffect(soundPlaying ? 1 : 0).opacity(soundPlaying ? 1 : 0).animation(.interpolatingSpring(stiffness: 170, damping: 15), value: soundPlaying).tint(Color.accentColor)
                    Image(systemName: "play.fill").font(.system(size: 64)).scaleEffect(soundPlaying ? 0 : 1).opacity(soundPlaying ? 0 : 1).animation(.interpolatingSpring(stiffness: 170, damping: 15), value: !soundPlaying).tint(Color.accentColor)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
