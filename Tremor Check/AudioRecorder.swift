import AVFoundation
import SwiftUI
import Speech

// MARK: - AudioRecorder Class

/**
 `AudioRecorder` is responsible for recording audio and processing it through the Speech framework to provide live audio-to-text transcription.
 
 It maintains the state of the recording process and updates the recognized text in real time. The class uses AVFoundation for audio recording,
 the Speech framework for recognition, and conforms to `ObservableObject` to allow UI updates via SwiftUI.
 */
class AudioRecorder: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    /// Optional audio recorder that writes audio data to a file.
    var audioRecorder: AVAudioRecorder?
    
    /// Indicates whether recording is currently in progress.
    @Published var isRecording = false
    
    /// Holds the text that has been recognized by the speech recognizer.
    @Published var recognizedText: String = ""
    
    /// URL where the recorded audio is saved.
    var audioFileURL: URL?
    
    // MARK: Speech Recognition Components
    
    /// The speech recognizer instance that handles converting audio to text.
    private let speechRecognizer = SFSpeechRecognizer()
    
    /// The recognition request that buffers the audio data for speech recognition.
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    /// The active recognition task for the speech recognizer.
    private var recognitionTask: SFSpeechRecognitionTask?
    
    /// Audio engine that manages the audio signal chain for capturing live audio.
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initializer
    
    /**
     Initializes a new `AudioRecorder` instance and requests speech recognition authorization.
     
     On initialization, the app asks the user for permission to use speech recognition. The authorization status is logged accordingly.
     */
    override init() {
        super.init()
        
        // Request authorization for speech recognition.
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Handle the various authorization statuses.
            switch authStatus {
            case .authorized:
                print("Speech recognition authorized.")
            case .denied, .restricted, .notDetermined:
                print("Speech recognition not authorized.")
            @unknown default:
                print("Unknown speech recognition authorization status.")
            }
        }
    }
    
    // MARK: - Recording Control Methods
    
    /**
     Starts recording audio and sets up live speech recognition.
     
     This method performs several tasks:
     - Checks if the speech recognizer is available.
     - Configures the audio session for recording.
     - Creates a file URL for saving the recorded audio.
     - Sets up the audio recorder with desired audio settings.
     - Initiates the speech recognition process to transcribe live audio.
     */
    func startRecording() {
        // Ensure that the speech recognizer exists and is available.
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available.")
            return
        }
        
        // Reset any previously recognized text and update recording state.
        recognizedText = ""
        isRecording = true
        
        // Configure the shared audio session.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set the session category to record and measurement mode, while ducking other audio.
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            // Activate the audio session.
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        // Create a file URL in the document directory to save the recording.
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                     .appendingPathComponent("recording.m4a")
        audioFileURL = url
        
        // Define audio recording settings.
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC), // Use AAC encoding.
            AVSampleRateKey: 44100,                    // Sample rate in Hz.
            AVNumberOfChannelsKey: 1,                  // Mono audio.
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue  // High quality encoding.
        ]
        
        do {
            // Initialize the audio recorder with the file URL and settings.
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            // Start recording immediately.
            audioRecorder?.record()
        } catch {
            print("Error starting recording: \(error)")
            return
        }
        
        // Begin the live speech recognition process.
        startSpeechRecognition()
    }
    
    /**
     Stops the audio recording and ends the speech recognition process.
     
     This method stops the audio recorder and also stops the audio engine and recognition task to ensure clean termination.
     */
    func stopRecording() {
        // Stop the audio recorder.
        audioRecorder?.stop()
        // Update the recording state.
        isRecording = false
        // Stop the speech recognition process.
        stopSpeechRecognition()
    }
    
    // MARK: - Speech Recognition Methods
    
    /**
     Sets up and starts the speech recognition task.
     
     This method:
     - Cancels any existing recognition task.
     - Creates a new recognition request.
     - Installs an audio tap on the input node to continuously capture audio buffers.
     - Prepares and starts the audio engine.
     - Initiates the recognition task that processes the audio buffers and updates the recognized text.
     */
    private func startSpeechRecognition() {
        // If a recognition task is already running, cancel it.
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Create a new recognition request to handle live audio buffers.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request.")
            return
        }
        
        // Enable reporting of partial results (live transcription updates).
        recognitionRequest.shouldReportPartialResults = true
        
        // Obtain the input node (microphone) from the audio engine.
        let inputNode = audioEngine.inputNode
        // Get the format in which the audio node outputs audio.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Remove any previous audio tap on the input node.
        inputNode.removeTap(onBus: 0)
        // Install a new audio tap to capture audio buffers and append them to the recognition request.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        // Prepare the audio engine for starting.
        audioEngine.prepare()
        do {
            // Start the audio engine to begin capturing audio.
            try audioEngine.start()
        } catch {
            print("Audio Engine couldn't start: \(error)")
            return
        }
        
        // Start the speech recognition task using the recognition request.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            // If a result is available, update the recognized text on the main thread.
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            // If an error occurs or the result is final, stop the audio engine and remove the tap.
            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        }
    }
    
    /**
     Stops the speech recognition process.
     
     This method stops the audio engine, signals the end of audio to the recognition request,
     cancels any ongoing recognition task, and clears related properties.
     */
    private func stopSpeechRecognition() {
        // Stop capturing audio.
        audioEngine.stop()
        // Inform the recognition request that no more audio will be appended.
        recognitionRequest?.endAudio()
        // Cancel any active recognition task.
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
