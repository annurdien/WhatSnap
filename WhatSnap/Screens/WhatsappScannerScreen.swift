import SwiftUI

struct WhatsappScannerScreen: View {
    @State var detectedPhoneNumber: String?
    @State var selectedCountry: String = "Indonesia"
    
    let countryCodes: [String: String] = Constant.countryCodes
    
    var body: some View {
        VStack {
            HStack {
                Image(.whatsappGreen)
                    .resizable()
                    .frame(width: 50, height: 50)
                
                Text(AppText.whatSnap)
                    .font(.title)
                    .bold()
                    .foregroundStyle(.green)
            }
            .padding(.bottom, 25)
            
            Spacer()
            
            ZStack {
                CameraView(detectedPhoneNumber: $detectedPhoneNumber)
                
                Picker(AppText.selectCountry, selection: $selectedCountry) {
                    ForEach(Array(countryCodes.keys), id: \.self) { country in
                        Text("\(country): \(countryCodes[country] ?? "")")
                            .tag(country)
                    }
                }
                .pickerStyle(.menu)
                .foregroundStyle(.green)
                .tint(.white)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
                .padding(.top, 15)
                .offset(y: -300)
                
                VStack {
                    Spacer()
                    
                    if let detectedPhoneNumber {
                        Button(action: {
                            openWhatsApp(phoneNumber: detectedPhoneNumber)
                        }, label: {
                            HStack {
                                Image(.whatsappIcon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .padding(.trailing, 5)
                                
                                Text(detectedPhoneNumber)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.forward.square")
                            }
                            .padding()
                            .foregroundStyle(.white)
                            .background(.green)
                            .clipShape(.buttonBorder)
                        })
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: 700)
            .background(.secondary)
            .cornerRadius(20)
        }
        .padding()
    }
    
    func openWhatsApp(phoneNumber: String) {
        let formattedPhoneNumber = phoneNumber.toPhoneNumberFormat(countryId: countryCodes[selectedCountry] ?? "+62")
        let urlString = "https://wa.me/\(formattedPhoneNumber)"
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            print("WhatsApp not installed or invalid phone number.")
        }
    }
}

#Preview {
    WhatsappScannerScreen()
}
