//
//  ContentView.swift
//  esp32_ble_client
//
//  Created by baby Enjhon on 2/10/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @ObservedObject var bleManager = BLEManager()
    
    @State var isEsp32LedEnabled = false
    @State var sevenSegmentValue = 0
    @State var trafficLightColor = "RED"

    //@State var isAutoSwitched = false
    @State private var timer: Timer.TimerPublisher = Timer.publish(every: 1, on: .main, in: .common)
    @State private var cancellable: AnyCancellable?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                if bleManager.peripherals.isEmpty {
                    ProgressView("ESP32 장치를 찾는중입니다")
                        .progressViewStyle(.circular)
                } else if bleManager.isConnected {
                    List {
                        
                        Section("Traffic Light") {
                            trafficLight
                        }
                        
                        Button("Disconnect") {
                            bleManager.disconnectFromPeripheral()
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .onAppear {
                        isEsp32LedEnabled = false
                        sevenSegmentValue = 0
                        trafficLightColor = "RED"
                        cancellable?.cancel()
                    }
                } else {
                    List(bleManager.peripherals) { peripheral in
                        device(peripheral)
                    }
                    .refreshable {
                        bleManager.refreshDevices()
                    }
                }
            }
            .navigationTitle("ESP32 Control")
        }
    }
    
    private var trafficLight: some View {
        VStack(alignment: .leading) {
            Divider()
            Picker("Traffic Light", selection: $trafficLightColor) {
                Text("Red").tag("RED")
                Text("Yellow").tag("YELLOW")
                Text("Green").tag("GREEN")
            }
            .frame(height: 50)
            .pickerStyle(.segmented)
            .tint(.blue)
            .onChange(of: trafficLightColor) { _, newValue in
                switch trafficLightColor {
                case "RED":
                    trafficLightColor = "RED"
                    bleManager.sendTextValue("RED")
                    print("RED Color..")
                case "YELLOW":
                    trafficLightColor = "YELLOW"
                    print("GREEN Color..")
                    bleManager.sendTextValue("YELLOW")
                case "GREEN":
                    trafficLightColor = "GREEN"
                    print("GREEN Color..")
                    bleManager.sendTextValue("GREEN")
                default:
                    trafficLightColor = "RED"
                    print("Default RED Color..")
                    bleManager.sendTextValue("RED")
                }
                
            }
        }
    }
    
    private func device(_ peripheral: Peripheral) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(peripheral.name)
                Spacer()
                Button(action: {
                    bleManager.connectPeripheral(peripheral: peripheral)
                }) {
                    Text("Connect")
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Group {
                    Text("""
                              Device UUID:
                              \(peripheral.id.uuidString)
                              """)
                    .padding([.bottom], 10)
                    
                    if let adsServiceUUIDs = peripheral.advertisementServiceUUIDs {
                        Text("Advertisement Service UUIDs:")
                        ForEach(adsServiceUUIDs, id: \.self) { uuid in
                            Text(uuid)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "chart.bar.fill")
                        Text("\(peripheral.rssi) dBm")
                    }
                    .padding([.top], 10)
                }
                .font(.footnote)
            }
        }
    }
}


#Preview {
    ContentView()
}
