//
//  ViewController.swift
//  MicrophoneAnalysis
//
//  Created by Kanstantsin Linou, revision history on Githbub.
//  Copyright © 2018 AudioKit. All rights reserved.
//

import AudioKit
import AudioKitUI
import UIKit

class ViewController: UIViewController {

    @IBOutlet private var frequencyLabel: UILabel!
    @IBOutlet private var amplitudeLabel: UILabel!
    @IBOutlet private var noteNameWithSharpsLabel: UILabel!
    @IBOutlet private var noteNameWithFlatsLabel: UILabel!
    @IBOutlet private var audioInputPlot: EZAudioPlot!
    @IBOutlet weak var sing: UILabel!

    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!

    let noteFrequencies = [16.35, 17.32, 18.35, 19.45, 20.6, 21.83, 23.12, 24.5, 25.96, 27.5, 29.14, 30.87]
    let noteNamesWithSharps = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let noteNamesWithFlats = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    func setupPlot() {
        let plot = AKNodeOutputPlot(mic, frame: audioInputPlot.bounds)
        plot.plotType = .rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.blue
        audioInputPlot.addSubview(plot)

        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let name = Notification.Name("didReceiveData")
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: name, object: nil)

        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        let devices = AudioKit.inputDevices

        do {
            try mic.setDevice(devices![0])
        } catch {
            AKLog("failed")
        }

        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0)

        AudioKit.output = silence
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        setupPlot()
        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.updateUI),
                             userInfo: nil,
                             repeats: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    @objc func updateUI() {
        if tracker.amplitude > 0.1 {
            frequencyLabel.text = String(format: "%0.1f", tracker.frequency)

            var frequency = Float(tracker.frequency)
            while frequency > Float(noteFrequencies[noteFrequencies.count - 1]) {
                frequency /= 2.0
            }
            while frequency < Float(noteFrequencies[0]) {
                frequency *= 2.0
            }

            var minDistance: Float = 10_000.0
            var index = 0

            for i in 0..<noteFrequencies.count {
                let distance = fabsf(Float(noteFrequencies[i]) - frequency)
                if distance < minDistance {
                    index = i
                    minDistance = distance
                }
            }
            let octave = Int(log2f(Float(tracker.frequency) / frequency))
            noteNameWithSharpsLabel.text = "\(noteNamesWithSharps[index])\(octave)"
            noteNameWithFlatsLabel.text = "\(noteNamesWithFlats[index])\(octave)"
        }
        amplitudeLabel.text = String(format: "%0.2f", tracker.amplitude)
    }
    @IBAction func openInput(_ sender: Any) {
        let mainStoryboard = UIStoryboard.init(name: "Main", bundle: nil)

        let vc:InputTableViewController = mainStoryboard.instantiateViewController(withIdentifier: "inputConfigRoot") as! InputTableViewController
        self.present(vc, animated: true) {

        }

    }

    
    @objc func onDidReceiveData(_ notification:Notification) {
        do {
            try AudioKit.stop()
        } catch {
            AKLog("AudioKit did not start!")
        }
        do {
            mic.stop()
            try mic.setDevice(notification.object as! AKDevice)
            mic.start()
        } catch {
            AKLog("failed")
        }
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
    }


}
