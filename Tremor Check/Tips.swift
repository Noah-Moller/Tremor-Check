import SwiftUI
import TipKit

struct StartRecordingTip: Tip {
    var title: Text {
        Text("Press Start Recording")
    }

    var message: Text? {
        Text("Press start recording and then speak the phrase.")
    }

    var image: Image? {
        Image(systemName: "record.circle")
    }
}

struct AnalyzeRecordingTip: Tip {
    var title: Text {
        Text("Press Analyze Phrase")
    }

    var message: Text? {
        Text("Press analyze phrase to detect potential voice tremors.")
    }

    var image: Image? {
        Image(systemName: "waveform.path")
    }
}

struct ArticleTip: Tip {
    var title: Text {
        Text("Tap the article to learn more")
    }

    var message: Text? {
        Text("Tap to article to be redirected to the article")
    }

    var image: Image? {
        Image(systemName: "magazine")
    }
}
