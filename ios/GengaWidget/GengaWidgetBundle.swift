import WidgetKit
import SwiftUI

@main
struct GengaWidgetBundle: WidgetBundle {
    var body: some Widget {
        GengaSummaryWidget()
        GengaQuickActionsWidget()
    }
}
