import SwiftUI

struct ToastView: View {
    @ObservedObject private var errorService = ErrorHandlingService.shared
    
    var body: some View {
        VStack {
            Spacer()
            if let appError = errorService.currentError {
                HStack {
                    Image(systemName: appError.isCritical ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(appError.isCritical ? .red : .yellow)
                    Text(appError.message)
                        .padding(.leading, 5)
                    Spacer()
                }
                .padding()
                .background(Material.bar)
                .cornerRadius(10)
                .shadow(radius: 5)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation {
                            errorService.clearError()
                        }
                    }
                }
                .onTapGesture {
                    withAnimation {
                        errorService.clearError()
                    }
                }
            }
        }
        .padding()
        .animation(.spring(), value: errorService.currentError?.id)
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        // To preview, you can temporarily set an error on the service
        let errorService = ErrorHandlingService.shared
        // errorService.showError(message: "This is a sample error message.")
        return ToastView()
    }
}
