import SwiftUI

struct ContentView: View {
    var body: some View {
        NookListView()
            .frame(width: 600, height: 700)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
