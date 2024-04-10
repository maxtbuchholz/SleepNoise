import Foundation
import AudioUnit
import AVFoundation

final class Synth: NSObject {
    
    var auAudioUnit: AUAudioUnit! = nil
    
    var avActive     = false
    var audioRunning = false
    
    var sampleRate : Double = 44100.0

    var v0  =  16383.0
    
    private var oscillator: Oscillator
    private var soundPlaying = false
    override init(){
        oscillator = Oscillator.init()
        self.lastPlayedTS = Date.now - 10.0
        self.lastSilenceTS = Date.now - 10.0
    }
    
    func setToneVolume(vol : Double) {
        v0 = vol * 32766.0
    }
    func setSoundPlaying(soundPlaying : Bool){
        self.soundPlaying = soundPlaying
    }
    
    func enableSpeaker() {
        if audioRunning { return }
        
        if (avActive == false) {
            
            do {
                
                let audioSession = AVAudioSession.sharedInstance()
                
                try audioSession.setCategory(AVAudioSession.Category.soloAmbient)
                
                var preferredIOBufferDuration = 4.0 * 0.0058
                let hwSRate = audioSession.sampleRate
                if hwSRate == 48000.0 { sampleRate = 48000.0 }
                if hwSRate == 48000.0 { preferredIOBufferDuration = 4.0 * 0.0053 }
                let desiredSampleRate = sampleRate
                try audioSession.setPreferredSampleRate(desiredSampleRate)
                try audioSession.setPreferredIOBufferDuration(preferredIOBufferDuration)
                
                NotificationCenter.default.addObserver(
                    forName: AVAudioSession.interruptionNotification,
                    object: nil,
                    queue: nil,
                    using: myAudioSessionInterruptionHandler )
                
                try audioSession.setActive(true)
                avActive = true
            } catch{
                print("Audio Session Error")
            }
        }
        do { try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: .mixWithOthers); try AVAudioSession.sharedInstance().setActive(true) } catch { print(error) }
        
        do {
            
            let audioComponentDescription = AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_RemoteIO,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0 )
            
            if (auAudioUnit == nil) {
                
                try auAudioUnit = AUAudioUnit(componentDescription: audioComponentDescription)
                
                let bus0 = auAudioUnit.inputBusses[0]
                
                let audioFormat = AVAudioFormat(
                    commonFormat: AVAudioCommonFormat.pcmFormatInt16,
                    sampleRate: Double(sampleRate),
                    channels:AVAudioChannelCount(2),
                    interleaved: true )
                    try bus0.setFormat(audioFormat!)
                auAudioUnit.outputProvider = { (
                    actionFlags,
                    timestamp,
                    frameCount,
                    inputBusNumber,
                    inputDataList ) -> AUAudioUnitStatus in
                    
                    self.fillSpeakerBuffer(inputDataList: inputDataList, frameCount: frameCount)
                    return(0)
                }
            }
            
            auAudioUnit.isOutputEnabled = true
            
            try auAudioUnit.allocateRenderResources()
            try auAudioUnit.startHardware()
            audioRunning = true
            
        } catch{
            print("Audio Error")
        }
    }
    private var lastPlayedTS : Date
    private var lastSilenceTS : Date
    private var maxTimeSinceSound = 0.15
    private var maxTimeSinceSilence = 0.05
        private func fillSpeakerBuffer(
            inputDataList : UnsafeMutablePointer<AudioBufferList>,
            frameCount : UInt32 )
        {
            let inputDataPtr = UnsafeMutableAudioBufferListPointer(inputDataList)
            let nBuffers = inputDataPtr.count
            if (nBuffers > 0) {
                
                let mBuffers : AudioBuffer = inputDataPtr[0]
                let count = Int(frameCount)
                var v = 0.0
                if (   self.v0 > 0)
                    && (self.soundPlaying )
                {
                    let elapsed = Date.now.timeIntervalSince(lastSilenceTS)
                    let perc = min(elapsed / self.maxTimeSinceSound, 1)
                    lastPlayedTS = Date.now
                    v  = self.v0 * perc ; if v > 32767 { v = 32767 }
                } else {
                    lastSilenceTS = Date.now
                    let elapsed = Date.now.timeIntervalSince(lastPlayedTS)
                    let perc = 1 - min(elapsed / self.maxTimeSinceSound, 1)
                    v = self.v0 * perc
                }
                if(v > 0){
                  oscillator.fillWithWhiteNoise(mBuffers: mBuffers, v: v, count: count)
                }else{
                    memset(mBuffers.mData, 0, Int(mBuffers.mDataByteSize))
                }
            }
        }
        
        func stop() {
            if (audioRunning) {
                auAudioUnit.stopHardware()
                audioRunning = false
            }
            if (avActive) {
                let audioSession = AVAudioSession.sharedInstance()
                do {
                     try audioSession.setActive(false)
                } catch {
                }
                 avActive = false
            }
        }
    
    private func myAudioSessionInterruptionHandler( notification: Notification ) -> Void {
        let interuptionDict = notification.userInfo
        if let interuptionType = interuptionDict?[AVAudioSessionInterruptionTypeKey] {
            let interuptionVal = AVAudioSession.InterruptionType(
                rawValue: (interuptionType as AnyObject).uintValue )
            if (interuptionVal == AVAudioSession.InterruptionType.began) {
                if (audioRunning) {
                    auAudioUnit.stopHardware()
                    audioRunning = false
                }
            }
        }
    }
}

