//
//  ContentViewModel.swift
//  SleepNoise
//
//  Created by Max Buchholz on 4/7/24.
//

import Foundation
class ContentViewModel: ObservableObject {
    private var synth : Synth
    @Published var text = "Wuh Woh Waggy";
    init() {
        self.synth = Synth.init()
        synth.enableSpeaker()
        self.text = text
    }
    func updateClock(){
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        self.text = String(hour) + ":" + String(minute) + ":" + String(second)
    }
    public func setSoundPlaying(soundPlaying: Bool){
        synth.setSoundPlaying(soundPlaying: soundPlaying)
    }
}
