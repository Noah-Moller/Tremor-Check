# Tremor Check

Tremor Check is an iOS application that I made for my Swift Student Challenge 2025 submission. The app is designed to help assess and monitor Parkinon's tremors through voice analysis and finger stability tests. The app provides a comprehensive suite of tools for tracking and analyzing tremor symptoms using modern iOS technologies.

## Screenshots

![Simulator Screenshot - iPad Pro 11-inch (M4) - 2025-02-21 at 12 00 12](https://github.com/user-attachments/assets/c7d4ea39-6219-4917-a27e-7432d1d34933)
![Simulator Screenshot - iPad Pro 11-inch (M4) - 2025-02-21 at 11 59 45](https://github.com/user-attachments/assets/ffc6eb80-7715-4c08-8a00-df44e8636948)
![Simulator Screenshot - iPad Pro 11-inch (M4) - 2025-02-21 at 11 59 40](https://github.com/user-attachments/assets/81e827df-73f8-4ac1-b7aa-2b2db192839b)


## Features

### 1. Voice Assessment
- Real-time voice recording and analysis
- Speech recognition capabilities
- Audio feature extraction for tremor analysis
- Voice box visualization with AR support
- Multiple phrase testing scenarios

### 2. Finger Stability Test
- Interactive finger stability assessment
- Real-time motion tracking
- Quantitative measurement of tremor intensity

### 3. Results and Analytics
- Detailed tremor reports
- Audio analytics visualization
- PDF report generation
- Historical data tracking

### 4. Additional Features
- Interactive 3D model of larynx muscles and ligaments
- Educational articles about tremors
- Tips and guidance for users
- User-friendly onboarding experience

## Technical Details

### Technologies Used
- SwiftUI for the user interface
- SwiftData for persistent storage
- CoreML for machine learning capabilities
- ARKit for augmented reality features
- Speech framework for voice recognition
- PDFKit for report generation

### Key Components
- `AudioRecorder`: Handles voice recording functionality
- `ExtractAudioFeatures`: Processes and analyzes audio data
- `VoiceAssessment`: Manages voice-based tremor assessment
- `FingerStabilityTestView`: Handles finger tremor testing
- `TremorReportView`: Generates comprehensive assessment reports

## Audio Analysis Algorithm

The app employs a sophisticated audio analysis system that extracts multiple features from voice recordings to assess tremor characteristics. Here are the key metrics analyzed:

### Core Measurements

#### 1. Jitter Analysis
- **Jitter Percentage**: Measures cycle-to-cycle frequency variations
- **Absolute Jitter**: Average absolute difference between consecutive frequencies
- **RAP (Relative Average Perturbation)**: Short-term frequency variation
- **PPQ (Period Perturbation Quotient)**: Medium-term frequency variation

#### 2. Shimmer Analysis
- **Shimmer Percentage**: Measures amplitude variations between cycles
- **APQ3/APQ5**: Amplitude perturbation quotients over 3 and 5 periods
- **DDA**: Difference of differences of amplitudes

#### 3. Frequency Analysis
- **Fundamental Frequency (F0)**: Base vocal frequency extraction
- **Harmonic-to-Noise Ratio (HNR)**: Measures voice clarity
- **Noise-to-Harmonic Ratio (NHR)**: Quantifies noise level in voice

### Advanced Features

#### 1. Spectral Analysis
- FFT-based frequency spectrum analysis
- Harmonic energy calculation
- Noise energy estimation
- Spectral spread measurements

#### 2. Nonlinear Dynamics
- **DFA (Detrended Fluctuation Analysis)**: Long-range correlations
- **RPDE (Recurrence Period Density Entropy)**: Voice complexity measure
- **PPE (Pitch Period Entropy)**: Pitch variability measurement
- **D2 (Correlation Dimension)**: Voice dynamics complexity

### Processing Pipeline
1. Audio frame segmentation (30ms frames, 50% overlap)
2. Feature extraction per frame
3. Statistical analysis and outlier removal
4. Comprehensive voice quality assessment

## Getting Started

### Prerequisites
- iOS device running iOS 15.0 or later
- Xcode 15.0 or later for development
- Swift 5.0 or later

### Installation
1. Clone the repository
2. Open `Tremor Check.xcodeproj` in Xcode
3. Build and run the project on your iOS device or simulator

## License

This project is licensed under the terms included in the LICENSE file.

## Support

For technical support or feature requests, please open an issue in the repository. 
