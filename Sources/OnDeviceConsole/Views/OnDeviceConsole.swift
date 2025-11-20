//
//  OnDeviceConsole.swift
//  OnDeviceConsole
//
//  Created by Tom Redway on 19/11/2025.
//

import SwiftUI

struct ConsoleOverlayView: View {
    
    @State private var consoleManager = ConsoleManager.shared
    @State private var isSheetPresented = false
    @State private var showHint = false
    @State private var hintTimer: Timer?
    
    var body: some View {
        
        VStack(alignment: .leading) {
            
            HStack(spacing: 12) {
                
                floatingButton
                
                if showHint, let latestLog = consoleManager.logs.last {
                    
                    hintView(log: latestLog)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding(.top, 60)
            .padding(.leading, 16)
            
            Spacer()
        }
        .onChange(of: consoleManager.logs.count) {
            
            showHintTemporarily()
        }
        .sheet(isPresented: $isSheetPresented) {
            
            consoleSheet
        }
    }
    
    private var floatingButton: some View {
        Button(action: {
            isSheetPresented = true
            showHint = false
            hintTimer?.invalidate()
        }) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
    
    private func hintView(log: ConsoleLog) -> some View {
        
        HStack(spacing: 8) {
            
            VStack(alignment: .leading, spacing: 2) {
                
                Text(log.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(log.message)
                    .font(.caption)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: 250)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 4)
    }
    
    private var consoleSheet: some View {
        
        NavigationView {
            
            ScrollViewReader { proxy in
                
                ScrollView {
                    
                    LazyVStack(alignment: .leading, spacing: 12) {
                        
                        ForEach(consoleManager.logs) { log in
                            
                            logRow(log: log)
                                .id(log.id)
                        }
                    }
                    .padding()
                }
                .onAppear {
                    
                    if let lastLog = consoleManager.logs.last {
                        
                        proxy.scrollTo(lastLog.id, anchor: .bottom)
                    }
                }
            }
            .navigationTitle("Console Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    
                    Button("Clear") { consoleManager.clearLogs() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    
                    Button("Done") { isSheetPresented = false }
                }
            }
        }
    }
    
    private func logRow(log: ConsoleLog) -> some View {
        
        VStack(alignment: .leading, spacing: 4) {
            
            Text(log.formattedTime)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(log.message)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func showHintTemporarily() {
        
        hintTimer?.invalidate()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            
            showHint = true
        }
        
        hintTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            
            Task { @MainActor in
            
                withAnimation(.easeInOut(duration: 0.3)) {
                    
                    showHint = false
                }
            }
        }
    }
}

extension View {
    
    public func consoleOverlay() -> some View {
        
        ZStack {
            
            self
            
            ConsoleOverlayView()
        }
    }
}
