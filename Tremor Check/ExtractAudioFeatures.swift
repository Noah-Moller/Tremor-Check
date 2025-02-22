import Accelerate
import AVFoundation

// MARK: - Audio Feature Extraction

/**
 Extracts various audio features from a recorded audio file.
 
 This function reads an audio file using AVFoundation, converts its data into a PCM buffer,
 and processes the raw audio samples to compute several voice quality metrics such as jitter,
 shimmer, fundamental frequency statistics, harmonic-to-noise ratios, and spectral spread values.
 The results are returned as a dictionary mapping feature names to their computed values.
 
 - Parameter url: The URL of the audio file to be processed.
 - Returns: A dictionary of feature names and values, or `nil` if an error occurs.
 */
func extractAudioFeatures(from url: URL) -> [String: Double]? {
    print("Starting audio feature extraction...")
    
    do {
        // Attempt to open the audio file for reading.
        let audioFile = try AVAudioFile(forReading: url)
        // Get the audio processing format (sample rate, channel count, etc.)
        let format = audioFile.processingFormat
        // Retrieve the total number of audio frames in the file.
        let frameLength = UInt32(audioFile.length)
        
        print("Audio file loaded - Format: \(format), Length: \(frameLength)")
        
        // Allocate an AVAudioPCMBuffer with the file's format and enough capacity for all frames.
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameLength) else {
            print("Failed to create PCM buffer")
            return nil
        }
        
        // Read the audio data from the file into the buffer.
        try audioFile.read(into: buffer)
        
        // Ensure that the buffer contains float channel data.
        guard let floatChannelData = buffer.floatChannelData else {
            print("Failed to get float channel data")
            return nil
        }
        
        print("Successfully read audio data into buffer")
        
        // Convert the first channel's data into an array of Floats.
        let audioData = Array(UnsafeBufferPointer(start: floatChannelData[0], count: Int(frameLength)))
        
        print("Converting to audio data array, length: \(audioData.count)")
        
        // Calculate fundamental frequencies (f0) and obtain summary statistics.
        let fundamentalFrequencies = calculateFundamentalFrequencies(audioData: audioData, sampleRate: format.sampleRate)
        // Compute jitter metrics based on variations in fundamental frequencies.
        let jitterPercentage = calculateJitterPercentage(fundamentalFrequencies: fundamentalFrequencies.frequencies)
        let jitterAbs = calculateJitterAbs(fundamentalFrequencies: fundamentalFrequencies.frequencies)
        let rap = calculateRAP(fundamentalFrequencies: fundamentalFrequencies.frequencies)
        let ppq = calculatePPQ(fundamentalFrequencies: fundamentalFrequencies.frequencies)
        
        // Calculate amplitude peaks and use them to derive shimmer and spectral spread features.
        let amplitudePeaks = calculateAmplitudePeaks(audioData: audioData, sampleRate: format.sampleRate)
        let shimmerPercentage = calculateShimmerPercentage(amplitudePeaks: amplitudePeaks)
        let (spread1, spread2) = calculateSpreadValues(audioData: audioData, sampleRate: format.sampleRate)
        // Compute Harmonics-to-Noise Ratio (HNR) and Noise-to-Harmonics Ratio (NHR) via FFT.
        let hnr = calculateHNR(audioData: audioData, sampleRate: format.sampleRate)
        let nhr = calculateNHR(audioData: audioData, sampleRate: format.sampleRate)
        // Compute the Pitch Period Entropy (PPE) as a measure of pitch variability.
        let ppe = calculatePPE(fundamentalFrequencies: fundamentalFrequencies.frequencies)
        
        // Return a dictionary containing all the computed audio features.
        return [
            "jitter_percent": jitterPercentage,
            "jitter_abs": jitterAbs,
            "rap": rap,
            "ppq": ppq,
            "shimmer_percent": shimmerPercentage,
            "spread1": spread1,
            "spread2": spread2,
            "hnr": hnr,
            "nhr": nhr,
            "ppe": ppe,
            "f0_mean": fundamentalFrequencies.average,
            "f0_max": fundamentalFrequencies.max,
            "f0_min": fundamentalFrequencies.min
        ]
    } catch {
        // If any error occurs during file reading or processing, log it and return nil.
        print("Error in audio feature extraction: \(error)")
        return nil
    }
}

// MARK: - Jitter and Shimmer Calculations

/**
 Calculates jitter, a measure of frequency instability in the audio signal.
 
 This function uses the zero-crossing rate to estimate the variability in the pitch period.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: The computed jitter value.
 */
func calculateJitter(audioData: [Float], sampleRate: Double) -> Double {
    // Calculate positions (indices) where the audio signal crosses zero.
    let zeroCrossings = zeroCrossingRate(audioData: audioData)
    // Compute the variability in pitch periods based on zero crossing differences.
    let pitchPeriodVariability = pitchPeriodVariation(zeroCrossings: zeroCrossings, sampleRate: sampleRate)
    return pitchPeriodVariability
}

/**
 Calculates shimmer, a measure of amplitude instability.
 
 This function computes the variability in the amplitude peaks over short time segments.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: The computed shimmer value.
 */
func calculateShimmer(audioData: [Float], sampleRate: Double) -> Double {
    // Compute amplitude variation across short time windows.
    let amplitudeVariability = amplitudeVariation(audioData: audioData, sampleRate: sampleRate)
    return amplitudeVariability
}

/**
 Calculates the Harmonics-to-Noise Ratio (HNR) of the audio signal.
 
 HNR is computed by performing an FFT to separate harmonic energy from noise energy,
 then converting the ratio into decibels.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: The HNR value in decibels.
 */
func calculateHNR(audioData: [Float], sampleRate: Double) -> Double {
    // Calculate the energy present in harmonic components.
    let harmonicEnergy = calculateHarmonicEnergy(audioData: audioData)
    // Calculate the energy assumed to be noise.
    let noiseEnergy = calculateNoiseEnergy(audioData: audioData)
    // Return the ratio in dB (10 * log10 of the ratio).
    return 10 * log10(harmonicEnergy / noiseEnergy)
}

// MARK: - Helper Functions for Signal Analysis

/**
 Calculates the positions of zero crossings in the audio data.
 
 A zero crossing occurs when the audio signal changes its sign. This information is useful
 for estimating pitch period variations.
 
 - Parameter audioData: Array of audio samples.
 - Returns: An array of indices (as Doubles) where zero crossings occur.
 */
func zeroCrossingRate(audioData: [Float]) -> [Double] {
    var zeroCrossings: [Double] = []
    // Iterate through the audio data starting from the second sample.
    for i in 1..<audioData.count {
        // Check if there is a sign change between consecutive samples.
        if (audioData[i-1] >= 0 && audioData[i] < 0) || (audioData[i-1] < 0 && audioData[i] >= 0) {
            zeroCrossings.append(Double(i))
        }
    }
    return zeroCrossings
}

/**
 Estimates the pitch period variation using zero crossing indices.
 
 This function calculates the time intervals (periods) between successive zero crossings,
 computes their average, and then determines the average absolute deviation from this mean.
 
 - Parameters:
    - zeroCrossings: Array of indices where zero crossings occur.
    - sampleRate: The sampling rate of the audio.
 - Returns: The average absolute deviation (variability) in the pitch period.
 */
func pitchPeriodVariation(zeroCrossings: [Double], sampleRate: Double) -> Double {
    // If there are too few zero crossings, return zero variation.
    guard zeroCrossings.count > 1 else { return 0.0 }
    
    var pitchPeriods: [Double] = []
    // Compute the period (in seconds) between each pair of consecutive zero crossings.
    for i in 1..<zeroCrossings.count {
        let period = (zeroCrossings[i] - zeroCrossings[i - 1]) / sampleRate
        pitchPeriods.append(period)
    }
    
    // Calculate the mean period.
    let meanPeriod = pitchPeriods.reduce(0, +) / Double(pitchPeriods.count)
    // Calculate the absolute deviations from the mean.
    let periodVariations = pitchPeriods.map { abs($0 - meanPeriod) }
    // Return the mean variation as a measure of jitter.
    let meanVariation = periodVariations.reduce(0, +) / Double(periodVariations.count)
    
    return meanVariation
}

/**
 Calculates the Noise-to-Harmonics Ratio (NHR) for the audio signal.
 
 NHR is computed as the ratio of noise energy to harmonic energy, where harmonic energy
 is estimated from the FFT of the signal.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: The computed NHR value.
 */
func calculateNHR(audioData: [Float], sampleRate: Double) -> Double {
    let harmonicEnergy = calculateHarmonicEnergy(audioData: audioData)
    let noiseEnergy = calculateNoiseEnergy(audioData: audioData)
    return noiseEnergy / harmonicEnergy
}

/**
 Computes amplitude variation (used for shimmer) over short segments of the audio signal.
 
 The audio is divided into small windows (e.g., 10ms). In each window, the peak amplitude is
 extracted, and the relative differences between successive peaks are computed.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: The average relative amplitude variation (shimmer) as a Double.
 */
func amplitudeVariation(audioData: [Float], sampleRate: Double) -> Double {
    // Define the window size as 10ms worth of samples.
    let windowSize = Int(sampleRate / 100.0)
    var amplitudePeaks: [Float] = []
    
    // Process the audio in non-overlapping windows.
    for i in stride(from: 0, to: audioData.count, by: windowSize) {
        let window = Array(audioData[i..<min(i + windowSize, audioData.count)])
        // Find the maximum absolute amplitude in the window.
        if let maxPeak = window.max() {
            amplitudePeaks.append(abs(maxPeak))
        }
    }
    
    // Ensure that there are enough peaks to calculate shimmer.
    guard amplitudePeaks.count > 1 else { return 0.0 }
    
    var shimmerValues: [Float] = []
    // Calculate the relative difference between consecutive amplitude peaks.
    for i in 1..<amplitudePeaks.count {
        let diff = abs(amplitudePeaks[i] - amplitudePeaks[i - 1])
        let avg = (amplitudePeaks[i] + amplitudePeaks[i - 1]) / 2
        if avg != 0 {
            shimmerValues.append(diff / avg)
        }
    }
    
    // Return the mean of the relative differences.
    let meanShimmer = shimmerValues.reduce(0, +) / Float(shimmerValues.count)
    return Double(meanShimmer)
}

// MARK: - Detailed Jitter Metrics

/**
 Calculates Jitter (%) based on the relative period-to-period variations in fundamental frequency.
 
 This function computes the differences in pitch periods (derived as the reciprocal of the frequency)
 between consecutive frames, averages these differences, and expresses the result as a percentage of
 the average period.
 
 - Parameter fundamentalFrequencies: An array of fundamental frequency values (f0).
 - Returns: The jitter percentage.
 */
func calculateJitterPercentage(fundamentalFrequencies: [Double]) -> Double {
    guard fundamentalFrequencies.count > 1 else {
        print("Not enough fundamental frequencies for jitter calculation")
        return 0.0
    }
    
    print("Calculating jitter from \(fundamentalFrequencies.count) frequencies")
    print("Frequencies: \(fundamentalFrequencies)")
    
    var periodVariations: [Double] = []
    // Convert each frequency to its corresponding period and compute differences.
    for i in 0..<fundamentalFrequencies.count-1 {
        let currentPeriod = 1.0 / fundamentalFrequencies[i]
        let nextPeriod = 1.0 / fundamentalFrequencies[i + 1]
        let variation = abs(nextPeriod - currentPeriod)
        periodVariations.append(variation)
    }
    
    print("Period variations: \(periodVariations)")
    
    // Compute the average period over all frequencies.
    let averagePeriod = fundamentalFrequencies.map { 1.0 / $0 }.reduce(0, +) / Double(fundamentalFrequencies.count)
    
    // Compute the average period-to-period variation.
    let averageVariation = periodVariations.reduce(0, +) / Double(periodVariations.count)
    // Express the jitter as a percentage of the average period.
    let jitterPercentage = (averageVariation / averagePeriod) * 100.0
    
    print("Average period: \(averagePeriod)")
    print("Average variation: \(averageVariation)")
    print("Calculated jitter percentage: \(jitterPercentage)")
    
    return jitterPercentage
}

/**
 Calculates Absolute Jitter (Jitter (Abs)) as the average absolute difference between successive frequencies.
 
 - Parameter fundamentalFrequencies: An array of fundamental frequency values.
 - Returns: The absolute jitter value.
 */
func calculateJitterAbs(fundamentalFrequencies: [Double]) -> Double {
    guard fundamentalFrequencies.count > 1 else { return 0.0 }
    var periodDifferences: [Double] = []
    for i in 1..<fundamentalFrequencies.count {
        periodDifferences.append(abs(fundamentalFrequencies[i] - fundamentalFrequencies[i - 1]))
    }
    return periodDifferences.reduce(0, +) / Double(periodDifferences.count)
}

/**
 Calculates RAP (Relative Average Perturbation) based on fundamental frequency variations.
 
 RAP is computed by taking the absolute difference between a frequency and the frequency two frames before,
 divided by 2, then averaging these values.
 
 - Parameter fundamentalFrequencies: An array of fundamental frequency values.
 - Returns: The RAP value.
 */
func calculateRAP(fundamentalFrequencies: [Double]) -> Double {
    guard fundamentalFrequencies.count >= 3 else { return 0.0 }
    var rapValues: [Double] = []
    for i in 2..<fundamentalFrequencies.count {
        let rap = abs(fundamentalFrequencies[i] - fundamentalFrequencies[i - 2]) / 2
        rapValues.append(rap)
    }
    return rapValues.reduce(0, +) / Double(rapValues.count)
}

/**
 Calculates PPQ (Five-point Period Perturbation Quotient) using fundamental frequencies.
 
 PPQ is computed as the average absolute difference between the current frequency and the frequency
 four frames earlier, divided by 4.
 
 - Parameter fundamentalFrequencies: An array of fundamental frequency values.
 - Returns: The PPQ value.
 */
func calculatePPQ(fundamentalFrequencies: [Double]) -> Double {
    guard fundamentalFrequencies.count >= 5 else { return 0.0 }
    var ppqValues: [Double] = []
    for i in 4..<fundamentalFrequencies.count {
        let ppq = abs((fundamentalFrequencies[i] - fundamentalFrequencies[i - 4]) / 4)
        ppqValues.append(ppq)
    }
    return ppqValues.reduce(0, +) / Double(ppqValues.count)
}

/**
 Calculates DDP (Difference of differences of periods), a derived measure from RAP.
 
 - Parameter fundamentalFrequencies: An array of fundamental frequency values.
 - Returns: The DDP value.
 */
func calculateDDP(fundamentalFrequencies: [Double]) -> Double {
    guard fundamentalFrequencies.count >= 2 else { return 0.0 }
    let rap = calculateRAP(fundamentalFrequencies: fundamentalFrequencies)
    return 2 * rap
}

// MARK: - Detailed Shimmer Metrics

/**
 Calculates Shimmer (%) based on amplitude peak variations.
 
 This function computes the relative differences between successive amplitude peaks,
 averages these differences, and expresses the result as a percentage.
 
 - Parameter amplitudePeaks: An array of peak amplitude values.
 - Returns: The shimmer percentage.
 */
func calculateShimmerPercentage(amplitudePeaks: [Double]) -> Double {
    guard amplitudePeaks.count > 1 else { return 0.0 }
    var amplitudeDifferences: [Double] = []
    for i in 1..<amplitudePeaks.count {
        amplitudeDifferences.append(abs(amplitudePeaks[i] - amplitudePeaks[i - 1]))
    }
    let avgAmplitudeDifference = amplitudeDifferences.reduce(0, +) / Double(amplitudeDifferences.count)
    let avgAmplitude = amplitudePeaks.reduce(0, +) / Double(amplitudePeaks.count)
    return (avgAmplitudeDifference / avgAmplitude) * 100.0
}

/**
 Calculates Shimmer in decibels (dB) based on amplitude peak ratios.
 
 - Parameter amplitudePeaks: An array of peak amplitude values.
 - Returns: The shimmer value in dB.
 */
func calculateShimmerDB(amplitudePeaks: [Double]) -> Double {
    guard amplitudePeaks.count > 1 else { return 0.0 }
    var shimmerDBValues: [Double] = []
    for i in 1..<amplitudePeaks.count {
        // Compute the ratio in dB between consecutive peaks.
        let shimmerDB = 20 * log10(amplitudePeaks[i] / amplitudePeaks[i - 1])
        shimmerDBValues.append(abs(shimmerDB))
    }
    return shimmerDBValues.reduce(0, +) / Double(shimmerDBValues.count)
}

/**
 Calculates APQ3 (Amplitude Perturbation Quotient over 3 periods).
 
 - Parameter amplitudePeaks: An array of peak amplitude values.
 - Returns: The APQ3 value.
 */
func calculateAPQ3(amplitudePeaks: [Double]) -> Double {
    guard amplitudePeaks.count >= 3 else { return 0.0 }
    var apqValues: [Double] = []
    for i in 2..<amplitudePeaks.count {
        let apq = abs((amplitudePeaks[i] + amplitudePeaks[i - 1] + amplitudePeaks[i - 2]) / 3)
        apqValues.append(apq)
    }
    return apqValues.reduce(0, +) / Double(apqValues.count)
}

/**
 Calculates APQ5 (Amplitude Perturbation Quotient over 5 periods).
 
 - Parameter amplitudePeaks: An array of peak amplitude values.
 - Returns: The APQ5 value.
 */
func calculateAPQ5(amplitudePeaks: [Double]) -> Double {
    guard amplitudePeaks.count >= 5 else { return 0.0 }
    var apqValues: [Double] = []
    for i in 4..<amplitudePeaks.count {
        let apq = abs((amplitudePeaks[i] - amplitudePeaks[i - 4]) / 5)
        apqValues.append(apq)
    }
    return apqValues.reduce(0, +) / Double(apqValues.count)
}

/**
 Calculates DDA (Difference of differences of amplitudes) for amplitude perturbation.
 
 - Parameter amplitudePeaks: An array of peak amplitude values.
 - Returns: The DDA value.
 */
func calculateDDA(amplitudePeaks: [Double]) -> Double {
    guard amplitudePeaks.count >= 3 else { return 0.0 }
    var ddaValues: [Double] = []
    for i in 1..<amplitudePeaks.count - 1 {
        let dda = abs(amplitudePeaks[i + 1] - 2 * amplitudePeaks[i] + amplitudePeaks[i - 1])
        ddaValues.append(dda)
    }
    return ddaValues.reduce(0, +) / Double(ddaValues.count)
}

// MARK: - FFT-Based Energy Calculations

/**
 Calculates the harmonic energy of the audio signal using an FFT.
 
 The FFT is performed on the audio data to obtain the frequency spectrum. The energy from
 the first few harmonic components (e.g., indices 1 through 9) is summed up as an estimate
 of the harmonic energy.
 
 - Parameter audioData: Array of audio samples.
 - Returns: The computed harmonic energy.
 */
func calculateHarmonicEnergy(audioData: [Float]) -> Double {
    // Prepare arrays for the real and imaginary parts of the FFT output.
    var real = [Float](repeating: 0.0, count: audioData.count)
    var imaginary = [Float](repeating: 0.0, count: audioData.count)
    
    // Calculate the log2 of the number of samples for FFT setup.
    let log2n = vDSP_Length(log2(Float(audioData.count)))
    let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
    
    // Create a DSPSplitComplex structure that holds the FFT data.
    var splitComplex = DSPSplitComplex(realp: &real, imagp: &imaginary)
    
    // Convert the audio data into a complex format required by the FFT function.
    audioData.withUnsafeBufferPointer { pointer in
        pointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: audioData.count) { complexPointer in
            vDSP_ctoz(complexPointer, 2, &splitComplex, 1, vDSP_Length(audioData.count / 2))
        }
    }
    
    // Perform an in-place FFT on the split-complex data.
    vDSP_fft_zrip(fftSetup!, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
    
    // Calculate the squared magnitudes (power) of the FFT output.
    var magnitudes = [Float](repeating: 0.0, count: audioData.count / 2)
    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(audioData.count / 2))
    
    // Sum the power of the first 10 harmonic components (ignoring the DC component at index 0).
    let harmonicEnergy = magnitudes[1..<10].reduce(0, +)
    
    // Clean up the FFT setup.
    vDSP_destroy_fftsetup(fftSetup)
    
    return Double(harmonicEnergy)
}

/**
 Calculates the Detrended Fluctuation Analysis (DFA) slope.
 
 DFA is a method for detecting long-range correlations in time series data. Here, the audio
 signal is first integrated, then divided into windows, detrended using a linear fit, and
 finally the fluctuations (RMS) are computed over different window sizes. A log-log plot is
 used to fit a line, whose slope is the DFA value.
 
 - Parameter audioData: Array of audio samples.
 - Returns: The DFA slope.
 */
func calculateDFA(audioData: [Float]) -> Double {
    // Convert the audio data to double precision for accurate computation.
    let audioDouble = audioData.map { Double($0) }
    let n = audioDouble.count
    
    // Calculate the mean of the audio data.
    let mean = audioDouble.reduce(0, +) / Double(n)
    
    // Create an integrated (cumulative sum) time series of deviations from the mean.
    var integratedSeries = [Double](repeating: 0.0, count: n)
    for i in 0..<n {
        let deviation = audioDouble[i] - mean
        integratedSeries[i] = (i == 0 ? deviation : integratedSeries[i - 1] + deviation)
    }
    
    // Define window sizes logarithmically spaced between a minimum and maximum window.
    let minWindow = 4
    let maxWindow = n / 4
    let numWindows = 20
    let windows = stride(from: log(Double(minWindow)), to: log(Double(maxWindow)), by: (log(Double(maxWindow)) - log(Double(minWindow))) / Double(numWindows)).map { exp($0) }
    
    var fluctuations = [Double]()
    // For each window size, compute the RMS of the detrended integrated series.
    for window in windows {
        let windowSize = Int(window)
        if windowSize >= n { break }
        
        var rmsValues = [Double]()
        for start in stride(from: 0, to: n - windowSize, by: windowSize) {
            let segment = Array(integratedSeries[start..<start+windowSize])
            
            // Fit a linear trend to the segment (least squares).
            let (slope, intercept) = linearFit(x: Array(0..<segment.count).map { Double($0) }, y: segment)
            // Compute the linear trend.
            let trend = segment.enumerated().map { Double($0.offset) * slope + intercept }
            // Detrend by subtracting the trend from the segment.
            let detrended = zip(segment, trend).map { $0.0 - $0.1 }
            
            // Compute the root mean square of the detrended segment.
            let rms = sqrt(detrended.map { $0 * $0 }.reduce(0, +) / Double(detrended.count))
            rmsValues.append(rms)
        }
        let avgRMS = rmsValues.reduce(0, +) / Double(rmsValues.count)
        fluctuations.append(avgRMS)
    }
    
    // Fit a line to the log-log plot of window sizes vs. fluctuations.
    let logWindows = windows.map { log($0) }
    let logFluctuations = fluctuations.map { log($0) }
    let (dfaSlope, _) = linearFit(x: logWindows, y: logFluctuations)
    
    return dfaSlope
}

/**
 Performs a simple linear least squares fit.
 
 Given arrays of x and y values, this function computes the slope and intercept of the best-fit line.
 
 - Parameters:
    - x: Array of x values.
    - y: Array of y values.
 - Returns: A tuple containing the slope and intercept.
 */
func linearFit(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
    let n = Double(x.count)
    let sumX = x.reduce(0, +)
    let sumY = y.reduce(0, +)
    let sumXY = zip(x, y).reduce(0) { $0 + $1.0 * $1.1 }
    let sumX2 = x.reduce(0) { $0 + $1 * $1 }
    
    let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
    let intercept = (sumY - slope * sumX) / n
    
    return (slope, intercept)
}

/**
 Calculates the noise energy in the audio signal.
 
 Noise energy is estimated as the total energy of the signal minus the harmonic energy.
 A non-negative value is ensured.
 
 - Parameter audioData: Array of audio samples.
 - Returns: The noise energy.
 */
func calculateNoiseEnergy(audioData: [Float]) -> Double {
    // Compute the total energy (sum of squares) of the signal.
    let totalEnergy = audioData.map { $0 * $0 }.reduce(0, +)
    // Get the harmonic energy from the FFT.
    let harmonicEnergy = calculateHarmonicEnergy(audioData: audioData)
    // The noise energy is the remainder; ensure it's non-negative.
    let noiseEnergy = Double(totalEnergy) - harmonicEnergy
    return max(noiseEnergy, 0.0)
}

// MARK: - Nonlinear Dynamics & Complexity Measures

/**
 Calculates the correlation dimension (D2) of the audio signal.
 
 D2 is estimated by reconstructing the phase space of the audio signal (using time delay embedding),
 computing pairwise distances, and analyzing how the correlation sum scales with a small radius epsilon.
 
 - Parameters:
    - audioData: Array of audio samples.
    - embeddingDimension: The dimension for phase space reconstruction (default is 2).
    - delay: The time delay for embedding (default is 1).
 - Returns: An estimate of the correlation dimension.
 */
func calculateD2(audioData: [Float], embeddingDimension: Int = 2, delay: Int = 1) -> Double {
    // Convert audio data to double for precision.
    let audioDouble = audioData.map { Double($0) }
    let n = audioDouble.count
    
    // Create an embedded time series (phase space reconstruction).
    var embeddedSeries = [[Double]]()
    for i in 0..<(n - (embeddingDimension - 1) * delay) {
        let vector = (0..<embeddingDimension).map { j in
            audioDouble[i + j * delay]
        }
        embeddedSeries.append(vector)
    }
    
    // Calculate pairwise distances between embedded vectors.
    var distances = [Double]()
    for i in 0..<embeddedSeries.count {
        for j in (i+1)..<embeddedSeries.count {
            let distance = euclideanDistance(embeddedSeries[i], embeddedSeries[j])
            distances.append(distance)
        }
    }
    
    // Choose a small radius epsilon based on the maximum distance.
    let epsilon = 0.1 * (distances.max() ?? 1.0)
    // Count how many distances are below epsilon.
    let correlationSum = distances.filter { $0 < epsilon }.count
    let correlation = Double(correlationSum) / Double(embeddedSeries.count * (embeddedSeries.count - 1) / 2)
    
    // The slope of the log-log plot of correlation vs. epsilon approximates the correlation dimension.
    return log(correlation) / log(epsilon)
}

/**
 Computes the Euclidean distance between two vectors.
 
 - Parameters:
    - a: First vector.
    - b: Second vector.
 - Returns: The Euclidean distance.
 */
func euclideanDistance(_ a: [Double], _ b: [Double]) -> Double {
    return sqrt(zip(a, b).map { pow($0 - $1, 2) }.reduce(0, +))
}

/**
 Calculates the Recurrence Period Density Entropy (RPDE) of the audio signal.
 
 RPDE measures the complexity of the signal by embedding it in a phase space, comparing
 the similarity of vectors within a specified radius, and then computing the approximate entropy.
 
 - Parameters:
    - audioData: Array of audio samples.
    - m: Embedding dimension (default is 2).
    - r: Threshold for similarity (default is 0.2).
 - Returns: The RPDE value.
 */
func calculateRPDE(audioData: [Float], m: Int = 2, r: Double = 0.2) -> Double {
    // Convert audio data to double precision.
    let audioDouble = audioData.map { Double($0) }
    let n = audioDouble.count
    var embeddedSeries = [[Double]]()
    
    // Create the embedded vectors (phase space reconstruction).
    for i in 0..<(n - (m - 1)) {
        let vector = Array(audioDouble[i..<i + m])
        embeddedSeries.append(vector)
    }
    
    // Calculate the similarity of each embedded vector with all others.
    var similarities = [Double]()
    for i in 0..<embeddedSeries.count {
        var count = 0
        for j in 0..<embeddedSeries.count {
            if euclideanDistance(embeddedSeries[i], embeddedSeries[j]) < r {
                count += 1
            }
        }
        similarities.append(Double(count) / Double(embeddedSeries.count))
    }
    
    // Compute the approximate entropy based on the average similarity.
    let avgSimilarity = similarities.reduce(0, +) / Double(similarities.count)
    return -log(avgSimilarity)
}

// MARK: - Additional Feature Calculations

/**
 Calculates the Pitch Period Entropy (PPE) from a set of fundamental frequencies.
 
 PPE is a measure of the variability or unpredictability of the pitch periods. Frequencies are
 first normalized, then binned into a histogram, and the entropy of the distribution is computed.
 
 - Parameter fundamentalFrequencies: An array of fundamental frequency values.
 - Returns: The computed entropy.
 */
func calculatePPE(fundamentalFrequencies: [Double]) -> Double {
    guard !fundamentalFrequencies.isEmpty else { return 0.0 }
    
    // Normalize the frequency values by dividing by the maximum frequency.
    let maxFreq = fundamentalFrequencies.max() ?? 1.0
    let normalizedFreqs = fundamentalFrequencies.map { $0 / maxFreq }
    
    // Define the number of bins for the histogram.
    let numBins = 10
    var bins = [Double](repeating: 0.0, count: numBins)
    // Populate the histogram by determining the bin for each normalized frequency.
    for freq in normalizedFreqs {
        let binIndex = min(Int(freq * Double(numBins)), numBins - 1)
        bins[binIndex] += 1.0
    }
    
    // Convert counts to probabilities.
    let total = bins.reduce(0, +)
    let probabilities = bins.map { $0 / total }
    
    // Calculate the entropy of the distribution.
    let entropy = probabilities.reduce(0.0) { (result, p) in
        return result - (p > 0 ? p * log(p) : 0)
    }
    
    return entropy
}

/**
 Calculates two spread values of the audio signal’s power spectrum.
 
 Spread1 is computed as the standard deviation (a measure of dispersion) of the power spectrum,
 and Spread2 is the mean power value.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: A tuple containing Spread1 and Spread2.
 */
func calculateSpreadValues(audioData: [Float], sampleRate: Double) -> (Double, Double) {
    // Ensure the number of audio samples is a power of 2 for efficient FFT computation.
    let n = audioData.count
    guard n > 0, (n & (n - 1)) == 0 else {
        print("Audio data length must be a power of 2 for FFT.")
        return (0.0, 0.0)
    }
    
    // Prepare arrays to store FFT results.
    var real = [Float](repeating: 0.0, count: n)
    var imaginary = [Float](repeating: 0.0, count: n)
    var magnitudes = [Float](repeating: 0.0, count: n / 2)
    
    // Set up the FFT configuration.
    let log2n = vDSP_Length(log2(Float(n)))
    guard let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2)) else {
        print("FFT setup failed.")
        return (0.0, 0.0)
    }
    
    // Create a DSPSplitComplex structure for the FFT.
    var splitComplex = DSPSplitComplex(realp: &real, imagp: &imaginary)
    
    // Convert the real audio data into split-complex format.
    audioData.withUnsafeBufferPointer { pointer in
        pointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n) { complexPointer in
            vDSP_ctoz(complexPointer, 2, &splitComplex, 1, vDSP_Length(n / 2))
        }
    }
    
    // Execute the FFT.
    vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
    
    // Compute the squared magnitude (power) for each frequency bin.
    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(n / 2))
    
    // Scale the magnitudes to compute the power spectrum.
    var powerSpectrum = [Float](repeating: 0.0, count: n / 2)
    let scale = 1.0 / Float(n)
    vDSP_vsmul(&magnitudes, 1, [scale], &powerSpectrum, 1, vDSP_Length(n / 2))
    
    // Calculate Spread1 as the standard deviation of the power spectrum.
    let meanPower = powerSpectrum.reduce(0, +) / Float(powerSpectrum.count)
    let variance = powerSpectrum.reduce(0) { $0 + pow($1 - meanPower, 2) } / Float(powerSpectrum.count)
    let spread1 = sqrt(variance)
    
    // Spread2 is defined as the mean power.
    let spread2 = meanPower
    
    // Clean up the FFT setup.
    vDSP_destroy_fftsetup(fftSetup)
    
    return (Double(spread1), Double(spread2))
}

/**
 Calculates fundamental frequencies (f0) and related statistics from the audio data.
 
 The function divides the audio into overlapping frames (30ms with 50% overlap), estimates the pitch
 of each frame using the autocorrelation method, removes outliers, and then computes the average,
 maximum, and minimum frequencies.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: A tuple containing:
    - frequencies: An array of estimated pitch frequencies.
    - average: The mean pitch frequency.
    - max: The maximum pitch frequency.
    - min: The minimum pitch frequency.
 */
func calculateFundamentalFrequencies(audioData: [Float], sampleRate: Double) -> (frequencies: [Double], average: Double, max: Double, min: Double) {
    // Define the frame size (30ms) and hop size (50% overlap).
    let frameSize = Int(sampleRate * 0.03)  // 30ms frames
    let hopSize = frameSize / 2              // 50% overlap
    var frequencies: [Double] = []
    
    // Process the audio in overlapping frames.
    for i in stride(from: 0, to: audioData.count - frameSize, by: hopSize) {
        let frame = Array(audioData[i..<i + frameSize])
        // Estimate the pitch of the frame using autocorrelation.
        if let pitch = calculatePitch(frame: frame, sampleRate: sampleRate) {
            frequencies.append(pitch)
        }
    }
    
    // Remove outliers from the frequency estimates.
    frequencies = removeOutliers(frequencies)
    
    guard !frequencies.isEmpty else {
        return ([], 0.0, 0.0, 0.0)
    }
    
    let averageFrequency = frequencies.reduce(0, +) / Double(frequencies.count)
    let maxFrequency = frequencies.max() ?? 0.0
    let minFrequency = frequencies.min() ?? 0.0
    
    return (frequencies, averageFrequency, maxFrequency, minFrequency)
}

/**
 Estimates the pitch of a single audio frame using the autocorrelation method.
 
 The frame is first normalized, then its autocorrelation is computed. A peak in the autocorrelation
 is sought within a range corresponding to expected human voice frequencies (50Hz–500Hz). The lag of
 the selected peak is used to compute the pitch.
 
 - Parameters:
    - frame: A segment of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: The estimated pitch frequency, or `nil` if no valid pitch is found.
 */
func calculatePitch(frame: [Float], sampleRate: Double) -> Double? {
    let n = frame.count
    var autocorrelation = [Float](repeating: 0.0, count: n)
    
    // Normalize the frame to ensure amplitude consistency.
    let normalizedFrame = normalizeAudio(frame)
    
    // Compute the autocorrelation of the normalized frame.
    vDSP_conv(normalizedFrame, 1, normalizedFrame, 1, &autocorrelation, 1, vDSP_Length(n), vDSP_Length(n))
    
    // Define expected lags corresponding to the maximum (500 Hz) and minimum (50 Hz) pitch.
    let minLag = Int(sampleRate / 500)  // Corresponds to maximum frequency (500 Hz)
    let maxLag = Int(sampleRate / 50)   // Corresponds to minimum frequency (50 Hz)
    // Use a threshold based on a fraction of the zero-lag autocorrelation value.
    let threshold = 0.2 * autocorrelation[0]
    
    var peakLag: Int?
    var maxValue: Float = 0.0
    
    // Search for the peak in the autocorrelation within the expected lag range.
    for i in minLag...min(maxLag, n-1) {
        if autocorrelation[i] > threshold &&
            autocorrelation[i] > autocorrelation[i-1] &&
            autocorrelation[i] > autocorrelation[i+1] &&
            autocorrelation[i] > maxValue {
            maxValue = autocorrelation[i]
            peakLag = i
        }
    }
    
    // If no peak is found, return nil.
    guard let lag = peakLag else {
        return nil
    }
    
    // Convert the lag (in samples) to frequency.
    let frequency = sampleRate / Double(lag)
    
    // Ensure the frequency is within the valid human voice range.
    if frequency >= 50.0 && frequency <= 500.0 {
        return frequency
    }
    
    return nil
}

/**
 Normalizes an audio frame so that its maximum absolute value is 1.
 
 - Parameter audio: An array of audio samples.
 - Returns: A normalized array of audio samples in the range [-1, 1].
 */
func normalizeAudio(_ audio: [Float]) -> [Float] {
    var normalized = audio
    
    // Find the maximum absolute value in the audio.
    var maxValue: Float = 0.0
    vDSP_maxmgv(audio, 1, &maxValue, vDSP_Length(audio.count))
    
    if maxValue > 0 {
        // Scale all samples so that the maximum absolute value becomes 1.
        var scale = Float(1.0) / maxValue
        vDSP_vsmul(audio, 1, &scale, &normalized, 1, vDSP_Length(audio.count))
    }
    
    return normalized
}

/**
 Extracts amplitude peaks from the audio signal using short windows.
 
 The audio is divided into small windows (10ms), and the maximum absolute amplitude in each window
 is recorded.
 
 - Parameters:
    - audioData: Array of audio samples.
    - sampleRate: The sampling rate of the audio.
 - Returns: An array of amplitude peak values.
 */
func calculateAmplitudePeaks(audioData: [Float], sampleRate: Double) -> [Double] {
    // Define window size corresponding to 10ms.
    let windowSize = Int(sampleRate / 100.0)
    var amplitudePeaks: [Double] = []
    
    // Process the audio in windows.
    for i in stride(from: 0, to: audioData.count, by: windowSize) {
        let window = Array(audioData[i..<min(i + windowSize, audioData.count)])
        if let maxPeak = window.max() {
            amplitudePeaks.append(Double(abs(maxPeak)))
        }
    }
    
    return amplitudePeaks
}

/**
 Removes statistical outliers from an array of values using the IQR method.
 
 - Parameter values: An array of Double values.
 - Returns: A filtered array with outliers removed.
 */
func removeOutliers(_ values: [Double]) -> [Double] {
    guard values.count > 4 else { return values }
    
    let sorted = values.sorted()
    // Determine the first (Q1) and third quartile (Q3) indices.
    let q1Index = values.count / 4
    let q3Index = (values.count * 3) / 4
    let iqr = sorted[q3Index] - sorted[q1Index]
    // Define the acceptable range using 1.5 * IQR.
    let lowerBound = sorted[q1Index] - (1.5 * iqr)
    let upperBound = sorted[q3Index] + (1.5 * iqr)
    
    return values.filter { $0 >= lowerBound && $0 <= upperBound }
}
